import bygg/config
import integration_helpers.{archetype_config, check_and_test, with_deps}
import unitest

pub fn testcontainers_franz_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_testcontainers_franz")
      |> with_deps(["testcontainers_gleam", "franz"]),
    "t_testcontainers_franz",
  )
}

pub fn webserver_pog_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_web_pog") |> with_deps(["wisp", "mist", "pog"]),
    "t_web_pog",
  )
}

pub fn webserver_pog_testcontainers_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_web_pog_testcontainers")
      |> with_deps(["wisp", "mist", "pog", "testcontainers_gleam"]),
    "t_web_pog_testcontainers",
  )
}

pub fn webserver_pog_lustre_testcontainers_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_web_pog_lustre_testcontainers")
      |> with_deps(["pog", "testcontainers_gleam", "lustre_server_component"]),
    "t_web_pog_lustre_testcontainers",
  )
}

pub fn webserver_valkyrie_testcontainers_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_web_testcontainers_valkyrie")
      |> with_deps(["wisp", "mist", "testcontainers_gleam", "valkyrie"]),
    "t_web_testcontainers_valkyrie",
  )
}

pub fn lustre_server_component_pog_franz_testcontainers_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_web_pog_franz_testcontainers")
      |> with_deps([
        "lustre_server_component",
        "pog",
        "testcontainers_gleam",
        "franz",
      ]),
    "t_web_pog_franz_testcontainers",
  )
}

pub fn webserver_pog_gleam_json_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_web_pog_json")
      |> with_deps(["wisp", "mist", "pog", "gleam_json"]),
    "t_web_pog_json",
  )
}

pub fn webserver_pog_envoy_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_web_pog_envoy")
      |> with_deps(["wisp", "mist", "pog", "envoy"]),
    "t_web_pog_envoy",
  )
}

pub fn lustre_server_component_pog_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_lsc_pog")
      |> with_deps(["lustre_server_component", "pog"]),
    "t_lsc_pog",
  )
}

pub fn webserver_rest_api_pog_test() {
  use <- unitest.tag("docker")
  check_and_test(
    archetype_config("t_archetype_rest_api_pog", "rest-api"),
    "t_archetype_rest_api_pog",
  )
}

pub fn webserver_pog_otp_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_web_pog_otp")
      |> with_deps(["wisp", "mist", "pog", "gleam_otp"]),
    "t_web_pog_otp",
  )
}
