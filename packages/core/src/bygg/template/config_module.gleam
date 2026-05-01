import gleam/list
import gleam/string

pub fn render(config_field_blocks: List(String)) -> String {
  let fields =
    list.map(config_field_blocks, fn(content) { "  " <> content <> "," })
    |> string.join("\n")

  let readers =
    list.map(config_field_blocks, fn(content) {
      case string.split(content, ": ") {
        [field_name, ..] ->
          "    "
          <> field_name
          <> ": read_env(\""
          <> string.uppercase(field_name)
          <> "\"),"
        _ -> ""
      }
    })
    |> string.join("\n")

  "import envoy
import gleam/string

pub type Config {
  Config(
" <> fields <> "
  )
}

pub fn load() -> Config {
  Config(
" <> readers <> "
  )
}

fn read_env(key: String) -> String {
  case envoy.get(key) {
    Ok(value) -> value
    Error(_) -> panic as string.concat([\"Missing environment variable: \", key])
  }
}
"
}
