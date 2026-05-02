import bygg/config
import integration_helpers.{
  check_and_test, compile_only, javascript, with_deps, with_dev_deps,
}
import unitest

pub fn lustre_spa_dev_tools_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_lustre_spa_dev_tools")
      |> javascript
      |> with_deps(["lustre"])
      |> with_dev_deps(["lustre_dev_tools"]),
    "lustre_spa_dev_tools_test",
  )
}

pub fn lustre_server_component_sqlight_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_lsc_sqlight")
      |> with_deps(["lustre_server_component", "sqlight"]),
    "lustre_server_component_sqlight_test",
  )
}

pub fn lustre_server_component_wisp_mist_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_lsc_web")
      |> with_deps(["lustre_server_component", "wisp", "mist"]),
    "lustre_server_component_wisp_mist_test",
  )
}

pub fn lustre_server_component_pog_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
    config.default("t_lsc_pog")
      |> with_deps(["lustre_server_component", "pog"]),
    "lustre_server_component_pog_check_test",
  )
}
