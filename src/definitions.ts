import { PluginListenerHandle } from '@capacitor/core';

declare global {
  interface PluginRegistry {
    DownloaderPlugin?: IDownloader;
  }
}

export interface IDownloader {
  initialize(): void;
  createDownload(options: DownloadOptions): Promise<CreateDownloadResponse>;
  start(options: Options): Promise<DownloadEventData>;
  pause(options: Options): Promise<void>;
  resume(options: Options): Promise<void>;
  cancel(options: Options): Promise<void>;
  getPath(options: Options): Promise<string>;
  getStatus(options: Options): Promise<IStatusCode>;
  addListener(
    event: 'progressUpdate',
    callback: (event: ProgressEventData) => void
  ): PluginListenerHandle;
}

export interface TimeOutOptions {
  timeout: number;
}

export interface Options {
  id: string;
}

export interface StartCallback {
  success: DownloadEventData;
  progress: ProgressEventData;
  error: DownloadEventError;
}

export interface DownloadEventError {
  status: StatusCode;
  message: string;
}

export interface DownloadEventData {
  status: StatusCode;
  path: string;
  message?: string;
}
export interface ProgressEventData {
  value: number;
  currentSize: number;
  totalSize: number;
  speed: number;
}

export interface IStatusCode {
  value: StatusCode;
}
export enum StatusCode {
  PENDING = 'pending',
  PAUSED = 'paused',
  DOWNLOADING = 'downloading',
  COMPLETED = 'completed',
  ERROR = 'error',
}

export interface DownloadOptions {
  url: string;
  query?: Object | string;
  headers?: Object;
  path?: string;
  fileName?: string;
}

export interface CreateDownloadResponse {
  value: string; // id
}
