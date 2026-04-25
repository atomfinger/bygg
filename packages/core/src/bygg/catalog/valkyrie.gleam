import bygg/code_block.{
  type CodeBlock, Always, CodeBlock, Declaration, DockerService, Import,
  MainBody, OtpChildSpec,
}

pub const code_blocks: List(CodeBlock) = [
  CodeBlock(Import, "gleam/option", Always),
  CodeBlock(Import, "gleam/erlang/process", Always),
  CodeBlock(Import, "valkyrie", Always),
  CodeBlock(
    MainBody,
    "let pool_name = process.new_name(\"valkyrie_connection_pool\")",
    Always,
  ),
  CodeBlock(OtpChildSpec, "create_valkyrie_pool(pool_name)", Always),
  CodeBlock(
    Declaration,
    "
pub fn create_valkyrie_pool(pool_name) {
  valkyrie.default_config()
  |> valkyrie.supervised_pool(
    size: 10,
    name: option.Some(pool_name),
    timeout: 1000,
  )
}
",
    Always,
  ),
  CodeBlock(
    DockerService,
    "  valkey:
    image: valkey/valkey:8.0.2-alpine
    ports:
      - \"6379:6379\"",
    Always,
  ),
]
