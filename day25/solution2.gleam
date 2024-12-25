import gleam/io
import gleam/list
import gleam/string
import pprint
import simplifile
import util

type Schematic {
  Key(sizes: List(Int))
  Lock(sizes: List(Int))
}

const size = 6

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  content
  |> string.split("\n\n")
  |> list.map(fn(x) {
    let split = x |> string.split("\n") |> list.map(string.to_graphemes)
    case
      split
      |> list.first
      |> util.result_expect
      |> list.first
      |> util.result_expect
    {
      "#" -> {
        Lock(
          split
          |> list.transpose
          |> list.map(fn(x) { { x |> list.count(fn(y) { y == "#" }) } - 1 }),
        )
      }
      "." ->
        Key(
          split
          |> list.transpose
          |> list.map(fn(x) { { x |> list.count(fn(y) { y == "#" }) } - 1 }),
        )
      _ -> panic
    }
  })
  |> list.combination_pairs
  |> list.filter(test_pair)
  |> list.length
  |> pprint.debug

  1
}

fn test_pair(x: #(Schematic, Schematic)) {
  let #(p1, p2) = x
  case p1, p2 {
    Lock(p1_sizes), Key(p2_sizes) | Key(p1_sizes), Lock(p2_sizes) ->
      list.map2(p1_sizes, p2_sizes, fn(a1, a2) { { a1 + a2 } <= { size - 1 } })
      |> list.all(fn(x) { x })
    _, _ -> False
  }
}
