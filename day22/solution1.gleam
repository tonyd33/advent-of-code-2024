import gleam/int
import gleam/io
import gleam/list
import gleam/string
import pprint
import simplifile
import util

const mod = 16_777_216

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  content
  |> string.trim_end
  |> string.split("\n")
  |> list.map(fn(x) { x |> int.parse |> util.result_expect })
  |> list.map(evolve_n(_, 2000))
  |> int.sum
  |> pprint.debug

  1
}

fn evolve_n(secret: Int, n: Int) {
  case n {
    0 -> secret
    _ -> evolve(secret) |> evolve_n(n - 1)
  }
}

fn evolve(secret: Int) {
  secret
  |> mix_and_prune_by(int.multiply(_, 64))
  |> mix_and_prune_by(fn(x) { x / 32 })
  |> mix_and_prune_by(int.multiply(_, 2048))
}

fn mix_and_prune_by(secret: Int, transform: fn(Int) -> Int) {
  secret
  |> transform
  |> int.bitwise_exclusive_or(secret)
  |> int.modulo(mod)
  |> util.result_expect
}
