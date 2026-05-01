import gleam/option.{type Option}

pub type Target {
  Erlang
  JavaScript
}

pub type JsRuntime {
  Node
  Deno
  Bun
}

pub type Link {
  Link(title: String, href: String)
}

pub type SelectedPackage {
  SelectedPackage(name: String, hex_name: String, version_constraint: String)
}

pub type ProjectConfig {
  ProjectConfig(
    name: String,
    version: String,
    description: Option(String),
    licences: List(String),
    target: Target,
    gleam_version_constraint: String,
    dependencies: List(SelectedPackage),
    dev_dependencies: List(SelectedPackage),
    application_start_module: Option(String),
    extra_applications: List(String),
    typescript_declarations: Bool,
    js_runtime: Option(JsRuntime),
    internal_modules: List(String),
    links: List(Link),
    archetype: Option(String),
  )
}

pub fn default(name: String) -> ProjectConfig {
  ProjectConfig(
    name: name,
    version: "1.0.0",
    description: option.None,
    licences: [],
    target: Erlang,
    gleam_version_constraint: ">= 1.16.0 and < 2.0.0",
    dependencies: [],
    dev_dependencies: [
      SelectedPackage("unitest", "unitest", ">= 1.5.0 and < 2.0.0"),
    ],
    application_start_module: option.None,
    extra_applications: [],
    typescript_declarations: False,
    js_runtime: option.None,
    internal_modules: [],
    links: [],
    archetype: option.None,
  )
}
