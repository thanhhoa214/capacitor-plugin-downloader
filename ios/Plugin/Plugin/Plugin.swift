import Foundation
import Capacitor
import CoreLocation
import UIKit
import Alamofire


class DownloadData {
    var url: String
    var status: StatusCode
    var downloadRequest: DownloadRequest?
    var fileName: String
    var absolutePath: String
    
    init(url: String, fileName: String, status: StatusCode) {
        self.url = url
        self.fileName = fileName
        self.status = status
        self.downloadRequest = nil
        self.absolutePath = ""
    }

    func setDownloadRequest(downloadRequest: DownloadRequest) {
        self.downloadRequest = downloadRequest
    }
    func setAbsolutePath(path: String) -> Void {
        self.absolutePath = path
    }
}


enum StatusCode: String {
    case PENDING = "pending"
    case PAUSED = "paused"
    case DOWNLOADING = "downloading"
    case COMPLETED = "completed"
    case ERROR = "error"
}

typealias JSObject = [String:Any]
typealias JSArray = [JSObject]
@objc(DownloaderPlugin)
public class DownloaderPlugin: CAPPlugin {
    static var downloadDatas:[String:DownloadData] = [:]
    
    @objc func initialize(){
//        Alamofire.Session.default.startRequestsImmediately = false
        Alamofire.Session.default.session.configuration.timeoutIntervalForRequest = 60
        Alamofire.Session.default.session.configuration.timeoutIntervalForResource = 60
    }
    
    @objc static func setTimeout(_ call: CAPPluginCall){
        let timeout = call.getInt("timeout") ?? 60
        Alamofire.Session.default.session.configuration.timeoutIntervalForRequest = Double(timeout)
        Alamofire.Session.default.session.configuration.timeoutIntervalForResource = Double(timeout)
        call.resolve()
    }
    
    public override func load() {
        self.initialize()
    }
    
    public func joinPath(left: String, right: String) -> String {
        let nsString: NSString = NSString.init(string:left);
        return nsString.appendingPathComponent(right);
    }
    
    public func generateId() -> String{
        return NSUUID().uuidString
    }
    
    @objc func createDownload(_ call: CAPPluginCall){
        let url = call.getString("url") ?? nil
        let fileName = call.getString("fileName") ?? ""
        if(url == nil){
            call.reject("Url missing")
            return
        }
//        let query = call.getString("query") ?? nil
//        let headers = call.getObject("headers") ?? nil
//        let path = call.getString("path") ?? nil
        let id = self.generateId()
        DownloaderPlugin.downloadDatas[id] = DownloadData(url: url ?? "", fileName: fileName, status: StatusCode.PENDING )
        
        var obj = JSObject()
        obj["value"] = id
        call.resolve(obj)
    }
    @objc func start(_ call: CAPPluginCall){
        
        let id = call.getString("id") ?? ""
        let downloadData = DownloaderPlugin.downloadDatas[id];
        if(id == "" || downloadData == nil){
            call.reject("Invalid id")
        }
        
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
            let fileUrl: URL! = documentsUrl?.appendingPathComponent(downloadData!.fileName)
            return (fileUrl, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let download = Alamofire.Session.default.download(downloadData!.url, to: destination)
        var lastRefreshTime = Int64(0);
        var lastBytesWritten =  Int64(0);
        download.downloadProgress{ progress in
            if(!progress.isFinished || !progress.isPaused){
                var data = JSObject()
                let currentBytes = progress.completedUnitCount
                let totalBytes = progress.totalUnitCount
                let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
                let minTime = 100
                var speed = Int64(0)
                if (
                    currentTime - lastRefreshTime >= minTime ||
                        currentBytes == totalBytes
                    ) {
                    var intervalTime = currentTime - lastRefreshTime;
                    if (intervalTime == 0) {
                        intervalTime += 1;
                    }
                    let updateBytes = Int64(currentBytes);
                    speed = Int64(round(Double(updateBytes / intervalTime)));
                    
                    data["value"] = round(progress.fractionCompleted * 100)
                    data["currentSize"] = currentBytes
                    data["totalSize"] = totalBytes
                    data["speed"] = speed
                    self.notifyListeners("progressUpdate", data: data)
                    lastRefreshTime = Int64(Date().timeIntervalSince1970 * 1000)
                    lastBytesWritten = currentBytes ;
                }
            }
        }
        
        download
            .validate()
            .responseData(completionHandler: { (response) in
                
                switch response.result {
                case .success( _):
                    let data = DownloaderPlugin.downloadDatas[id]
                    let absolutePath = response.fileURL?.absoluteString
                    if (absolutePath == nil) {
                        call.reject("Download Failed")
                    }
                    data?.setAbsolutePath(path: absolutePath!)
                    var object = JSObject()
                    object["status"] = StatusCode.COMPLETED.rawValue
                    object["path"] =  absolutePath
                    call.resolve(object)
                    break;
                case .failure(let error):
                    call.reject(error.localizedDescription)
                    break;
                }
            })
                

    }
    @objc func pause(_ call: CAPPluginCall){
        let id = call.getString("id") ?? nil
        if(id == nil){
            call.reject("Invalid id")
        }
        let downloadRequest = DownloaderPlugin.downloadDatas[id ?? ""]?.downloadRequest
        downloadRequest?.suspend()
        call.resolve()
    }
    @objc func resume(_ call: CAPPluginCall){
        let id = call.getString("id") ?? nil
        if(id == nil){
            call.reject("Invalid id")
        }
        let downloadRequest = DownloaderPlugin.downloadDatas[id ?? ""]?.downloadRequest
        downloadRequest?.resume()
        call.resolve()
    }
    @objc func cancel(_ call: CAPPluginCall){
        let id = call.getString("id") ?? nil
        if(id == nil){
            call.reject("Invalid id")
        }
        let downloadRequest = DownloaderPlugin.downloadDatas[id ?? ""]?.downloadRequest
        downloadRequest?.cancel()
        call.resolve()
    }
    @objc func getPath(_ call: CAPPluginCall){
        let id = call.getString("id") ?? nil
        let hasData = DownloaderPlugin.downloadDatas[id ?? ""]
        var obj = JSObject()
        if(hasData != nil && hasData?.fileName != nil){
            obj["value"] = hasData?.absolutePath
        }else{
            obj["value"] = nil
        }
        call.resolve(obj)
        
    }
    @objc func getStatus(_ call: CAPPluginCall){
        let id = call.getString("id") ?? nil
        let hasData = DownloaderPlugin.downloadDatas[id ?? ""]
        var obj = JSObject()
        if(hasData != nil && hasData?.status != nil){
            obj["value"] = hasData?.status
        }else{
            obj["value"] = StatusCode.PENDING
        }
        call.resolve(obj)
    }
}
