import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import internal/ets/memo
import simplifile

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  let assert [patterns_str, designs_str] =
    content
    |> string.trim_end
    |> string.split("\n\n")

  let patterns = parse_patterns(patterns_str)
  let designs = parse_designs(designs_str)
  use cache <- memo.create()

  designs
  |> list.map(towel_ways(_, patterns, cache))
  |> list.fold(0, int.add)
}

fn towel_ways(
  towel: String,
  available_patterns: List(String),
  // path: List(String),
  cache,
) -> Int {
  use <- memo.memoize(cache, #(towel))
  use <- bool.guard(when: string.length(towel) == 0, return: 1)

  available_patterns
  |> list.map(fn(pattern) {
    let does_start = string.starts_with(towel, pattern)
    use <- bool.guard(when: !does_start, return: 0)
    towel_ways(
      towel |> string.drop_start(string.length(pattern)),
      available_patterns,
      cache,
    )
  })
  |> int.sum
}

// fn towel_ways(
// towel: String,
// available_patterns: List(String),
// path: List(String),
// cache,
// ) -> List(List(String)) {
// use <- memo.memoize(cache, #(towel, path))
// use <- bool.guard(when: string.length(towel) == 0, return: [path])

// available_patterns
// |> list.flat_map(fn(pattern) {
// let does_start = string.starts_with(towel, pattern)
// use <- bool.guard(when: !does_start, return: [path])
// towel_ways(
// towel |> string.drop_start(string.length(pattern)),
// available_patterns,
// path,
// cache,
// )
// |> list.map(fn(p) { [towel, ..p] })
// })
// |> list.filter(fn(p) { list.length(p) > 0 })
// }

fn parse_patterns(str) {
  str |> string.split(", ")
}

fn parse_designs(str) {
  str |> string.split("\n")
}
