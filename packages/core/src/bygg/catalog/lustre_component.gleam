import bygg/code_block.{type CodeBlock, Always, CodeBlock, Declaration, Import}

pub const code_blocks: List(CodeBlock) = [
  CodeBlock(Import, "gleam/string", Always),
  CodeBlock(Import, "lustre", Always),
  CodeBlock(Import, "lustre/element.{type Element}", Always),
  CodeBlock(Import, "lustre/element/html", Always),
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
