import gleam/int
import gleam/list
import gleam/string

const gleam_docker_image_tag = "1.15.4"

fn indent(block: String) -> String {
  block
  |> string.split("\n")
  |> list.map(fn(line) { "  " <> line })
  |> string.join("\n")
}

pub fn compose(
  service_blocks: List(String),
  volume_blocks: List(String),
  app_port: Int,
  has_env: Bool,
) -> String {
  let service_names =
    list.filter_map(service_blocks, fn(block) {
      case string.split(block, "\n") {
        [first_line, ..] ->
          case string.split(string.trim(first_line), ":") {
            [name, ..] if name != "" -> Ok(name)
            _ -> Error(Nil)
          }
        _ -> Error(Nil)
      }
    })

  let app_service = case app_port {
    0 -> ""
    port -> {
      let port_str = int.to_string(port)
      let port_part =
        "\n  ports:\n    - \"" <> port_str <> ":" <> port_str <> "\""
      let env_part = case has_env {
        False -> ""
        True -> "\n  env_file:\n    - .env"
      }
      let depends_part = case service_names {
        [] -> ""
        names ->
          "\n  depends_on:\n"
          <> {
            list.map(names, fn(n) { "    - " <> n })
            |> string.join("\n")
          }
      }
      "app:\n  build: ." <> port_part <> env_part <> depends_part
    }
  }

  let all_services = case app_service {
    "" -> service_blocks
    app_service -> [app_service, ..service_blocks]
  }

  let indented_services =
    list.map(all_services, indent)
    |> string.join("\n")

  let volumes_section = case volume_blocks {
    [] -> ""
    volume_blocks ->
      "\n\nvolumes:\n"
      <> {
        list.map(volume_blocks, indent)
        |> string.join("\n")
      }
  }

  "services:\n" <> indented_services <> volumes_section <> "\n"
}

pub fn dockerfile(dockerfile_instructions: List(String)) -> String {
  let extra_instructions = case dockerfile_instructions {
    [] -> ""
    lines -> "\n" <> string.join(lines, "\n") <> "\n"
  }
  "FROM ghcr.io/gleam-lang/gleam:v"
  <> gleam_docker_image_tag
  <> "-erlang-alpine\n\nWORKDIR /app\n"
  <> extra_instructions
  <> "\nCOPY . .\nRUN gleam deps download\n\nCMD [\"gleam\", \"run\"]\n"
}
