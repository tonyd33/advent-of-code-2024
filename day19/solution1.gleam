import gleam/bool
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
  |> list.filter(can_make_towel(_, patterns, cache))
  |> list.length
  |> io.debug

  1
}

fn can_make_towel(
  towel: String,
  available_patterns: List(String),
  cache,
) -> Bool {
  use <- memo.memoize(cache, #(towel))
  use <- bool.guard(when: string.length(towel) == 0, return: True)

  available_patterns
  |> list.any(fn(pattern) {
    let does_start = string.starts_with(towel, pattern)
    case does_start {
      True ->
        can_make_towel(
          towel |> string.drop_start(string.length(pattern)),
          available_patterns,
          cache,
        )

      False -> False
    }
  })
}

fn parse_patterns(str) {
  str |> string.split(", ")
}

fn parse_designs(str) {
  str |> string.split("\n")
}
