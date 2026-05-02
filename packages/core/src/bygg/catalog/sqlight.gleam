import bygg/contribution_block.{type Contribution, Contribution, empty}
import gleam/option.{Some}

pub fn contribution() -> Contribution {
  Contribution(
    ..empty(),
    imports: ["sqlight"],
    test_imports: ["sqlight"],
    context_fields: ["sqlite: sqlight.Connection"],
    config_fields: ["database_path: String"],
    env_vars: env_vars(),
    main_body: ["let assert Ok(sqlite) = sqlight.open(cfg.database_path)"],
    dockerfile_instructions: ["RUN apk add --no-cache sqlite-dev sqlite-libs"],
    test_setup_fallback: Some("let assert Ok(sqlite) = sqlight.open(\":memory:\")"),
  )
}

fn env_vars() -> List(String) {
  ["# Path to the SQLite database file\nDATABASE_PATH=./my_app_dev.db"]
}
