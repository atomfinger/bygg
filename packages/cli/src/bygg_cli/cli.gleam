import bygg/archetype
import bygg/catalog
import bygg/config.{
  type ProjectConfig, type SelectedPackage, Erlang, JavaScript, ProjectConfig,
  SelectedPackage,
}
import bygg/generator
import bygg/versions
import bygg_cli/output
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam_community/ansi
import glint
import snag

fn name_flag() {
  glint.string_flag("name")
  |> glint.flag_help("Project name (defaults to first positional arg)")
}

fn version_flag() {
  glint.string_flag("version")
  |> glint.flag_default("1.0.0")
  |> glint.flag_help("Package version")
}

fn description_flag() {
  glint.string_flag("description")
  |> glint.flag_help("Short project description")
}

fn target_flag() {
  glint.string_flag("target")
  |> glint.flag_default("erlang")
  |> glint.flag_help("Compilation target: erlang or javascript")
}

fn licence_flag() {
  glint.strings_flag("licence")
  |> glint.flag_help("SPDX licence identifier (repeatable)")
}

fn gleam_flag() {
  glint.string_flag("gleam")
  |> glint.flag_default(versions.default_version().constraint)
  |> glint.flag_help("Gleam version constraint")
}

fn dep_flag() {
  glint.strings_flag("dep")
  |> glint.flag_help("Add a runtime dependency by hex name (repeatable)")
}

fn dev_dep_flag() {
  glint.strings_flag("dev-dep")
  |> glint.flag_help("Add a dev dependency by hex name (repeatable)")
}

fn outdir_flag() {
  glint.string_flag("outdir")
  |> glint.flag_help("Output directory (defaults to ./<project-name>)")
}

fn archetype_flag() {
  glint.string_flag("archetype")
  |> glint.flag_help(
    "Project archetype to use (e.g., rest-api-erlang, browser-app-js)",
  )
}

pub fn new_command() -> glint.Command(Nil) {
  use get_name <- glint.flag(name_flag())
  use get_version <- glint.flag(version_flag())
  use get_description <- glint.flag(description_flag())
  use get_target <- glint.flag(target_flag())
  use get_licence <- glint.flag(licence_flag())
  use get_gleam <- glint.flag(gleam_flag())
  use get_dep <- glint.flag(dep_flag())
  use get_dev_dep <- glint.flag(dev_dep_flag())
  use get_outdir <- glint.flag(outdir_flag())
  use get_archetype <- glint.flag(archetype_flag())
  use named, args, flags <- glint.command()

  let project_config =
    build_config_from_flags(
      named,
      args,
      flags,
      get_name,
      get_version,
      get_description,
      get_target,
      get_licence,
      get_gleam,
      get_dep,
      get_dev_dep,
      get_archetype,
    )

  let outdir = case result.unwrap(get_outdir(flags), "") {
    "" -> "./" <> project_config.name
    output_directory -> output_directory
  }

  case generator.generate(project_config) {
    Error(error) -> io.println(ansi.red("Error: " <> error))
    Ok(project) ->
      case output.write_to_disk(project, outdir) {
        Ok(_) -> print_success(project_config.name, outdir)
        Error(error) ->
          io.println(ansi.red("Error: " <> snag.pretty_print(error)))
      }
  }
}

fn build_config_from_flags(
  _named,
  args: List(String),
  flags,
  get_name,
  get_version,
  get_description,
  get_target,
  get_licence,
  get_gleam,
  get_dep,
  get_dev_dep,
  get_archetype,
) -> ProjectConfig {
  let name = case result.unwrap(get_name(flags), "") {
    "" ->
      case args {
        [first, ..] -> first
        [] -> "my_project"
      }
    name -> name
  }

  let version = result.unwrap(get_version(flags), "1.0.0")
  let description = case result.unwrap(get_description(flags), "") {
    "" -> option.None
    description -> option.Some(description)
  }
  let target = case result.unwrap(get_target(flags), "erlang") {
    "javascript" | "js" -> JavaScript
    _ -> Erlang
  }
  let licences = result.unwrap(get_licence(flags), [])
  let gleam_constraint =
    result.unwrap(get_gleam(flags), versions.default_version().constraint)
  let dep_names = result.unwrap(get_dep(flags), [])
  let dev_dep_names = result.unwrap(get_dev_dep(flags), [])

  let dependencies = resolve_packages(dep_names)
  let dev_dependencies = resolve_packages(dev_dep_names)

  ProjectConfig(
    name: name,
    version: version,
    description: description,
    licences: licences,
    target: target,
    gleam_version_constraint: gleam_constraint,
    dependencies: dependencies,
    dev_dependencies: dev_dependencies,
    application_start_module: option.None,
    extra_applications: [],
    typescript_declarations: False,
    js_runtime: option.None,
    internal_modules: [],
    links: [],
    archetype: case result.unwrap(get_archetype(flags), "") {
      "" -> option.None
      a -> option.Some(a)
    },
  )
}

fn resolve_packages(names: List(String)) -> List(SelectedPackage) {
  list.map(names, fn(name) {
    case catalog.find_by_name(name) {
      Ok(package) ->
        SelectedPackage(
          package.name,
          package.hex_name,
          package.default_constraint,
        )
      Error(_) -> SelectedPackage(name, name, ">= 1.0.0 and < 2.0.0")
    }
  })
}

pub fn list_deps_command() -> glint.Command(Nil) {
  use get_target <- glint.flag(target_flag())
  use _named, _args, flags <- glint.command()

  let target = case result.unwrap(get_target(flags), "erlang") {
    "javascript" | "js" -> JavaScript
    _ -> Erlang
  }

  let packages = catalog.for_target(target)

  io.println(ansi.bold(
    "\n  Available packages for "
    <> case target {
      Erlang -> "erlang"
      JavaScript -> "javascript"
    }
    <> " target:\n",
  ))

  list.each(catalog.all_categories(), fn(category) {
    let category_packages =
      list.filter(packages, fn(package) {
        package.category == category
        && !package.is_hidden
        && !package.is_disabled
      })
    case category_packages {
      [] -> Nil
      _ -> {
        io.println(ansi.bold("  [" <> catalog.category_label(category) <> "]"))
        list.each(category_packages, fn(package) {
          let dev_label = case package.dev_only {
            True -> ansi.dim(" (dev)")
            False -> ""
          }
          io.println("    " <> ansi.cyan(package.hex_name) <> dev_label)
          io.println(ansi.dim("      " <> package.description))
        })
        io.println("")
      }
    }
  })
}

fn print_success(name: String, outdir: String) -> Nil {
  io.println("")
  io.println(ansi.green("  ✓ Created " <> name))
  io.println("")
  io.println("  Next steps:")
  io.println(ansi.dim("    cd " <> outdir))
  io.println(ansi.dim("    gleam run"))
  io.println("")
}

pub fn list_archetypes_command() -> glint.Command(Nil) {
  use _named, _args, _flags <- glint.command()

  io.println(ansi.bold("\n  Available archetypes:\n"))

  list.each(archetype.all, fn(arch) {
    io.println("  " <> ansi.cyan(arch.name))
    io.println(ansi.dim("    " <> arch.description))
    io.println("")
  })
}
