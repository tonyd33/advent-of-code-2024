import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import rememo/memo
import simplifile

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  let stones =
    content
    |> string.trim_end
    |> string.split(" ")
    |> list.filter_map(int.base_parse(_, 10))

  // holy shit this cut the runtime to less than a second
  use cache <- memo.create()
  iterate_stones(75, stones, cache)
}

fn iterate_stones(i: Int, stones: List(Int), cache) -> Int {
  use <- memo.memoize(cache, #(i, stones))
  case i {
    1 -> blink(stones) |> list.length
    otw -> {
      stones
      |> list.map(fn(stone) { iterate_stones(otw - 1, blink([stone]), cache) })
      |> int.sum
    }
  }
}

fn blink_stone(stone: Int) -> List(Int) {
  // i can't find a logarithm function in the gleam stdlib, so we'll do this
  // by converting to a string and checking str len lmao
  let num_digits = int.to_string(stone) |> string.length
  let num_digits_modulo_2 = num_digits % 2

  case stone, num_digits_modulo_2 {
    0, _ -> [1]
    num, 0 -> {
      let assert Ok(divisor) =
        int.power(10, int.to_float(num_digits / 2)) |> result.map(float.round)
      [num / divisor, num % divisor]
    }
    num, _ -> [2024 * num]
  }
}

fn blink(stones: List(Int)) -> List(Int) {
  stones |> list.flat_map(with: blink_stone)
}
