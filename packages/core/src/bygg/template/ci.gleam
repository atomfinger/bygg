import gleam/string

pub fn render(
  name: String,
  gleam_version: String,
  needs_testcontainers: Bool,
) -> String {
  case name {
    "github_actions" -> github_actions(gleam_version, needs_testcontainers)
    "gitlab_ci" -> gitlab_ci(gleam_version, needs_testcontainers)
    "circleci" -> circleci(gleam_version, needs_testcontainers)
    "travisci" -> travisci(gleam_version, needs_testcontainers)
    _ -> ""
  }
}

fn github_actions(gleam_version: String, needs_testcontainers: Bool) -> String {
  let elixir_line = case needs_testcontainers {
    True -> "          elixir-version: \"1.17\"\n"
    False -> ""
  }
  "name: CI

on:
  push:
    branches: [\"main\"]
  pull_request:
    branches: [\"main\"]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: \"27\"
          rebar3-version: \"3\"
          gleam-version: \"{gleam_version}\"
{elixir_line}      - run: gleam build
      - run: gleam test
"
  |> string.replace("{gleam_version}", gleam_version)
  |> string.replace("{elixir_line}", elixir_line)
}

fn gitlab_ci(gleam_version: String, needs_testcontainers: Bool) -> String {
  let services_block = case needs_testcontainers {
    True -> "\nservices:\n  - docker:dind\n"
    False -> ""
  }
  let variables_block = case needs_testcontainers {
    True ->
      "\nvariables:\n  DOCKER_HOST: tcp://docker:2376\n  DOCKER_TLS_CERTDIR: \"/certs\"\n"
    False -> ""
  }
  let extra_packages = case needs_testcontainers {
    True -> " elixir docker-cli"
    False -> ""
  }
  "image: ghcr.io/gleam-lang/gleam:v{gleam_version}-erlang-alpine
{services_block}{variables_block}
before_script:
  - apk add --no-cache rebar3{extra_packages}

test:
  script:
    - gleam build
    - gleam test
"
  |> string.replace("{gleam_version}", gleam_version)
  |> string.replace("{services_block}", services_block)
  |> string.replace("{variables_block}", variables_block)
  |> string.replace("{extra_packages}", extra_packages)
}

fn circleci(gleam_version: String, needs_testcontainers: Bool) -> String {
  case needs_testcontainers {
    False ->
      "version: 2.1

jobs:
  test:
    docker:
      - image: ghcr.io/gleam-lang/gleam:v{gleam_version}-erlang
    steps:
      - checkout
      - run:
          name: Install rebar3
          command: apt-get update && apt-get install -y rebar3
      - run: gleam build
      - run: gleam test

workflows:
  ci:
    jobs:
      - test
"
      |> string.replace("{gleam_version}", gleam_version)
    True ->
      "version: 2.1

jobs:
  test:
    machine:
      image: ubuntu-2204:current
    steps:
      - checkout
      - run:
          name: Install Gleam
          command: |
            curl -fsSL https://github.com/gleam-lang/gleam/releases/download/v{gleam_version}/gleam-v{gleam_version}-x86_64-unknown-linux-musl.tar.gz | tar xz -C /usr/local/bin
      - run:
          name: Install rebar3 and Elixir
          command: apt-get update && apt-get install -y rebar3 elixir
      - run: gleam build
      - run: gleam test

workflows:
  ci:
    jobs:
      - test
"
      |> string.replace("{gleam_version}", gleam_version)
  }
}

fn travisci(gleam_version: String, needs_testcontainers: Bool) -> String {
  let services_block = case needs_testcontainers {
    True -> "\nservices:\n  - docker\n"
    False -> ""
  }
  let elixir_install = case needs_testcontainers {
    True -> "  - sudo apt-get update && sudo apt-get install -y elixir\n"
    False -> ""
  }
  "language: erlang
otp_release:
  - \"27\"
{services_block}
before_install:
  - curl -fsSL https://github.com/gleam-lang/gleam/releases/download/v{gleam_version}/gleam-v{gleam_version}-x86_64-unknown-linux-musl.tar.gz | tar xz -C /usr/local/bin
{elixir_install}
script:
  - gleam build
  - gleam test
"
  |> string.replace("{gleam_version}", gleam_version)
  |> string.replace("{services_block}", services_block)
  |> string.replace("{elixir_install}", elixir_install)
}
