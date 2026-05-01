import gleam/option.{type Option, None}

pub type Contribution {
  Contribution(
    imports: List(String),
    js_only_imports: List(String),
    erlang_only_imports: List(String),
    test_imports: List(String),
    testcontainers_test_imports: List(String),
    context_fields: List(String),
    config_fields: List(String),
    env_vars: List(String),
    main_body: List(String),
    declarations: List(String),
    otp_child_specs: List(String),
    docker_service: Option(String),
    docker_volumes: List(String),
    dockerfile_instructions: List(String),
    test_helper: Option(String),
    test_setup_call: Option(String),
    test_container_handle: Option(String),
    test_setup_fallback: Option(String),
  )
}

pub fn empty() -> Contribution {
  Contribution(
    imports: [],
    js_only_imports: [],
    erlang_only_imports: [],
    test_imports: [],
    testcontainers_test_imports: [],
    context_fields: [],
    config_fields: [],
    env_vars: [],
    main_body: [],
    declarations: [],
    otp_child_specs: [],
    docker_service: None,
    docker_volumes: [],
    dockerfile_instructions: [],
    test_helper: None,
    test_setup_call: None,
    test_container_handle: None,
    test_setup_fallback: None,
  )
}
