import JSZip from "jszip";

export async function downloadZip(projectName, files) {
  const zip = new JSZip();
  const folder = zip.folder(projectName);
  for (const [path, content] of files) {
    folder.file(path, content);
  }
  const blob = await zip.generateAsync({ type: "blob", compression: "DEFLATE" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = projectName + ".zip";
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
