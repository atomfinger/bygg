import bygg/code_block.{
  type CodeBlock, Always, CodeBlock, ConfigField, ContextField, DockerService,
  DockerVolume, EnvVar, Import, MainBody, OtpChildSpec, TestImport, TestSetup,
}

pub const code_blocks: List(CodeBlock) = [
  CodeBlock(Import, "gleam/int", Always),
  CodeBlock(Import, "gleam/option.{Some}", Always),
  CodeBlock(Import, "pog", Always),
  CodeBlock(ContextField, "db: pog.Connection", Always),
  CodeBlock(
    MainBody,
    "let assert Ok(db_port) = int.parse(cfg.database_port)",
    Always,
  ),
  CodeBlock(
    MainBody,
    "let db = pog.named_connection(process.new_name(\"db\"))",
    Always,
  ),
  CodeBlock(
    OtpChildSpec,
    "pog.default_config(process.new_name(\"db\"))
      |> pog.host(cfg.database_host)
      |> pog.port(db_port)
      |> pog.database(cfg.database_name)
      |> pog.user(cfg.database_user)
      |> pog.password(Some(cfg.database_password))
      |> pog.supervised",
    Always,
  ),
  CodeBlock(ConfigField, "database_host: String", Always),
  CodeBlock(ConfigField, "database_port: String", Always),
  CodeBlock(ConfigField, "database_name: String", Always),
  CodeBlock(ConfigField, "database_user: String", Always),
  CodeBlock(ConfigField, "database_password: String", Always),
  CodeBlock(EnvVar, "# PostgreSQL host\nDATABASE_HOST=localhost", Always),
  CodeBlock(EnvVar, "# PostgreSQL port\nDATABASE_PORT=5432", Always),
  CodeBlock(
    EnvVar,
    "# PostgreSQL database name\nDATABASE_NAME={project_name}_dev",
    Always,
  ),
  CodeBlock(EnvVar, "# PostgreSQL user\nDATABASE_USER={project_name}", Always),
  CodeBlock(EnvVar, "# PostgreSQL password\nDATABASE_PASSWORD=password", Always),
  CodeBlock(
    DockerService,
    "  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: {project_name}
      POSTGRES_PASSWORD: password
      POSTGRES_DB: {project_name}_dev
    ports:
      - \"5432:5432\"
    volumes:
      - postgres_data:/var/lib/postgresql/data",
    Always,
  ),
  CodeBlock(DockerVolume, "  postgres_data:", Always),
  CodeBlock(TestImport, "testcontainers_gleam", Always),
  CodeBlock(TestImport, "testcontainers_gleam/postgres", Always),
  CodeBlock(
    TestSetup,
    "  let assert Ok(_running_pg) =
    postgres.new()
    |> postgres.build()
    |> testcontainers_gleam.start_container()
  Nil",
    Always,
  ),
]
