@target(erlang)
import argv
import gleam/io
import gleam/list
import gleam/string
import seed_toml
import simplifile

const seed_path = "../../scripts/seed/gleam.toml"

const catalog_path = "src/bygg/catalog.gleam"

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

pub fn main() {
  let args = argv.load().arguments
  case args {
    ["--check"] -> run(check_mode: True)
    ["--update"] -> run(check_mode: False)
    _ -> {
      io.println("usage: gleam run -m sync_catalog -- --check | --update")
      halt(1)
    }
  }
}

fn run(check_mode check_mode: Bool) {
  let seed = case seed_toml.read(seed_path) {
    Ok(entries) -> entries
    Error(_) -> {
      io.println("error: could not read " <> seed_path)
      halt(1)
      []
    }
  }

  let catalog_content = case simplifile.read(catalog_path) {
    Ok(c) -> c
    Error(_) -> {
      io.println("error: could not read " <> catalog_path)
      halt(1)
      ""
    }
  }

  let mismatches = find_mismatches(catalog_content, seed)

  case mismatches {
    [] ->
      io.println(
        "✓ all version constraints in catalog.gleam match scripts/seed/gleam.toml",
      )
    _ ->
      case check_mode {
        True -> {
          io.println("✗ version constraint mismatches found:\n")
          list.each(mismatches, fn(m) {
            let #(name, seed_c, cat_c) = m
            io.println(
              "  "
              <> name
              <> "\n    seed:    "
              <> seed_c
              <> "\n    catalog: "
              <> cat_c
              <> "\n",
            )
          })
          io.println(
            "run: cd packages/core && gleam run -m sync_catalog -- --update",
          )
          halt(1)
        }
        False -> {
          let updates =
            list.map(mismatches, fn(m) {
              let #(name, seed_c, _) = m
              #(name, seed_c)
            })
          let new_content = rewrite_catalog(catalog_content, updates)
          case simplifile.write(catalog_path, new_content) {
            Ok(_) ->
              list.each(mismatches, fn(m) {
                let #(name, seed_c, cat_c) = m
                io.println(
                  "updated " <> name <> ": " <> cat_c <> " → " <> seed_c,
                )
              })
            Error(_) -> {
              io.println("error: could not write " <> catalog_path)
              halt(1)
            }
          }
        }
      }
  }
}

fn find_mismatches(
  catalog: String,
  seed: List(seed_toml.Entry),
) -> List(#(String, String, String)) {
  catalog
  |> string.split("\n")
  |> find_loop("", seed, [])
  |> list.reverse
}

fn find_loop(
  lines: List(String),
  current_hex_name: String,
  seed: List(seed_toml.Entry),
  acc: List(#(String, String, String)),
) -> List(#(String, String, String)) {
  case lines {
    [] -> acc
    [line, ..rest] -> {
      let trimmed = string.trim(line)
      case extract_field(trimmed, "hex_name: \"") {
        Ok(name) -> find_loop(rest, name, seed, acc)
        Error(_) ->
          case
            current_hex_name != "",
            extract_field(trimmed, "default_constraint: \"")
          {
            True, Ok(cat_c) -> {
              let already_seen =
                list.any(acc, fn(m) {
                  let #(n, _, _) = m
                  n == current_hex_name
                })
              let acc = case
                already_seen,
                list.find(seed, fn(e) { e.name == current_hex_name })
              {
                False, Ok(entry) if entry.constraint != cat_c -> [
                  #(current_hex_name, entry.constraint, cat_c),
                  ..acc
                ]
                _, _ -> acc
              }
              find_loop(rest, "", seed, acc)
            }
            _, _ -> find_loop(rest, current_hex_name, seed, acc)
          }
      }
    }
  }
}

fn rewrite_catalog(
  catalog: String,
  updates: List(#(String, String)),
) -> String {
  catalog
  |> string.split("\n")
  |> rewrite_loop("", updates, [])
  |> list.reverse
  |> string.join("\n")
}

fn rewrite_loop(
  lines: List(String),
  current_hex_name: String,
  updates: List(#(String, String)),
  acc: List(String),
) -> List(String) {
  case lines {
    [] -> acc
    [line, ..rest] -> {
      let trimmed = string.trim(line)
      case extract_field(trimmed, "hex_name: \"") {
        Ok(name) -> rewrite_loop(rest, name, updates, [line, ..acc])
        Error(_) ->
          case
            current_hex_name != "",
            extract_field(trimmed, "default_constraint: \"")
          {
            True, Ok(cat_c) -> {
              let new_line = case list.key_find(updates, current_hex_name) {
                Ok(new_c) ->
                  string.replace(
                    line,
                    "default_constraint: \"" <> cat_c <> "\"",
                    "default_constraint: \"" <> new_c <> "\"",
                  )
                Error(_) -> line
              }
              rewrite_loop(rest, "", updates, [new_line, ..acc])
            }
            _, _ -> rewrite_loop(rest, current_hex_name, updates, [line, ..acc])
          }
      }
    }
  }
}

fn extract_field(line: String, prefix: String) -> Result(String, Nil) {
  case string.starts_with(line, prefix) {
    False -> Error(Nil)
    True -> {
      let after = string.drop_start(line, string.length(prefix))
      case string.split_once(after, "\"") {
        Ok(#(value, _)) -> Ok(value)
        Error(_) -> Error(Nil)
      }
    }
  }
}
