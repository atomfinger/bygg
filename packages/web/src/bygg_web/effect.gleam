import bygg/generator.{type FileEntry}
import gleam/list
import lustre/effect.{type Effect}

@external(javascript, "./ffi/zip.mjs", "downloadZip")
fn download_zip_ffi(project_name: String, files: List(#(String, String))) -> Nil

pub fn download_zip(
  project_name: String,
  files: List(FileEntry),
) -> Effect(msg) {
  effect.from(fn(_dispatch) {
    let pairs = list.map(files, fn(f) { #(f.path, f.content) })
    download_zip_ffi(project_name, pairs)
  })
}
