import bygg/config.{type ProjectConfig}
import bygg/contribution.{type NamedContribution}
import bygg/profile.{
  type ApplicationProfile, BasicApp, BrowserApp, Library, LustreComponent,
  LustreServerComponent, WebServer,
}
import bygg/template/imports as imports_module
import bygg/template/test_utils_module
import gleam/list

pub fn render(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  contributions: List(NamedContribution),
) -> String {
  let has_testcontainers =
    list.any(config.dependencies, fn(p) { p.hex_name == "testcontainers_gleam" })
    || list.any(config.dev_dependencies, fn(p) {
      p.hex_name == "testcontainers_gleam"
    })

  let has_test_utils =
    test_utils_module.needs_test_utils(
      contributions,
      app_profile,
      has_testcontainers,
    )

  let has_containers =
    has_testcontainers
    && !list.is_empty(contribution.all_test_helpers(contributions))
  let needs_integration_tag = has_containers

  let context_fields = contribution.all_context_fields(contributions)
  let has_context =
    !list.is_empty(context_fields)
    && case app_profile {
      WebServer | LustreServerComponent -> True
      _ -> False
    }

  let test_utils_import = case has_test_utils, has_containers {
    True, True -> [config.name <> "/test_utils.{setup, stop_containers}"]
    True, False -> [config.name <> "/test_utils.{setup}"]
    False, _ -> []
  }

  let setup_call = case has_test_utils {
    True -> "  let test_context = setup()\n"
    False -> ""
  }

  let stop_call = case has_containers {
    True -> "\n  stop_containers(test_context.container_ids)"
    False -> ""
  }

  let integration_tag = case needs_integration_tag {
    True -> "  use <- unitest.tag(\"integration\")\n"
    False -> ""
  }

  case app_profile {
    Library -> render_library(config, test_utils_import, setup_call, stop_call)
    BrowserApp | LustreComponent ->
      render_browser_or_component(
        config,
        test_utils_import,
        setup_call,
        stop_call,
      )
    WebServer ->
      render_web_server(
        config,
        test_utils_import,
        integration_tag,
        setup_call,
        stop_call,
        has_context,
      )
    LustreServerComponent ->
      render_lustre_server_component(
        config,
        test_utils_import,
        integration_tag,
        setup_call,
        stop_call,
      )
    BasicApp ->
      render_basic_app(
        config,
        test_utils_import,
        integration_tag,
        setup_call,
        stop_call,
        has_test_utils,
      )
  }
}

fn render_library(
  config: ProjectConfig,
  test_utils_import: List(String),
  setup_call: String,
  stop_call: String,
) -> String {
  let _ = setup_call
  let _ = stop_call
  let all_imports = list.flatten([["unitest", config.name], test_utils_import])

  imports_module.render(all_imports)
  <> "\n\npub fn main() {\n  unitest.main()\n}\n\npub fn hello_test() {\n  assert \"Hello from "
  <> config.name
  <> "!\" = "
  <> config.name
  <> ".hello()\n}\n"
}

fn render_browser_or_component(
  config: ProjectConfig,
  test_utils_import: List(String),
  setup_call: String,
  stop_call: String,
) -> String {
  let _ = setup_call
  let _ = stop_call
  let all_imports =
    list.flatten([
      ["gleam/string", "lustre/element", config.name, "unitest"],
      test_utils_import,
    ])

  imports_module.render(all_imports)
  <> "\n\npub fn main() {\n  unitest.main()\n}\n\npub fn view_renders_test() {\n  let html = "
  <> config.name
  <> ".view() |> element.to_string()\n  assert True = string.contains(html, \"Hello from "
  <> config.name
  <> "!\")\n}\n"
}

fn render_web_server(
  config: ProjectConfig,
  test_utils_import: List(String),
  integration_tag: String,
  setup_call: String,
  stop_call: String,
  has_context: Bool,
) -> String {
  let all_imports =
    list.flatten([
      [config.name, "gleam/http", "unitest", "wisp/simulate"],
      test_utils_import,
    ])

  let handler_call = case has_context {
    False -> config.name <> ".handle_request(req)"
    True -> config.name <> ".handle_request(req, test_context.ctx)"
  }

  let test_body =
    integration_tag
    <> setup_call
    <> "  let req = simulate.request(http.Get, \"/\")\n  let response = "
    <> handler_call
    <> "\n  assert 200 = response.status"
    <> stop_call

  imports_module.render(all_imports)
  <> "\n\npub fn main() {\n  unitest.main()\n}\n\npub fn get_root_test() {\n"
  <> test_body
  <> "\n}\n"
}

fn render_lustre_server_component(
  config: ProjectConfig,
  test_utils_import: List(String),
  integration_tag: String,
  setup_call: String,
  stop_call: String,
) -> String {
  let all_imports =
    list.flatten([
      ["gleam/string", "lustre/element", config.name, "unitest"],
      test_utils_import,
    ])

  let test_body =
    integration_tag
    <> setup_call
    <> "  let html = "
    <> config.name
    <> ".view() |> element.to_string()\n  assert True = string.contains(html, \"Hello from "
    <> config.name
    <> "!\")"
    <> stop_call

  imports_module.render(all_imports)
  <> "\n\npub fn main() {\n  unitest.main()\n}\n\npub fn view_renders_test() {\n"
  <> test_body
  <> "\n}\n"
}

fn render_basic_app(
  config: ProjectConfig,
  test_utils_import: List(String),
  integration_tag: String,
  setup_call: String,
  stop_call: String,
  has_test_utils: Bool,
) -> String {
  let all_imports = list.flatten([["unitest"], test_utils_import])
  let _ = config

  // When containers are involved, setup() and stop_containers() form the body.
  // Otherwise emit `Nil` as the placeholder (avoids the `True = True` warning).
  let has_containers = stop_call != ""
  let body = case has_test_utils, has_containers {
    True, True ->
      integration_tag
      <> setup_call
      <> "  // Verify your application logic here"
      <> stop_call
    True, False ->
      integration_tag
      <> setup_call
      <> "  // Verify your application logic here\n"
      <> "  Nil"
    False, _ -> "  // Verify your application logic here\n  Nil"
  }

  imports_module.render(all_imports)
  <> "\n\npub fn main() {\n  unitest.main()\n}\n\npub fn example_test() {\n"
  <> body
  <> "\n}\n"
}
