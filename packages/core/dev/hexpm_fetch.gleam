@target(erlang)
import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/result
import gleam/string

@external(erlang, "timer", "sleep")
fn sleep(ms: Int) -> Nil

pub fn latest_stable_version(name: String) -> Result(String, String) {
  fetch(name, 1)
}

fn fetch(name: String, attempt: Int) -> Result(String, String) {
  let url = "https://hex.pm/api/packages/" <> name
  use req <- result.try(
    request.to(url)
    |> result.map_error(fn(_) { "invalid url for " <> name }),
  )
  let req =
    req
    |> request.prepend_header("user-agent", "bygg-update-deps/1.0")
    |> request.prepend_header("accept", "application/json")
  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(e) {
      "http error for " <> name <> ": " <> string.inspect(e)
    }),
  )
  case resp.status {
    200 ->
      decode_latest(resp.body)
      |> result.map_error(fn(_) { "decode error for " <> name })
    429 if attempt <= 1 -> {
      sleep(65_000)
      fetch(name, attempt + 1)
    }
    status ->
      Error("unexpected status " <> int.to_string(status) <> " for " <> name)
  }
}

fn decode_latest(body: String) -> Result(String, Nil) {
  let decoder =
    decode.field("latest_stable_version", decode.string, decode.success)
  json.parse(body, decoder)
  |> result.map_error(fn(_) { Nil })
}
