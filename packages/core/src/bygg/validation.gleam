import bygg/archetype
import bygg/catalog.{
  BothTargets, ErlangOnly, FrontendFramework, HttpServer, JavaScriptOnly,
  LustreComponent, LustreServerComponent, WebFramework,
}
import bygg/config.{type ProjectConfig, Erlang, JavaScript}
import gleam/list
import gleam/option

pub fn validate(config: ProjectConfig) -> Result(ProjectConfig, String) {
  let has_manual_deps =
    !list.is_empty(config.dependencies)
    || !list.is_empty(config.dev_dependencies)

  case config.archetype {
    option.Some(arch_name) -> {
      case has_manual_deps {
        True ->
          Error(
            "Cannot use an archetype and manually specify dependencies at the same time.",
          )
        False ->
          case archetype.find(arch_name) {
            Ok(_) -> Ok(config)
            Error(_) -> Error("Unknown archetype: " <> arch_name)
          }
      }
    }
    option.None -> {
      let dep_names: List(String) =
        list.map(config.dependencies, fn(dependency) { dependency.name })

      case check_target_compatibility(dep_names, config.target) {
        Error(msg) -> Error(msg)
        Ok(_) ->
          case check_roles(dep_names) {
            Error(msg) -> Error(msg)
            Ok(_) -> Ok(config)
          }
      }
    }
  }
}

fn check_target_compatibility(
  dep_names: List(String),
  target: config.Target,
) -> Result(Nil, String) {
  let incompatible =
    list.filter(dep_names, fn(name) {
      case catalog.find_by_name(name) {
        Ok(pkg) ->
          case pkg.targets, target {
            ErlangOnly, Erlang -> False
            JavaScriptOnly, JavaScript -> False
            BothTargets, _ -> False
            ErlangOnly, JavaScript -> True
            JavaScriptOnly, Erlang -> True
          }
        Error(_) -> False
      }
    })

  case incompatible {
    [] -> Ok(Nil)
    [name, ..] -> {
      let target_name = case target {
        Erlang -> "Erlang"
        JavaScript -> "JavaScript"
      }
      Error(
        "Package \""
        <> name
        <> "\" is not compatible with the "
        <> target_name
        <> " target.",
      )
    }
  }
}

fn check_roles(dep_names: List(String)) -> Result(Nil, String) {
  let roles = catalog.roles_for(dep_names)

  let has_frontend = list.contains(roles, FrontendFramework)
  let has_lustre_component = list.contains(roles, LustreComponent)
  let has_lustre_server = list.contains(roles, LustreServerComponent)
  let has_web =
    list.contains(roles, WebFramework) || list.contains(roles, HttpServer)

  let primary_count: Int =
    [has_frontend, has_lustre_component, has_lustre_server]
    |> list.count(fn(has_type) { has_type })

  case primary_count > 1 {
    True ->
      Error(
        "Conflicting application types selected. Choose one of: a browser app (lustre), "
        <> "a Lustre component, or a Lustre server component — not multiple.",
      )
    False ->
      case has_frontend && has_web {
        True ->
          Error(
            "A browser app (lustre) cannot be combined with a web server (wisp/mist). "
            <> "Pick one application type.",
          )
        False -> Ok(Nil)
      }
  }
}
