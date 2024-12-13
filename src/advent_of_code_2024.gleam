import gleam/io
import glint
import argv

import day9/solution1 as day9_solution1
import day9/solution2 as day9_solution2

fn input_flag() -> glint.Flag(String) {
  glint.string_flag("input")
  |> glint.flag_default("input0")
  |> glint.flag_help("Input")
}

fn run() {
  use <- glint.command_help("Runs a day's solution")

  use day_arg <- glint.named_arg("day")
  use solution_arg <- glint.named_arg("solution")

  use input <- glint.flag(input_flag())

  use named, _args, flags <- glint.command()
  let assert Ok(input) = input(flags)

  let day = day_arg(named)
  let solution = solution_arg(named)

  case day, solution {
    "9", "1" -> day9_solution1.solution(input)
    "9", "2" -> day9_solution2.solution(input)
    _, _ -> panic as "Unknown day or solution"
  }
  |> io.debug
}

pub fn main() {
  glint.new()
  |> glint.with_name("advent_of_code_2024")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: [], do: run())
  |> glint.run(argv.load().arguments)
}