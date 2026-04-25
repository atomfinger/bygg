import bygg/config.{type ProjectConfig}
import bygg/contribution.{type CodeContribution}
import bygg/profile.{type ApplicationProfile}
import bygg/template/shared

pub fn src_module(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  contributions: List(CodeContribution),
) -> String {
  shared.src_module(config, app_profile, contributions)
}

pub fn test_module(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  contributions: List(CodeContribution),
) -> String {
  shared.test_module(config, app_profile, contributions)
}

pub fn gitignore(config: ProjectConfig) -> String {
  shared.gitignore(config)
}

pub fn readme(
  config: ProjectConfig,
  app_profile: ApplicationProfile,
  config_fields: List(String),
  needs_docker: Bool,
  needs_dockerfile: Bool,
  app_port: Int,
) -> String {
  shared.readme(
    config,
    app_profile,
    config_fields,
    needs_docker,
    needs_dockerfile,
    app_port,
  )
}

pub fn env_example(env_var_blocks: List(String)) -> String {
  shared.env_example(env_var_blocks)
}

pub fn config_module(
  project_name: String,
  config_field_blocks: List(String),
) -> String {
  shared.config_module(project_name, config_field_blocks)
}

pub fn docker_compose(
  service_blocks: List(String),
  volume_blocks: List(String),
  app_port: Int,
  has_env: Bool,
) -> String {
  shared.docker_compose(service_blocks, volume_blocks, app_port, has_env)
}

pub fn dockerfile(dockerfile_instructions: List(String)) -> String {
  shared.dockerfile(dockerfile_instructions)
}

pub fn context_module(context_fields: List(String)) -> String {
  shared.context_module(context_fields)
}
