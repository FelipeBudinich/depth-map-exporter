import { BrowserWindow, dialog } from "electron";
import path from "node:path";

export type OutputPathOptions = {
  includeAudio?: boolean;
  stackVertical?: boolean;
};

export async function chooseInput(window: BrowserWindow): Promise<string | undefined> {
  const result = await dialog.showOpenDialog(window, {
    title: "Choose input MP4",
    properties: ["openFile"],
    filters: [{ name: "MP4 Video", extensions: ["mp4"] }]
  });
  return result.canceled ? undefined : result.filePaths[0];
}

export async function chooseModel(window: BrowserWindow): Promise<string | undefined> {
  const result = await dialog.showOpenDialog(window, {
    title: "Choose Core ML model",
    properties: ["openFile", "openDirectory"],
    filters: [{ name: "Core ML Model", extensions: ["mlpackage", "mlmodel", "mlmodelc"] }]
  });
  return result.canceled ? undefined : result.filePaths[0];
}

export async function chooseOutput(window: BrowserWindow, inputPath?: string, options: OutputPathOptions = {}): Promise<string | undefined> {
  const result = await dialog.showSaveDialog(window, {
    title: "Choose output MP4",
    defaultPath: inputPath ? defaultOutputPath(inputPath, options) : undefined,
    filters: [{ name: "MP4 Video", extensions: ["mp4"] }]
  });
  return result.canceled ? undefined : result.filePath;
}

export function defaultOutputPath(inputPath: string, options: OutputPathOptions = {}): string {
  const parsed = path.parse(inputPath);
  const suffix = options.stackVertical ? "-depth-test" : "-depth";
  const audioSuffix = options.includeAudio ? "-audio" : "";
  return path.join(parsed.dir, `${parsed.name}${suffix}${audioSuffix}.mp4`);
}
