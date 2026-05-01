import gleam/list
import gleam/string

pub fn render(config_field_blocks: List(String)) -> String {
  let field_names =
    list.filter_map(config_field_blocks, fn(content) {
      case string.split(content, ": ") {
        [name, ..] -> Ok(name)
        _ -> Error(Nil)
      }
    })

  let reader_args =
    list.map(field_names, fn(n) {
      n <> ": read_env(\"" <> string.uppercase(n) <> "\")"
    })

  "import envoy
import gleam/string

pub type Config {
" <> render_constructor("  ", config_field_blocks) <> "
}

pub fn load() -> Config {
" <> render_constructor("  ", reader_args) <> "
}

fn read_env(key: String) -> String {
  case envoy.get(key) {
    Ok(value) -> value
    Error(_) -> panic as string.concat([\"Missing environment variable: \", key])
  }
}
"
}

fn render_constructor(indent: String, args: List(String)) -> String {
  let inline = indent <> "Config(" <> string.join(args, ", ") <> ")"
  case string.length(inline) <= 80 {
    True -> inline
    False ->
      indent
      <> "Config(\n"
      <> indent
      <> "  "
      <> string.join(args, ",\n" <> indent <> "  ")
      <> ",\n"
      <> indent
      <> ")"
  }
}
