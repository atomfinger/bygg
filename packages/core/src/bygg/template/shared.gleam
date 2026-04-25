import bygg/code_block.{
  ConfigField, ContextField, Declaration, Import, MainBody, OtpChildSpec,
  TestImport, TestSetup,
}
import gleam/int
import gleam/list
import gleam/option
import gleam/string

const gleam_docker_image_tag = "1.15.4"

import bygg/config.{type ProjectConfig}
import bygg/contribution.{type CodeContribution, blocks_for}
import bygg/profile.{
  type ApplicationProfile, BasicApp, BrowserApp, Library, LustreComponent,
  LustreServerComponent, WebServer,
}

pub fn src_module(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  contributions: List(CodeContribution),
) -> String {
  case app_profile {
    Library ->
      "pub fn hello() -> String {\n  \"Hello from " <> config.name <> "!\"\n}\n"
    BrowserApp -> browser_app_src(contributions)
    LustreComponent -> lustre_component_src(config, contributions)
    BasicApp -> basic_app_src(config, contributions)
    WebServer -> web_server_src(config, contributions)
    LustreServerComponent -> lustre_server_component_src(config, contributions)
  }
}

fn browser_app_src(contributions: List(CodeContribution)) -> String {
  let imports = blocks_for(contributions, Import)
  let declarations = blocks_for(contributions, Declaration)

  render_imports(imports) <> "

pub fn main() {
  let app = lustre.element(view())
  case lustre.start(app, \"#app\", Nil) {
    Ok(_) -> Nil
    Error(lustre.NotABrowser) ->
      panic as \"This app runs in a browser — use `gleam run -m lustre/dev start`\"
    Error(err) -> panic as string.inspect(err)
  }
}
" <> string.join(declarations, "")
}

fn lustre_component_src(
  config: ProjectConfig,
  contributions: List(CodeContribution),
) -> String {
  let imports = blocks_for(contributions, Import)
  let declarations = blocks_for(contributions, Declaration)

  render_imports(imports) <> "

pub fn main() {
  let app = lustre.element(view())
  case lustre.register(app, \"" <> config.name <> "-component\") {
    Ok(_) -> Nil
    Error(lustre.NotABrowser) ->
      panic as \"This component runs in a browser — use `gleam run -m lustre/dev start`\"
    Error(err) -> panic as string.inspect(err)
  }
}
" <> string.join(declarations, "")
}

fn field_names(context_fields: List(String)) -> List(String) {
  list.filter_map(context_fields, fn(content) {
    case string.split(content, ": ") {
      [name, ..] -> Ok(name)
      _ -> Error(Nil)
    }
  })
}

fn basic_app_src(
  config: ProjectConfig,
  contributions: List(CodeContribution),
) -> String {
  case list.is_empty(blocks_for(contributions, ConfigField)) {
    True ->
      "import gleam/io

pub fn main() {
  io.println(\"Hello, world!\")
}
"
    False -> {
      let external_imports =
        list.flatten([
          ["gleam/erlang/process"],
          blocks_for(contributions, Import),
        ])

      let suppress_bindings =
        blocks_for(contributions, ContextField)
        |> field_names()
        |> list.map(fn(name) { "\n  let _ = " <> name })
        |> string.join("")

      let init_stmts =
        blocks_for(contributions, MainBody)
        |> list.map(fn(stmt) { "\n  " <> stmt })
        |> string.join("")

      render_imports(external_imports) <> "\nimport " <> config.name <> "/config

pub fn main() {
  let cfg = config.load()" <> init_stmts <> "

  // TODO: add your application logic here" <> suppress_bindings <> "

  process.sleep_forever()
}
"
    }
  }
}

fn web_server_src(
  config: ProjectConfig,
  contributions: List(CodeContribution),
) -> String {
  let context_fields = blocks_for(contributions, ContextField)
  let has_context = !list.is_empty(context_fields)
  let has_config = !list.is_empty(blocks_for(contributions, ConfigField))
  let has_otp =
    list.any(config.dependencies, fn(dependency) {
      dependency.name == "gleam_otp"
    })
  let otp_children = blocks_for(contributions, OtpChildSpec)

  let base_imports = case has_otp {
    True -> [
      "gleam/erlang/process",
      "gleam/otp/static_supervisor",
      "mist",
      "wisp",
      "wisp/wisp_mist",
    ]
    False -> ["gleam/erlang/process", "mist", "wisp", "wisp/wisp_mist"]
  }

  let context_import = case has_context {
    False -> []
    True -> [config.name <> "/context.{type Context, Context}"]
  }

  let all_imports =
    list.flatten([
      base_imports,
      context_import,
      blocks_for(contributions, Import),
    ])

  let names = field_names(context_fields)

  let ctx_construction = case has_context {
    False -> ""
    True ->
      "\n  let ctx = Context("
      <> string.join(list.map(names, fn(n) { n <> ": " <> n }), ", ")
      <> ")"
  }

  let handler_arg = case has_context {
    False -> "handle_request"
    True -> "fn(req) { handle_request(req, ctx) }"
  }

  let handler_sig = case has_context {
    False -> "fn handle_request(req: wisp.Request) -> wisp.Response {"
    True ->
      "fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {"
  }

  let startup = case has_otp {
    False -> "
  let assert Ok(_) =
    wisp_mist.handler(" <> handler_arg <> ", secret_key_base)
    |> mist.new()
    |> mist.port(3000)
    |> mist.start()
"
    True -> {
      let extra_children =
        list.map(otp_children, fn(spec) {
          "\n    |> static_supervisor.add(\n      " <> spec <> ",\n    )"
        })
        |> string.join("")

      "
  let assert Ok(_) =
    static_supervisor.new(strategy: static_supervisor.OneForOne)
    |> static_supervisor.add(
      wisp_mist.handler(" <> handler_arg <> ", secret_key_base)
      |> mist.new()
      |> mist.port(3000)
      |> mist.supervised,
    )" <> extra_children <> "
    |> static_supervisor.start()
"
    }
  }

  render_imports(all_imports)
  <> case has_config {
    False -> ""
    True -> "\nimport " <> config.name <> "/config"
  }
  <> "
"
  <> "
pub fn main() {
  wisp.configure_logger()
"
  <> case has_config {
    False -> ""
    True -> "\n  let cfg = config.load()"
  }
  <> {
    blocks_for(contributions, MainBody)
    |> list.map(fn(stmt) { "\n  " <> stmt })
    |> string.join("")
  }
  <> case has_config {
    False -> ""
    True -> "\n"
  }
  <> ctx_construction
  <> "
  let secret_key_base = wisp.random_string(64)
"
  <> startup
  <> "\n  process.sleep_forever()
}

"
  <> handler_sig
  <> "
  use _req <- wisp.handle_head(req)"
  <> case has_context {
    False -> ""
    True -> "\n  let _ = ctx"
  }
  <> "
  wisp.ok()
  |> wisp.string_body(\"Hello from "
  <> config.name
  <> "!\")
}
"
  <> string.join(blocks_for(contributions, Declaration), "")
}

fn lustre_server_component_src(
  config: ProjectConfig,
  contributions: List(CodeContribution),
) -> String {
  let context_fields = blocks_for(contributions, ContextField)
  let has_context = !list.is_empty(context_fields)
  let has_config = !list.is_empty(blocks_for(contributions, ConfigField))
  let has_otp =
    list.any(config.dependencies, fn(dependency) {
      dependency.name == "gleam_otp"
    })
  let otp_children = blocks_for(contributions, OtpChildSpec)

  let names = field_names(context_fields)

  let ctx_construction = case has_context {
    False -> ""
    True ->
      "\n  let ctx = Context("
      <> string.join(list.map(names, fn(n) { n <> ": " <> n }), ", ")
      <> ")"
  }

  let serve_ws_sig = case has_context {
    False ->
      "
fn serve_ws(req: Request(Connection)) -> response.Response(ResponseData) {"
    True ->
      "
fn serve_ws(req: Request(Connection), ctx: Context) -> response.Response(ResponseData) {"
  }

  let otp_import = case has_otp {
    True -> ["gleam/otp/static_supervisor"]
    False -> []
  }

  let context_import = case has_context {
    False -> []
    True -> [config.name <> "/context.{type Context, Context}"]
  }

  let all_imports =
    list.flatten([otp_import, context_import, blocks_for(contributions, Import)])

  let ws_route = case has_context {
    False -> "        [\"ws\"] -> serve_ws(req)"
    True -> "        [\"ws\"] -> serve_ws(req, ctx)"
  }

  let startup = case has_otp {
    False -> "  let assert Ok(_) =
    fn(req: Request(Connection)) -> response.Response(ResponseData) {
      case request.path_segments(req) {
        [] -> serve_html()
        [\"lustre\", \"runtime.mjs\"] -> serve_runtime()
" <> ws_route <> "
        _ ->
          response.new(404)
          |> response.set_body(mist.Bytes(bytes_tree.new()))
      }
    }
    |> mist.new
    |> mist.port(1234)
    |> mist.start
"
    True -> {
      let extra_children =
        list.map(otp_children, fn(spec) {
          "\n    |> static_supervisor.add(\n      " <> spec <> ",\n    )"
        })
        |> string.join("")

      "  let assert Ok(_) =
    static_supervisor.new(strategy: static_supervisor.OneForOne)
    |> static_supervisor.add(
      fn(req: Request(Connection)) -> response.Response(ResponseData) {
        case request.path_segments(req) {
          [] -> serve_html()
          [\"lustre\", \"runtime.mjs\"] -> serve_runtime()
" <> "  " <> ws_route <> "
          _ ->
            response.new(404)
            |> response.set_body(mist.Bytes(bytes_tree.new()))
        }
      }
      |> mist.new
      |> mist.port(1234)
      |> mist.supervised,
    )" <> extra_children <> "
    |> static_supervisor.start()
"
    }
  }

  render_imports(all_imports)
  <> case has_config {
    False -> ""
    True -> "\nimport " <> config.name <> "/config"
  }
  <> "
"
  <> "
pub fn main() {"
  <> case has_config {
    False -> ""
    True -> "\n  let cfg = config.load()"
  }
  <> {
    blocks_for(contributions, MainBody)
    |> list.map(fn(stmt) { "\n  " <> stmt })
    |> string.join("")
  }
  <> ctx_construction
  <> "
"
  <> startup
  <> "
  process.sleep_forever()
}
"
  <> string.join(blocks_for(contributions, Declaration), "")
  <> serve_ws_sig
  <> "
  mist.websocket(
    request: req,
    on_init: fn(_) {"
  <> case has_context {
    False -> ""
    True -> "\n      let _ = ctx"
  }
  <> "
      let app = lustre.element(view())
      let assert Ok(component) = lustre.start_server_component(app, Nil)
      let self = process.new_subject()
      let selector = process.new_selector() |> process.select(self)
      server_component.register_subject(self)
      |> lustre.send(to: component)
      #(SocketState(component:, self:), Some(selector))
    },
    handler: fn(state: SocketState, message, conn) {
      case message {
        mist.Text(text) -> {
          case json.parse(text, server_component.runtime_message_decoder()) {
            Ok(msg) -> lustre.send(state.component, msg)
            Error(_) -> Nil
          }
          mist.continue(state)
        }
        mist.Custom(msg) -> {
          let json_msg = server_component.client_message_to_json(msg)
          let assert Ok(_) =
            mist.send_text_frame(conn, json.to_string(json_msg))
          mist.continue(state)
        }
        mist.Binary(_) -> mist.continue(state)
        mist.Closed | mist.Shutdown -> mist.stop()
      }
    },
    on_close: fn(state: SocketState) {
      lustre.shutdown()
      |> lustre.send(to: state.component)
    },
  )
}
"
}

pub fn render_imports(imports: List(String)) -> String {
  imports
  |> list.unique()
  |> list.sort(string.compare)
  |> list.map(fn(module_path) { "import " <> module_path })
  |> string.join("\n")
}

pub fn context_module(context_fields: List(String)) -> String {
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

pub fn test_module(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  contributions: List(CodeContribution),
) -> String {
  let has_testcontainers =
    list.any(config.dependencies, fn(package) {
      package.hex_name == "testcontainers_gleam"
    })
    || list.any(config.dev_dependencies, fn(package) {
      package.hex_name == "testcontainers_gleam"
    })

  let test_imports = blocks_for(contributions, TestImport) |> list.unique()

  let setup_code =
    blocks_for(contributions, TestSetup)
    |> string.join("\n")
    |> fn(setup_code_string) {
      case setup_code_string {
        "" ->
          "  // let assert Ok(running) = testcontainers_gleam.start_container(container)"
        _ -> setup_code_string
      }
    }

  case app_profile {
    Library -> {
      let base_imports = case has_testcontainers {
        True -> [
          "gleeunit/should",
          "testcontainers_gleam/integration",
          config.name,
        ]
        False -> ["gleeunit", "gleeunit/should", config.name]
      }

      let all_imports = case has_testcontainers {
        True -> list.flatten([base_imports, test_imports])
        False -> base_imports
      }

      let main_body = case has_testcontainers {
        True -> "  integration.main()"
        False -> "  gleeunit.main()"
      }

      let test_body = case has_testcontainers {
        True -> "  use <- integration.guard()\n" <> setup_code <> "\n"
        False -> ""
      }

      render_imports(all_imports)
      <> "\n\npub fn main() {\n"
      <> main_body
      <> "\n}\n\npub fn hello_test() {\n"
      <> test_body
      <> "  "
      <> config.name
      <> ".hello()\n  |> should.equal(\"Hello from "
      <> config.name
      <> "!\")\n}\n"
    }
    _ -> {
      let base_imports = case has_testcontainers {
        True -> ["testcontainers_gleam/integration"]
        False -> ["gleeunit"]
      }

      let all_imports = case has_testcontainers {
        True -> list.flatten([base_imports, test_imports])
        False -> base_imports
      }

      let main_body = case has_testcontainers {
        True -> "  integration.main()"
        False -> "  gleeunit.main()"
      }

      let extra = case has_testcontainers {
        True ->
          "\n\npub fn example_test() {\n  use <- integration.guard()\n"
          <> setup_code
          <> "\n}\n"
        False -> ""
      }

      render_imports(all_imports)
      <> "\n\npub fn main() {\n"
      <> main_body
      <> "\n}\n"
      <> extra
    }
  }
}

pub fn gitignore(_config: ProjectConfig) -> String {
  "/build/
*.beam
*.ez
erl_crash.dump
.env
"
}

pub fn readme(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  config_fields: List(String),
  needs_docker: Bool,
  needs_dockerfile: Bool,
  app_port: Int,
) -> String {
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
  let test_section = "\n## Testing\n\n```sh\ngleam test\n```\n"

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

pub fn env_example(env_var_blocks: List(String)) -> String {
  string.join(env_var_blocks, "\n\n") <> "\n"
}

pub fn config_module(
  _project_name: String,
  config_field_blocks: List(String),
) -> String {
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

pub fn docker_compose(
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
        "\n    ports:\n      - \"" <> port_str <> ":" <> port_str <> "\""
      let env_part = case has_env {
        False -> ""
        True -> "\n    env_file:\n      - .env"
      }
      let depends_part = case service_names {
        [] -> ""
        names ->
          "\n    depends_on:\n"
          <> {
            list.map(names, fn(n) { "      - " <> n })
            |> string.join("\n")
          }
      }
      "  app:\n    build: ." <> port_part <> env_part <> depends_part
    }
  }

  let all_services = case app_service {
    "" -> service_blocks
    app_service -> [app_service, ..service_blocks]
  }

  let volumes_section = case volume_blocks {
    [] -> ""
    volume_blocks -> "\n\nvolumes:\n" <> string.join(volume_blocks, "\n")
  }

  "services:\n" <> string.join(all_services, "\n") <> volumes_section <> "\n"
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
