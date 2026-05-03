import bygg/archetype
import bygg/catalog
import bygg/config.{type ProjectConfig, ProjectConfig, SelectedPackage}
import gleam/list
import gleam/option

pub fn complete(config: ProjectConfig) -> ProjectConfig {
  config
  |> apply_archetype
  |> add_selected_dev("unitest")
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
            hex_name: option.unwrap(package.hex_name, package.name),
            version_constraint: option.unwrap(
              package.default_constraint,
              ">= 1.0.0 and < 2.0.0",
            ),
          ),
        ]),
      )
  }
}

fn has_dev_dep(config: ProjectConfig, name: String) -> Bool {
  list.any(config.dev_dependencies, fn(dependency) { dependency.name == name })
}

fn add_selected_dev(config: ProjectConfig, name: String) -> ProjectConfig {
  case has_dev_dep(config, name), catalog.find_by_name(name) {
    True, _ -> config
    False, Error(_) -> config
    False, Ok(package) ->
      ProjectConfig(
        ..config,
        dev_dependencies: list.append(config.dev_dependencies, [
          SelectedPackage(
            name: package.name,
            hex_name: option.unwrap(package.hex_name, package.name),
            version_constraint: option.unwrap(
              package.default_constraint,
              ">= 1.0.0 and < 2.0.0",
            ),
          ),
        ]),
      )
  }
}

fn apply_archetype(config: ProjectConfig) -> ProjectConfig {
  case config.archetype {
    option.Some(arch_name) -> {
      case archetype.find(arch_name) {
        Ok(arch) -> {
          let with_deps =
            list.fold(arch.dependencies, config, fn(cfg, dep) {
              add_selected(cfg, dep)
            })
          let with_dev_deps =
            list.fold(arch.dev_dependencies, with_deps, fn(cfg, dep) {
              add_selected_dev(cfg, dep)
            })
          ProjectConfig(..with_dev_deps, target: arch.target)
        }
        Error(_) -> config
      }
    }
    option.None -> config
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
