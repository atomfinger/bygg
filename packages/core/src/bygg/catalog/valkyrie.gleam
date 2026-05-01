import bygg/contribution_block.{type Contribution, Contribution, empty}
import gleam/option.{Some}

const app_imports = ["gleam/option", "gleam/erlang/process", "valkyrie"]

pub fn contribution() -> Contribution {
  Contribution(
    ..empty(),
    imports: app_imports,
    main_body: [
      "let pool_name = process.new_name(\"valkyrie_connection_pool\")",
    ],
    otp_child_specs: ["create_valkyrie_pool(pool_name)"],
    declarations: [pool_decl()],
    docker_service: Some(docker_service()),
  )
}

fn pool_decl() -> String {
  "
pub fn create_valkyrie_pool(pool_name) {
  valkyrie.default_config()
  |> valkyrie.supervised_pool(
    size: 10,
    name: option.Some(pool_name),
    timeout: 1000,
  )
}
"
}

fn docker_service() -> String {
  "valkey:
  image: valkey/valkey:8.0.2-alpine
  ports:
    - \"6379:6379\""
}
