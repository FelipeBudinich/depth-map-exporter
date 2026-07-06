import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import readline from "node:readline";
import { ExportJob, ExportProgress, ExportSettings, JobStore } from "./jobStore";

const computeModes = new Set(["all", "cpuAndGPU", "cpuAndNeuralEngine", "cpuOnly"]);
const formats = new Set(["grayscale", "inverse-grayscale"]);
const normalizers = new Set(["global", "ema", "per-frame"]);
const resizeModes = new Set(["stretch", "letterbox"]);

export type DryRunResult = {
  ok: boolean;
  stdout: string;
  stderr: string;
  error?: string;
};

export function parseSettings(form: URLSearchParams): ExportSettings {
  return {
    inputPath: form.get("inputPath")?.trim() ?? "",
    outputPath: form.get("outputPath")?.trim() ?? "",
    modelPath: form.get("modelPath")?.trim() ?? "",
    compute: (form.get("compute") || "all") as ExportSettings["compute"],
    format: (form.get("format") || "grayscale") as ExportSettings["format"],
    normalize: (form.get("normalize") || "global") as ExportSettings["normalize"],
    modelInput: form.get("modelInput")?.trim() || "auto",
    modelResize: (form.get("modelResize") || "stretch") as ExportSettings["modelResize"],
    modelShortSide: parsePositiveInt(form.get("modelShortSide"), 518),
    modelSizeMultiple: parsePositiveInt(form.get("modelSizeMultiple"), 14),
    outputMaxSide: parsePositiveInt(form.get("outputMaxSide"), 1920),
    bitrate: parsePositiveInt(form.get("bitrate"), 12_000_000),
    sampleStep: parsePositiveInt(form.get("sampleStep"), 30),
    includeAudio: parseCheckbox(form.get("includeAudio")),
    stackVertical: parseCheckbox(form.get("stackVertical")),
    overwrite: form.get("overwrite") !== null
  };
}

export function validateSettings(settings: ExportSettings): string[] {
  const errors: string[] = [];
  if (!settings.inputPath || !fs.existsSync(settings.inputPath)) errors.push("Input path does not exist.");
  if (settings.inputPath && path.extname(settings.inputPath).toLowerCase() !== ".mp4") errors.push("Input path must end in .mp4.");
  if (!settings.modelPath || !fs.existsSync(settings.modelPath)) errors.push("Model path does not exist.");
  if (settings.modelPath && ![".mlpackage", ".mlmodel", ".mlmodelc"].includes(path.extname(settings.modelPath).toLowerCase())) {
    errors.push("Model path must end in .mlpackage, .mlmodel, or .mlmodelc.");
  }
  if (!settings.outputPath || path.extname(settings.outputPath).toLowerCase() !== ".mp4") errors.push("Output path must end in .mp4.");
  if (settings.modelInput !== "auto" && !/^[1-9]\d*x[1-9]\d*$/i.test(settings.modelInput)) {
    errors.push("Model input must be auto or WIDTHxHEIGHT.");
  }
  if (!computeModes.has(settings.compute)) errors.push("Invalid compute setting.");
  if (!formats.has(settings.format)) errors.push("Invalid format setting.");
  if (!normalizers.has(settings.normalize)) errors.push("Invalid normalization setting.");
  if (!resizeModes.has(settings.modelResize)) errors.push("Invalid model resize setting.");
  if (!isPositiveInteger(settings.modelShortSide)) errors.push("Model short side must be positive.");
  if (!isPositiveInteger(settings.modelSizeMultiple)) errors.push("Model size multiple must be positive.");
  if (!isPositiveInteger(settings.outputMaxSide)) errors.push("Output max side must be positive.");
  if (!isPositiveInteger(settings.bitrate)) errors.push("Bitrate must be positive.");
  if (!isPositiveInteger(settings.sampleStep)) errors.push("Sample step must be positive.");
  if (settings.outputPath && fs.existsSync(settings.outputPath) && !settings.overwrite) {
    errors.push("Output exists. Enable overwrite or choose a different path.");
  }
  return errors;
}

export function buildCliArgs(settings: ExportSettings, mode: "dry-run" | "export"): string[] {
  const args = [
    "--input", settings.inputPath,
    "--output", settings.outputPath,
    "--model", settings.modelPath,
    "--compute", settings.compute,
    "--format", settings.format,
    "--normalize", settings.normalize,
    "--model-input", settings.modelInput,
    "--model-resize", settings.modelResize,
    "--model-short-side", String(settings.modelShortSide),
    "--model-size-multiple", String(settings.modelSizeMultiple),
    "--output-max-side", String(settings.outputMaxSide),
    "--bitrate", String(settings.bitrate),
    "--sample-step", String(settings.sampleStep)
  ];

  if (settings.overwrite) {
    args.push("--overwrite");
  }
  if (settings.includeAudio) {
    args.push("--include-audio");
  }
  if (settings.stackVertical) {
    args.push("--stack-vertical");
  }
  if (mode === "dry-run") {
    args.push("--dry-run");
  } else {
    args.push("--progress-json");
  }
  return args;
}

export async function runDryRun(cliPath: string, settings: ExportSettings): Promise<DryRunResult> {
  return new Promise((resolve) => {
    const child = spawn(cliPath, buildCliArgs(settings, "dry-run"), { shell: false });
    let stdout = "";
    let stderr = "";
    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");
    child.stdout.on("data", (chunk) => { stdout += chunk; });
    child.stderr.on("data", (chunk) => { stderr += chunk; });
    child.on("error", (error) => {
      resolve({ ok: false, stdout, stderr, error: error.message });
    });
    child.on("close", (code) => {
      if (code === 0) {
        resolve({ ok: true, stdout, stderr });
      } else {
        resolve({ ok: false, stdout, stderr, error: stderr || `depth-exporter exited with code ${code}` });
      }
    });
  });
}

export function startExport(cliPath: string, settings: ExportSettings, store: JobStore): ExportJob {
  const job = store.create(settings);
  const child = spawn(cliPath, buildCliArgs(settings, "export"), { shell: false });
  store.attachChild(job, child);

  const stdoutLines = readline.createInterface({ input: child.stdout });
  stdoutLines.on("line", (line) => {
    try {
      const event = JSON.parse(line) as ExportProgress;
      if (event.type === "progress") {
        store.setProgress(job, event);
      }
    } catch {
      store.appendLog(job, line);
    }
  });

  const stderrLines = readline.createInterface({ input: child.stderr });
  stderrLines.on("line", (line) => store.appendLog(job, line));

  child.on("error", (error) => {
    if (job.cancelledByUser) {
      return;
    }
    store.markError(job, error.message);
  });

  child.on("close", (code) => {
    if (job.status === "cancelled" || job.cancelledByUser) {
      return;
    }
    if (code === 0) {
      store.markDone(job);
    } else {
      const message = job.logs.length > 0 ? job.logs.slice(-12).join("\n") : `depth-exporter exited with code ${code}`;
      store.markError(job, message);
    }
  });

  return job;
}

function parsePositiveInt(value: string | null, fallback: number): number {
  if (!value) return fallback;
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && String(parsed) === value.trim() ? parsed : Number.NaN;
}

function parseCheckbox(value: string | null): boolean {
  return value !== null && (value === "" || value === "on" || value === "true");
}

function isPositiveInteger(value: number): boolean {
  return Number.isInteger(value) && value > 0;
}
