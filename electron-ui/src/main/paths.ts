import { app } from "electron";
import fs from "node:fs";
import path from "node:path";

export type AppPaths = {
  appRoot: string;
  rendererRoot: string;
  cliPath?: string;
  bundledModelPath?: string;
};

export function resolveAppPaths(): AppPaths {
  const appRoot = path.resolve(__dirname, "..", "..");
  const workspaceRoot = path.resolve(appRoot, "..");
  const rendererRoot = path.join(appRoot, "dist", "renderer");

  const cliCandidates = [
    process.env.DEPTH_EXPORTER_PATH,
    path.join(workspaceRoot, ".build", "arm64-apple-macosx", "release", "depth-exporter"),
    path.join(appRoot, "resources", "bin", "depth-exporter"),
    path.join(process.resourcesPath, "bin", "depth-exporter")
  ].filter(Boolean) as string[];

  const modelCandidates = [
    path.join(appRoot, "resources", "models", "DepthAnythingV2SmallF16.mlpackage"),
    path.join(process.resourcesPath, "models", "DepthAnythingV2SmallF16.mlpackage")
  ];

  if (app.isPackaged) {
    cliCandidates.unshift(path.join(process.resourcesPath, "bin", "depth-exporter"));
    modelCandidates.unshift(path.join(process.resourcesPath, "models", "DepthAnythingV2SmallF16.mlpackage"));
  }

  return {
    appRoot,
    rendererRoot,
    cliPath: cliCandidates.find(exists),
    bundledModelPath: modelCandidates.find(exists)
  };
}

function exists(candidate: string): boolean {
  try {
    fs.accessSync(candidate, fs.constants.F_OK);
    return true;
  } catch {
    return false;
  }
}
