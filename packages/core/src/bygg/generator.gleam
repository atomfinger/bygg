import bygg/catalog
import bygg/config.{type ProjectConfig, type SelectedPackage, Erlang}
import bygg/contribution.{type NamedContribution}
import bygg/defaults
import bygg/profile
import bygg/template
import bygg/toml
import bygg/validation
import gleam/list
import gleam/option.{None, Some}
import gleam/result

pub type FileEntry {
  FileEntry(path: String, content: String)
}

pub type GeneratedProject {
  GeneratedProject(files: List(FileEntry))
}

type ContributionSlots {
  ContributionSlots(
    config_fields: List(String),
    context_fields: List(String),
    env_vars: List(String),
    docker_services: List(String),
    docker_volumes: List(String),
    dockerfile_instructions: List(String),
  )
}

type GenerationFlags {
  GenerationFlags(
    app_port: Int,
    needs_config_module: Bool,
    needs_context_module: Bool,
    needs_docker: Bool,
    needs_dockerfile: Bool,
    needs_docker_compose: Bool,
  )
}

pub fn generate(config: ProjectConfig) -> Result(GeneratedProject, String) {
  use config <- result.try(validation.validate(config))
  let config = defaults.complete(config)
  let app_profile = profile.detect(config)
  let contributions = collect_contributions(config)
  let slots = contribution_slots(contributions)
  let flags = determine_flags(config, app_profile, slots)
  let config = adjust_deps(config, app_profile, slots)
  Ok(
    GeneratedProject(files: build_files(
      config,
      app_profile,
      contributions,
      slots,
      flags,
    )),
  )
}

fn collect_contributions(config: ProjectConfig) -> List(NamedContribution) {
  let all_dep_names =
    list.map(config.dependencies, fn(dependency) { dependency.name })
    |> list.append(
      list.map(config.dev_dependencies, fn(dependency) { dependency.name }),
    )
  contribution.collect(all_dep_names)
  |> contribution.filter_for_target(config.target)
  |> contribution.resolve_conflicts()
  |> contribution.substitute(config.name)
}

fn contribution_slots(
  contributions: List(NamedContribution),
) -> ContributionSlots {
  ContributionSlots(
    config_fields: contribution.all_config_fields(contributions),
    context_fields: contribution.all_context_fields(contributions),
    env_vars: contribution.all_env_vars(contributions),
    docker_services: contribution.all_docker_services(contributions),
    docker_volumes: contribution.all_docker_volumes(contributions),
    dockerfile_instructions: contribution.all_dockerfile_instructions(
      contributions,
    ),
  )
}

fn determine_flags(
  config: ProjectConfig,
  app_profile: profile.ApplicationProfile,
  slots: ContributionSlots,
) -> GenerationFlags {
  let app_port = case app_profile {
    profile.WebServer -> 3000
    profile.LustreServerComponent -> 1234
    _ -> 0
  }
  let needs_docker = !list.is_empty(slots.docker_services)
  let needs_dockerfile = case config.target, app_profile {
    Erlang, profile.WebServer -> True
    Erlang, profile.LustreServerComponent -> True
    _, _ -> False
  }
  GenerationFlags(
    app_port: app_port,
    needs_config_module: !list.is_empty(slots.config_fields),
    needs_context_module: !list.is_empty(slots.context_fields),
    needs_docker: needs_docker,
    needs_dockerfile: needs_dockerfile,
    needs_docker_compose: needs_docker || needs_dockerfile,
  )
}

fn adjust_deps(
  config: ProjectConfig,
  app_profile: profile.ApplicationProfile,
  slots: ContributionSlots,
) -> ProjectConfig {
  let deps =
    config.dependencies
    |> ensure_dep("gleam_stdlib")
    |> add_envoy_if_needed(slots.config_fields)
    |> add_erlang_dep_if_needed(app_profile, slots.config_fields)
    |> add_http_deps_if_needed(app_profile)

  let dev_deps =
    config.dev_dependencies
    |> add_lustre_dev_tools_if_needed(app_profile)

  case deps == config.dependencies, dev_deps == config.dev_dependencies {
    True, True -> config
    _, _ ->
      config.ProjectConfig(
        ..config,
        dependencies: deps,
        dev_dependencies: dev_deps,
      )
  }
}

fn add_envoy_if_needed(
  deps: List(SelectedPackage),
  config_fields: List(String),
) -> List(SelectedPackage) {
  case config_fields {
    [] -> deps
    _ -> ensure_dep(deps, "envoy")
  }
}

fn add_erlang_dep_if_needed(
  deps: List(SelectedPackage),
  app_profile: profile.ApplicationProfile,
  config_fields: List(String),
) -> List(SelectedPackage) {
  case app_profile {
    profile.WebServer | profile.LustreServerComponent ->
      ensure_dep(deps, "gleam_erlang")
    profile.BasicApp ->
      case config_fields {
        [] -> deps
        _ -> ensure_dep(deps, "gleam_erlang")
      }
    _ -> deps
  }
}

fn add_http_deps_if_needed(
  deps: List(SelectedPackage),
  app_profile: profile.ApplicationProfile,
) -> List(SelectedPackage) {
  case app_profile {
    profile.LustreServerComponent ->
      deps
      |> ensure_dep("gleam_http")
      |> ensure_dep("gleam_json")
    profile.WebServer ->
      deps
      |> ensure_dep("gleam_http")
    _ -> deps
  }
}

fn add_lustre_dev_tools_if_needed(
  dev_deps: List(SelectedPackage),
  app_profile: profile.ApplicationProfile,
) -> List(SelectedPackage) {
  case app_profile {
    profile.BrowserApp | profile.LustreComponent ->
      ensure_dep(dev_deps, "lustre_dev_tools")
    _ -> dev_deps
  }
}

fn build_files(
  config: ProjectConfig,
  app_profile: profile.ApplicationProfile,
  contributions: List(NamedContribution),
  slots: ContributionSlots,
  flags: GenerationFlags,
) -> List(FileEntry) {
  let has_testcontainers =
    list.any(config.dependencies, fn(p) { p.hex_name == "testcontainers_gleam" })
    || list.any(config.dev_dependencies, fn(p) {
      p.hex_name == "testcontainers_gleam"
    })

  let base_files: List(FileEntry) = [
    FileEntry("gleam.toml", toml.render(config)),
    FileEntry(
      "src/" <> config.name <> ".gleam",
      template.src_module(config, app_profile, contributions),
    ),
    FileEntry(
      "test/" <> config.name <> "_test.gleam",
      template.test_module(config, app_profile, contributions),
    ),
    FileEntry(".gitignore", template.gitignore(config)),
    FileEntry(
      "README.md",
      template.readme(
        config,
        app_profile,
        slots.config_fields,
        flags.needs_docker,
        flags.needs_dockerfile,
        flags.app_port,
      ),
    ),
  ]

  let test_utils_files: List(FileEntry) = case
    template.test_utils_module(
      config,
      app_profile,
      contributions,
      has_testcontainers,
    )
  {
    None -> []
    Some(content) -> [
      FileEntry("test/" <> config.name <> "/test_utils.gleam", content),
    ]
  }

  let env_files: List(FileEntry) = case slots.env_vars {
    [] -> []
    env_var_blocks -> [
      FileEntry(".env.example", template.env_example(env_var_blocks)),
    ]
  }

  let config_module_files: List(FileEntry) = case flags.needs_config_module {
    False -> []
    True -> [
      FileEntry(
        "src/" <> config.name <> "/config.gleam",
        template.config_module(config.name, slots.config_fields),
      ),
    ]
  }

  let context_module_files: List(FileEntry) = case flags.needs_context_module {
    False -> []
    True -> [
      FileEntry(
        "src/" <> config.name <> "/context.gleam",
        template.context_module(slots.context_fields),
      ),
    ]
  }

  let docker_files: List(FileEntry) = case flags.needs_docker_compose {
    False -> []
    True -> [
      FileEntry(
        "docker-compose.yml",
        template.docker_compose(
          slots.docker_services,
          slots.docker_volumes,
          flags.app_port,
          !list.is_empty(slots.env_vars),
        ),
      ),
    ]
  }

  let dockerfile_files: List(FileEntry) = case flags.needs_dockerfile {
    False -> []
    True -> [
      FileEntry(
        "Dockerfile",
        template.dockerfile(slots.dockerfile_instructions),
      ),
    ]
  }

  list.flatten([
    base_files,
    test_utils_files,
    env_files,
    config_module_files,
    context_module_files,
    docker_files,
    dockerfile_files,
  ])
}

fn ensure_dep(
  deps: List(SelectedPackage),
  name: String,
) -> List(SelectedPackage) {
  case list.any(deps, fn(dependency) { dependency.name == name }) {
    True -> deps
    False ->
      list.append(deps, [
        case catalog.find_by_name(name) {
          Ok(package) ->
            config.SelectedPackage(
              package.name,
              package.hex_name,
              package.default_constraint,
            )
          Error(_) -> config.SelectedPackage(name, name, ">= 1.0.0 and < 2.0.0")
        },
      ])
  }
}
