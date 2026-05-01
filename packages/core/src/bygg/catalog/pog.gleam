import bygg/contribution_block.{type Contribution, Contribution, empty}
import gleam/option.{Some}

const app_imports = ["gleam/int", "gleam/option.{Some}", "pog"]

const test_imports = ["gleam/erlang/process", "pog"]

const testcontainers_test_imports = [
  "testcontainers_gleam",
  "testcontainers_gleam/container",
  "testcontainers_gleam/postgres",
]

const config_fields = [
  "database_host: String",
  "database_port: String",
  "database_name: String",
  "database_user: String",
  "database_password: String",
]

pub fn contribution() -> Contribution {
  Contribution(
    ..empty(),
    imports: app_imports,
    test_imports: test_imports,
    testcontainers_test_imports: testcontainers_test_imports,
    context_fields: ["db: pog.Connection"],
    config_fields: config_fields,
    env_vars: env_vars(),
    main_body: main_body(),
    otp_child_specs: [otp_child_spec()],
    docker_service: Some(docker_service()),
    docker_volumes: ["postgres_data:"],
    test_helper: Some(start_postgres_helper()),
    test_setup_call: Some("let #(running_pg, db) = start_postgres()"),
    test_container_handle: Some("container.container_id(running_pg)"),
    test_setup_fallback: Some(test_setup_fallback()),
  )
}

fn main_body() -> List(String) {
  [
    "let assert Ok(db_port) = int.parse(cfg.database_port)",
    "let db = pog.named_connection(process.new_name(\"postgress\"))",
  ]
}

fn env_vars() -> List(String) {
  [
    "# PostgreSQL host\nDATABASE_HOST=localhost",
    "# PostgreSQL port\nDATABASE_PORT=5432",
    "# PostgreSQL database name\nDATABASE_NAME={project_name}_dev",
    "# PostgreSQL user\nDATABASE_USER={project_name}",
    "# PostgreSQL password\nDATABASE_PASSWORD=password",
  ]
}

fn otp_child_spec() -> String {
  "pog.default_config(process.new_name(\"postgress\"))
      |> pog.host(cfg.database_host)
      |> pog.port(db_port)
      |> pog.database(cfg.database_name)
      |> pog.user(cfg.database_user)
      |> pog.password(Some(cfg.database_password))
      |> pog.supervised"
}

fn docker_service() -> String {
  "postgres:
  image: postgres:18-alpine
  environment:
    POSTGRES_USER: {project_name}
    POSTGRES_PASSWORD: password
    POSTGRES_DB: {project_name}_dev
  ports:
    - \"5432:5432\"
  volumes:
    - postgres_data:/var/lib/postgresql/data"
}

fn start_postgres_helper() -> String {
  "fn start_postgres() {
  let assert Ok(running_pg) =
    postgres.new()
    |> postgres.build()
    |> testcontainers_gleam.start_container()
  let assert Ok(pg_port) = container.mapped_port(running_pg, 5432)
  let db_name = process.new_name(\"test_db\")
  let assert Ok(_) =
    pog.default_config(db_name)
    |> pog.host(\"localhost\")
    |> pog.port(pg_port)
    |> pog.start()
  let db = pog.named_connection(db_name)
  #(running_pg, db)
}"
}

fn test_setup_fallback() -> String {
  "let db_name = process.new_name(\"test_db\")
  let assert Ok(_) =
    pog.default_config(db_name)
    |> pog.host(\"localhost\")
    |> pog.port(5432)
    |> pog.database(\"{project_name}_dev\")
    |> pog.user(\"{project_name}\")
    |> pog.password(option.Some(\"password\"))
    |> pog.start()
  let db = pog.named_connection(db_name)"
}
