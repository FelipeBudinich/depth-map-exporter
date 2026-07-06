import { app, BrowserWindow } from "electron";
import { JobStore } from "./jobStore";
import { resolveAppPaths } from "./paths";
import { startLocalServer, LocalServer } from "./localServer";

let mainWindow: BrowserWindow | undefined;
let localServer: LocalServer | undefined;

async function createWindow(): Promise<void> {
  const paths = resolveAppPaths();
  const jobs = new JobStore();

  mainWindow = new BrowserWindow({
    width: 1120,
    height: 860,
    minWidth: 900,
    minHeight: 700,
    title: "Depth Exporter",
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true
    }
  });

  localServer = await startLocalServer(paths, jobs, () => {
    if (!mainWindow) {
      throw new Error("Main window is not available.");
    }
    return mainWindow;
  });

  console.log(`Depth Exporter GUI listening at ${localServer.url}`);
  await mainWindow.loadURL(localServer.url);
}

app.whenReady().then(async () => {
  await createWindow();

  app.on("activate", async () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      await createWindow();
    }
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});

app.on("before-quit", async () => {
  if (localServer) {
    await localServer.close();
  }
});
