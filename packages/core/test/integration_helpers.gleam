import bygg/catalog
import bygg/config.{type ProjectConfig, JavaScript, SelectedPackage}
import bygg/generator.{type GeneratedProject}
import filepath
import gleam/list
import gleam/option
import gleam/result
import simplifile

@external(erlang, "bygg_test_runner_ffi", "run_command")
fn ffi_run_command(cmd: String, dir: String) -> Result(String, String)

@external(erlang, "bygg_test_runner_ffi", "abs_path")
fn ffi_abs_path(path: String) -> String

pub fn project_dir(name: String) -> String {
  ffi_abs_path("tmp/integration-test/" <> name)
}

pub fn check_and_test(cfg: ProjectConfig, project_name: String) -> Nil {
  let out = setup_project(cfg, project_name)
  assert_step("gleam deps download", out)
  assert_step("gleam check", out)
  assert_step("gleam test", out)
  assert_step("gleam format --check src test", out)
}

pub fn compile_only(cfg: ProjectConfig, project_name: String) -> Nil {
  let out = setup_project(cfg, project_name)
  assert_step("gleam deps download", out)
  assert_step("gleam check", out)
  assert_step("gleam format --check src test", out)
}

fn setup_project(cfg: ProjectConfig, project_name: String) -> String {
  let out = project_dir(project_name)
  // Ensure directory exists before cleaning stale build artifacts
  let _ = simplifile.create_directory_all(out)
  let _ = ffi_run_command("rm -rf build", out)
  let project = case generator.generate(cfg) {
    Ok(p) -> p
    Error(msg) ->
      panic as { "Generation failed for " <> project_name <> ": " <> msg }
  }
  case write_project(project, out) {
    Ok(_) -> Nil
    Error(msg) ->
      panic as { "Write failed for " <> project_name <> ": " <> msg }
  }
  copy_seed_manifest(out)
  out
}

// Copy the seed project's manifest.toml into the generated project on first run so
// that `gleam deps download` uses pinned versions without querying the Hex API.
// Skips if a manifest already exists — Gleam will have generated a correct
// project-specific one on the previous run, and overwriting it would invalidate it.
fn copy_seed_manifest(project_out: String) -> Nil {
  let dest = filepath.join(project_out, "manifest.toml")
  case simplifile.is_file(dest) {
    Ok(True) -> Nil
    _ -> {
      let seed = ffi_abs_path("../../scripts/seed/manifest.toml")
      case simplifile.read(seed) {
        Ok(content) -> {
          let _ = simplifile.write(dest, content)
          Nil
        }
        Error(_) -> Nil
      }
    }
  }
}

fn assert_step(cmd: String, dir: String) -> Nil {
  case ffi_run_command(cmd, dir) {
    Ok(_) -> Nil
    Error(output) -> panic as { cmd <> " failed:\n" <> output }
  }
}

pub fn with_deps(cfg: ProjectConfig, names: List(String)) -> ProjectConfig {
  let deps =
    list.map(names, fn(name) {
      let assert Ok(pkg) = catalog.find_by_name(name)
      SelectedPackage(pkg.name, pkg.hex_name, pkg.default_constraint)
    })
  config.ProjectConfig(..cfg, dependencies: deps)
}

pub fn with_dev_deps(cfg: ProjectConfig, names: List(String)) -> ProjectConfig {
  let extra =
    list.map(names, fn(name) {
      let assert Ok(pkg) = catalog.find_by_name(name)
      SelectedPackage(pkg.name, pkg.hex_name, pkg.default_constraint)
    })
  config.ProjectConfig(
    ..cfg,
    dev_dependencies: list.append(cfg.dev_dependencies, extra),
  )
}

pub fn javascript(cfg: ProjectConfig) -> ProjectConfig {
  config.ProjectConfig(..cfg, target: JavaScript)
}

pub fn with_archetype(cfg: ProjectConfig, name: String) -> ProjectConfig {
  config.ProjectConfig(..cfg, archetype: option.Some(name))
}

pub fn archetype_config(project_name: String, arch: String) -> ProjectConfig {
  config.ProjectConfig(
    ..config.default(project_name),
    dependencies: [],
    dev_dependencies: [],
    archetype: option.Some(arch),
  )
}

pub fn write_project(
  project: GeneratedProject,
  dir: String,
) -> Result(Nil, String) {
  use _ <- result.try(
    simplifile.create_directory_all(dir)
    |> result.map_error(simplifile.describe_error),
  )
  list.try_each(project.files, fn(entry) {
    let full_path = filepath.join(dir, entry.path)
    let file_dir = filepath.directory_name(full_path)
    use _ <- result.try(
      simplifile.create_directory_all(file_dir)
      |> result.map_error(simplifile.describe_error),
    )
    simplifile.write(full_path, entry.content)
    |> result.map_error(simplifile.describe_error)
  })
}
