import bygg/config.{
  type JsRuntime, type ProjectConfig, type Target, Bun, Deno, Erlang, JavaScript,
  Node,
}
import gleam/list
import gleam/option
import gleam/string

pub fn render(config: ProjectConfig) -> String {
  [
    required_fields(config),
    optional_description(config),
    optional_licences(config),
    optional_links(config),
    optional_gleam_version(config),
    target_field(config),
    optional_internal_modules(config),
    optional_erlang_section(config),
    optional_javascript_section(config),
    dependencies_section(config),
    dev_dependencies_section(config),
  ]
  |> list.filter(fn(section) { section != "" })
  |> string.join("\n")
}

fn required_fields(config: ProjectConfig) -> String {
  "name = \"" <> config.name <> "\"\nversion = \"" <> config.version <> "\""
}

fn optional_description(config: ProjectConfig) -> String {
  case config.description {
    option.None -> ""
    option.Some(desc) -> "description = \"" <> desc <> "\""
  }
}

fn optional_licences(config: ProjectConfig) -> String {
  case config.licences {
    [] -> ""
    licences ->
      "licences = ["
      <> list.map(licences, fn(licence) { "\"" <> licence <> "\"" })
      |> string.join(", ")
      <> "]"
  }
}

fn optional_links(config: ProjectConfig) -> String {
  case config.links {
    [] -> ""
    links ->
      list.map(links, fn(link) {
        "links = [{ title = \""
        <> link.title
        <> "\", href = \""
        <> link.href
        <> "\" }]"
      })
      |> string.join("\n")
  }
}

fn optional_gleam_version(config: ProjectConfig) -> String {
  "gleam = \"" <> config.gleam_version_constraint <> "\""
}

fn target_field(config: ProjectConfig) -> String {
  case config.target {
    Erlang -> ""
    JavaScript -> "target = \"javascript\""
  }
}

fn optional_internal_modules(config: ProjectConfig) -> String {
  case config.internal_modules {
    [] -> ""
    modules ->
      "internal_modules = ["
      <> list.map(modules, fn(module) { "\"" <> module <> "\"" })
      |> string.join(", ")
      <> "]"
  }
}

fn optional_erlang_section(config: ProjectConfig) -> String {
  let has_start_module = option.is_some(config.application_start_module)
  let has_extra_apps = config.extra_applications != []

  case has_start_module || has_extra_apps {
    False -> ""
    True -> {
      let start_module_line = case config.application_start_module {
        option.None -> ""
        option.Some(module) ->
          "application_start_module = \"" <> module <> "\"\n"
      }
      let extra_apps_line = case config.extra_applications {
        [] -> ""
        apps ->
          "extra_applications = ["
          <> list.map(apps, fn(application) { "\"" <> application <> "\"" })
          |> string.join(", ")
          <> "]\n"
      }
      "[erlang]\n" <> start_module_line <> extra_apps_line
    }
  }
}

fn optional_javascript_section(config: ProjectConfig) -> String {
  case config.target {
    Erlang -> ""
    JavaScript -> {
      let ts_line = case config.typescript_declarations {
        False -> ""
        True -> "typescript_declarations = true\n"
      }
      let runtime_line = case config.js_runtime {
        option.None -> ""
        option.Some(rt) -> "runtime = \"" <> runtime_string(rt) <> "\"\n"
      }
      case ts_line <> runtime_line {
        "" -> ""
        body -> "[javascript]\n" <> body
      }
    }
  }
}

fn runtime_string(runtime: JsRuntime) -> String {
  case runtime {
    Node -> "node"
    Deno -> "deno"
    Bun -> "bun"
  }
}

fn dependencies_section(config: ProjectConfig) -> String {
  case config.dependencies {
    [] -> "[dependencies]"
    dependencies ->
      "[dependencies]\n"
      <> list.map(dependencies, fn(dependency) {
        dependency.hex_name <> " = \"" <> dependency.version_constraint <> "\""
      })
      |> string.join("\n")
  }
}

fn dev_dependencies_section(config: ProjectConfig) -> String {
  case config.dev_dependencies {
    [] -> "[dev-dependencies]"
    dependencies ->
      "[dev-dependencies]\n"
      <> list.map(dependencies, fn(dependency) {
        dependency.hex_name <> " = \"" <> dependency.version_constraint <> "\""
      })
      |> string.join("\n")
  }
}

pub fn target_string(target: Target) -> String {
  case target {
    Erlang -> "erlang"
    JavaScript -> "javascript"
  }
}
