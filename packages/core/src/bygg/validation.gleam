import bygg/catalog.{
  FrontendFramework, HttpServer, LustreComponent, LustreServerComponent,
  WebFramework,
}
import bygg/config.{type ProjectConfig}
import gleam/list

pub fn validate(config: ProjectConfig) -> Result(ProjectConfig, String) {
  let dep_names: List(String) =
    list.map(config.dependencies, fn(dependency) { dependency.name })
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
        False -> Ok(config)
      }
  }
}
