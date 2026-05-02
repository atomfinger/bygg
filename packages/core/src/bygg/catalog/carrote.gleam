import bygg/contribution_block.{type Contribution, Contribution, empty}
import gleam/option.{Some}

const app_imports = [
  "carotte", "gleam/erlang/process", "gleam/int", "gleam/otp/static_supervisor",
]

const test_imports = ["carotte"]

const testcontainers_test_imports = [
  "testcontainers_gleam", "testcontainers_gleam/container",
  "testcontainers_gleam/rabbitmq",
]

pub fn contribution() -> Contribution {
  Contribution(
    ..empty(),
    imports: app_imports,
    test_imports: test_imports,
    testcontainers_test_imports: testcontainers_test_imports,
    context_fields: ["mq: carotte.Client", "consumers: carotte.Consumer"],
    config_fields: ["rabbitmq_host: String", "rabbitmq_port: String"],
    env_vars: env_vars(),
    main_body: main_body(),
    docker_service: Some(docker_service()),
    test_helper: Some(start_rabbitmq_helper()),
    test_setup_call: Some("let #(running_mq, mq) = start_rabbitmq()"),
    test_container_handle: Some("container.container_id(running_mq)"),
    test_setup_fallback: Some(test_setup_fallback()),
  )
}

fn env_vars() -> List(String) {
  [
    "# RabbitMQ hostname\nRABBITMQ_HOST=localhost",
    "# RabbitMQ port\nRABBITMQ_PORT=5672",
  ]
}

fn main_body() -> List(String) {
  [
    "let assert Ok(rabbitmq_port) = int.parse(cfg.rabbitmq_port)
  let assert Ok(mq) =
    carotte.ClientConfig(
      ..carotte.default_client(),
      host: cfg.rabbitmq_host,
      port: rabbitmq_port,
    )
    |> carotte.start()",
    "let consumers_name = process.new_name(\"consumers\")
  let consumer_spec = carotte.consumer_supervised(consumers_name)
  let assert Ok(_) =
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(consumer_spec)
    |> static_supervisor.start()
  let consumers = carotte.named_consumer(consumers_name)",
  ]
}

fn docker_service() -> String {
  "rabbitmq:
  image: rabbitmq:4-alpine
  ports:
    - \"5672:5672\""
}

fn start_rabbitmq_helper() -> String {
  "fn start_rabbitmq() {
  let assert Ok(Nil) = testcontainers_gleam.start_link()
  let config = rabbitmq.new()
  let built = rabbitmq.build(config)
  let assert Ok(running_mq) = testcontainers_gleam.start_container(built)
  let mq_port = rabbitmq.port(running_mq)
  let assert Ok(mq) =
    carotte.ClientConfig(..carotte.default_client(), port: mq_port)
    |> carotte.start()
  #(running_mq, mq)
}"
}

fn test_setup_fallback() -> String {
  "let assert Ok(mq) = carotte.default_client() |> carotte.start()"
}
