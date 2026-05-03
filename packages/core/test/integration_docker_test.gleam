import bygg/config
import integration_helpers.{archetype_config, check_and_test, with_deps}
import unitest

pub fn testcontainers_franz_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_testcontainers_franz")
      |> with_deps(["testcontainers_gleam", "franz"]),
    "testcontainers_franz_test",
  )
}

pub fn webserver_pog_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_web_pog") |> with_deps(["wisp", "mist", "pog"]),
    "webserver_pog_test",
  )
}

pub fn webserver_pog_testcontainers_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_web_pog_testcontainers")
      |> with_deps(["wisp", "mist", "pog", "testcontainers_gleam"]),
    "webserver_pog_testcontainers_test",
  )
}

pub fn webserver_pog_lustre_testcontainers_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_web_pog_lustre_testcontainers")
      |> with_deps(["pog", "testcontainers_gleam", "lustre_server_component"]),
    "webserver_pog_lustre_testcontainers_test",
  )
}

pub fn webserver_valkyrie_testcontainers_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_web_testcontainers_valkyrie")
      |> with_deps(["wisp", "mist", "testcontainers_gleam", "valkyrie"]),
    "webserver_valkyrie_testcontainers_test",
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
    "lustre_server_component_pog_franz_testcontainers_test",
  )
}

pub fn webserver_pog_gleam_json_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_web_pog_json")
      |> with_deps(["wisp", "mist", "pog", "gleam_json"]),
    "webserver_pog_gleam_json_test",
  )
}

pub fn lustre_server_component_pog_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_lsc_pog")
      |> with_deps(["lustre_server_component", "pog"]),
    "lustre_server_component_pog_test",
  )
}

pub fn webserver_rest_api_pog_test() {
  use <- unitest.tag("docker")
  check_and_test(
    archetype_config("t_archetype_rest_api_pog", "rest-api"),
    "webserver_rest_api_pog_test",
  )
}

pub fn webserver_pog_otp_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_web_pog_otp")
      |> with_deps(["wisp", "mist", "pog", "gleam_otp"]),
    "webserver_pog_otp_test",
  )
}

pub fn testcontainers_carotte_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_testcontainers_carotte")
      |> with_deps(["testcontainers_gleam", "carotte"]),
    "testcontainers_carotte_test",
  )
}

pub fn testcontainers_shork_test() {
  use <- unitest.tag("docker")
  check_and_test(
    config.default("t_testcontainers_shork")
      |> with_deps(["testcontainers_gleam", "shork"]),
    "testcontainers_shork_test",
  )
}
