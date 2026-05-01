import gleam/list
import gleam/string

pub fn render(imports: List(String)) -> String {
  imports
  |> list.unique()
  |> list.sort(string.compare)
  |> list.map(fn(module_path) { "import " <> module_path })
  |> string.join("\n")
}
