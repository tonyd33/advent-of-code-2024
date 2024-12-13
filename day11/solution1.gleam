import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  content
  |> string.trim_end
  |> string.split(" ")
  |> list.filter_map(int.base_parse(_, 10))
  // yy24p is faster than writing a loop, fuck you
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> blink
  |> list.length
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
