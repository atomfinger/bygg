import bygg/config.{type ProjectConfig}
import gleam/string

pub fn gitignore(
  _config: ProjectConfig,
  extra_entries: List(String),
) -> String {
  let base = "/build/\n*.beam\n*.ez\nerl_crash.dump\n.env\n"
  case extra_entries {
    [] -> base
    _ -> base <> "\n" <> string.join(extra_entries, "\n") <> "\n"
  }
}

pub fn env_example(env_var_blocks: List(String)) -> String {
  string.join(env_var_blocks, "\n\n") <> "\n"
}
