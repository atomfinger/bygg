import gleam/list

pub type GleamVersion {
  GleamVersion(label: String, constraint: String, is_default: Bool)
}

pub const versions: List(GleamVersion) = [
  GleamVersion(
    label: "1.15.x (latest)",
    constraint: ">= 1.15.0 and < 2.0.0",
    is_default: True,
  ),
]

pub fn default_version() -> GleamVersion {
  let assert Ok(version) =
    list.find(versions, fn(version) { version.is_default })
  version
}
