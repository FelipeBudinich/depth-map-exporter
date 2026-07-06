(function () {
  let source = null;

  function byId(id) {
    return document.getElementById(id);
  }

  function connect(jobId) {
    if (!jobId) return;
    if (source) source.close();

    source = new EventSource(`/export/events/${encodeURIComponent(jobId)}`);
    const exportButton = byId("export-button");
    const cancelButton = byId("cancel-button");
    if (exportButton) exportButton.disabled = true;
    if (cancelButton) cancelButton.disabled = false;

    source.addEventListener("progress", function (event) {
      const progress = JSON.parse(event.data);
      setText("stage-label", progress.stage);
      setText("percent-text", `${Number(progress.percent || 0).toFixed(1)}%`);
      setText("frame-text", `${progress.frame}/${progress.totalFrames}`);
      const bar = byId("progress-bar");
      if (bar) bar.style.width = `${Math.max(0, Math.min(100, progress.percent || 0))}%`;
    });

    source.addEventListener("log", function (event) {
      const payload = JSON.parse(event.data);
      appendLog(payload.line || "");
    });

    source.addEventListener("done", function (event) {
      const payload = JSON.parse(event.data || "{}");
      finish("done");
      showPreview(payload.previewUrl || `/preview/${encodeURIComponent(jobId)}`);
    });

    source.addEventListener("error", function (event) {
      const message = event.data ? JSON.parse(event.data).message : "Export failed.";
      finish("error");
      showError(message);
    });

    source.addEventListener("cancelled", function () {
      finish("cancelled");
    });
  }

  function finish(stage) {
    setText("stage-label", stage);
    const exportButton = byId("export-button");
    const cancelButton = byId("cancel-button");
    if (exportButton) exportButton.disabled = false;
    if (cancelButton) cancelButton.disabled = true;
    if (source) {
      source.close();
      source = null;
    }
  }

  function showPreview(src) {
    const panel = byId("preview-panel");
    const video = byId("preview-video");
    if (video && src) video.src = src;
    if (panel) panel.classList.remove("hidden");
  }

  function showError(message) {
    const panel = byId("error-panel");
    if (!panel) return;
    panel.innerHTML = `<section class="mt-5 rounded-lg border border-red-900/70 bg-red-950/50 p-4 text-red-100">
      <h2 class="mb-2 text-base font-medium">Error</h2>
      <p class="whitespace-pre-wrap text-sm"></p>
    </section>`;
    const text = panel.querySelector("p");
    if (text) text.textContent = message;
  }

  function appendLog(line) {
    const output = byId("log-output");
    if (!output || !line) return;
    output.textContent += `${line}\n`;
    output.scrollTop = output.scrollHeight;
  }

  function setText(id, text) {
    const element = byId(id);
    if (element) element.textContent = text;
  }

  document.body.addEventListener("htmx:afterSwap", function (event) {
    const panel = byId("progress-panel");
    if (panel && panel.dataset.jobId && event.detail.target && event.detail.target.id === "progress-panel") {
      connect(panel.dataset.jobId);
    }
  });
})();
