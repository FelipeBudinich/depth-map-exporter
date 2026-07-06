const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const rendererSrc = path.join(root, "src", "renderer");
const rendererDest = path.join(root, "dist", "renderer");

fs.mkdirSync(path.join(rendererDest, "assets", "vendor"), { recursive: true });
fs.copyFileSync(path.join(rendererSrc, "index.html"), path.join(rendererDest, "index.html"));
fs.copyFileSync(path.join(rendererSrc, "app.js"), path.join(rendererDest, "assets", "app.js"));
fs.copyFileSync(
  path.join(root, "node_modules", "htmx.org", "dist", "htmx.min.js"),
  path.join(rendererDest, "assets", "vendor", "htmx.min.js")
);
