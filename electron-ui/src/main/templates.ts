import { AppPaths } from "./paths";
import { ExportJob, ExportSettings, JobStatus } from "./jobStore";
import { checked, escapeHtml, jsonAttribute, selected } from "./html";

export function defaultSettings(paths: AppPaths): ExportSettings {
  return {
    inputPath: "",
    outputPath: "",
    modelPath: paths.bundledModelPath ?? "",
    compute: "all",
    format: "grayscale",
    normalize: "global",
    modelInput: "auto",
    modelResize: "stretch",
    modelShortSide: 518,
    modelSizeMultiple: 14,
    outputMaxSide: 1920,
    bitrate: 12_000_000,
    sampleStep: 30,
    includeAudio: false,
    stackVertical: false,
    overwrite: true
  };
}

export function mainPage(settings: ExportSettings, paths: AppPaths): string {
  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Depth Exporter</title>
    <link rel="stylesheet" href="/assets/styles.css">
    <script defer src="/assets/vendor/htmx.min.js"></script>
    <script defer src="/assets/app.js"></script>
  </head>
  <body class="min-h-screen bg-zinc-950 text-zinc-100 antialiased">
    <main class="mx-auto max-w-5xl px-6 py-8">
      <header class="mb-6">
        <h1 class="text-2xl font-semibold tracking-normal">Depth Exporter</h1>
        <p class="mt-1 text-sm text-zinc-400">Apple Silicon Core ML depth-map exporter</p>
      </header>

      ${paths.cliPath ? "" : errorPanel(["depth-exporter binary was not found. Set DEPTH_EXPORTER_PATH or build the Swift CLI first."])}

      <form id="export-form" class="space-y-5">
        ${fileFields(settings)}
        ${settingsPanel(settings)}

        <section class="rounded-lg border border-zinc-800 bg-zinc-900/80 p-4">
          <div class="flex flex-wrap items-center gap-3">
            <button type="button" class="btn-primary" hx-post="/dry-run" hx-include="#export-form" hx-target="#dry-run-panel" hx-swap="outerHTML">Analyze</button>
            <button id="export-button" type="button" class="btn-success" hx-post="/export/start" hx-include="#export-form" hx-target="#progress-panel" hx-swap="outerHTML">Export</button>
            <p class="text-sm text-zinc-400">Audio is off unless Include original audio is enabled.</p>
          </div>
        </section>
      </form>

      ${dryRunPanel()}
      ${progressPanel()}
      ${logPanel()}
      ${previewPanel()}
      <div id="error-panel"></div>
    </main>
  </body>
</html>`;
}

export function fileFields(settings: ExportSettings): string {
  return `<section id="file-fields" class="rounded-lg border border-zinc-800 bg-zinc-900/80 p-4">
    <div class="mb-4 flex items-center justify-between gap-4">
      <h2 class="text-base font-medium">Files</h2>
      <span class="text-xs text-zinc-500">Local paths only</span>
    </div>
    <div class="grid gap-4">
      ${pathField("Input MP4 path", "inputPath", settings.inputPath, "Choose Input", "/select/input")}
      ${pathField("Model path", "modelPath", settings.modelPath, "Choose Model", "/select/model")}
      ${pathField("Output MP4 path", "outputPath", settings.outputPath, "Choose Output", "/select/output")}
    </div>
  </section>`;
}

export function settingsPanel(settings: ExportSettings): string {
  return `<section class="rounded-lg border border-zinc-800 bg-zinc-900/80 p-4">
    <div class="mb-4 flex items-center justify-between gap-4">
      <h2 class="text-base font-medium">Settings</h2>
      <span class="text-xs text-zinc-500">Swift CLI options</span>
    </div>
    <div class="grid gap-4 md:grid-cols-3">
      ${selectField("Format", "format", settings.format, [["grayscale", "grayscale"], ["inverse-grayscale", "inverse-grayscale"]])}
      ${selectField("Normalize", "normalize", settings.normalize, [["global", "global"], ["ema", "ema"], ["per-frame", "per-frame"]])}
      ${selectField("Compute", "compute", settings.compute, [["all", "all"], ["cpuAndGPU", "cpuAndGPU"], ["cpuAndNeuralEngine", "cpuAndNeuralEngine"], ["cpuOnly", "cpuOnly"]])}
    </div>
    <div class="mt-4 grid gap-3 md:grid-cols-2">
      ${checkboxField("Include original audio", "includeAudio", settings.includeAudio, "Copy the first source audio track into the MP4.")}
      ${checkboxField("Export stacked test video", "stackVertical", settings.stackVertical, "Place source video above the depth map for visual checks.")}
    </div>

    <details class="mt-4 rounded-lg border border-zinc-800 bg-zinc-950/60 p-3">
      <summary class="cursor-pointer text-sm font-medium text-zinc-200">Advanced</summary>
      <div class="mt-4 grid gap-4 md:grid-cols-3">
        ${inputField("Model input", "modelInput", settings.modelInput, "auto or WIDTHxHEIGHT")}
        ${selectField("Model resize", "modelResize", settings.modelResize, [["stretch", "stretch"], ["letterbox", "letterbox"]])}
        ${numberField("Model short side", "modelShortSide", settings.modelShortSide)}
        ${numberField("Model size multiple", "modelSizeMultiple", settings.modelSizeMultiple)}
        ${numberField("Output max side", "outputMaxSide", settings.outputMaxSide)}
        ${numberField("Bitrate", "bitrate", settings.bitrate)}
        ${numberField("Sample step", "sampleStep", settings.sampleStep)}
        <label class="flex items-center gap-2 rounded-lg border border-zinc-800 bg-zinc-950 px-3 py-2 text-sm">
          <input class="h-4 w-4 accent-sky-500" type="checkbox" name="overwrite" ${checked(settings.overwrite)}>
          <span>Overwrite existing output</span>
        </label>
      </div>
    </details>
  </section>`;
}

export function dryRunPanel(stdout = "", stderr = ""): string {
  const empty = !stdout && !stderr;
  return `<section id="dry-run-panel" class="mt-5 rounded-lg border border-zinc-800 bg-zinc-900/80 p-4 ${empty ? "hidden" : ""}">
    <div class="mb-3 flex items-center justify-between gap-4">
      <h2 class="text-base font-medium">Dry Run</h2>
      <span class="text-xs text-zinc-500">Metadata from depth-exporter</span>
    </div>
    ${stdout ? `<pre class="max-h-96 overflow-auto rounded-lg bg-zinc-950 p-3 font-mono text-xs leading-relaxed text-zinc-200">${escapeHtml(stdout)}</pre>` : ""}
    ${stderr ? `<pre class="mt-3 max-h-48 overflow-auto rounded-lg bg-zinc-950 p-3 font-mono text-xs leading-relaxed text-zinc-400">${escapeHtml(stderr)}</pre>` : ""}
  </section>`;
}

export function progressPanel(job?: ExportJob): string {
  const progress = job?.progress;
  const status = job?.status ?? "idle";
  const percent = progress?.percent ?? 0;
  const stage = progress?.stage ?? status;
  const frameText = progress ? `${progress.frame}/${progress.totalFrames}` : "0/0";
  const layoutText = job?.settings.stackVertical ? "Stacked test video" : "Depth only";
  const audioText = job?.settings.includeAudio ? "Original audio" : "Off";
  return `<section id="progress-panel" ${job ? `data-job-id="${escapeHtml(job.id)}"` : ""} class="mt-5 rounded-lg border border-zinc-800 bg-zinc-900/80 p-4">
    <div class="mb-3 flex items-center justify-between gap-4">
      <h2 class="text-base font-medium">Export</h2>
      <span id="stage-label" class="rounded bg-zinc-800 px-2 py-1 text-xs text-zinc-300">${escapeHtml(stage)}</span>
    </div>
    <div class="mb-3 grid gap-2 text-sm text-zinc-400 md:grid-cols-2">
      <span>Layout: <span class="text-zinc-200">${escapeHtml(layoutText)}</span></span>
      <span>Audio: <span class="text-zinc-200">${escapeHtml(audioText)}</span></span>
    </div>
    <div class="h-3 overflow-hidden rounded-full bg-zinc-800">
      <div id="progress-bar" class="h-full rounded-full bg-sky-500 transition-all" style="width: ${Math.max(0, Math.min(100, percent))}%"></div>
    </div>
    <div class="mt-2 flex items-center justify-between text-sm text-zinc-400">
      <span id="percent-text">${percent.toFixed(1)}%</span>
      <span id="frame-text">${escapeHtml(frameText)}</span>
    </div>
    <div class="mt-4 flex gap-3">
      <button id="cancel-button" type="button" class="btn-danger" ${job?.status === "running" ? "" : "disabled"} hx-post="/export/cancel" hx-vals='${jsonAttribute({ jobId: job?.id ?? "" })}' hx-target="#progress-panel" hx-swap="outerHTML">Cancel</button>
    </div>
  </section>`;
}

export function logPanel(lines: string[] = []): string {
  return `<section id="log-panel" class="mt-5 rounded-lg border border-zinc-800 bg-zinc-900/80 p-4">
    <details ${lines.length ? "open" : ""}>
      <summary class="cursor-pointer text-base font-medium">Logs</summary>
      <pre id="log-output" class="mt-3 max-h-64 overflow-auto rounded-lg bg-zinc-950 p-3 font-mono text-xs leading-relaxed text-zinc-300">${escapeHtml(lines.join("\n"))}</pre>
    </details>
  </section>`;
}

export function previewPanel(job?: ExportJob, hidden = true): string {
  const jobId = job?.id ?? "";
  const videoSrc = job ? `/preview/${encodeURIComponent(job.id)}` : "";
  return `<section id="preview-panel" ${jobId ? `data-job-id="${escapeHtml(jobId)}"` : ""} class="mt-5 rounded-lg border border-zinc-800 bg-zinc-900/80 p-4 ${hidden ? "hidden" : ""}">
    <div class="mb-3 flex items-center justify-between gap-4">
      <h2 class="text-base font-medium">Preview</h2>
      <form hx-post="/reveal-output" hx-target="#reveal-result" hx-swap="innerHTML">
        <input type="hidden" name="jobId" value="${escapeHtml(jobId)}">
        <button id="reveal-button" type="submit" class="btn-secondary" ${job ? "" : "disabled"}>Reveal in Finder</button>
      </form>
    </div>
    <video id="preview-video" class="w-full rounded-lg border border-zinc-800 bg-black" controls src="${escapeHtml(videoSrc)}"></video>
    <div id="reveal-result" class="mt-2 text-sm text-zinc-400"></div>
  </section>`;
}

export function errorPanel(errors: string[] | string): string {
  const lines = Array.isArray(errors) ? errors : [errors];
  return `<section id="error-panel" class="mt-5 rounded-lg border border-red-900/70 bg-red-950/50 p-4 text-red-100">
    <h2 class="mb-2 text-base font-medium">Error</h2>
    <ul class="list-disc space-y-1 pl-5 text-sm">${lines.map((line) => `<li>${escapeHtml(line)}</li>`).join("")}</ul>
  </section>`;
}

export function revealResult(message: string): string {
  return `<span>${escapeHtml(message)}</span>`;
}

function pathField(label: string, name: keyof ExportSettings, value: string, buttonText: string, endpoint: string): string {
  return `<label class="grid gap-2">
    <span class="text-sm text-zinc-300">${escapeHtml(label)}</span>
    <div class="flex gap-2">
      <input class="field font-mono" name="${name}" value="${escapeHtml(value)}" spellcheck="false">
      <button type="button" class="btn-secondary shrink-0" hx-post="${endpoint}" hx-include="#export-form" hx-target="#file-fields" hx-swap="outerHTML">${escapeHtml(buttonText)}</button>
    </div>
  </label>`;
}

function inputField(label: string, name: keyof ExportSettings, value: string, placeholder = ""): string {
  return `<label class="grid gap-2">
    <span class="text-sm text-zinc-300">${escapeHtml(label)}</span>
    <input class="field" name="${name}" value="${escapeHtml(value)}" placeholder="${escapeHtml(placeholder)}">
  </label>`;
}

function numberField(label: string, name: keyof ExportSettings, value: number): string {
  return `<label class="grid gap-2">
    <span class="text-sm text-zinc-300">${escapeHtml(label)}</span>
    <input class="field" name="${name}" type="number" min="1" value="${escapeHtml(value)}">
  </label>`;
}

function selectField(label: string, name: keyof ExportSettings, value: string, options: Array<[string, string]>): string {
  return `<label class="grid gap-2">
    <span class="text-sm text-zinc-300">${escapeHtml(label)}</span>
    <select class="field" name="${name}">
      ${options.map(([optionValue, text]) => `<option value="${escapeHtml(optionValue)}" ${selected(value, optionValue)}>${escapeHtml(text)}</option>`).join("")}
    </select>
  </label>`;
}

function checkboxField(label: string, name: keyof ExportSettings, value: boolean, detail: string): string {
  return `<label class="flex gap-3 rounded-lg border border-zinc-800 bg-zinc-950 px-3 py-3 text-sm">
    <input class="mt-0.5 h-4 w-4 shrink-0 accent-sky-500" type="checkbox" name="${name}" ${checked(value)}>
    <span class="grid gap-1">
      <span class="text-zinc-200">${escapeHtml(label)}</span>
      <span class="text-xs leading-5 text-zinc-500">${escapeHtml(detail)}</span>
    </span>
  </label>`;
}
