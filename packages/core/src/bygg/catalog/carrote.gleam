import bygg/contribution_block.{type Contribution, Contribution, empty}
import gleam/option.{Some}

const app_imports = [
  "carotte", "gleam/erlang/process", "gleam/int", "gleam/otp/static_supervisor",
]

const test_imports = ["carotte"]

pub fn contribution() -> Contribution {
  Contribution(
    ..empty(),
    imports: app_imports,
    test_imports: test_imports,
    context_fields: ["mq: carotte.Client", "consumers: carotte.Consumer"],
    config_fields: ["rabbitmq_host: String", "rabbitmq_port: String"],
    env_vars: env_vars(),
    main_body: main_body(),
    docker_service: Some(docker_service()),
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
