import bygg/config
import integration_helpers.{
  check_and_test, compile_only, javascript, with_deps, with_dev_deps,
}
import unitest

// ============================================================
// Lustre browser SPA scenarios (JavaScript target)
// Run with: gleam test -- --tag no_docker
// ============================================================

pub fn lustre_spa_dev_tools_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_lustre_spa_dev_tools")
      |> javascript
      |> with_deps(["lustre"])
      |> with_dev_deps(["lustre_dev_tools"]),
    "t_lustre_spa_dev_tools",
  )
}

// ============================================================
// Lustre server component scenarios (Erlang target)
// ============================================================

pub fn lustre_server_component_sqlight_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_lsc_sqlight")
      |> with_deps(["lustre_server_component", "sqlight"]),
    "t_lsc_sqlight",
  )
}

pub fn lustre_server_component_wisp_mist_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    config.default("t_lsc_web")
      |> with_deps(["lustre_server_component", "wisp", "mist"]),
    "t_lsc_web",
  )
}

// LSC docker scenarios — compile check only

pub fn lustre_server_component_pog_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
    config.default("t_lsc_pog")
      |> with_deps(["lustre_server_component", "pog"]),
    "t_lsc_pog",
  )
}
