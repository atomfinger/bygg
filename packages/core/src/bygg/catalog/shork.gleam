import bygg/contribution_block.{type Contribution, Contribution, empty}
import gleam/option.{Some}

const config_fields = [
  "database_host: String",
  "database_port: String",
  "database_name: String",
  "database_user: String",
  "database_password: String",
]

const app_imports = ["gleam/int", "shork"]

const test_imports = ["shork"]

const testcontainers_test_imports = [
  "testcontainers_gleam", "testcontainers_gleam/container",
  "testcontainers_gleam/mysql",
]

pub fn contribution() -> Contribution {
  Contribution(
    ..empty(),
    imports: app_imports,
    test_imports: test_imports,
    testcontainers_test_imports: testcontainers_test_imports,
    context_fields: ["mysql: shork.Connection"],
    config_fields: config_fields,
    env_vars: env_vars(),
    main_body: main_body(),
    docker_service: Some(docker_service()),
    docker_volumes: ["mysql_data:"],
    test_helper: Some(start_mysql_helper()),
    test_setup_call: Some("let #(running_mysql, mysql) = start_mysql()"),
    test_container_handle: Some("container.container_id(running_mysql)"),
    test_setup_fallback: Some(test_setup_fallback()),
  )
}

fn main_body() -> List(String) {
  [
    "let assert Ok(db_port) = int.parse(cfg.database_port)",
    "let mysql =
    shork.default_config()
    |> shork.host(cfg.database_host)
    |> shork.port(db_port)
    |> shork.database(cfg.database_name)
    |> shork.user(cfg.database_user)
    |> shork.password(cfg.database_password)
    |> shork.connect",
  ]
}

fn env_vars() -> List(String) {
  [
    "# MySQL hostname\nDATABASE_HOST=localhost",
    "# MySQL port\nDATABASE_PORT=3306",
    "# MySQL database name\nDATABASE_NAME={project_name}_dev",
    "# MySQL user\nDATABASE_USER={project_name}",
    "# MySQL password\nDATABASE_PASSWORD=password",
  ]
}

fn docker_service() -> String {
  "mysql:
  image: mysql:8.0
  environment:
    MYSQL_DATABASE: {project_name}_dev
    MYSQL_USER: {project_name}
    MYSQL_PASSWORD: password
    MYSQL_ROOT_PASSWORD: rootpassword
  ports:
    - \"3306:3306\"
  volumes:
    - mysql_data:/var/lib/mysql"
}

fn start_mysql_helper() -> String {
  "fn start_mysql() {
  let assert Ok(Nil) = testcontainers_gleam.start_link()
  let config = mysql.new() |> mysql.with_image(\"mysql:8.0\")
  let built = mysql.build(config)
  let assert Ok(running_mysql) = testcontainers_gleam.start_container(built)
  let mysql_port = mysql.port(running_mysql)
  let mysql_conn =
    shork.default_config()
    |> shork.host(\"localhost\")
    |> shork.port(mysql_port)
    |> shork.database(\"test\")
    |> shork.user(\"test\")
    |> shork.password(\"test\")
    |> shork.connect
  #(running_mysql, mysql_conn)
}"
}

fn test_setup_fallback() -> String {
  "let mysql =
    shork.default_config()
    |> shork.host(\"localhost\")
    |> shork.port(3306)
    |> shork.database(\"{project_name}_dev\")
    |> shork.user(\"{project_name}\")
    |> shork.password(\"password\")
    |> shork.connect"
}
