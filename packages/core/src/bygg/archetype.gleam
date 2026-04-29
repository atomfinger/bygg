import bygg/config.{type Target, Erlang, JavaScript}
import gleam/list

pub type Archetype {
  Archetype(
    name: String,
    description: String,
    target: Target,
    dependencies: List(String),
    dev_dependencies: List(String),
  )
}

pub const all: List(Archetype) = [
  Archetype(
    name: "rest-api",
    description: "REST API with Wisp and Mist targeting Erlang",
    target: Erlang,
    dependencies: ["wisp", "mist", "gleam_otp", "gleam_json"],
    dev_dependencies: [],
  ),
  Archetype(
    name: "ssr-website",
    description: "Server-side rendered Lustre website targeting Erlang",
    target: Erlang,
    dependencies: ["wisp", "mist", "gleam_otp", "lustre_server_component"],
    dev_dependencies: [],
  ),
  Archetype(
    name: "browser-app",
    description: "Client-side single page application with Lustre targeting JavaScript",
    target: JavaScript,
    dependencies: ["lustre"],
    dev_dependencies: ["lustre_dev_tools"],
  ),
]

pub fn find(name: String) -> Result(Archetype, Nil) {
  list.find(all, fn(a) { a.name == name })
}
