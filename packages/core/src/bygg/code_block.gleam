import bygg/config.{type Target}

pub type CodeSlot {
  Import
  ContextField
  MainBody
  TestImport
  TestSetup
  // field in the generated Config type: "database_path: String"
  // env key is derived by uppercasing the field name
  ConfigField
  // entry in .env.example: "# Description\nKEY=value"
  EnvVar
  // service block in docker-compose.yml; use {project_name} for substitution
  DockerService
  // volume entry in docker-compose.yml
  DockerVolume
  // static top-level declaration emitted in the src module (function or type)
  Declaration
  // expression passed to static_supervisor.add(...) when gleam_otp is selected
  OtpChildSpec
  // instruction added to the generated project Dockerfile (e.g. "RUN apk add --no-cache sqlite-dev")
  DockerfileInstruction
}

pub type Condition {
  Always
  WhenTarget(Target)
}

pub type CodeBlock {
  CodeBlock(slot: CodeSlot, content: String, condition: Condition)
}
