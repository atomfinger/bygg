import bygg/code_block.{
  type CodeBlock, Always, CodeBlock, ConfigField, ContextField, DockerService,
  EnvVar, Import, MainBody, TestImport, TestSetup,
}

pub const code_blocks: List(CodeBlock) = [
  CodeBlock(Import, "franz", Always),
  CodeBlock(Import, "gleam/int", Always),
  CodeBlock(ContextField, "kafka: franz.Client", Always),
  CodeBlock(
    MainBody,
    "let assert Ok(kafka_port) = int.parse(cfg.kafka_port)",
    Always,
  ),
  CodeBlock(
    MainBody,
    "let assert Ok(started) =
    franz.new([franz.Endpoint(cfg.kafka_host, kafka_port)], process.new_name(\"kafka\"))
    |> franz.start()
  let kafka = started.data",
    Always,
  ),
  CodeBlock(ConfigField, "kafka_host: String", Always),
  CodeBlock(ConfigField, "kafka_port: String", Always),
  CodeBlock(EnvVar, "# Kafka broker hostname\nKAFKA_HOST=localhost", Always),
  CodeBlock(EnvVar, "# Kafka broker port\nKAFKA_PORT=9092", Always),
  CodeBlock(
    DockerService,
    "  kafka:
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
      - \"9092:9092\"",
    Always,
  ),
  CodeBlock(TestImport, "testcontainers_gleam", Always),
  CodeBlock(TestImport, "testcontainers_gleam/kafka", Always),
  CodeBlock(
    TestSetup,
    "  let assert Ok(_running_kafka) =
    kafka.new()
    |> kafka.build()
    |> testcontainers_gleam.start_container()
  Nil",
    Always,
  ),
]
