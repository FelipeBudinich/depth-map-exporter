export function escapeHtml(value: unknown): string {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll("\"", "&quot;")
    .replaceAll("'", "&#39;");
}

export function selected(current: string, value: string): string {
  return current === value ? "selected" : "";
}

export function checked(value: boolean): string {
  return value ? "checked" : "";
}

export function jsonAttribute(value: unknown): string {
  return escapeHtml(JSON.stringify(value));
}
