import bygg/contribution_block.{type Contribution, Contribution, empty}

const app_imports = [
  "gleam/bytes_tree", "gleam/erlang/application",
  "gleam/erlang/process.{type Subject}", "gleam/http/request.{type Request}",
  "gleam/http/response", "gleam/json", "gleam/option.{Some}", "lustre",
  "lustre/attribute", "lustre/element.{type Element}", "lustre/element/html",
  "lustre/server_component", "mist.{type Connection, type ResponseData}",
]

pub fn contribution() -> Contribution {
  Contribution(..empty(), imports: app_imports, declarations: [
    serve_html_decl(),
    serve_runtime_decl(),
    socket_state_decl(),
    view_decl(),
  ])
}

fn serve_html_decl() -> String {
  "
fn serve_html() -> response.Response(ResponseData) {
  let body =
    html.html([attribute.lang(\"en\")], [
      html.head([], [
        html.meta([attribute.charset(\"utf-8\")]),
        html.script(
          [attribute.type_(\"module\"), attribute.src(\"/lustre/runtime.mjs\")],
          \"\",
        ),
      ]),
      html.body([], [
        server_component.element([server_component.route(\"/ws\")], []),
      ]),
    ])
    |> element.to_document_string_tree
    |> bytes_tree.from_string_tree

  response.new(200)
  |> response.set_body(mist.Bytes(body))
  |> response.set_header(\"content-type\", \"text/html\")
}
"
}

fn serve_runtime_decl() -> String {
  "
fn serve_runtime() -> response.Response(ResponseData) {
  let assert Ok(priv) = application.priv_directory(\"lustre\")
  case
    mist.send_file(
      priv <> \"/static/lustre-server-component.mjs\",
      offset: 0,
      limit: option.None,
    )
  {
    Ok(file) ->
      response.new(200)
      |> response.set_header(\"content-type\", \"application/javascript\")
      |> response.set_body(file)
    Error(_) ->
      response.new(404)
      |> response.set_body(mist.Bytes(bytes_tree.new()))
  }
}
"
}

fn socket_state_decl() -> String {
  "
type SocketState {
  SocketState(
    component: lustre.Runtime(Nil),
    self: Subject(server_component.ClientMessage(Nil)),
  )
}
"
}

fn view_decl() -> String {
  "
pub fn view() -> Element(Nil) {
  html.p([], [html.text(\"Hello from {project_name}!\")])
}
"
}
