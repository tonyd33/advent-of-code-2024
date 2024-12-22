import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile
import util

const mod = 16_777_216

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  let seq_to_winnings_individuals =
    content
    |> string.trim_end
    |> string.split("\n")
    |> list.map(fn(x) { x |> int.parse |> util.result_expect })
    |> list.map(fn(num) {
      num
      |> evolve_n(2000, [])
      |> list.prepend(num)
      |> list.map(fn(x) { x % 10 })
      |> list.window_by_2
      |> list.map(fn(x) { #(x.1, x.1 - x.0) })
      |> list.window(4)
      |> list.fold(dict.new(), fn(acc, x) {
        let seq = x |> list.map(pair.second)
        let assert Ok(wins) = x |> list.last |> result.map(pair.first)

        case dict.has_key(acc, seq) {
          True -> acc
          False -> dict.insert(acc, seq, wins)
        }
      })
    })

  let all_sequences =
    seq_to_winnings_individuals
    |> list.fold(set.new(), fn(s, v) {
      let seqs = v |> dict.keys |> set.from_list
      set.union(s, seqs)
    })
    |> set.to_list

  let sequence_would_win = fn(seq) -> Int {
    use acc, seq_to_winning_individual <- list.fold(
      seq_to_winnings_individuals,
      0,
    )
    let win_for_monkey =
      seq_to_winning_individual |> dict.get(seq) |> result.unwrap(0)
    acc + win_for_monkey
  }

  let best =
    all_sequences
    |> list.map(sequence_would_win)
    |> list.reduce(int.max)
    |> result.unwrap(0)
  io.debug(best)

  1
}

fn evolve_n(secret: Int, n: Int, seq: List(Int)) {
  case n {
    0 -> seq |> list.reverse
    _ -> {
      let evolution = evolve(secret)
      evolve_n(evolution, n - 1, [evolution, ..seq])
    }
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
