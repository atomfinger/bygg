import bygg/catalog/franz as franz_pkg
import bygg/catalog/lustre_browser_app as lustre_browser_app_pkg
import bygg/catalog/lustre_component as lustre_component_pkg
import bygg/catalog/lustre_server_component as lustre_sc_pkg
import bygg/catalog/pog as pog_pkg
import bygg/catalog/sqlight as sqlight_pkg
import bygg/catalog/valkyrie
import bygg/code_block.{type CodeBlock}
import bygg/config.{type Target, Erlang, JavaScript}
import gleam/list

pub type SupportedTarget {
  ErlangOnly
  JavaScriptOnly
  BothTargets
}

pub type Category {
  Http
  Database
  Testing
  Serialization
  Utilities
  Ui
  Crypto
  Logging
  Telemetry
}

pub type Role {
  WebFramework
  HttpServer
  FrontendFramework
  LustreComponent
  LustreServerComponent
  DatabaseClient
}

pub type Package {
  Package(
    name: String,
    hex_name: String,
    description: String,
    default_constraint: String,
    targets: SupportedTarget,
    min_gleam_version: String,
    category: Category,
    dev_only: Bool,
    requires_otp: Bool,
    roles: List(Role),
    code_blocks: List(CodeBlock),
  )
}

pub const packages: List(Package) = [
  Package(
    name: "gleam_stdlib",
    hex_name: "gleam_stdlib",
    description: "The Gleam standard library",
    default_constraint: ">= 1.0.0 and < 2.0.0",
    targets: BothTargets,
    min_gleam_version: "1.0.0",
    category: Utilities,
    dev_only: False,
    requires_otp: False,
    roles: [],
    code_blocks: [],
  ),
  Package(
    name: "gleam_erlang",
    hex_name: "gleam_erlang",
    description: "Gleam bindings to Erlang/OTP",
    default_constraint: ">= 1.0.0 and < 2.0.0",
    targets: ErlangOnly,
    min_gleam_version: "1.0.0",
    category: Utilities,
    dev_only: False,
    requires_otp: False,
    roles: [],
    code_blocks: [],
  ),
  Package(
    name: "gleam_otp",
    hex_name: "gleam_otp",
    description: "OTP actors and supervisors for Gleam",
    default_constraint: ">= 1.0.0 and < 2.0.0",
    targets: ErlangOnly,
    min_gleam_version: "1.0.0",
    category: Utilities,
    dev_only: False,
    requires_otp: False,
    roles: [],
    code_blocks: [],
  ),
  Package(
    name: "simplifile",
    hex_name: "simplifile",
    description: "Simple file I/O for Gleam",
    default_constraint: ">= 2.4.0 and < 3.0.0",
    targets: ErlangOnly,
    min_gleam_version: "1.0.0",
    category: Utilities,
    dev_only: False,
    requires_otp: False,
    roles: [],
    code_blocks: [],
  ),
  Package(
    name: "envoy",
    hex_name: "envoy",
    description: "Environment variable access for Gleam",
    default_constraint: ">= 1.0.0 and < 2.0.0",
    targets: BothTargets,
    min_gleam_version: "1.0.0",
    category: Utilities,
    dev_only: False,
    requires_otp: False,
    roles: [],
    code_blocks: [],
  ),
  Package(
    name: "wisp",
    hex_name: "wisp",
    description: "A practical Gleam web framework",
    default_constraint: ">= 2.0.0 and < 3.0.0",
    targets: ErlangOnly,
    min_gleam_version: "1.0.0",
    category: Http,
    dev_only: False,
    requires_otp: False,
    roles: [WebFramework],
    code_blocks: [],
  ),
  Package(
    name: "mist",
    hex_name: "mist",
    description: "HTTP/1.1 and HTTP/2 server for Gleam",
    default_constraint: ">= 6.0.0 and < 7.0.0",
    targets: ErlangOnly,
    min_gleam_version: "1.0.0",
    category: Http,
    dev_only: False,
    requires_otp: False,
    roles: [HttpServer],
    code_blocks: [],
  ),
  Package(
    name: "gleam_http",
    hex_name: "gleam_http",
    description: "HTTP types for Gleam (request, response, method)",
    default_constraint: ">= 4.0.0 and < 5.0.0",
    targets: BothTargets,
    min_gleam_version: "1.0.0",
    category: Http,
    dev_only: False,
    requires_otp: False,
    roles: [],
    code_blocks: [],
  ),
  Package(
    name: "sqlight",
    hex_name: "sqlight",
    description: "SQLite client for Gleam",
    default_constraint: ">= 1.0.0 and < 2.0.0",
    targets: ErlangOnly,
    min_gleam_version: "1.0.0",
    category: Database,
    dev_only: False,
    requires_otp: False,
    roles: [DatabaseClient],
    code_blocks: sqlight_pkg.code_blocks,
  ),
  Package(
    name: "valkyrie",
    hex_name: "valkyrie",
    description: "A lightweight, high performance Gleam client for Valkey, KeyDB, Redis, Dragonfly and other Redis-compatible databases.",
    default_constraint: ">= 4.0.0 and < 5.0.0",
    targets: ErlangOnly,
    min_gleam_version: "1.0.0",
    category: Database,
    dev_only: False,
    requires_otp: True,
    roles: [DatabaseClient],
    code_blocks: valkyrie.code_blocks,
  ),
  Package(
    name: "gleam_json",
    hex_name: "gleam_json",
    description: "JSON encoding and decoding for Gleam",
    default_constraint: ">= 3.0.0 and < 4.0.0",
    targets: BothTargets,
    min_gleam_version: "1.0.0",
    category: Serialization,
    dev_only: False,
    requires_otp: False,
    roles: [],
    code_blocks: [],
  ),
  Package(
    name: "lustre",
    hex_name: "lustre",
    description: "Build browser SPAs with Lustre (lustre.simple / lustre.application)",
    default_constraint: ">= 5.6.0 and < 6.0.0",
    targets: JavaScriptOnly,
    min_gleam_version: "1.0.0",
    category: Ui,
    dev_only: False,
    requires_otp: False,
    roles: [FrontendFramework],
    code_blocks: lustre_browser_app_pkg.code_blocks,
  ),
  Package(
    name: "lustre_component",
    hex_name: "lustre",
    description: "Build reusable Web Components with Lustre (lustre.component / element.register)",
    default_constraint: ">= 5.6.0 and < 6.0.0",
    targets: JavaScriptOnly,
    min_gleam_version: "1.0.0",
    category: Ui,
    dev_only: False,
    requires_otp: False,
    roles: [LustreComponent],
    code_blocks: lustre_component_pkg.code_blocks,
  ),
  Package(
    name: "lustre_server_component",
    hex_name: "lustre",
    description: "Run Lustre on Erlang/OTP and stream DOM patches to the browser",
    default_constraint: ">= 5.6.0 and < 6.0.0",
    targets: ErlangOnly,
    min_gleam_version: "1.0.0",
    category: Ui,
    dev_only: False,
    requires_otp: False,
    roles: [LustreServerComponent],
    code_blocks: lustre_sc_pkg.code_blocks,
  ),
  Package(
    name: "lustre_dev_tools",
    hex_name: "lustre_dev_tools",
    description: "Dev server and build tooling for Lustre browser apps",
    default_constraint: ">= 2.3.0 and < 3.0.0",
    targets: JavaScriptOnly,
    min_gleam_version: "1.0.0",
    category: Ui,
    dev_only: True,
    requires_otp: False,
    roles: [],
    code_blocks: [],
  ),
  Package(
    name: "gleeunit",
    hex_name: "gleeunit",
    description: "Test runner for Gleam",
    default_constraint: ">= 1.0.0 and < 2.0.0",
    targets: BothTargets,
    min_gleam_version: "1.0.0",
    category: Testing,
    dev_only: True,
    requires_otp: False,
    roles: [],
    code_blocks: [],
  ),
  Package(
    name: "birdie",
    hex_name: "birdie",
    description: "Snapshot testing for Gleam",
    default_constraint: ">= 1.0.0 and < 2.0.0",
    targets: BothTargets,
    min_gleam_version: "1.0.0",
    category: Testing,
    dev_only: True,
    requires_otp: False,
    roles: [],
    code_blocks: [],
  ),
  Package(
    name: "squirrel",
    hex_name: "squirrel",
    description: "Type-safe SQL in Gleam",
    default_constraint: ">= 4.4.0 and < 5.0.0",
    targets: ErlangOnly,
    min_gleam_version: "1.0.0",
    category: Database,
    dev_only: True,
    requires_otp: False,
    roles: [],
    code_blocks: [],
  ),
  Package(
    name: "pog",
    hex_name: "pog",
    description: "PostgreSQL client for Gleam",
    default_constraint: ">= 4.0.0 and < 5.0.0",
    targets: ErlangOnly,
    min_gleam_version: "1.0.0",
    category: Database,
    dev_only: False,
    requires_otp: True,
    roles: [DatabaseClient],
    code_blocks: pog_pkg.code_blocks,
  ),
  Package(
    name: "franz",
    hex_name: "franz",
    description: "Apache Kafka client for Gleam",
    default_constraint: ">= 3.0.0 and < 4.0.0",
    targets: ErlangOnly,
    min_gleam_version: "1.0.0",
    category: Utilities,
    dev_only: False,
    requires_otp: False,
    roles: [],
    code_blocks: franz_pkg.code_blocks,
  ),
  Package(
    name: "testcontainers_gleam",
    hex_name: "testcontainers_gleam",
    description: "Testcontainers for Gleam",
    default_constraint: ">= 2.0.0 and < 3.0.0",
    targets: ErlangOnly,
    min_gleam_version: "1.0.0",
    category: Testing,
    dev_only: True,
    requires_otp: False,
    roles: [],
    code_blocks: [],
  ),
]

pub fn for_target(target: Target) -> List(Package) {
  list.filter(packages, fn(package) {
    case package.targets, target {
      BothTargets, _ -> True
      ErlangOnly, Erlang -> True
      JavaScriptOnly, JavaScript -> True
      _, _ -> False
    }
  })
}

pub fn by_category(category: Category) -> List(Package) {
  list.filter(packages, fn(package) { package.category == category })
}

pub fn find_by_hex_name(hex_name: String) -> Result(Package, Nil) {
  list.find(packages, fn(package) { package.hex_name == hex_name })
}

pub fn find_by_name(name: String) -> Result(Package, Nil) {
  list.find(packages, fn(package) { package.name == name })
}

pub fn roles_for(names: List(String)) -> List(Role) {
  list.flat_map(names, fn(name) {
    case find_by_name(name) {
      Ok(package) -> package.roles
      Error(_) -> []
    }
  })
}

pub fn has_role(names: List(String), role: Role) -> Bool {
  list.contains(roles_for(names), role)
}

pub fn all_categories() -> List(Category) {
  [
    Http,
    Database,
    Testing,
    Serialization,
    Utilities,
    Ui,
    Crypto,
    Logging,
    Telemetry,
  ]
}

pub fn category_label(category: Category) -> String {
  case category {
    Http -> "HTTP"
    Database -> "Database"
    Testing -> "Testing"
    Serialization -> "Serialization"
    Utilities -> "Utilities"
    Ui -> "UI"
    Crypto -> "Crypto"
    Logging -> "Logging"
    Telemetry -> "Telemetry"
  }
}
