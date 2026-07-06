import { BrowserWindow, shell } from "electron";
import http, { IncomingMessage, ServerResponse } from "node:http";
import fs from "node:fs";
import path from "node:path";
import { chooseInput, chooseModel, chooseOutput, defaultOutputPath } from "./dialogs";
import { buildCliArgs, parseSettings, runDryRun, startExport, validateSettings } from "./depthJob";
import { errorPanel, fileFields, previewPanel, progressPanel, revealResult, dryRunPanel } from "./templates";
import { JobEvent, JobStore } from "./jobStore";
import { AppPaths } from "./paths";
import { mimeType } from "./mime";

export type LocalServer = {
  port: number;
  url: string;
  close: () => Promise<void>;
};

export async function startLocalServer(paths: AppPaths, jobs: JobStore, getWindow: () => BrowserWindow): Promise<LocalServer> {
  const server = http.createServer(async (request, response) => {
    try {
      await route(request, response, paths, jobs, getWindow);
    } catch (error) {
      sendHtml(response, 500, errorPanel(error instanceof Error ? error.message : String(error)));
    }
  });

  await new Promise<void>((resolve) => {
    server.listen(0, "127.0.0.1", resolve);
  });

  const address = server.address();
  if (!address || typeof address === "string") {
    throw new Error("Could not bind local server to 127.0.0.1.");
  }

  return {
    port: address.port,
    url: `http://127.0.0.1:${address.port}/`,
    close: () => new Promise((resolve) => server.close(() => resolve()))
  };
}

async function route(
  request: IncomingMessage,
  response: ServerResponse,
  paths: AppPaths,
  jobs: JobStore,
  getWindow: () => BrowserWindow
): Promise<void> {
  const method = request.method ?? "GET";
  const url = new URL(request.url ?? "/", "http://127.0.0.1");

  if (method === "GET" && url.pathname === "/") {
    const { mainPage, defaultSettings } = await import("./templates");
    sendHtml(response, 200, mainPage(defaultSettings(paths), paths));
    return;
  }

  if (method === "GET" && url.pathname.startsWith("/assets/")) {
    serveAsset(response, paths.rendererRoot, url.pathname);
    return;
  }

  if (method === "POST" && url.pathname === "/select/input") {
    const form = await readForm(request);
    const settings = parseSettings(form);
    const selected = await chooseInput(getWindow());
    if (selected) {
      settings.inputPath = selected;
      if (!settings.outputPath) {
        settings.outputPath = defaultOutputPath(selected, settings);
      }
    }
    sendHtml(response, 200, fileFields(settings));
    return;
  }

  if (method === "POST" && url.pathname === "/select/model") {
    const form = await readForm(request);
    const settings = parseSettings(form);
    const selected = await chooseModel(getWindow());
    if (selected) {
      settings.modelPath = selected;
    }
    sendHtml(response, 200, fileFields(settings));
    return;
  }

  if (method === "POST" && url.pathname === "/select/output") {
    const form = await readForm(request);
    const settings = parseSettings(form);
    const selected = await chooseOutput(getWindow(), settings.inputPath, settings);
    if (selected) {
      settings.outputPath = selected;
    }
    sendHtml(response, 200, fileFields(settings));
    return;
  }

  if (method === "POST" && url.pathname === "/dry-run") {
    const settings = parseSettings(await readForm(request));
    const errors = validateSettings(settings);
    if (!paths.cliPath) errors.unshift("depth-exporter binary was not found.");
    if (errors.length || !paths.cliPath) {
      sendHtml(response, 400, targetErrorPanel("dry-run-panel", errors));
      return;
    }
    const result = await runDryRun(paths.cliPath, settings);
    if (!result.ok) {
      sendHtml(response, 500, targetErrorPanel("dry-run-panel", [
        result.error ?? "Dry-run failed.",
        result.stdout,
        result.stderr
      ].filter(Boolean)));
      return;
    }
    sendHtml(response, 200, dryRunPanel(result.stdout, result.stderr));
    return;
  }

  if (method === "POST" && url.pathname === "/export/start") {
    const settings = parseSettings(await readForm(request));
    const errors = validateSettings(settings);
    if (!paths.cliPath) errors.unshift("depth-exporter binary was not found.");
    if (jobs.hasRunningJob()) errors.push("Only one active export is allowed.");
    if (errors.length || !paths.cliPath) {
      sendHtml(response, 400, targetErrorPanel("progress-panel", errors));
      return;
    }
    const job = startExport(paths.cliPath, settings, jobs);
    const fragment = progressPanel(job) + previewPanel(job, true) + logPanelOob([]);
    sendHtml(response, 200, fragment);
    return;
  }

  if (method === "POST" && url.pathname === "/export/cancel") {
    const form = await readForm(request);
    const job = jobs.cancel(form.get("jobId") ?? "");
    sendHtml(response, 200, job ? progressPanel(job) : targetErrorPanel("progress-panel", "No running job was found."));
    return;
  }

  if (method === "GET" && url.pathname.startsWith("/export/events/")) {
    const jobId = decodeURIComponent(url.pathname.replace("/export/events/", ""));
    streamJobEvents(response, jobs, jobId);
    return;
  }

  if (method === "POST" && url.pathname === "/reveal-output") {
    const form = await readForm(request);
    const job = jobs.get(form.get("jobId") ?? "") ?? jobs.getLastSuccessfulJob();
    if (!job || job.status !== "done") {
      sendHtml(response, 400, revealResult("No completed output is available."));
      return;
    }
    shell.showItemInFolder(job.settings.outputPath);
    sendHtml(response, 200, revealResult("Revealed in Finder."));
    return;
  }

  if (method === "GET" && url.pathname.startsWith("/preview/")) {
    const jobId = decodeURIComponent(url.pathname.replace("/preview/", ""));
    servePreview(request, response, jobs, jobId);
    return;
  }

  sendHtml(response, 404, errorPanel("Not found."));
}

async function readForm(request: IncomingMessage): Promise<URLSearchParams> {
  const chunks: Buffer[] = [];
  for await (const chunk of request) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  return new URLSearchParams(Buffer.concat(chunks).toString("utf8"));
}

function serveAsset(response: ServerResponse, rendererRoot: string, pathname: string): void {
  const relativePath = pathname.replace(/^\/assets\//, "");
  const filePath = path.normalize(path.join(rendererRoot, "assets", relativePath));
  const assetRoot = path.join(rendererRoot, "assets");
  if (!filePath.startsWith(assetRoot) || !fs.existsSync(filePath)) {
    sendHtml(response, 404, "Not found.");
    return;
  }
  response.writeHead(200, { "Content-Type": mimeType(filePath) });
  fs.createReadStream(filePath).pipe(response);
}

function streamJobEvents(response: ServerResponse, jobs: JobStore, jobId: string): void {
  const job = jobs.get(jobId);
  if (!job) {
    response.writeHead(404, { "Content-Type": "text/event-stream" });
    sendEvent(response, "error", { message: "Job not found." });
    response.end();
    return;
  }

  response.writeHead(200, {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    "Connection": "keep-alive"
  });

  for (const line of job.logs) {
    sendEvent(response, "log", { line });
  }
  if (job.progress) {
    sendEvent(response, "progress", job.progress);
  }

  if (job.status !== "running") {
    sendTerminalEvent(response, job.status, job.id, job.error);
    return;
  }

  const unsubscribe = jobs.subscribe(jobId, (event) => {
    writeJobEvent(response, event);
    if (event.type === "done" || event.type === "error" || event.type === "cancelled") {
      unsubscribe();
      response.end();
    }
  });

  requestClose(response, unsubscribe);
}

function writeJobEvent(response: ServerResponse, event: JobEvent): void {
  if (event.type === "progress") sendEvent(response, "progress", event.progress);
  if (event.type === "log") sendEvent(response, "log", { line: event.line });
  if (event.type === "done") sendEvent(response, "done", { jobId: event.job.id, previewUrl: `/preview/${encodeURIComponent(event.job.id)}` });
  if (event.type === "error") sendEvent(response, "error", { message: event.message });
  if (event.type === "cancelled") sendEvent(response, "cancelled", { jobId: event.job.id });
}

function sendTerminalEvent(response: ServerResponse, status: string, jobId: string, error?: string): void {
  if (status === "done") sendEvent(response, "done", { jobId, previewUrl: `/preview/${encodeURIComponent(jobId)}` });
  else if (status === "cancelled") sendEvent(response, "cancelled", { jobId });
  else sendEvent(response, "error", { message: error ?? "Job failed." });
  response.end();
}

function sendEvent(response: ServerResponse, event: string, data: unknown): void {
  response.write(`event: ${event}\n`);
  response.write(`data: ${JSON.stringify(data)}\n\n`);
}

function requestClose(response: ServerResponse, cleanup: () => void): void {
  response.on("close", cleanup);
}

function servePreview(request: IncomingMessage, response: ServerResponse, jobs: JobStore, jobId: string): void {
  const job = jobs.get(jobId);
  if (!job || job.status !== "done") {
    sendHtml(response, 404, "Preview is not available.");
    return;
  }

  const filePath = job.settings.outputPath;
  if (!fs.existsSync(filePath)) {
    sendHtml(response, 404, "Output file was not found.");
    return;
  }

  const stat = fs.statSync(filePath);
  const range = request.headers.range;
  if (range) {
    const match = /^bytes=(\d*)-(\d*)$/.exec(range);
    if (match) {
      const start = match[1] ? Number.parseInt(match[1], 10) : 0;
      const end = match[2] ? Number.parseInt(match[2], 10) : stat.size - 1;
      response.writeHead(206, {
        "Content-Type": "video/mp4",
        "Content-Length": end - start + 1,
        "Content-Range": `bytes ${start}-${end}/${stat.size}`,
        "Accept-Ranges": "bytes"
      });
      fs.createReadStream(filePath, { start, end }).pipe(response);
      return;
    }
  }

  response.writeHead(200, {
    "Content-Type": "video/mp4",
    "Content-Length": stat.size,
    "Accept-Ranges": "bytes"
  });
  fs.createReadStream(filePath).pipe(response);
}

function sendHtml(response: ServerResponse, status: number, body: string): void {
  response.writeHead(status, { "Content-Type": "text/html; charset=utf-8" });
  response.end(body);
}

function logPanelOob(lines: string[]): string {
  return `<section id="log-panel" hx-swap-oob="outerHTML" class="mt-5 rounded-lg border border-zinc-800 bg-zinc-900/80 p-4">
    <details open>
      <summary class="cursor-pointer text-base font-medium">Logs</summary>
      <pre id="log-output" class="mt-3 max-h-64 overflow-auto rounded-lg bg-zinc-950 p-3 font-mono text-xs leading-relaxed text-zinc-300">${lines.join("\n")}</pre>
    </details>
  </section>`;
}

function targetErrorPanel(targetId: string, errors: string[] | string): string {
  const lines = Array.isArray(errors) ? errors : [errors];
  return `<section id="${targetId}" class="mt-5 rounded-lg border border-red-900/70 bg-red-950/50 p-4 text-red-100">
    <h2 class="mb-2 text-base font-medium">Error</h2>
    <ul class="list-disc space-y-1 pl-5 text-sm">${lines.map((line) => `<li>${escapeHtmlLocal(line)}</li>`).join("")}</ul>
  </section>`;
}

function escapeHtmlLocal(value: unknown): string {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll("\"", "&quot;")
    .replaceAll("'", "&#39;");
}
