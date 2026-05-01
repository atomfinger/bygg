import bygg/contribution_block.{type Contribution, Contribution, empty}
import gleam/option.{Some}

const app_imports = ["franz", "gleam/int"]

const test_imports = ["franz", "gleam/erlang/process"]

const testcontainers_test_imports = [
  "testcontainers_gleam", "testcontainers_gleam/container",
  "testcontainers_gleam/kafka",
]

pub fn contribution() -> Contribution {
  Contribution(
    ..empty(),
    imports: app_imports,
    test_imports: test_imports,
    testcontainers_test_imports: testcontainers_test_imports,
    context_fields: ["kafka: franz.Client"],
    config_fields: ["kafka_host: String", "kafka_port: String"],
    env_vars: env_vars(),
    main_body: main_body(),
    docker_service: Some(docker_service()),
    test_helper: Some(start_kafka_helper()),
    test_setup_call: Some("let #(running_kafka, kafka) = start_kafka()"),
    test_container_handle: Some("container.container_id(running_kafka)"),
    test_setup_fallback: Some(test_setup_fallback()),
  )
}

fn env_vars() -> List(String) {
  [
    "# Kafka broker hostname\nKAFKA_HOST=localhost",
    "# Kafka broker port\nKAFKA_PORT=9092",
  ]
}

fn main_body() -> List(String) {
  [
    "let assert Ok(kafka_port) = int.parse(cfg.kafka_port)",
    "let assert Ok(started) =
    franz.new(
      [franz.Endpoint(cfg.kafka_host, kafka_port)],
      process.new_name(\"kafka\"),
    )
    |> franz.start()
  let kafka = started.data",
  ]
}

fn docker_service() -> String {
  "kafka:
  image: apache/kafka:4.2.0
  environment:
    KAFKA_NODE_ID: 1
    KAFKA_PROCESS_ROLES: broker,controller
    KAFKA_LISTENERS: CONTROLLER://:29093,PLAINTEXT_HOST://:9092,PLAINTEXT://:19092
    KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
    KAFKA_ADVERTISED_LISTENERS: PLAINTEXT_HOST://localhost:9092,PLAINTEXT://kafka:19092
    KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
    KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
    KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:29093
    CLUSTER_ID: 4L6g3nShT-eMCtK--X86sw
    KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
    KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
    KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
  ports:
    - \"9092:9092\""
}

fn start_kafka_helper() -> String {
  "fn start_kafka() {
  let assert Ok(Nil) = testcontainers_gleam.start_link()
  let config = kafka.new()
  let built = kafka.build(config)
  let assert Ok(running_kafka) = testcontainers_gleam.start_container(built)
  let assert Ok(Nil) = kafka.after_start(config, running_kafka)
  let assert Ok(kafka_port) = container.mapped_port(running_kafka, 9092)
  let kafka_name = process.new_name(\"test_kafka\")
  let assert Ok(started) =
    franz.new([franz.Endpoint(\"localhost\", kafka_port)], kafka_name)
    |> franz.start()
  let kafka = started.data
  #(running_kafka, kafka)
}"
}

fn test_setup_fallback() -> String {
  "let kafka_name = process.new_name(\"test_kafka\")
  let assert Ok(started) =
    franz.new([franz.Endpoint(\"localhost\", 9092)], kafka_name)
    |> franz.start()
  let kafka = started.data"
}
