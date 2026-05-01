import bygg/config.{type ProjectConfig}
import bygg/contribution.{type NamedContribution}
import bygg/profile.{
  type ApplicationProfile, BasicApp, BrowserApp, Library, LustreComponent,
  LustreServerComponent, WebServer,
}
import bygg/template/imports as imports_module
import gleam/list
import gleam/string

pub fn render(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  contributions: List(NamedContribution),
) -> String {
  case app_profile {
    Library ->
      "pub fn hello() -> String {\n  \"Hello from " <> config.name <> "!\"\n}\n"
    BrowserApp -> browser_app(contributions)
    LustreComponent -> lustre_component(config, contributions)
    BasicApp -> basic_app(config, contributions)
    WebServer -> web_server(config, contributions)
    LustreServerComponent -> lustre_server_component(config, contributions)
  }
}

fn browser_app(contributions: List(NamedContribution)) -> String {
  let imports = contribution.all_imports(contributions)
  let declarations = contribution.all_declarations(contributions)

  imports_module.render(imports) <> "

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

fn lustre_component(
  config: ProjectConfig,
  contributions: List(NamedContribution),
) -> String {
  let imports = contribution.all_imports(contributions)
  let declarations = contribution.all_declarations(contributions)

  imports_module.render(imports) <> "

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

fn basic_app(
  config: ProjectConfig,
  contributions: List(NamedContribution),
) -> String {
  case list.is_empty(contribution.all_config_fields(contributions)) {
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
          contribution.all_imports(contributions),
        ])

      let suppress_bindings =
        contribution.all_context_fields(contributions)
        |> field_names()
        |> list.map(fn(name) { "\n  let _ = " <> name })
        |> string.join("")

      let init_stmts =
        contribution.all_main_body(contributions)
        |> list.map(fn(stmt) { "\n  " <> stmt })
        |> string.join("")

      imports_module.render(external_imports)
      <> "\nimport "
      <> config.name
      <> "/config

pub fn main() {
  let cfg = config.load()"
      <> init_stmts
      <> "

  // TODO: add your application logic here"
      <> suppress_bindings
      <> "

  process.sleep_forever()
}
"
    }
  }
}

fn web_server(
  config: ProjectConfig,
  contributions: List(NamedContribution),
) -> String {
  let context_fields = contribution.all_context_fields(contributions)
  let has_context = !list.is_empty(context_fields)
  let has_config = !list.is_empty(contribution.all_config_fields(contributions))
  let has_otp =
    list.any(config.dependencies, fn(dependency) {
      dependency.name == "gleam_otp"
    })
  let otp_children = contribution.all_otp_child_specs(contributions)

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

  let config_import = case has_config {
    True -> [config.name <> "/config"]
    False -> []
  }

  let all_imports =
    list.flatten([
      base_imports,
      context_import,
      config_import,
      contribution.all_imports(contributions),
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
    False -> "pub fn handle_request(req: wisp.Request) -> wisp.Response {"
    True ->
      "pub fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {"
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
          let line = "    |> static_supervisor.add(" <> spec <> ")"
          case !string.contains(spec, "\n") && string.length(line) <= 80 {
            True -> "\n" <> line
            False ->
              "\n    |> static_supervisor.add(\n      " <> spec <> ",\n    )"
          }
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

  imports_module.render(all_imports) <> "
" <> "
pub fn main() {
  wisp.configure_logger()
" <> case has_config {
    False -> ""
    True -> "\n  let cfg = config.load()"
  } <> {
    contribution.all_main_body(contributions)
    |> list.map(fn(stmt) { "\n  " <> stmt })
    |> string.join("")
  } <> case has_config {
    False -> ""
    True -> "\n"
  } <> ctx_construction <> "
  let secret_key_base = wisp.random_string(64)
" <> startup <> "\n  process.sleep_forever()
}

" <> handler_sig <> "
  use _req <- wisp.handle_head(req)" <> case has_context {
    False -> ""
    True -> "\n  let _ = ctx"
  } <> "
  wisp.ok()
  |> wisp.string_body(\"Hello from " <> config.name <> "!\")
}
" <> string.join(contribution.all_declarations(contributions), "")
}

fn lustre_server_component(
  config: ProjectConfig,
  contributions: List(NamedContribution),
) -> String {
  let context_fields = contribution.all_context_fields(contributions)
  let has_context = !list.is_empty(context_fields)
  let has_config = !list.is_empty(contribution.all_config_fields(contributions))
  let has_otp =
    list.any(config.dependencies, fn(dependency) {
      dependency.name == "gleam_otp"
    })
  let otp_children = contribution.all_otp_child_specs(contributions)

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
fn serve_ws(
  req: Request(Connection),
  ctx: Context,
) -> response.Response(ResponseData) {"
  }

  let otp_import = case has_otp {
    True -> ["gleam/otp/static_supervisor"]
    False -> []
  }

  let context_import = case has_context {
    False -> []
    True -> [config.name <> "/context.{type Context, Context}"]
  }

  let config_import = case has_config {
    True -> [config.name <> "/config"]
    False -> []
  }

  let all_imports =
    list.flatten([
      otp_import,
      context_import,
      config_import,
      contribution.all_imports(contributions),
    ])

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
          let line = "    |> static_supervisor.add(" <> spec <> ")"
          case !string.contains(spec, "\n") && string.length(line) <= 80 {
            True -> "\n" <> line
            False ->
              "\n    |> static_supervisor.add(\n      " <> spec <> ",\n    )"
          }
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

  imports_module.render(all_imports) <> "
" <> "
pub fn main() {" <> case has_config {
    False -> ""
    True -> "\n  let cfg = config.load()"
  } <> {
    contribution.all_main_body(contributions)
    |> list.map(fn(stmt) { "\n  " <> stmt })
    |> string.join("")
  } <> ctx_construction <> "
" <> startup <> "
  process.sleep_forever()
}
" <> string.join(contribution.all_declarations(contributions), "") <> serve_ws_sig <> "
  mist.websocket(
    request: req,
    on_init: fn(_) {" <> case has_context {
    False -> ""
    True -> "\n      let _ = ctx"
  } <> "
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
