import gleam/io
import glint
import argv

import day9/solution1 as day9_solution1
import day9/solution2 as day9_solution2
import day11/solution1 as day11_solution1
import day11/solution2 as day11_solution2
import day12/solution1 as day12_solution1
import day12/solution2 as day12_solution2
import day13/solution1 as day13_solution1
import day13/solution2 as day13_solution2
import day14/solution1 as day14_solution1
import day15/solution1 as day15_solution1
import day15/solution2 as day15_solution2
import day16/solution1 as day16_solution1
import day16/solution2 as day16_solution2
import day17/solution1 as day17_solution1
import day18/solution1 as day18_solution1
import day18/solution2 as day18_solution2
import day19/solution1 as day19_solution1
import day19/solution2 as day19_solution2
import day20/solution1 as day20_solution1
import day20/solution2 as day20_solution2
import day21/solution1 as day21_solution1
import day21/solution2 as day21_solution2

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
    "11", "1" -> day11_solution1.solution(input)
    "11", "2" -> day11_solution2.solution(input)
    "12", "1" -> day12_solution1.solution(input)
    "12", "2" -> day12_solution2.solution(input)
    "13", "1" -> day13_solution1.solution(input)
    "13", "2" -> day13_solution2.solution(input)
    "14", "1" -> day14_solution1.solution(input)
    "15", "1" -> day15_solution1.solution(input)
    "15", "2" -> day15_solution2.solution(input)
    "16", "1" -> day16_solution1.solution(input)
    "16", "2" -> day16_solution2.solution(input)
    "17", "1" -> day17_solution1.solution(input)
    "18", "1" -> day18_solution1.solution(input)
    "18", "2" -> day18_solution2.solution(input)
    "19", "1" -> day19_solution1.solution(input)
    "19", "2" -> day19_solution2.solution(input)
    "20", "1" -> day20_solution1.solution(input)
    "20", "2" -> day20_solution2.solution(input)
    "21", "1" -> day21_solution1.solution(input)
    "21", "2" -> day21_solution2.solution(input)
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
