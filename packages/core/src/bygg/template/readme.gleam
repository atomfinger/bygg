import bygg/config.{type ProjectConfig}
import bygg/profile.{
  type ApplicationProfile, BasicApp, BrowserApp, Library, LustreComponent,
  LustreServerComponent, WebServer,
}
import gleam/int
import gleam/list
import gleam/option
import gleam/string

pub fn render(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  config_fields: List(String),
  needs_docker: Bool,
  needs_dockerfile: Bool,
  app_port: Int,
) -> String {
  let has_testcontainers =
    list.any(config.dev_dependencies, fn(p) {
      p.hex_name == "testcontainers_gleam"
    })

  let description_section = case config.description {
    option.None -> ""
    option.Some(desc) -> "\n" <> desc <> "\n"
  }

  let prerequisites_section = case needs_dockerfile {
    False -> ""
    True ->
      "\n## Prerequisites\n\n"
      <> "- [Docker Engine 24+](https://docs.docker.com/engine/install/) and [Docker Compose v2](https://docs.docker.com/compose/install/)\n"
      <> "- Or: [Gleam 1.15+](https://gleam.run/getting-started/installing/) and Erlang/OTP 27+\n"
  }

  let setup_section =
    build_setup_section(config_fields, needs_docker, needs_dockerfile, app_port)
  let main_section = build_main_section(app_profile, needs_dockerfile)
  let test_section = case needs_docker && !has_testcontainers {
    True ->
      "\n## Testing\n\nStart the services first:\n\n```sh\ndocker-compose up -d\n```\n\nThen run the tests:\n\n```sh\ngleam test\n```\n"
    False -> "\n## Testing\n\n```sh\ngleam test\n```\n"
  }

  "# "
  <> config.name
  <> "\n"
  <> description_section
  <> prerequisites_section
  <> setup_section
  <> main_section
  <> test_section
}

fn build_setup_section(
  config_fields: List(String),
  needs_docker: Bool,
  needs_dockerfile: Bool,
  app_port: Int,
) -> String {
  case needs_dockerfile {
    False -> {
      let items =
        list.flatten([
          case config_fields {
            [] -> []
            _ -> [
              "Copy `.env.example` to `.env` and configure your environment variables",
            ]
          },
          case needs_docker {
            False -> []
            True -> ["Start services: `docker-compose up -d`"]
          },
        ])
      case items {
        [] -> ""
        _ ->
          "\n## Setup\n\n"
          <> {
            list.map(items, fn(item) { "- [ ] " <> item })
            |> string.join("\n")
          }
          <> "\n"
      }
    }
    True -> {
      let port_url = case app_port {
        0 -> ""
        port -> {
          let port_string = int.to_string(port)
          "\nThen open [http://localhost:"
          <> port_string
          <> "](http://localhost:"
          <> port_string
          <> ") in your browser.\n"
        }
      }
      let env_step = case config_fields {
        [] -> ""
        _ -> "cp .env.example .env\n"
      }
      let quick_start =
        "\n## Quick start\n\n```sh\n"
        <> env_step
        <> "docker-compose up\n```\n"
        <> port_url

      let services_cmd = case needs_docker {
        False -> ""
        True -> "docker-compose up -d --scale app=0\n"
      }
      let running_locally =
        "\n## Running locally\n\n```sh\n"
        <> env_step
        <> services_cmd
        <> "gleam run\n```\n"
        <> port_url

      quick_start <> running_locally
    }
  }
}

fn build_main_section(
  app_profile: ApplicationProfile,
  needs_dockerfile: Bool,
) -> String {
  case app_profile {
    Library -> ""
    BrowserApp | LustreComponent ->
      "\n## Development\n\n```sh\ngleam run -m lustre/dev start\n```\n\n## Building\n\n```sh\ngleam run -m lustre/dev bundle\n```\n"
    LustreServerComponent ->
      case needs_dockerfile {
        True -> ""
        False ->
          "\n## Running\n\n```sh\ngleam run\n```\n\nThen open [http://localhost:1234](http://localhost:1234) in your browser.\n"
      }
    BasicApp | WebServer ->
      case needs_dockerfile {
        True -> ""
        False -> "\n## Running\n\n```sh\ngleam run\n```\n"
      }
  }
}
