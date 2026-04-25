import bygg/code_block.{
  type CodeBlock, Always, CodeBlock, ConfigField, ContextField,
  DockerfileInstruction, EnvVar, Import, MainBody,
}

pub const code_blocks: List(CodeBlock) = [
  CodeBlock(Import, "sqlight", Always),
  CodeBlock(ContextField, "db: sqlight.Connection", Always),
  CodeBlock(
    MainBody,
    "let assert Ok(db) = sqlight.open(cfg.database_path)",
    Always,
  ),
  CodeBlock(ConfigField, "database_path: String", Always),
  CodeBlock(
    EnvVar,
    "# Path to the SQLite database file\nDATABASE_PATH=./my_app_dev.db",
    Always,
  ),
  CodeBlock(
    DockerfileInstruction,
    "RUN apk add --no-cache sqlite-dev sqlite-libs",
    Always,
  ),
]
