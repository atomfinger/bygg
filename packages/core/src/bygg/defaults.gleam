import bygg/catalog
import bygg/config.{type ProjectConfig, ProjectConfig, SelectedPackage}
import gleam/list

pub fn complete(config: ProjectConfig) -> ProjectConfig {
  config
  |> add_mist_for_server_component
  |> add_otp_for_requiring_packages
}

fn has_dep(config: ProjectConfig, name: String) -> Bool {
  list.any(config.dependencies, fn(dependency) { dependency.name == name })
}

fn add_selected(config: ProjectConfig, name: String) -> ProjectConfig {
  case has_dep(config, name), catalog.find_by_name(name) {
    True, _ -> config
    False, Error(_) -> config
    False, Ok(package) ->
      ProjectConfig(
        ..config,
        dependencies: list.append(config.dependencies, [
          SelectedPackage(
            name: package.name,
            hex_name: package.hex_name,
            version_constraint: package.default_constraint,
          ),
        ]),
      )
  }
}

fn add_otp_for_requiring_packages(config: ProjectConfig) -> ProjectConfig {
  let needs_otp =
    list.any(config.dependencies, fn(dep) {
      case catalog.find_by_name(dep.name) {
        Ok(package) -> package.requires_otp
        Error(_) -> False
      }
    })
  case needs_otp {
    False -> config
    True -> add_selected(config, "gleam_otp")
  }
}

fn add_mist_for_server_component(config: ProjectConfig) -> ProjectConfig {
  let dep_names =
    list.map(config.dependencies, fn(dependency) { dependency.name })
  let has_server_component =
    catalog.has_role(dep_names, catalog.LustreServerComponent)
  let has_server =
    catalog.has_role(dep_names, catalog.WebFramework)
    || catalog.has_role(dep_names, catalog.HttpServer)

  case has_server_component && !has_server {
    False -> config
    True -> config |> add_selected("mist")
  }
}
