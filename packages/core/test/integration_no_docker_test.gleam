import bygg/config
import integration_helpers.{
  check_and_test, compile_only, javascript, with_deps, with_dev_deps,
}
import unitest

pub fn basic_app_test() {
  use <- unitest.tag("no_docker")
  check_and_test(config.default("t_basic"), "basic_app_test")
}

pub fn webserver_wisp_mist_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_webserver") |> with_deps(["wisp", "mist"]),
    "webserver_wisp_mist_test",
  )
}

pub fn webserver_sqlight_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_web_sqlight") |> with_deps(["wisp", "mist", "sqlight"]),
    "webserver_sqlight_test",
  )
}

pub fn lustre_spa_js_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_lustre_spa") |> javascript |> with_deps(["lustre"]),
    "lustre_spa_js_test",
  )
}

pub fn lustre_web_component_js_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_lustre_component")
      |> javascript
      |> with_deps(["lustre_component"]),
    "lustre_web_component_js_test",
  )
}

pub fn lustre_server_component_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_lustre_server_component")
      |> with_deps(["lustre_server_component"]),
    "lustre_server_component_test",
  )
}

pub fn testcontainers_only_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_testcontainers") |> with_deps(["testcontainers_gleam"]),
    "testcontainers_only_test",
  )
}

pub fn webserver_gleam_otp_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_webserver_otp")
      |> with_deps(["wisp", "mist", "gleam_otp"]),
    "webserver_gleam_otp_test",
  )
}

pub fn webserver_sqlight_otp_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_web_sqlight_otp")
      |> with_deps(["wisp", "mist", "sqlight", "gleam_otp"]),
    "webserver_sqlight_otp_test",
  )
}

pub fn lustre_server_component_otp_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_lustre_server_component_otp")
      |> with_deps(["lustre_server_component", "gleam_otp"]),
    "lustre_server_component_otp_test",
  )
}

pub fn basic_gleam_otp_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_basic_otp") |> with_deps(["gleam_otp"]),
    "basic_gleam_otp_test",
  )
}

pub fn basic_birdie_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_basic_birdie") |> with_dev_deps(["birdie"]),
    "basic_birdie_test",
  )
}

pub fn webserver_birdie_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_web_birdie")
      |> with_deps(["wisp", "mist"])
      |> with_dev_deps(["birdie"]),
    "webserver_birdie_test",
  )
}

pub fn testcontainers_franz_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
    config.default("t_testcontainers_franz")
      |> with_deps(["testcontainers_gleam", "franz"]),
    "t_testcontainers_franz",
  )
}

pub fn webserver_pog_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
    config.default("t_web_pog") |> with_deps(["wisp", "mist", "pog"]),
    "t_web_pog",
  )
}

pub fn webserver_pog_testcontainers_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
    config.default("t_web_pog_testcontainers")
      |> with_deps(["wisp", "mist", "pog", "testcontainers_gleam"]),
    "t_web_pog_testcontainers",
  )
}

pub fn webserver_pog_lustre_testcontainers_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
    config.default("t_web_pog_lustre_testcontainers")
      |> with_deps(["pog", "testcontainers_gleam", "lustre_server_component"]),
    "t_web_pog_lustre_testcontainers",
  )
}

pub fn webserver_valkyrie_testcontainers_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
    config.default("t_web_testcontainers_valkyrie")
      |> with_deps(["wisp", "mist", "testcontainers_gleam", "valkyrie"]),
    "t_web_testcontainers_valkyrie",
  )
}

pub fn lustre_server_component_pog_franz_testcontainers_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
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

pub fn webserver_valkyrie_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
    config.default("t_web_valkyrie") |> with_deps(["wisp", "mist", "valkyrie"]),
    "t_web_valkyrie",
  )
}

pub fn franz_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(config.default("t_franz") |> with_deps(["franz"]), "t_franz")
}

pub fn carotte_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
    config.default("t_carotte") |> with_deps(["carotte"]),
    "t_carotte",
  )
}

pub fn testcontainers_carotte_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
    config.default("t_testcontainers_carotte")
      |> with_deps(["testcontainers_gleam", "carotte"]),
    "t_testcontainers_carotte",
  )
}

pub fn shork_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
    config.default("t_shork") |> with_deps(["shork"]),
    "t_shork",
  )
}

pub fn testcontainers_shork_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
    config.default("t_testcontainers_shork")
      |> with_deps(["testcontainers_gleam", "shork"]),
    "t_testcontainers_shork",
  )
}
