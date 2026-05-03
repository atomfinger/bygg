import bygg/catalog/carrote as carrote_pkg
import bygg/catalog/franz as franz_pkg
import bygg/catalog/lustre_browser_app as lustre_browser_app_pkg
import bygg/catalog/lustre_component as lustre_component_pkg
import bygg/catalog/lustre_server_component as lustre_sc_pkg
import bygg/catalog/pog as pog_pkg
import bygg/catalog/shork as shork_pkg
import bygg/catalog/sqlight as sqlight_pkg
import bygg/catalog/valkyrie as valkyrie_pkg
import bygg/config.{type Target, Erlang, JavaScript}
import bygg/contribution_block.{type Contribution, empty}
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
  Messaging
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
    contribution: fn() -> Contribution,
    is_hidden: Bool,
    is_disabled: Bool,
    repository: String,
  )
}

fn default(
  name name: String,
  hex_name hex_name: String,
  description description: String,
  default_constraint default_constraint: String,
) {
  Package(
    name: name,
    hex_name: hex_name,
    description: description,
    default_constraint: default_constraint,
    targets: BothTargets,
    min_gleam_version: "1.0.0",
    category: Utilities,
    dev_only: False,
    requires_otp: False,
    roles: [],
    contribution: empty,
    is_hidden: False,
    is_disabled: False,
    repository: "https://hex.pm/packages/" <> hex_name,
  )
}

pub fn packages() -> List(Package) {
  [
    Package(
      ..default(
        name: "gleam_stdlib",
        hex_name: "gleam_stdlib",
        description: "The Gleam standard library",
        default_constraint: ">= 1.0.0 and < 2.0.0",
      ),
      is_hidden: True,
      repository: "https://github.com/gleam-lang/stdlib",
    ),
    Package(
      ..default(
        name: "gleam_erlang",
        hex_name: "gleam_erlang",
        description: "Gleam bindings to Erlang/OTP",
        default_constraint: ">= 1.0.0 and < 2.0.0",
      ),
      targets: ErlangOnly,
      repository: "https://github.com/gleam-lang/erlang",
    ),
    Package(
      ..default(
        name: "gleam_otp",
        hex_name: "gleam_otp",
        description: "OTP actors and supervisors for Gleam",
        default_constraint: ">= 1.0.0 and < 2.0.0",
      ),
      targets: ErlangOnly,
      repository: "https://github.com/gleam-lang/otp",
    ),
    Package(
      ..default(
        name: "envoy",
        hex_name: "envoy",
        description: "Environment variable access for Gleam",
        default_constraint: ">= 1.0.0 and < 2.0.0",
      ),
      repository: "https://github.com/lpil/envoy",
      is_hidden: True,
    ),
    Package(
      ..default(
        name: "wisp",
        hex_name: "wisp",
        description: "A practical Gleam web framework",
        default_constraint: ">= 2.0.0 and < 3.0.0",
      ),
      targets: ErlangOnly,
      category: Http,
      roles: [WebFramework],
      repository: "https://github.com/gleam-wisp/wisp",
    ),
    Package(
      ..default(
        name: "mist",
        hex_name: "mist",
        description: "HTTP/1.1 and HTTP/2 server for Gleam",
        default_constraint: ">= 6.0.0 and < 7.0.0",
      ),
      targets: ErlangOnly,
      category: Http,
      roles: [HttpServer],
      repository: "https://github.com/rawhat/mist",
    ),
    Package(
      ..default(
        name: "gleam_http",
        hex_name: "gleam_http",
        description: "HTTP types for Gleam (request, response, method)",
        default_constraint: ">= 4.0.0 and < 5.0.0",
      ),
      category: Http,
      repository: "https://github.com/gleam-lang/http",
    ),
    Package(
      ..default(
        name: "sqlight",
        hex_name: "sqlight",
        description: "SQLite client for Gleam",
        default_constraint: ">= 1.0.0 and < 2.0.0",
      ),
      targets: ErlangOnly,
      category: Database,
      roles: [DatabaseClient],
      contribution: sqlight_pkg.contribution,
      repository: "https://github.com/lpil/sqlight",
    ),
    Package(
      ..default(
        name: "valkyrie",
        hex_name: "valkyrie",
        description: "A lightweight, high performance Gleam client for Valkey, KeyDB, Redis, Dragonfly and other Redis-compatible databases.",
        default_constraint: ">= 4.0.0 and < 5.0.0",
      ),
      targets: ErlangOnly,
      category: Database,
      requires_otp: True,
      roles: [DatabaseClient],
      contribution: valkyrie_pkg.contribution,
      repository: "https://github.com/Pevensie/valkyrie",
    ),
    Package(
      ..default(
        name: "gleam_json",
        hex_name: "gleam_json",
        description: "JSON encoding and decoding for Gleam",
        default_constraint: ">= 3.0.0 and < 4.0.0",
      ),
      category: Serialization,
      repository: "https://github.com/gleam-lang/json",
    ),
    Package(
      ..default(
        name: "lustre",
        hex_name: "lustre",
        description: "Build browser SPAs with Lustre (lustre.simple / lustre.application)",
        default_constraint: ">= 5.6.0 and < 6.0.0",
      ),
      targets: JavaScriptOnly,
      category: Ui,
      roles: [FrontendFramework],
      contribution: lustre_browser_app_pkg.contribution,
      repository: "https://github.com/lustre-labs/lustre",
    ),
    Package(
      ..default(
        name: "lustre_component",
        hex_name: "lustre",
        description: "Build reusable Web Components with Lustre (lustre.component / element.register)",
        default_constraint: ">= 5.6.0 and < 6.0.0",
      ),
      targets: JavaScriptOnly,
      category: Ui,
      roles: [LustreComponent],
      contribution: lustre_component_pkg.contribution,
      repository: "https://github.com/lustre-labs/lustre",
    ),
    Package(
      ..default(
        name: "lustre_server_component",
        hex_name: "lustre",
        description: "Run Lustre on Erlang/OTP and stream DOM patches to the browser",
        default_constraint: ">= 5.6.0 and < 6.0.0",
      ),
      targets: ErlangOnly,
      category: Ui,
      roles: [LustreServerComponent],
      contribution: lustre_sc_pkg.contribution,
      repository: "https://github.com/lustre-labs/lustre",
    ),
    Package(
      ..default(
        name: "lustre_dev_tools",
        hex_name: "lustre_dev_tools",
        description: "Dev server and build tooling for Lustre browser apps",
        default_constraint: ">= 2.3.0 and < 3.0.0",
      ),
      targets: JavaScriptOnly,
      category: Ui,
      dev_only: True,
      repository: "https://github.com/lustre-labs/dev-tools",
    ),
    Package(
      ..default(
        name: "unitest",
        hex_name: "unitest",
        description: "Test runner for Gleam",
        default_constraint: ">= 1.5.0 and < 2.0.0",
      ),
      category: Testing,
      dev_only: True,
      is_hidden: True,
      repository: "https://github.com/jtdowney/unitest",
    ),
    Package(
      ..default(
        name: "pog",
        hex_name: "pog",
        description: "PostgreSQL client for Gleam",
        default_constraint: ">= 4.0.0 and < 5.0.0",
      ),
      targets: ErlangOnly,
      category: Database,
      requires_otp: True,
      roles: [DatabaseClient],
      contribution: pog_pkg.contribution,
      repository: "https://github.com/gleam-lang/pog",
    ),
    Package(
      ..default(
        name: "franz",
        hex_name: "franz",
        description: "Apache Kafka client for Gleam",
        default_constraint: ">= 3.0.0 and < 4.0.0",
      ),
      targets: ErlangOnly,
      category: Messaging,
      contribution: franz_pkg.contribution,
      repository: "https://github.com/renatillas/franz",
    ),
    Package(
      ..default(
        name: "testcontainers_gleam",
        hex_name: "testcontainers_gleam",
        description: "Testcontainers for Gleam",
        default_constraint: ">= 2.0.0 and < 3.0.0",
      ),
      targets: ErlangOnly,
      category: Testing,
      dev_only: True,
      repository: "https://github.com/darky/testcontainers-gleam",
    ),
    Package(
      ..default(
        name: "shork",
        hex_name: "shork",
        description: "MySQL / MariaDB database client",
        default_constraint: ">= 1.5.0 and < 2.0.0",
      ),
      targets: ErlangOnly,
      category: Database,
      roles: [DatabaseClient],
      contribution: shork_pkg.contribution,
      repository: "https://github.com/gleam-lang/shork",
    ),
    Package(
      ..default(
        name: "carotte",
        hex_name: "carotte",
        description: "A type-safe RabbitMQ client for Gleam",
        default_constraint: ">= 5.0.0 and < 6.0.0",
      ),
      targets: ErlangOnly,
      category: Messaging,
      requires_otp: True,
      contribution: carrote_pkg.contribution,
      repository: "https://github.com/renatillas/carotte",
    ),
  ]
}

pub fn for_target(target: Target) -> List(Package) {
  list.filter(packages(), fn(package) {
    case package.is_disabled, package.targets, target {
      True, _, _ -> False
      _, BothTargets, _ -> True
      _, ErlangOnly, Erlang -> True
      _, JavaScriptOnly, JavaScript -> True
      _, _, _ -> False
    }
  })
}

pub fn by_category(category: Category) -> List(Package) {
  list.filter(packages(), fn(package) { package.category == category })
}

pub fn find_by_hex_name(hex_name: String) -> Result(Package, Nil) {
  list.find(packages(), fn(package) { package.hex_name == hex_name })
}

pub fn find_by_name(name: String) -> Result(Package, Nil) {
  list.find(packages(), fn(package) { package.name == name })
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
    Messaging,
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
    Messaging -> "Messaging"
    Ui -> "UI"
    Crypto -> "Crypto"
    Logging -> "Logging"
    Telemetry -> "Telemetry"
  }
}
