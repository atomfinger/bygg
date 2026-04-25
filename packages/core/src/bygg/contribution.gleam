import bygg/catalog
import bygg/code_block.{
  type CodeBlock, type CodeSlot, Always, CodeBlock, ContextField, MainBody,
  WhenTarget,
}
import bygg/config.{type Target}
import gleam/list
import gleam/string

pub type CodeContribution {
  CodeContribution(hex_name: String, blocks: List(CodeBlock))
}

pub fn collect(names: List(String)) -> List(CodeContribution) {
  list.filter_map(names, fn(name) {
    case catalog.find_by_name(name) {
      Ok(package) ->
        case package.code_blocks {
          [] -> Error(Nil)
          blocks ->
            Ok(CodeContribution(hex_name: package.hex_name, blocks: blocks))
        }
      Error(_) -> Error(Nil)
    }
  })
}

pub fn filter_for_target(
  contributions: List(CodeContribution),
  target: Target,
) -> List(CodeContribution) {
  list.map(contributions, fn(contribution) {
    CodeContribution(
      ..contribution,
      blocks: list.filter(contribution.blocks, fn(block) {
        case block.condition {
          Always -> True
          WhenTarget(target_to_check) -> target_to_check == target
        }
      }),
    )
  })
}

pub fn blocks_for(
  contributions: List(CodeContribution),
  slot: CodeSlot,
) -> List(String) {
  list.flat_map(contributions, fn(contribution) {
    list.filter_map(contribution.blocks, fn(block) {
      case block {
        CodeBlock(block_slot, content, _) if block_slot == slot -> Ok(content)
        _ -> Error(Nil)
      }
    })
  })
}

pub fn substitute(
  contributions: List(CodeContribution),
  project_name: String,
) -> List(CodeContribution) {
  list.map(contributions, fn(contribution) {
    CodeContribution(
      ..contribution,
      blocks: list.map(contribution.blocks, fn(block) {
        CodeBlock(
          ..block,
          content: string.replace(block.content, "{project_name}", project_name),
        )
      }),
    )
  })
}

pub fn resolve_conflicts(
  contributions: List(CodeContribution),
) -> List(CodeContribution) {
  let conflicted =
    contributions
    |> collect_context_field_names()
    |> find_conflicted_names()
  case conflicted {
    [] -> contributions
    _ -> apply_conflict_prefixes(contributions, conflicted)
  }
}

fn collect_context_field_names(
  contributions: List(CodeContribution),
) -> List(String) {
  list.flat_map(contributions, fn(contribution) {
    blocks_for([contribution], ContextField)
    |> list.filter_map(fn(content) {
      case string.split(content, ": ") {
        [name, ..] -> Ok(name)
        _ -> Error(Nil)
      }
    })
  })
}

fn find_conflicted_names(all_names: List(String)) -> List(String) {
  all_names
  |> list.filter(fn(name) {
    list.count(all_names, fn(name_to_count) { name_to_count == name }) > 1
  })
  |> list.unique()
}

fn apply_conflict_prefixes(
  contributions: List(CodeContribution),
  conflicted: List(String),
) -> List(CodeContribution) {
  list.map(contributions, fn(contribution) {
    CodeContribution(
      ..contribution,
      blocks: list.map(contribution.blocks, fn(block) {
        case block.slot {
          ContextField ->
            prefix_context_field(block, contribution.hex_name, conflicted)
          MainBody ->
            prefix_main_body_refs(block, contribution.hex_name, conflicted)
          _ -> block
        }
      }),
    )
  })
}

fn prefix_context_field(
  block: CodeBlock,
  hex_name: String,
  conflicted: List(String),
) -> CodeBlock {
  case string.split(block.content, ": ") {
    [name, ..rest] ->
      case list.contains(conflicted, name) {
        True ->
          CodeBlock(
            ContextField,
            hex_name <> "_" <> name <> ": " <> string.join(rest, ": "),
            block.condition,
          )
        False -> block
      }
    _ -> block
  }
}

fn prefix_main_body_refs(
  block: CodeBlock,
  hex_name: String,
  conflicted: List(String),
) -> CodeBlock {
  list.fold(conflicted, block, fn(acc_block, name) {
    let prefixed = hex_name <> "_" <> name
    CodeBlock(
      MainBody,
      acc_block.content
        |> string.replace("Ok(" <> name <> ")", "Ok(" <> prefixed <> ")")
        |> string.replace("let " <> name <> " ", "let " <> prefixed <> " "),
      acc_block.condition,
    )
  })
}
