import { ChildProcessWithoutNullStreams } from "node:child_process";
import { EventEmitter } from "node:events";

export type JobStatus = "idle" | "running" | "done" | "error" | "cancelled";

export type ComputeMode = "all" | "cpuAndGPU" | "cpuAndNeuralEngine" | "cpuOnly";
export type DepthFormat = "grayscale" | "inverse-grayscale";
export type NormalizeMode = "global" | "ema" | "per-frame";
export type ModelResizeMode = "stretch" | "letterbox";

export type ExportSettings = {
  inputPath: string;
  outputPath: string;
  modelPath: string;
  compute: ComputeMode;
  format: DepthFormat;
  normalize: NormalizeMode;
  modelInput: "auto" | string;
  modelResize: ModelResizeMode;
  modelShortSide: number;
  modelSizeMultiple: number;
  outputMaxSide: number;
  bitrate: number;
  sampleStep: number;
  includeAudio: boolean;
  stackVertical: boolean;
  overwrite: boolean;
};

export type ExportProgress = {
  type: "progress";
  stage: "metadata" | "sampling" | "processing" | "writing" | "done";
  frame: number;
  totalFrames: number;
  percent: number;
};

export type ExportJob = {
  id: string;
  status: JobStatus;
  settings: ExportSettings;
  child?: ChildProcessWithoutNullStreams;
  progress?: ExportProgress;
  logs: string[];
  error?: string;
  startedAt: number;
  finishedAt?: number;
  cancelledByUser?: boolean;
};

export type JobEvent =
  | { type: "progress"; progress: ExportProgress }
  | { type: "log"; line: string }
  | { type: "done"; job: ExportJob }
  | { type: "error"; job: ExportJob; message: string }
  | { type: "cancelled"; job: ExportJob };

export class JobStore {
  private readonly jobs = new Map<string, ExportJob>();
  private readonly events = new EventEmitter();
  private lastSuccessfulJobId?: string;

  create(settings: ExportSettings): ExportJob {
    const job: ExportJob = {
      id: crypto.randomUUID(),
      status: "running",
      settings,
      logs: [],
      startedAt: Date.now()
    };
    this.jobs.set(job.id, job);
    return job;
  }

  get(jobId: string): ExportJob | undefined {
    return this.jobs.get(jobId);
  }

  getLastSuccessfulJob(): ExportJob | undefined {
    return this.lastSuccessfulJobId ? this.jobs.get(this.lastSuccessfulJobId) : undefined;
  }

  hasRunningJob(): boolean {
    return Array.from(this.jobs.values()).some((job) => job.status === "running");
  }

  attachChild(job: ExportJob, child: ChildProcessWithoutNullStreams): void {
    job.child = child;
  }

  appendLog(job: ExportJob, line: string): void {
    if (!line) {
      return;
    }
    job.logs.push(line);
    this.emit(job.id, { type: "log", line });
  }

  setProgress(job: ExportJob, progress: ExportProgress): void {
    job.progress = progress;
    this.emit(job.id, { type: "progress", progress });
  }

  markDone(job: ExportJob): void {
    job.status = "done";
    job.finishedAt = Date.now();
    this.lastSuccessfulJobId = job.id;
    this.emit(job.id, { type: "done", job });
  }

  markError(job: ExportJob, message: string): void {
    job.status = "error";
    job.error = message;
    job.finishedAt = Date.now();
    this.emit(job.id, { type: "error", job, message });
  }

  markCancelled(job: ExportJob): void {
    job.status = "cancelled";
    job.cancelledByUser = true;
    job.finishedAt = Date.now();
    this.emit(job.id, { type: "cancelled", job });
  }

  cancel(jobId: string): ExportJob | undefined {
    const job = this.jobs.get(jobId);
    if (!job || job.status !== "running") {
      return job;
    }
    job.cancelledByUser = true;
    job.child?.kill("SIGTERM");
    this.markCancelled(job);
    return job;
  }

  subscribe(jobId: string, listener: (event: JobEvent) => void): () => void {
    const channel = this.channel(jobId);
    this.events.on(channel, listener);
    return () => {
      this.events.off(channel, listener);
    };
  }

  private emit(jobId: string, event: JobEvent): void {
    this.events.emit(this.channel(jobId), event);
  }

  private channel(jobId: string): string {
    return `job:${jobId}`;
  }
}
