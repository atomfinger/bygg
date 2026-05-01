import bygg/catalog
import bygg/config.{type Target, JavaScript}
import bygg/contribution_block.{type Contribution, Contribution, empty}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub type NamedContribution {
  NamedContribution(hex_name: String, contribution: Contribution)
}

pub fn collect(names: List(String)) -> List(NamedContribution) {
  list.filter_map(names, fn(name) {
    case catalog.find_by_name(name) {
      Ok(package) -> {
        let c = package.contribution()
        case c == empty() {
          True -> Error(Nil)
          False ->
            Ok(NamedContribution(hex_name: package.hex_name, contribution: c))
        }
      }
      Error(_) -> Error(Nil)
    }
  })
}

pub fn filter_for_target(
  contributions: List(NamedContribution),
  target: Target,
) -> List(NamedContribution) {
  list.map(contributions, fn(nc) {
    let c = nc.contribution
    let target_specific = case target {
      JavaScript -> c.js_only_imports
      _ -> c.erlang_only_imports
    }
    let new_imports = list.append(c.imports, target_specific)
    NamedContribution(
      ..nc,
      contribution: Contribution(
        ..c,
        imports: new_imports,
        js_only_imports: [],
        erlang_only_imports: [],
      ),
    )
  })
}

pub fn substitute(
  contributions: List(NamedContribution),
  project_name: String,
) -> List(NamedContribution) {
  list.map(contributions, fn(nc) {
    NamedContribution(
      ..nc,
      contribution: substitute_one(nc.contribution, project_name),
    )
  })
}

fn replace_all(s: String, project_name: String) -> String {
  string.replace(s, "{project_name}", project_name)
}

fn replace_in_list(items: List(String), project_name: String) -> List(String) {
  list.map(items, replace_all(_, project_name))
}

fn replace_in_option(
  o: Option(String),
  project_name: String,
) -> Option(String) {
  case o {
    None -> None
    Some(s) -> Some(replace_all(s, project_name))
  }
}

fn substitute_one(c: Contribution, project_name: String) -> Contribution {
  Contribution(
    imports: replace_in_list(c.imports, project_name),
    js_only_imports: replace_in_list(c.js_only_imports, project_name),
    erlang_only_imports: replace_in_list(c.erlang_only_imports, project_name),
    test_imports: replace_in_list(c.test_imports, project_name),
    testcontainers_test_imports: replace_in_list(
      c.testcontainers_test_imports,
      project_name,
    ),
    context_fields: replace_in_list(c.context_fields, project_name),
    config_fields: replace_in_list(c.config_fields, project_name),
    env_vars: replace_in_list(c.env_vars, project_name),
    main_body: replace_in_list(c.main_body, project_name),
    declarations: replace_in_list(c.declarations, project_name),
    otp_child_specs: replace_in_list(c.otp_child_specs, project_name),
    docker_service: replace_in_option(c.docker_service, project_name),
    docker_volumes: replace_in_list(c.docker_volumes, project_name),
    dockerfile_instructions: replace_in_list(
      c.dockerfile_instructions,
      project_name,
    ),
    test_helper: replace_in_option(c.test_helper, project_name),
    test_setup_call: replace_in_option(c.test_setup_call, project_name),
    test_container_handle: replace_in_option(
      c.test_container_handle,
      project_name,
    ),
    test_setup_fallback: replace_in_option(c.test_setup_fallback, project_name),
  )
}

pub fn resolve_conflicts(
  contributions: List(NamedContribution),
) -> List(NamedContribution) {
  let conflicted =
    contributions
    |> all_context_field_names()
    |> find_conflicted_names()
  case conflicted {
    [] -> contributions
    _ -> apply_conflict_prefixes(contributions, conflicted)
  }
}

fn all_context_field_names(
  contributions: List(NamedContribution),
) -> List(String) {
  list.flat_map(contributions, fn(nc) {
    list.filter_map(nc.contribution.context_fields, field_name)
  })
}

fn field_name(field: String) -> Result(String, Nil) {
  case string.split(field, ": ") {
    [name, ..] -> Ok(name)
    _ -> Error(Nil)
  }
}

fn find_conflicted_names(all_names: List(String)) -> List(String) {
  all_names
  |> list.filter(fn(name) {
    list.count(all_names, fn(other) { other == name }) > 1
  })
  |> list.unique()
}

fn apply_conflict_prefixes(
  contributions: List(NamedContribution),
  conflicted: List(String),
) -> List(NamedContribution) {
  list.map(contributions, fn(nc) {
    let c = nc.contribution
    let new_context_fields =
      list.map(c.context_fields, fn(f) {
        prefix_context_field(f, nc.hex_name, conflicted)
      })
    let updated =
      Contribution(
        ..c,
        context_fields: new_context_fields,
        main_body: list.map(c.main_body, prefix_refs(_, nc.hex_name, conflicted)),
        test_setup_call: option.map(c.test_setup_call, prefix_refs(
          _,
          nc.hex_name,
          conflicted,
        )),
        test_setup_fallback: option.map(c.test_setup_fallback, prefix_refs(
          _,
          nc.hex_name,
          conflicted,
        )),
        test_helper: option.map(c.test_helper, prefix_refs(
          _,
          nc.hex_name,
          conflicted,
        )),
      )
    NamedContribution(..nc, contribution: updated)
  })
}

fn prefix_context_field(
  field: String,
  hex_name: String,
  conflicted: List(String),
) -> String {
  case string.split(field, ": ") {
    [name, ..rest] ->
      case list.contains(conflicted, name) {
        True -> hex_name <> "_" <> name <> ": " <> string.join(rest, ": ")
        False -> field
      }
    _ -> field
  }
}

fn prefix_refs(
  content: String,
  hex_name: String,
  conflicted: List(String),
) -> String {
  list.fold(conflicted, content, fn(acc, name) {
    let prefixed = hex_name <> "_" <> name
    acc
    |> string.replace("Ok(" <> name <> ")", "Ok(" <> prefixed <> ")")
    |> string.replace("let " <> name <> " ", "let " <> prefixed <> " ")
  })
}

// Aggregators across all contributions

pub fn all_imports(contributions: List(NamedContribution)) -> List(String) {
  list.flat_map(contributions, fn(nc) { nc.contribution.imports })
}

pub fn all_test_imports(
  contributions: List(NamedContribution),
  has_testcontainers: Bool,
) -> List(String) {
  let regular =
    list.flat_map(contributions, fn(nc) { nc.contribution.test_imports })
  case has_testcontainers {
    False -> regular
    True ->
      list.append(
        regular,
        list.flat_map(contributions, fn(nc) {
          nc.contribution.testcontainers_test_imports
        }),
      )
  }
}

pub fn all_context_fields(
  contributions: List(NamedContribution),
) -> List(String) {
  list.flat_map(contributions, fn(nc) { nc.contribution.context_fields })
}

pub fn all_config_fields(
  contributions: List(NamedContribution),
) -> List(String) {
  list.flat_map(contributions, fn(nc) { nc.contribution.config_fields })
}

pub fn all_env_vars(contributions: List(NamedContribution)) -> List(String) {
  list.flat_map(contributions, fn(nc) { nc.contribution.env_vars })
}

pub fn all_main_body(contributions: List(NamedContribution)) -> List(String) {
  list.flat_map(contributions, fn(nc) { nc.contribution.main_body })
}

pub fn all_declarations(
  contributions: List(NamedContribution),
) -> List(String) {
  list.flat_map(contributions, fn(nc) { nc.contribution.declarations })
}

pub fn all_otp_child_specs(
  contributions: List(NamedContribution),
) -> List(String) {
  list.flat_map(contributions, fn(nc) { nc.contribution.otp_child_specs })
}

pub fn all_docker_services(
  contributions: List(NamedContribution),
) -> List(String) {
  list.filter_map(contributions, fn(nc) {
    option.to_result(nc.contribution.docker_service, Nil)
  })
}

pub fn all_docker_volumes(
  contributions: List(NamedContribution),
) -> List(String) {
  list.flat_map(contributions, fn(nc) { nc.contribution.docker_volumes })
}

pub fn all_dockerfile_instructions(
  contributions: List(NamedContribution),
) -> List(String) {
  list.flat_map(contributions, fn(nc) {
    nc.contribution.dockerfile_instructions
  })
}

pub fn all_test_helpers(
  contributions: List(NamedContribution),
) -> List(String) {
  list.filter_map(contributions, fn(nc) {
    option.to_result(nc.contribution.test_helper, Nil)
  })
}

pub fn all_test_setup_calls(
  contributions: List(NamedContribution),
) -> List(String) {
  list.filter_map(contributions, fn(nc) {
    option.to_result(nc.contribution.test_setup_call, Nil)
  })
}

pub fn all_test_container_handles(
  contributions: List(NamedContribution),
) -> List(String) {
  list.filter_map(contributions, fn(nc) {
    option.to_result(nc.contribution.test_container_handle, Nil)
  })
}

pub fn all_test_setup_fallbacks(
  contributions: List(NamedContribution),
) -> List(String) {
  list.filter_map(contributions, fn(nc) {
    option.to_result(nc.contribution.test_setup_fallback, Nil)
  })
}
