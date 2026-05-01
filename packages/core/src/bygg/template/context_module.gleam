import gleam/list
import gleam/string

pub fn render(context_fields: List(String)) -> String {
  let imports =
    list.filter_map(context_fields, fn(field) {
      case string.split(field, ": ") {
        [_, type_str, ..] ->
          case string.split(type_str, ".") {
            [module, ..] -> Ok(module)
            _ -> Error(Nil)
          }
        _ -> Error(Nil)
      }
    })
    |> list.unique()
    |> list.sort(string.compare)
    |> list.map(fn(module_path) { "import " <> module_path })
    |> string.join("\n")

  imports
  <> "\n\npub type Context {\n  Context("
  <> string.join(context_fields, ", ")
  <> ")\n}\n"
}
