import gleam/bool
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/set.{type Set}
import gleam/string
import pprint
import simplifile
import util

type Operation {
  OR
  XOR
  AND
}

type Calculation {
  Calculation(x1: String, op: Operation, x2: String, into: String)
}

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  let assert [inputs_str, calculations_str] =
    content
    |> string.trim_end
    |> string.split("\n\n")

  let inputs = parse_inputs(inputs_str)
  let calculations = parse_calculations(calculations_str)

  let result =
    calculate_iter(inputs, calculations)
    |> dict.to_list
    |> list.filter_map(fn(x) {
      use <- bool.guard(!string.starts_with(x.0, "z"), Error(Nil))
      x.0
      |> string.replace("z", "")
      |> int.parse
      |> result.map(fn(x0) { #(x0, x.1) })
    })
    |> list.sort(fn(x, y) { int.compare(x.0, y.0) })
    |> list.index_fold(0, fn(acc, value, i) {
      let num = case value.1 {
        True -> 1
        False -> 0
      }
      acc
      + {
        num
        * { int.power(2, int.to_float(i)) |> util.result_expect |> float.round }
      }
    })
    |> pprint.debug
  1
}

fn calculate_iter(repo: Dict(String, Bool), remaining: List(Calculation)) {
  let res =
    remaining
    |> list.pop_map(fn(c) {
      let x1 = dict.get(repo, c.x1)
      let x2 = dict.get(repo, c.x2)

      use x <- result.map(result.all([x1, x2]))
      let assert [x1, x2] = x
      #(c.into, calculate(x1, x2, c.op))
    })

  case res {
    Ok(#(#(into, bool), remaining)) ->
      calculate_iter(repo |> dict.insert(into, bool), remaining)
    Error(_) -> repo
  }
}

fn calculate(x1: Bool, x2: Bool, op: Operation) -> Bool {
  case op {
    AND -> x1 && x2
    OR -> x1 || x2
    XOR -> bool.exclusive_or(x1, x2)
  }
}

fn parse_inputs(str: String) -> Dict(String, Bool) {
  str
  |> string.split("\n")
  |> list.map(fn(x) {
    let assert [id, on] = x |> string.split(": ")
    #(id, on)
  })
  |> list.fold(dict.new(), fn(acc, val) {
    let #(id, on) = val
    let on_bool = case on {
      "0" -> False
      "1" -> True
      _ -> panic
    }
    dict.insert(acc, id, on_bool)
  })
}

fn parse_calculations(str: String) -> List(Calculation) {
  str
  |> string.split("\n")
  |> list.map(fn(line) {
    let assert Ok(regex) =
      regexp.from_string(
        "^([a-zA-Z0-9]+)\\s+(XOR|OR|AND)\\s+([a-zA-Z0-9]+)\\s+->\\s+([a-zA-Z0-9]+)$",
      )
    let assert [
      regexp.Match(
        _,
        [
          option.Some(x1),
          option.Some(op_str),
          option.Some(x2),
          option.Some(into),
        ],
      ),
    ] = regexp.scan(regex, line)

    let op = case op_str {
      "XOR" -> XOR
      "AND" -> AND
      "OR" -> OR
      _ -> panic
    }
    Calculation(x1, op, x2, into)
  })
}
