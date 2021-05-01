package co.fitcom.capacitor.Downloader;

import android.content.Context;
import android.os.AsyncTask;
import android.os.PowerManager;

import com.getcapacitor.JSObject;
import com.getcapacitor.NativePlugin;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;


@NativePlugin()
public class DownloaderPlugin extends Plugin {
    HashMap<String, DownloadData> downloadDataHashMap = new HashMap<>();

    @PluginMethod
    public void createDownload(PluginCall call) {
        String url = call.getString("url", "");
        String fileName = call.getString("fileName", "");

        final DownloadTask downloadTask = new DownloadTask(this.getContext(), fileName);
        String currentTimestamp = System.nanoTime() + "";
        this.downloadDataHashMap.put(currentTimestamp, new DownloadData(url, downloadTask));
        JSObject object = new JSObject();
        object.put("value", currentTimestamp);
        call.resolve(object);
    }

    @PluginMethod
    public void start(PluginCall call) {
        String id = call.getString("id", "");
        if (id != null && id.length() != 0) {
            DownloadData downloadData = this.downloadDataHashMap.get(id);
            downloadData.getTask().setCall(call);
            downloadData.getTask().execute(downloadData.getUrl());
        }
    }


    class DownloadData {
        private String url;
        private DownloadTask task;

        public DownloadData(String url, DownloadTask task) {
            this.url = url;
            this.task = task;
        }

        public DownloadTask getTask() {
            return task;
        }

        public String getUrl() {
            return url;
        }
    }

    class DownloadTask extends AsyncTask<String, Integer, String> {

        private Context context;
        private PowerManager.WakeLock mWakeLock;
        private PluginCall call;
        private String path;

        public DownloadTask(Context context, String path) {
            this.context = context;
            this.path = path;
        }

        public void setCall(PluginCall call) {
            this.call = call;
        }

        @Override
        protected String doInBackground(String... sUrl) {
            InputStream input = null;
            OutputStream output = null;
            HttpURLConnection connection = null;
            long startTime = System.nanoTime();
            try {
                URL url = new URL(sUrl[0]);
                connection = (HttpURLConnection) url.openConnection();
                connection.connect();

                // expect HTTP 200 OK, so we don't mistakenly save error report
                // instead of the file
                if (connection.getResponseCode() != HttpURLConnection.HTTP_OK) {
                    return "Server returned HTTP " + connection.getResponseCode()
                            + " " + connection.getResponseMessage();
                }

                // this will be useful to display download percentage
                // might be -1: server did not report the length
                int totalByteCount = connection.getContentLength();

                // download the file
                input = connection.getInputStream();
                File file = new File(this.context.getExternalFilesDir(""), path);
                file.getParentFile().mkdirs(); // Will create parent directories if not exists
                file.createNewFile();

                output = new FileOutputStream(file, false);

                byte data[] = new byte[4096];
                long downloadedByteCount = 0;
                int count;
                int speed;
                int minTime = 1000;
                long lastRefreshTime = 0;
                long currentTime = 0;
                int downloadedPercent;
                long intervalTimeInMilis;
                long bytesOfChunk = totalByteCount / 1000;
                int indexOfBytesOfChunk = 0;
                while ((count = input.read(data)) != -1) {
                    if (isCancelled() || totalByteCount <= 0) {
                        input.close();
                        return null;
                    }

                    downloadedByteCount += count;
                    currentTime = System.nanoTime();
                    if (downloadedByteCount >= bytesOfChunk * indexOfBytesOfChunk) {
                        intervalTimeInMilis = currentTime - lastRefreshTime;
                        if (intervalTimeInMilis == 0) {
                            intervalTimeInMilis += 1;
                        }

                        speed = (int) (downloadedByteCount / (intervalTimeInMilis * 1000));
                        downloadedPercent = (int) (downloadedByteCount * 100 / totalByteCount);
                        publishProgress(downloadedPercent, (int) speed, (int) downloadedByteCount, totalByteCount);
                        lastRefreshTime = currentTime;
                        indexOfBytesOfChunk += 1;
                    }
                    output.write(data, 0, count);
                }
                return file.getAbsolutePath();
            } catch (Exception e) {
                return e.toString();
            } finally {
                try {
                    if (output != null)
                        output.close();
                    if (input != null)
                        input.close();
                } catch (IOException ignored) {
                }
                if (connection != null)
                    connection.disconnect();
            }
        }

        @Override
        protected void onPreExecute() {
            super.onPreExecute();
            // take CPU lock to prevent CPU from going off if the user
            // presses the power button during download
            PowerManager pm = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
            mWakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,
                    getClass().getName());
            mWakeLock.acquire();
        }

        @Override
        protected void onProgressUpdate(Integer... progress) {
            JSObject object = new JSObject();
            object.put("value", progress[0]);
            object.put("speed", progress[1]);
            object.put("currentSize", progress[2]);
            object.put("totalSize", progress[3]);
            notifyListeners("progressUpdate", object);
        }

        @Override
        protected void onPostExecute(String result) {
            mWakeLock.release();
            JSObject object = new JSObject();
            object.put("path", result);
            call.resolve(object);
        }
    }
}
