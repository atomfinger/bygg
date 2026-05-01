import birdie
import bygg/catalog
import bygg/config.{
  type ProjectConfig, Erlang, JavaScript, ProjectConfig, SelectedPackage,
}
import bygg/contribution.{type NamedContribution, NamedContribution}
import bygg/contribution_block.{Contribution, empty}
import bygg/generator
import bygg/profile.{
  BasicApp, BrowserApp, Library, LustreComponent, LustreServerComponent,
  WebServer,
}
import bygg/template
import bygg/toml
import gleam/list
import gleam/option
import gleam/string
import gleeunit/should
import unitest

pub fn main() -> Nil {
  unitest.run(unitest.default_options())
}

pub fn profile_basic_app_test() {
  let config =
    config.default("my_app")
    |> with_dep("gleam_json")
  profile.detect(config)
  |> should.equal(BasicApp)
}

pub fn profile_web_server_wisp_test() {
  let config =
    config.default("my_api")
    |> with_dep("wisp")
    |> with_dep("mist")
  profile.detect(config)
  |> should.equal(WebServer)
}

pub fn profile_web_server_mist_only_test() {
  let config =
    config.default("my_api")
    |> with_dep("mist")
  profile.detect(config)
  |> should.equal(WebServer)
}

pub fn profile_browser_app_test() {
  let config =
    config.default("my_site")
    |> fn(c) { ProjectConfig(..c, target: JavaScript) }
    |> with_dep("lustre")
  profile.detect(config)
  |> should.equal(BrowserApp)
}

pub fn profile_lustre_component_test() {
  let config =
    config.default("my_component")
    |> fn(c) { ProjectConfig(..c, target: JavaScript) }
    |> with_dep("lustre_component")
  profile.detect(config)
  |> should.equal(LustreComponent)
}

pub fn profile_lustre_server_component_test() {
  let config =
    config.default("my_server")
    |> with_dep("lustre_server_component")
  profile.detect(config)
  |> should.equal(LustreServerComponent)
}

pub fn profile_basic_app_no_deps_test() {
  let config = config.default("my_lib")
  profile.detect(config)
  |> should.equal(BasicApp)
}

pub fn toml_includes_name_test() {
  let config = config.default("my_project")
  let output = toml.render(config)
  output
  |> string.contains("name = \"my_project\"")
  |> should.be_true()
}

pub fn toml_includes_version_test() {
  let config = config.default("my_project")
  let output = toml.render(config)
  output
  |> string.contains("version = \"1.0.0\"")
  |> should.be_true()
}

pub fn toml_includes_gleam_constraint_test() {
  let config = config.default("my_project")
  let output = toml.render(config)
  output
  |> string.contains("gleam = \"")
  |> should.be_true()
}

pub fn toml_erlang_target_omitted_test() {
  let config = config.default("my_project")
  let output = toml.render(config)
  output
  |> string.contains("target = \"erlang\"")
  |> should.be_false()
}

pub fn toml_javascript_target_included_test() {
  let config = ProjectConfig(..config.default("my_site"), target: JavaScript)
  let output = toml.render(config)
  output
  |> string.contains("target = \"javascript\"")
  |> should.be_true()
}

pub fn toml_description_test() {
  let config =
    ProjectConfig(
      ..config.default("my_project"),
      description: option.Some("A great project"),
    )
  let output = toml.render(config)
  output
  |> string.contains("description = \"A great project\"")
  |> should.be_true()
}

pub fn toml_dependencies_test() {
  let config =
    config.default("my_project")
    |> with_dep("gleam_json")
  let output = toml.render(config)
  output
  |> string.contains("gleam_json")
  |> should.be_true()
}

pub fn generator_produces_gleam_toml_test() {
  let config = config.default("my_project")
  let assert Ok(project) = generator.generate(config)
  let paths = list.map(project.files, fn(f) { f.path })
  paths
  |> list.contains("gleam.toml")
  |> should.be_true()
}

pub fn generator_produces_src_module_test() {
  let config = config.default("my_project")
  let assert Ok(project) = generator.generate(config)
  let paths = list.map(project.files, fn(f) { f.path })
  paths
  |> list.contains("src/my_project.gleam")
  |> should.be_true()
}

pub fn generator_produces_test_module_test() {
  let config = config.default("my_project")
  let assert Ok(project) = generator.generate(config)
  let paths = list.map(project.files, fn(f) { f.path })
  paths
  |> list.contains("test/my_project_test.gleam")
  |> should.be_true()
}

pub fn generator_produces_env_example_for_sqlight_test() {
  let config =
    config.default("my_app")
    |> with_dep("sqlight")
  let assert Ok(project) = generator.generate(config)
  let paths = list.map(project.files, fn(f) { f.path })
  paths
  |> list.contains(".env.example")
  |> should.be_true()
}

pub fn generator_produces_docker_compose_for_web_server_test() {
  let config =
    config.default("my_app")
    |> with_dep("wisp")
    |> with_dep("mist")
  let assert Ok(project) = generator.generate(config)
  let paths = list.map(project.files, fn(f) { f.path })
  paths
  |> list.contains("docker-compose.yml")
  |> should.be_true()
}

pub fn generator_no_docker_compose_for_basic_app_test() {
  let config = config.default("my_app")
  let assert Ok(project) = generator.generate(config)
  let paths = list.map(project.files, fn(f) { f.path })
  paths
  |> list.contains("docker-compose.yml")
  |> should.be_false()
}

pub fn catalog_filter_erlang_excludes_js_only_test() {
  let erlang_pkgs = catalog.for_target(Erlang)
  erlang_pkgs
  |> list.any(fn(p) { p.targets == catalog.JavaScriptOnly })
  |> should.be_false()
}

pub fn catalog_filter_js_excludes_erlang_only_test() {
  let js_pkgs = catalog.for_target(JavaScript)
  js_pkgs
  |> list.any(fn(p) { p.targets == catalog.ErlangOnly })
  |> should.be_false()
}

pub fn catalog_find_sqlight_test() {
  catalog.find_by_hex_name("sqlight")
  |> should.be_ok()
}

pub fn catalog_sqlight_has_config_field_blocks_test() {
  let assert Ok(sqlight) = catalog.find_by_hex_name("sqlight")
  sqlight.contribution().config_fields
  |> list.is_empty()
  |> should.be_false()
}

fn with_dep(config: ProjectConfig, name: String) -> ProjectConfig {
  let pkg = case catalog.find_by_name(name) {
    Ok(p) -> SelectedPackage(p.name, p.hex_name, p.default_constraint)
    Error(_) -> SelectedPackage(name, name, ">= 1.0.0 and < 2.0.0")
  }
  ProjectConfig(..config, dependencies: [pkg, ..config.dependencies])
}

pub fn snapshot_toml_basic_app_test() {
  let config = config.default("my_app")
  toml.render(config)
  |> birdie.snap(title: "toml_basic_app")
}

pub fn snapshot_toml_web_server_test() {
  let config =
    config.default("my_api")
    |> with_dep("wisp")
    |> with_dep("mist")
  toml.render(config)
  |> birdie.snap(title: "toml_web_server")
}

pub fn snapshot_toml_with_description_and_licence_test() {
  let config =
    ProjectConfig(
      ..config.default("my_project"),
      description: option.Some("A great Gleam project"),
      licences: ["Apache-2.0"],
    )
  toml.render(config)
  |> birdie.snap(title: "toml_with_description_and_licence")
}

pub fn snapshot_toml_javascript_target_test() {
  let config = ProjectConfig(..config.default("my_site"), target: JavaScript)
  toml.render(config)
  |> birdie.snap(title: "toml_javascript_target")
}

pub fn snapshot_main_basic_app_test() {
  let config = config.default("my_app")
  template.src_module(config, BasicApp, [])
  |> birdie.snap(title: "main_basic_app")
}

pub fn snapshot_main_web_server_test() {
  let config = config.default("my_api")
  template.src_module(config, WebServer, [])
  |> birdie.snap(title: "main_web_server")
}

pub fn snapshot_main_browser_app_test() {
  let config = config.default("my_site")
  let contributions =
    ["lustre"]
    |> contribution.collect()
    |> contribution.resolve_conflicts()
    |> contribution.substitute(config.name)
  template.src_module(config, BrowserApp, contributions)
  |> birdie.snap(title: "main_browser_app")
}

pub fn snapshot_main_library_test() {
  let config = config.default("my_lib")
  template.src_module(config, Library, [])
  |> birdie.snap(title: "main_library")
}

pub fn snapshot_main_lustre_component_test() {
  let config = config.default("my_component")
  let contributions =
    ["lustre_component"]
    |> contribution.collect()
    |> contribution.resolve_conflicts()
    |> contribution.substitute(config.name)
  template.src_module(config, LustreComponent, contributions)
  |> birdie.snap(title: "main_lustre_component")
}

pub fn snapshot_main_lustre_server_component_test() {
  let config = config.default("my_server")
  let contributions =
    ["lustre_server_component"]
    |> contribution.collect()
    |> contribution.resolve_conflicts()
  template.src_module(config, LustreServerComponent, contributions)
  |> birdie.snap(title: "main_lustre_server_component")
}

pub fn snapshot_main_web_server_with_sqlight_test() {
  let config =
    config.default("my_app")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("sqlight")
  let contributions =
    ["sqlight"]
    |> contribution.collect()
    |> contribution.resolve_conflicts()
  template.src_module(config, WebServer, contributions)
  |> birdie.snap(title: "main_web_server_with_sqlight")
}

pub fn snapshot_main_basic_app_with_franz_test() {
  let config =
    config.default("my_app")
    |> with_dep("franz")
    |> with_dep("testcontainers_gleam")
  let contributions =
    ["franz"]
    |> contribution.collect()
    |> contribution.resolve_conflicts()
  template.src_module(config, BasicApp, contributions)
  |> birdie.snap(title: "main_basic_app_with_franz")
}

pub fn snapshot_toml_franz_test() {
  let config =
    config.default("my_app")
    |> with_dep("franz")
  toml.render(config)
  |> birdie.snap(title: "toml_franz")
}

pub fn snapshot_docker_compose_franz_test() {
  let config =
    config.default("my_app")
    |> with_dep("franz")
  let assert Ok(project) = generator.generate(config)
  case list.find(project.files, fn(f) { f.path == "docker-compose.yml" }) {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  |> birdie.snap(title: "docker_compose_franz")
}

pub fn contribution_filter_for_target_test() {
  let erlang_contributions =
    contribution.collect(["franz"])
    |> contribution.filter_for_target(Erlang)
  erlang_contributions
  |> contribution.all_imports()
  |> list.is_empty()
  |> should.be_false()
}

pub fn contribution_conflict_resolution_test() {
  let make = fn(hex_name, field) {
    NamedContribution(
      hex_name: hex_name,
      contribution: Contribution(..empty(), context_fields: [field]),
    )
  }
  let contributions =
    [
      make("pkg_a", "db: pkg_a.Connection"),
      make("pkg_b", "db: pkg_b.Connection"),
    ]
    |> contribution.resolve_conflicts()
  let fields =
    contribution.all_context_fields(contributions)
    |> list.filter_map(fn(content) {
      case string.split(content, ": ") {
        [name, ..] -> Ok(name)
        _ -> Error(Nil)
      }
    })
  fields
  |> should.equal(["pkg_a_db", "pkg_b_db"])
}

pub fn generator_sqlight_includes_envoy_dep_test() {
  let config =
    config.default("my_app")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("sqlight")
  let assert Ok(project) = generator.generate(config)
  let toml_content = case
    list.find(project.files, fn(f) { f.path == "gleam.toml" })
  {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  toml_content
  |> string.contains("envoy")
  |> should.be_true()
}

pub fn generator_web_server_sqlight_has_context_test() {
  let config =
    config.default("my_app")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("sqlight")
  let assert Ok(project) = generator.generate(config)
  let ctx = case
    list.find(project.files, fn(f) { f.path == "src/my_app/context.gleam" })
  {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  ctx
  |> string.contains("pub type Context")
  |> should.be_true()
  let src = case
    list.find(project.files, fn(f) { f.path == "src/my_app.gleam" })
  {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  src
  |> string.contains("sqlight.open")
  |> should.be_true()
}

pub fn snapshot_test_module_basic_app_test() {
  let config = config.default("my_app")
  template.test_module(config, BasicApp, [])
  |> birdie.snap(title: "test_module_basic_app")
}

pub fn snapshot_test_module_library_test() {
  let config = config.default("my_lib")
  template.test_module(config, Library, [])
  |> birdie.snap(title: "test_module_library")
}

pub fn snapshot_test_module_with_testcontainers_test() {
  let config =
    config.default("my_app")
    |> with_dep("testcontainers_gleam")
  template.test_module(config, BasicApp, [])
  |> birdie.snap(title: "test_module_with_testcontainers")
}

pub fn snapshot_test_module_library_with_testcontainers_test() {
  let config =
    config.default("my_lib")
    |> with_dep("testcontainers_gleam")
  template.test_module(config, Library, [])
  |> birdie.snap(title: "test_module_library_with_testcontainers")
}

pub fn snapshot_test_module_with_franz_and_testcontainers_test() {
  let config =
    config.default("my_app")
    |> with_dep("franz")
    |> with_dep("testcontainers_gleam")
  let contributions: List(NamedContribution) =
    contribution.collect(["franz", "testcontainers_gleam"])
  template.test_module(config, BasicApp, contributions)
  |> birdie.snap(title: "test_module_with_franz_and_testcontainers")
}

pub fn generator_web_server_with_otp_uses_supervisor_test() {
  let config =
    config.default("my_api")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("gleam_otp")
  let assert Ok(project) = generator.generate(config)
  let src = case
    list.find(project.files, fn(f) { f.path == "src/my_api.gleam" })
  {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  src
  |> string.contains("static_supervisor")
  |> should.be_true()
  src
  |> string.contains("mist.supervised")
  |> should.be_true()
}

pub fn generator_web_server_without_otp_uses_direct_start_test() {
  let config =
    config.default("my_api")
    |> with_dep("wisp")
    |> with_dep("mist")
  let assert Ok(project) = generator.generate(config)
  let src = case
    list.find(project.files, fn(f) { f.path == "src/my_api.gleam" })
  {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  src
  |> string.contains("static_supervisor")
  |> should.be_false()
  src
  |> string.contains("mist.start()")
  |> should.be_true()
}

pub fn generator_context_module_emitted_for_web_server_with_sqlight_test() {
  let config =
    config.default("my_api")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("sqlight")
  let assert Ok(project) = generator.generate(config)
  let paths = list.map(project.files, fn(f) { f.path })
  paths
  |> list.contains("src/my_api/context.gleam")
  |> should.be_true()
}

pub fn generator_context_module_not_emitted_for_basic_app_test() {
  let config =
    config.default("my_app")
    |> with_dep("sqlight")
  let assert Ok(project) = generator.generate(config)
  let paths = list.map(project.files, fn(f) { f.path })
  paths
  |> list.contains("src/my_app/context.gleam")
  |> should.be_false()
}

pub fn generator_main_module_imports_context_not_defines_it_test() {
  let config =
    config.default("my_api")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("sqlight")
  let assert Ok(project) = generator.generate(config)
  let src = case
    list.find(project.files, fn(f) { f.path == "src/my_api.gleam" })
  {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  src
  |> string.contains("pub type Context")
  |> should.be_false()
  src
  |> string.contains("import my_api/context.{type Context, Context}")
  |> should.be_true()
}

pub fn generator_otp_not_auto_added_for_web_server_test() {
  let config =
    config.default("my_api")
    |> with_dep("wisp")
    |> with_dep("mist")
  let assert Ok(project) = generator.generate(config)
  let toml_content = case
    list.find(project.files, fn(f) { f.path == "gleam.toml" })
  {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  toml_content
  |> string.contains("gleam_otp")
  |> should.be_false()
}

pub fn snapshot_main_web_server_with_otp_test() {
  let config =
    config.default("my_api")
    |> with_dep("gleam_otp")
  template.src_module(config, WebServer, [])
  |> birdie.snap(title: "main_web_server_with_otp")
}

pub fn snapshot_main_lustre_server_component_with_otp_test() {
  let config =
    config.default("my_server")
    |> with_dep("gleam_otp")
  let contributions =
    ["lustre_server_component"]
    |> contribution.collect()
    |> contribution.resolve_conflicts()
  template.src_module(config, LustreServerComponent, contributions)
  |> birdie.snap(title: "main_lustre_server_component_with_otp")
}

pub fn generator_web_server_has_dockerfile_test() {
  let config =
    config.default("my_api")
    |> with_dep("wisp")
    |> with_dep("mist")
  let assert Ok(project) = generator.generate(config)
  let paths = list.map(project.files, fn(f) { f.path })
  paths
  |> list.contains("Dockerfile")
  |> should.be_true()
  paths
  |> list.contains("docker-compose.yml")
  |> should.be_true()
}

pub fn generator_lustre_server_component_has_dockerfile_test() {
  let config =
    config.default("my_server")
    |> with_dep("lustre_server_component")
  let assert Ok(project) = generator.generate(config)
  let paths = list.map(project.files, fn(f) { f.path })
  paths
  |> list.contains("Dockerfile")
  |> should.be_true()
}

pub fn generator_basic_app_no_dockerfile_test() {
  let config = config.default("my_app")
  let assert Ok(project) = generator.generate(config)
  let paths = list.map(project.files, fn(f) { f.path })
  paths
  |> list.contains("Dockerfile")
  |> should.be_false()
}

pub fn generator_sqlight_dockerfile_has_apk_install_test() {
  let config =
    config.default("my_api")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("sqlight")
  let assert Ok(project) = generator.generate(config)
  let dockerfile_content =
    list.find(project.files, fn(f) { f.path == "Dockerfile" })
    |> fn(r) {
      case r {
        Ok(f) -> f.content
        Error(_) -> ""
      }
    }
  dockerfile_content
  |> string.contains("apk add")
  |> should.be_true()
  dockerfile_content
  |> string.contains("sqlite")
  |> should.be_true()
}

pub fn generator_docker_compose_web_server_has_app_service_test() {
  let config =
    config.default("my_api")
    |> with_dep("wisp")
    |> with_dep("mist")
  let assert Ok(project) = generator.generate(config)
  let compose =
    list.find(project.files, fn(f) { f.path == "docker-compose.yml" })
    |> fn(r) {
      case r {
        Ok(f) -> f.content
        Error(_) -> ""
      }
    }
  compose
  |> string.contains("app:")
  |> should.be_true()
  compose
  |> string.contains("3000:3000")
  |> should.be_true()
}

pub fn snapshot_dockerfile_basic_test() {
  template.dockerfile([])
  |> birdie.snap(title: "dockerfile_basic")
}

pub fn snapshot_dockerfile_sqlight_test() {
  let contributions =
    ["sqlight"]
    |> contribution.collect()
    |> contribution.resolve_conflicts()
  contribution.all_dockerfile_instructions(contributions)
  |> template.dockerfile()
  |> birdie.snap(title: "dockerfile_sqlight")
}

pub fn snapshot_docker_compose_web_server_test() {
  let config =
    config.default("my_api")
    |> with_dep("wisp")
    |> with_dep("mist")
  let assert Ok(project) = generator.generate(config)
  case list.find(project.files, fn(f) { f.path == "docker-compose.yml" }) {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  |> birdie.snap(title: "docker_compose_web_server")
}

pub fn snapshot_main_web_server_with_pog_test() {
  let config =
    config.default("my_app")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("pog")
    |> with_dep("gleam_otp")
  let contributions =
    ["pog"]
    |> contribution.collect()
    |> contribution.resolve_conflicts()
    |> contribution.substitute("my_app")
  template.src_module(config, WebServer, contributions)
  |> birdie.snap(title: "main_web_server_with_pog")
}

pub fn snapshot_docker_compose_pog_test() {
  let config =
    config.default("my_app")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("pog")
  let assert Ok(project) = generator.generate(config)
  case list.find(project.files, fn(f) { f.path == "docker-compose.yml" }) {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  |> birdie.snap(title: "docker_compose_pog")
}

pub fn snapshot_toml_pog_test() {
  let config =
    config.default("my_app")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("pog")
  let assert Ok(project) = generator.generate(config)
  case list.find(project.files, fn(f) { f.path == "gleam.toml" }) {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  |> birdie.snap(title: "toml_pog")
}

pub fn snapshot_test_module_with_pog_and_testcontainers_test() {
  let config =
    config.default("my_app")
    |> with_dep("pog")
    |> with_dep("testcontainers_gleam")
  let contributions: List(NamedContribution) =
    contribution.collect(["pog", "testcontainers_gleam"])
  template.test_module(config, BasicApp, contributions)
  |> birdie.snap(title: "test_module_with_pog_and_testcontainers")
}

pub fn generator_pog_auto_adds_gleam_otp_test() {
  let config =
    config.default("my_app")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("pog")
  let assert Ok(project) = generator.generate(config)
  case list.find(project.files, fn(f) { f.path == "gleam.toml" }) {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  |> string.contains("gleam_otp")
  |> should.be_true()
}

pub fn generator_pog_uses_supervisor_test() {
  let config =
    config.default("my_app")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("pog")
  let assert Ok(project) = generator.generate(config)
  let src = case
    list.find(project.files, fn(f) { f.path == "src/my_app.gleam" })
  {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  src |> string.contains("static_supervisor") |> should.be_true()
  src |> string.contains("pog.supervised") |> should.be_true()
}

pub fn generator_pog_has_postgres_docker_service_test() {
  let config =
    config.default("my_app")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("pog")
  let assert Ok(project) = generator.generate(config)
  let compose = case
    list.find(project.files, fn(f) { f.path == "docker-compose.yml" })
  {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  compose |> string.contains("postgres:") |> should.be_true()
  compose |> string.contains("postgres_data:") |> should.be_true()
}

pub fn snapshot_docker_compose_valkyrie_test() {
  let config =
    config.default("my_app")
    |> with_dep("valkyrie")
  let assert Ok(project) = generator.generate(config)
  case list.find(project.files, fn(f) { f.path == "docker-compose.yml" }) {
    Ok(f) -> f.content
    Error(_) -> ""
  }
  |> birdie.snap(title: "docker_compose_valkyrie")
}

pub fn generator_valkyrie_test() {
  let config =
    config.default("my_app")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("valkyrie")
  let assert Ok(project) = generator.generate(config)
  let src =
    list.find(project.files, fn(f) { f.path == "src/my_app.gleam" })
    |> should.be_ok()
  src.content
  |> birdie.snap(title: "valkyrie")
}

pub fn snapshot_test_utils_pog_with_testcontainers_test() {
  let config =
    config.default("my_app")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("pog")
    |> with_dep("testcontainers_gleam")
  let assert Ok(project) = generator.generate(config)
  let f =
    list.find(project.files, fn(f) { f.path == "test/my_app/test_utils.gleam" })
    |> should.be_ok()
  f.content
  |> birdie.snap(title: "test_utils_pog_with_testcontainers")
}

pub fn snapshot_test_utils_franz_with_testcontainers_test() {
  let config =
    config.default("my_app")
    |> with_dep("franz")
    |> with_dep("testcontainers_gleam")
  let assert Ok(project) = generator.generate(config)
  let f =
    list.find(project.files, fn(f) { f.path == "test/my_app/test_utils.gleam" })
    |> should.be_ok()
  f.content
  |> birdie.snap(title: "test_utils_franz_with_testcontainers")
}

pub fn snapshot_test_utils_sqlight_no_testcontainers_test() {
  let config =
    config.default("my_app")
    |> with_dep("wisp")
    |> with_dep("mist")
    |> with_dep("sqlight")
  let assert Ok(project) = generator.generate(config)
  let f =
    list.find(project.files, fn(f) { f.path == "test/my_app/test_utils.gleam" })
    |> should.be_ok()
  f.content
  |> birdie.snap(title: "test_utils_sqlight_no_testcontainers")
}
