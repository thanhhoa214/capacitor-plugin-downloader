import {
  IDownloader,
  IStatusCode,
  DownloadOptions,
  DownloadEventData,
  Options,
  TimeOutOptions,
  CreateDownloadResponse,
  ProgressEventData,
} from './definitions';
import { PluginListenerHandle, Plugins } from '@capacitor/core';
const { DownloaderPlugin } = Plugins;
export class Downloader implements IDownloader {
  addListener(
    event: 'progressUpdate',
    callback: (event: ProgressEventData) => void
  ): PluginListenerHandle {
    return DownloaderPlugin.addListener(event, callback);
  }
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

  start(options: Options): Promise<DownloadEventData> {
    return DownloaderPlugin.start(options);
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
