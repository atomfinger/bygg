import bygg/config
import integration_helpers.{
  check_and_test, compile_only, javascript, with_deps, with_dev_deps,
}
import unitest

// ============================================================
// no_docker tier — no external services required
// Run with: gleam test -- --tag no_docker
// ============================================================

pub fn basic_app_test() {
  use <- unitest.tag("no_docker")
  check_and_test(config.default("t_basic"), "t_basic")
}

pub fn webserver_wisp_mist_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_webserver") |> with_deps(["wisp", "mist"]),
    "t_webserver",
  )
}

pub fn webserver_sqlight_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_web_sqlight") |> with_deps(["wisp", "mist", "sqlight"]),
    "t_web_sqlight",
  )
}

pub fn lustre_spa_js_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_lustre_spa") |> javascript |> with_deps(["lustre"]),
    "t_lustre_spa",
  )
}

pub fn lustre_web_component_js_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_lustre_component")
      |> javascript
      |> with_deps(["lustre_component"]),
    "t_lustre_component",
  )
}

pub fn lustre_server_component_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_lustre_server_component")
      |> with_deps(["lustre_server_component"]),
    "t_lustre_server_component",
  )
}

pub fn testcontainers_only_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_testcontainers") |> with_deps(["testcontainers_gleam"]),
    "t_testcontainers",
  )
}

pub fn webserver_gleam_otp_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_webserver_otp")
      |> with_deps(["wisp", "mist", "gleam_otp"]),
    "t_webserver_otp",
  )
}

pub fn webserver_sqlight_otp_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_web_sqlight_otp")
      |> with_deps(["wisp", "mist", "sqlight", "gleam_otp"]),
    "t_web_sqlight_otp",
  )
}

pub fn lustre_server_component_otp_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_lustre_server_component_otp")
      |> with_deps(["lustre_server_component", "gleam_otp"]),
    "t_lustre_server_component_otp",
  )
}

pub fn basic_gleam_otp_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_basic_otp") |> with_deps(["gleam_otp"]),
    "t_basic_otp",
  )
}

pub fn basic_birdie_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_basic_birdie") |> with_dev_deps(["birdie"]),
    "t_basic_birdie",
  )
}

pub fn webserver_birdie_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_web_birdie")
      |> with_deps(["wisp", "mist"])
      |> with_dev_deps(["birdie"]),
    "t_web_birdie",
  )
}

// ============================================================
// docker scenarios — compile check only (runs on every PR)
// Verifies generated code compiles; gleam test is skipped since
// it requires external services (postgres, kafka, Docker daemon).
// ============================================================

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
