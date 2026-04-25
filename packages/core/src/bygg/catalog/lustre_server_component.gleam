import bygg/code_block.{type CodeBlock, Always, CodeBlock, Declaration, Import}

pub const code_blocks: List(CodeBlock) = [
  CodeBlock(Import, "gleam/bytes_tree", Always),
  CodeBlock(Import, "gleam/erlang/application", Always),
  CodeBlock(Import, "gleam/erlang/process.{type Subject}", Always),
  CodeBlock(Import, "gleam/http/request.{type Request}", Always),
  CodeBlock(Import, "gleam/http/response", Always),
  CodeBlock(Import, "gleam/json", Always),
  CodeBlock(Import, "gleam/option.{Some}", Always),
  CodeBlock(Import, "lustre", Always),
  CodeBlock(Import, "lustre/attribute", Always),
  CodeBlock(Import, "lustre/element.{type Element}", Always),
  CodeBlock(Import, "lustre/element/html", Always),
  CodeBlock(Import, "lustre/server_component", Always),
  CodeBlock(Import, "mist.{type Connection, type ResponseData}", Always),
  CodeBlock(
    Declaration,
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
",
    Always,
  ),
  CodeBlock(
    Declaration,
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
",
    Always,
  ),
  CodeBlock(
    Declaration,
    "
type SocketState {
  SocketState(
    component: lustre.Runtime(Nil),
    self: Subject(server_component.ClientMessage(Nil)),
  )
}
",
    Always,
  ),
  CodeBlock(
    Declaration,
    "
fn view() -> Element(Nil) {
  html.p([], [html.text(\"Hello from {project_name}!\")])
}
",
    Always,
  ),
]
