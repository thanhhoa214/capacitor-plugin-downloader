import {
  IDownloader,
  IStatusCode,
  DownloadOptions,
  DownloadEventData,
  Options,
  TimeOutOptions,
  CreateDownloadResponse,
  ProgressEventData,
  StatusCode,
} from './definitions';
import { Plugins } from '@capacitor/core';
const { DownloaderPlugin } = Plugins;
export class Downloader implements IDownloader {
  initialize() {
    DownloaderPlugin.initialize();
  }
  init() {
    this.init();
  }
  public static setTimeout(options: TimeOutOptions) {
    return (DownloaderPlugin as any).setTimeout(options);
  }
  getStatus(options: Options): Promise<IStatusCode> {
    return DownloaderPlugin.getStatus(options);
  }
  createDownload(options: DownloadOptions): Promise<CreateDownloadResponse> {
    return DownloaderPlugin.createDownload(options);
  }

  cancel(options: Options) {
    return DownloaderPlugin.cancel(options);
  }

  start(
    options: Options,
    progress?: (event: ProgressEventData) => void
  ): Promise<DownloadEventData> {
    return new Promise(async (resolve, reject) => {
      DownloaderPlugin.start(
        options,
        (data: ProgressEventData | DownloadEventData, error: string) => {
          if (!error) {
            const dataParsedType = data as DownloadEventData;
            if (dataParsedType.status != null) {
              resolve(dataParsedType);
            } else {
              if (progress) progress(data as ProgressEventData);
            }
          } else {
            reject({
              status: StatusCode.ERROR,
              message: error,
            });
          }
        }
      );
    });
  }
  pause(options: Options): Promise<void> {
    return DownloaderPlugin.pause(options);
  }
  resume(options: Options): Promise<void> {
    return DownloaderPlugin.resume(options);
  }
  getPath(options: Options): Promise<string> {
    return DownloaderPlugin.getPath(options);
  }
}
