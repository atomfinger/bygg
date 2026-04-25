import argv
import bygg_cli/cli
import glint

pub fn main() -> Nil {
  glint.new()
  |> glint.with_name("bygg")
  |> glint.global_help(
    "A project scaffolding tool for the Gleam programming language",
  )
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: ["new"], do: cli.new_command())
  |> glint.add(at: ["list-deps"], do: cli.list_deps_command())
  |> glint.run(argv.load().arguments)
}
