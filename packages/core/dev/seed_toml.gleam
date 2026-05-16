import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Entry {
  Entry(name: String, constraint: String)
}

pub fn read(path: String) -> Result(List(Entry), simplifile.FileError) {
  use content <- result.try(simplifile.read(path))
  content
  |> string.split("\n")
  |> parse_lines(False, [])
  |> Ok
}

pub fn write(
  path: String,
  updates: List(#(String, String)),
) -> Result(Nil, simplifile.FileError) {
  use content <- result.try(simplifile.read(path))
  content
  |> string.split("\n")
  |> list.map(fn(line) { apply_update(line, updates) })
  |> string.join("\n")
  |> simplifile.write(path, _)
}

fn parse_lines(
  lines: List(String),
  in_deps: Bool,
  acc: List(Entry),
) -> List(Entry) {
  case lines {
    [] -> list.reverse(acc)
    [line, ..rest] -> {
      let trimmed = string.trim(line)
      case trimmed {
        "[dependencies]" | "[dev_dependencies]" -> parse_lines(rest, True, acc)
        _ -> {
          let new_in_deps = case string.starts_with(trimmed, "[") {
            True -> False
            False -> in_deps
          }
          case in_deps, string.starts_with(trimmed, "#") {
            True, False ->
              case parse_entry(trimmed) {
                Ok(entry) -> parse_lines(rest, new_in_deps, [entry, ..acc])
                Error(_) -> parse_lines(rest, new_in_deps, acc)
              }
            _, _ -> parse_lines(rest, new_in_deps, acc)
          }
        }
      }
    }
  }
}

fn parse_entry(line: String) -> Result(Entry, Nil) {
  use #(name, rest) <- result.try(string.split_once(line, "="))
  let constraint =
    rest
    |> string.trim
    |> string.drop_start(1)
    |> string.drop_end(1)
  Ok(Entry(string.trim(name), constraint))
}

fn apply_update(line: String, updates: List(#(String, String))) -> String {
  let trimmed = string.trim(line)
  case string.split_once(trimmed, "=") {
    Ok(#(name, _)) ->
      case list.key_find(updates, string.trim(name)) {
        Ok(new_constraint) ->
          string.trim(name) <> " = \"" <> new_constraint <> "\""
        Error(_) -> line
      }
    Error(_) -> line
  }
}
