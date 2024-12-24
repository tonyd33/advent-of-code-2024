import gleam/bool
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/regexp
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder.{type Yielder}
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

type BinaryTree(a) {
  Node(into: a, left: BinaryTree(a), op: Operation, right: BinaryTree(a))
  Leaf(into: a)
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
  let calculations_map =
    calculations
    |> list.map(fn(x) { #(x.into, x) })
    |> dict.from_list
  let calculations_trees =
    calculations
    |> list.filter(fn(x) { x.into |> string.starts_with("z") })
    |> list.map(fn(x) { #(x.into, to_tree(calculations_map, x.into)) })
    |> dict.from_list

  // ok what if we just try to figure out what changes will make it addition
  // first and then backtrack from there

  let repo = calculate_iter(inputs, calculations)
  let expected = repo |> expected_result |> in_binary |> yielder.from_list
  let actual = repo |> get_prefixed("z") |> in_binary |> yielder.from_list

  let diffs =
    list.range(1, int.max(yielder.length(expected), yielder.length(actual)))
    |> list.fold([], fn(acc, i) {
      let expected_i = {
        expected |> yielder.at(i) |> result.unwrap(False)
      }
      let actual_i = {
        actual |> yielder.at(i) |> result.unwrap(False)
      }
      case expected_i != actual_i {
        True -> [
          #({ "z" <> { int.to_string(i) |> string.pad_start(2, "0") } }, #(
            expected_i,
            actual_i,
          )),
          ..acc
        ]
        False -> acc
      }
    })
    |> pprint.debug

  // map from one of the z's to all of the depending calculations
  let potentials =
    diffs
    |> list.map(fn(v) {
      let #(x, _) = v
      #(
        x,
        fold_tree_depth(
          calculations_trees |> dict.get(x) |> util.result_expect,
          [],
          fn(acc, val, depth) { [#(depth, val), ..acc] },
          0,
        )
          |> list.filter_map(fn(x) {
            calculations_map
            |> dict.get(x.1)
            |> result.map(fn(y) { #(x.0, y) })
          })
          |> set.from_list,
      )
    })
    |> dict.from_list
  // |> pprint.debug

  let potentials_and_depth =
    potentials
    |> dict.fold(set.new(), fn(acc, _, v) { set.union(acc, v) })
    |> set.to_list

  // let potentials_inverse =
  // potentials
  // |> dict.fold(set.new(), fn(acc, _, v) { set.union(acc, v) })
  // |> set.to_list
  // // which ones does this wire matter for?
  // |> list.map(fn(x) {
  // #(
  // x.into,
  // potentials
  // |> dict.filter(fn(_, v) { set.contains(v, x) })
  // |> dict.keys
  // |> set.from_list,
  // )
  // })
  // |> pprint.debug
  // // filter down for combinations that actually cover the entire diff
  // |> list.combinations(8)
  // |> fn(x) {
  // pprint.debug(list.length(x))
  // x
  // }
  // |> list.filter(fn(comb) {
  // let covering =
  // comb
  // |> list.fold(set.new(), fn(acc, val) { set.union(acc, val.1) })
  // set.size(covering) > 1
  // // covering == { diffs |> list.map(pair.first) |> set.from_list }
  // })
  // |> list.length
  // |> pprint.debug

  1
}

fn yielder_combinations(items: Yielder(a), by n: Int) -> Yielder(Yielder(a)) {
  case n {
    0 -> yielder.from_list([yielder.from_list([])])
    _ -> {
      let first = yielder.first(items)
      case first {
        Ok(first) -> {
          let rest = yielder.drop(items, 1)
          let first_combinations =
            yielder.map(yielder_combinations(rest, n - 1), with: fn(com) {
              yielder.prepend(com, first)
            })

          yielder.fold(
            first_combinations,
            yielder_combinations(rest, n),
            fn(acc, c) { yielder.prepend(acc, c) },
          )
        }
        Error(_) -> yielder.empty()
      }
    }
  }
}

/// Calculations map `into` to Calculation
fn to_tree(
  calculations: Dict(String, Calculation),
  item: String,
) -> BinaryTree(String) {
  case dict.get(calculations, item) {
    Error(_) -> Leaf(item)
    Ok(calculation) -> {
      let left = to_tree(calculations, calculation.x1)
      let right = to_tree(calculations, calculation.x2)
      Node(item, left, calculation.op, right)
    }
  }
}

fn fold_tree(over tree: BinaryTree(a), from initial: b, with fun: fn(b, a) -> b) {
  case tree {
    Leaf(into) -> fun(initial, into)
    Node(into, x, _, y) ->
      initial
      |> fold_tree(x, _, fun)
      |> fold_tree(y, _, fun)
      |> fun(into)
  }
}

fn fold_tree_depth(
  over tree: BinaryTree(a),
  from initial: b,
  with fun: fn(b, a, Int) -> b,
  depth depth: Int,
) {
  case tree {
    Leaf(into) -> fun(initial, into, depth)
    Node(into, x, _, y) ->
      initial
      |> fold_tree_depth(x, _, fun, depth + 1)
      |> fold_tree_depth(y, _, fun, depth + 1)
      |> fun(into, depth)
  }
}

fn in_binary(num: Int) -> List(Bool) {
  case num {
    0 -> [False]
    _ -> in_binary_rec(num)
  }
}

fn in_binary_rec(num: Int) -> List(Bool) {
  case num {
    0 -> []
    _ -> [
      case num % 2 {
        0 -> False
        _ -> True
      },
      ..in_binary_rec(num / 2)
    ]
  }
}

fn filter_prefix(repo: Dict(String, Bool), char: String) {
  repo
  |> dict.to_list
  |> list.filter_map(fn(x) {
    use <- bool.guard(!string.starts_with(x.0, char), Error(Nil))
    x.0
    |> string.replace(char, "")
    |> int.parse
    |> result.map(fn(x0) { #(x0, x.1) })
  })
}

fn get_prefixed(repo: Dict(String, Bool), char: String) {
  repo
  |> dict.to_list
  |> list.filter_map(fn(x) {
    use <- bool.guard(!string.starts_with(x.0, char), Error(Nil))
    x.0
    |> string.replace(char, "")
    |> int.parse
    |> result.map(fn(x0) { #(x0, x.1) })
  })
  |> list.sort(fn(x, y) { int.compare(x.0, y.0) })
  |> list.index_fold(0, fn(acc, value, i) {
    let num = case value.1 {
      True -> 1
      False -> 0
    }
    let digit = {
      num
      * { int.power(2, int.to_float(i)) |> util.result_expect |> float.round }
    }
    acc + digit
  })
}

fn is_addition(repo: Dict(String, Bool)) {
  let x = repo |> get_prefixed("x")
  let y = repo |> get_prefixed("y")
  let z = repo |> get_prefixed("z")

  x + y == z
}

fn expected_result(repo: Dict(String, Bool)) {
  let x = repo |> get_prefixed("x")
  let y = repo |> get_prefixed("y")

  x + y
}

fn evaluate_tree(tree: BinaryTree(String), inputs: Dict(String, Bool)) -> Bool {
  case tree {
    Leaf(x) -> inputs |> dict.get(x) |> util.result_expect
    Node(_, x, op, y) ->
      calculate(evaluate_tree(x, inputs), evaluate_tree(y, inputs), op)
  }
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

fn parse_calculations(str: String) {
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
