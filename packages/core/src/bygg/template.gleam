import bygg/config.{type ProjectConfig}
import bygg/contribution.{type NamedContribution}
import bygg/profile.{type ApplicationProfile}
import bygg/template/ci
import bygg/template/config_module as config_module_template
import bygg/template/context_module as context_module_template
import bygg/template/docker
import bygg/template/env
import bygg/template/readme as readme_template
import bygg/template/src_module as src_module_template
import bygg/template/test_module as test_module_template
import bygg/template/test_utils_module as test_utils_module_template
import gleam/option.{type Option}

pub fn src_module(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  contributions: List(NamedContribution),
) -> String {
  src_module_template.render(config, app_profile, contributions)
}

pub fn test_module(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  contributions: List(NamedContribution),
) -> String {
  test_module_template.render(config, app_profile, contributions)
}

pub fn test_utils_module(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  contributions: List(NamedContribution),
  has_testcontainers: Bool,
) -> Option(String) {
  test_utils_module_template.render(
    config,
    app_profile,
    contributions,
    has_testcontainers,
  )
}

pub fn gitignore(config: ProjectConfig, extra_entries: List(String)) -> String {
  env.gitignore(config, extra_entries)
}

pub fn readme(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  config_fields: List(String),
  needs_docker: Bool,
  needs_dockerfile: Bool,
  app_port: Int,
) -> String {
  readme_template.render(
    config,
    app_profile,
    config_fields,
    needs_docker,
    needs_dockerfile,
    app_port,
  )
}

pub fn env_example(env_var_blocks: List(String)) -> String {
  env.env_example(env_var_blocks)
}

pub fn config_module(
  _project_name: String,
  config_field_blocks: List(String),
) -> String {
  config_module_template.render(config_field_blocks)
}

pub fn docker_compose(
  service_blocks: List(String),
  volume_blocks: List(String),
  app_port: Int,
  has_env: Bool,
) -> String {
  docker.compose(service_blocks, volume_blocks, app_port, has_env)
}

pub fn dockerfile(dockerfile_instructions: List(String)) -> String {
  docker.dockerfile(dockerfile_instructions)
}

pub fn context_module(context_fields: List(String)) -> String {
  context_module_template.render(context_fields)
}

pub fn ci_config(
  name: String,
  gleam_version: String,
  needs_testcontainers: Bool,
) -> String {
  ci.render(name, gleam_version, needs_testcontainers)
}
