import integration_helpers.{archetype_config, check_and_test, compile_only}
import unitest

pub fn webserver_rest_api_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    archetype_config("t_archetype_rest_api", "rest-api"),
    "webserver_rest_api_test",
  )
}

pub fn webserver_ssr_website_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    archetype_config("t_archetype_ssr", "ssr-website"),
    "webserver_ssr_website_test",
  )
}

pub fn lustre_browser_app_test() {
  use <- unitest.tag("no_docker")
  check_and_test(
    archetype_config("t_archetype_browser", "browser-app"),
    "lustre_browser_app_test",
  )
}

pub fn webserver_rest_api_pog_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
    archetype_config("t_archetype_rest_api_pog", "rest-api"),
    "webserver_rest_api_pog_check_test",
  )
}

pub fn webserver_ssr_pog_check_test() {
  use <- unitest.tag("no_docker")
  compile_only(
    archetype_config("t_archetype_ssr_pog", "ssr-website"),
    "webserver_ssr_pog_check_test",
  )
}
