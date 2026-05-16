@target(erlang)
import dep_constraints
import gleam/io
import gleam/list
import hexpm_fetch
import seed_toml

const seed_path = "../../scripts/seed/gleam.toml"

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

pub fn main() {
  let entries = case seed_toml.read(seed_path) {
    Ok(e) -> e
    Error(_) -> {
      io.println("error: could not read " <> seed_path)
      halt(1)
      []
    }
  }

  let #(updates, had_errors) =
    list.fold(entries, #([], False), fn(acc, entry) {
      let #(updates, had_errors) = acc
      case hexpm_fetch.latest_stable_version(entry.name) {
        Error(msg) -> {
          io.println("ERROR " <> entry.name <> ": " <> msg)
          #(updates, True)
        }
        Ok(latest) ->
          case dep_constraints.parse(entry.constraint) {
            Error(_) -> {
              io.println(
                "SKIPPED " <> entry.name <> ": unrecognised constraint format",
              )
              #(updates, had_errors)
            }
            Ok(current) ->
              case dep_constraints.update(current, latest) {
                Error(_) -> {
                  io.println(
                    "SKIPPED "
                    <> entry.name
                    <> ": already at latest ("
                    <> latest
                    <> ")",
                  )
                  #(updates, had_errors)
                }
                Ok(new_constraint) -> {
                  let new_str = dep_constraints.to_string(new_constraint)
                  io.println(
                    "UPDATED "
                    <> entry.name
                    <> ": "
                    <> entry.constraint
                    <> " → "
                    <> new_str,
                  )
                  #([#(entry.name, new_str), ..updates], had_errors)
                }
              }
          }
      }
    })

  case updates {
    [] -> Nil
    _ ->
      case seed_toml.write(seed_path, updates) {
        Ok(_) -> Nil
        Error(_) -> {
          io.println("error: could not write " <> seed_path)
          halt(1)
        }
      }
  }

  case had_errors {
    True -> halt(1)
    False -> Nil
  }
}
