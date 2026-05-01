import bygg/config.{type ProjectConfig}
import bygg/contribution.{type NamedContribution}
import bygg/profile.{type ApplicationProfile, LustreServerComponent, WebServer}
import bygg/template/imports as imports_module
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub fn needs_test_utils(
  contributions: List(NamedContribution),
  app_profile: ApplicationProfile,
  has_testcontainers: Bool,
) -> Bool {
  let has_helpers =
    has_testcontainers
    && !list.is_empty(contribution.all_test_helpers(contributions))
  let has_fallback =
    !list.is_empty(contribution.all_test_setup_fallbacks(contributions))
  let has_context =
    !list.is_empty(contribution.all_context_fields(contributions))
    && case app_profile {
      WebServer | LustreServerComponent -> True
      _ -> False
    }
  has_helpers || has_fallback || has_context
}

pub fn render(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  contributions: List(NamedContribution),
  has_testcontainers: Bool,
) -> Option(String) {
  case needs_test_utils(contributions, app_profile, has_testcontainers) {
    False -> None
    True -> Some(build(config, app_profile, contributions, has_testcontainers))
  }
}

fn build(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  contributions: List(NamedContribution),
  has_testcontainers: Bool,
) -> String {
  let context_fields = contribution.all_context_fields(contributions)
  let has_context =
    !list.is_empty(context_fields)
    && case app_profile {
      WebServer | LustreServerComponent -> True
      _ -> False
    }

  let test_helpers = case has_testcontainers {
    True -> contribution.all_test_helpers(contributions)
    False -> []
  }
  let container_handles = case has_testcontainers {
    True -> contribution.all_test_container_handles(contributions)
    False -> []
  }
  let has_containers = !list.is_empty(test_helpers)

  let setup_lines = case has_testcontainers {
    True -> contribution.all_test_setup_calls(contributions)
    False -> contribution.all_test_setup_fallbacks(contributions)
  }

  let test_imports =
    contribution.all_test_imports(contributions, has_testcontainers)

  let extra_imports =
    list.flatten([
      // for stop_containers
      case has_containers {
        True -> ["gleam/list"]
        False -> []
      },
      case has_context {
        True -> [config.name <> "/context.{type Context, Context}"]
        False -> []
      },
      // gleam/option for fallback paths that use option.Some
      case
        has_testcontainers,
        list.any(setup_lines, string.contains(_, "option."))
      {
        False, True -> ["gleam/option"]
        _, _ -> []
      },
      // gleam/int for fallback paths using int.parse
      case
        has_testcontainers,
        list.any(setup_lines, string.contains(_, "int.parse"))
      {
        False, True -> ["gleam/int"]
        _, _ -> []
      },
    ])

  let all_imports = list.flatten([test_imports, extra_imports])

  let context_field_names =
    list.filter_map(context_fields, fn(field) {
      case string.split(field, ": ") {
        [name, ..] -> Ok(name)
        _ -> Error(Nil)
      }
    })

  let test_context = build_test_context(has_context, has_containers)
  let helpers = build_helpers(test_helpers)
  let setup_fn =
    build_setup(
      setup_lines,
      has_containers,
      has_context,
      context_field_names,
      container_handles,
    )
  let stop_fn = build_stop_containers(has_containers)

  imports_module.render(all_imports)
  <> "\n"
  <> test_context
  <> helpers
  <> setup_fn
  <> stop_fn
}

fn build_test_context(has_context: Bool, has_containers: Bool) -> String {
  let fields = []
  let fields = case has_context {
    True -> list.append(fields, ["ctx: Context"])
    False -> fields
  }
  let fields = case has_containers {
    True -> list.append(fields, ["container_ids: List(String)"])
    False -> fields
  }
  case list.is_empty(fields) {
    True -> "\npub type TestContext {\n  TestContext\n}\n"
    False -> {
      let inline =
        "\npub type TestContext {\n  TestContext("
        <> string.join(fields, ", ")
        <> ")\n}\n"
      let line = "  TestContext(" <> string.join(fields, ", ") <> ")"
      case string.length(line) <= 80 {
        True -> inline
        False ->
          "\npub type TestContext {\n  TestContext(\n    "
          <> string.join(fields, ",\n    ")
          <> ",\n  )\n}\n"
      }
    }
  }
}

fn build_helpers(test_helpers: List(String)) -> String {
  case test_helpers {
    [] -> ""
    helpers ->
      list.map(helpers, fn(h) { "\n" <> h <> "\n" })
      |> string.join("")
  }
}

fn build_setup(
  setup_lines: List(String),
  has_containers: Bool,
  has_context: Bool,
  context_field_names: List(String),
  container_handles: List(String),
) -> String {
  let active_lines = case setup_lines {
    [] -> ""
    lines ->
      list.map(lines, fn(line) { "  " <> line }) |> string.join("\n") <> "\n"
  }

  let fields = []
  let fields = case has_context {
    True ->
      list.append(fields, [
        "ctx: Context("
        <> string.join(
          list.map(context_field_names, fn(n) { n <> ": " <> n }),
          ", ",
        )
        <> ")",
      ])
    False -> fields
  }
  let fields = case has_containers {
    True ->
      list.append(fields, [
        "container_ids: [" <> string.join(container_handles, ", ") <> "]",
      ])
    False -> fields
  }
  let ret_val = case list.is_empty(fields) {
    True -> "  TestContext\n"
    False -> {
      let inline = "  TestContext(" <> string.join(fields, ", ") <> ")"
      case string.length(inline) <= 80 {
        True -> inline <> "\n"
        False ->
          case has_containers {
            False -> inline <> "\n"
            True -> {
              let ctx_prefix = case has_context {
                True ->
                  "ctx: Context("
                  <> string.join(
                    list.map(context_field_names, fn(n) { n <> ": " <> n }),
                    ", ",
                  )
                  <> "), "
                False -> ""
              }
              let items =
                list.map(container_handles, fn(h) { "\n    " <> h <> "," })
                |> string.join("")
              "  TestContext("
              <> ctx_prefix
              <> "container_ids: ["
              <> items
              <> "\n  ])\n"
            }
          }
      }
    }
  }

  "\npub fn setup() -> TestContext {\n" <> active_lines <> ret_val <> "}\n"
}

fn build_stop_containers(has_containers: Bool) -> String {
  case has_containers {
    False -> ""
    True ->
      "\npub fn stop_containers(ids: List(String)) {\n  list.each(ids, testcontainers_gleam.stop_container)\n}\n"
  }
}
