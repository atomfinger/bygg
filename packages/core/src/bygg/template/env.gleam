import bygg/config.{type ProjectConfig}
import gleam/string

pub fn gitignore(_config: ProjectConfig) -> String {
  "/build/
*.beam
*.ez
erl_crash.dump
.env
"
}

pub fn env_example(env_var_blocks: List(String)) -> String {
  string.join(env_var_blocks, "\n\n") <> "\n"
}
