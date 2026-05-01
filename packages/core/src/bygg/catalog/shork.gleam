import bygg/contribution_block.{type Contribution, Contribution, empty}
import gleam/option.{Some}

const config_fields = [
  "database_host: String",
  "database_port: String",
  "database_name: String",
  "database_user: String",
  "database_password: String",
]

const test_imports = ["shork"]

const app_imports = ["shork"]

const testcontainers_test_imports = [
  "testcontainers_gleam",
  "testcontainers_gleam/container",
  "testcontainers_gleam/mysql",
]

pub fn contribution() -> Contribution {
  Contribution(
    ..empty(),
    imports: app_imports,
    test_imports: test_imports,
    testcontainers_test_imports: testcontainers_test_imports,
    context_fields: ["db: shork.Connection"],
    config_fields: config_fields,
    env_vars: env_vars(),
    main_body: ["let connection = createConnection(cfg)"],
    docker_service: Some(docker_service()),
    docker_volumes: ["mysql_data:"],
    test_helper: Some(start_mysql_helper()),
    declarations: [create_connection_decleration()],
    test_setup_call: Some("let running_mysql = start_mysql()"),
    test_container_handle: Some("container.container_id(running_mysql)"),
  )
}

fn create_connection_decleration() {
  "fn createConnection(config: Config) {
  let assert Ok(db_port) = int.parse(config.database_port)
  shork.default_config()
      |> shork.user(\"config.database_user\")
      |> shork.password(\"config.database_password\")
      |> shork.database(\"config.database_name\")
      |> shork.port(db_port)
      |> shork.host(config.database_host)
      |> shork.connect
    }"
}

fn env_vars() -> List(String) {
  [
    "# MYSQL host\nDATABASE_HOST=localhost",
    "# MYSQL port\nDATABASE_PORT=3306",
    "# MYSQL database name\nDATABASE_NAME={project_name}_dev",
    "# MYSQL user\nDATABASE_USER={project_name}",
    "# MYSQL password\nDATABASE_PASSWORD=password",
  ]
}

fn docker_service() -> String {
  "mysql:
  image: mysql:latest
  container_name: mysql-container
  environment:
    MYSQL_ROOT_PASSWORD: my-secret-pw
    MYSQL_DATABASE: my_database
  ports:
  - \"3306:3306\"
  volumes:
    - mysql-data:/var/lib/mysql"
}

fn start_mysql_helper() -> String {
  "fn start_mysql() {
  let config = mysql.new()
  let container = mysql.build(config)
  let assert Ok(running_mysql) = testcontainers_gleam.start_container(container)
  let params = mysql.connection_parameters(running)
  running_mysql
}"
}
