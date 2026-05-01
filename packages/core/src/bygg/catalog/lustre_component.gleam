import bygg/contribution_block.{type Contribution, Contribution, empty}

const app_imports = [
  "gleam/string", "lustre", "lustre/element.{type Element}",
  "lustre/element/html",
]

pub fn contribution() -> Contribution {
  Contribution(..empty(), imports: app_imports, declarations: [view_decl()])
}

fn view_decl() -> String {
  "
pub fn view() -> Element(Nil) {
  html.p([], [html.text(\"Hello from {project_name}!\")])
}
"
}
