import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub type Version {
  Version(major: Int, minor: Int, patch: Int)
}

pub type Constraint {
  Constraint(floor: Version, ceiling: Version)
}

pub fn parse(s: String) -> Result(Constraint, Nil) {
  case string.split(s, " and ") {
    [floor_part, ceiling_part] -> {
      use floor <- result.try(parse_bound(floor_part, ">="))
      use ceiling <- result.try(parse_bound(ceiling_part, "<"))
      Ok(Constraint(floor, ceiling))
    }
    _ -> Error(Nil)
  }
}

pub fn to_string(c: Constraint) -> String {
  ">= "
  <> version_to_string(c.floor)
  <> " and < "
  <> version_to_string(c.ceiling)
}

pub fn update(current: Constraint, latest: String) -> Result(Constraint, Nil) {
  use latest_v <- result.try(parse_version(latest))
  case compare(latest_v, current.floor), compare(latest_v, current.ceiling) {
    Lt, _ -> Error(Nil)
    Eq, _ -> Error(Nil)
    Gt, Lt -> Ok(Constraint(latest_v, current.ceiling))
    Gt, _ -> Ok(Constraint(latest_v, Version(latest_v.major + 1, 0, 0)))
  }
}

fn parse_bound(s: String, prefix: String) -> Result(Version, Nil) {
  s
  |> string.trim
  |> string.drop_start(string.length(prefix))
  |> string.trim
  |> parse_version
}

fn parse_version(s: String) -> Result(Version, Nil) {
  case string.split(string.trim(s), ".") {
    [maj, min, patch] -> {
      use major <- result.try(int.parse(maj))
      use minor <- result.try(int.parse(min))
      use p <- result.try(int.parse(patch))
      Ok(Version(major, minor, p))
    }
    _ -> Error(Nil)
  }
}

fn version_to_string(v: Version) -> String {
  int.to_string(v.major)
  <> "."
  <> int.to_string(v.minor)
  <> "."
  <> int.to_string(v.patch)
}

type Order {
  Lt
  Eq
  Gt
}

fn compare(a: Version, b: Version) -> Order {
  let pairs = [#(a.major, b.major), #(a.minor, b.minor), #(a.patch, b.patch)]
  list.fold_until(pairs, Eq, fn(_, pair) {
    case pair.0 - pair.1 {
      0 -> list.Continue(Eq)
      n if n < 0 -> list.Stop(Lt)
      _ -> list.Stop(Gt)
    }
  })
}
