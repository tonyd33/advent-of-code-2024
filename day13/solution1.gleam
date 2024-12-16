import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regexp
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Vector2(num) {
  Vector2Int(x: num, y: num)
}

type Vector2Int =
  Vector2(Int)

type ClawMachine {
  ClawMachine(a: Vector2Int, b: Vector2Int, prize: Vector2Int)
}

/// Only allow positive values
type DiophantineEq {
  DiophantineEq(a: Int, b: Int, c: Int)
}

/// dio.a * sol.x + dio.b * sol.y == dio.c
type DiophantineSolution {
  DiophantineSolution(x: Int, y: Int)
}

type DiophantineEnumerator {
  DiophantineEnumerator(sol: DiophantineSolution, l: Int, r: Int, g: Int)
}

type Interval(num) {
  Interval(min: num, max: num)
}

type IntInterval =
  Interval(Int)

type SlideDirection {
  Left
  Right
}

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  content
  |> string.trim_end
  |> string.split("\n\n")
  |> list.filter_map(fn(game) {
    case game |> string.split("\n") {
      [button_a, button_b, prize] -> Ok(parse_game(button_a, button_b, prize))
      _ -> Error(Nil)
    }
  })
  |> list.map(fn(claw) { claw |> solve_claw |> option.unwrap(0) })
  |> io.debug
  |> int.sum
}

fn parse_game(button_a, button_b, prize) {
  let assert [a_vec, b_vec, prize_vec] =
    [button_a, button_b, prize] |> list.map(parse_line)

  ClawMachine(a_vec, b_vec, prize_vec)
}

fn parse_line(line) {
  let assert Ok(coord_regex) = regexp.from_string("[XY][\\+=](\\d+)")
  let assert [
    regexp.Match(_, [option.Some(x_str)]),
    regexp.Match(_, [option.Some(y_str)]),
  ] = regexp.scan(coord_regex, line)

  let assert #(Ok(x), Ok(y)) = #(int.parse(x_str), int.parse(y_str))

  Vector2Int(x, y)
}

/// Get the least cost solution
fn solve_claw(claw: ClawMachine) {
  // Treat each component as a linear diophantine equation
  let dio_x = DiophantineEq(claw.a.x, claw.b.x, claw.prize.x)
  let dio_y = DiophantineEq(claw.a.y, claw.b.y, claw.prize.y)

  let interval = Interval(0, 100)
  let sol_x =
    get_diophantine_enumerator(dio_x, interval, interval)
    |> io.debug
    |> result.map(enumerate_diophantine(_, dio_x, 0, []))
    |> result.unwrap([])
    |> set.from_list
  let sol_y =
    get_diophantine_enumerator(dio_y, interval, interval)
    |> io.debug
    |> result.map(enumerate_diophantine(_, dio_y, 0, []))
    |> result.unwrap([])
    |> set.from_list

  let both =
    sol_x
    |> set.intersection(sol_y)
    |> set.to_list

  both
  |> list.fold(
    from: option.None,
    with: fn(maybe_curr_least: option.Option(Int), elt) {
      io.debug(elt)
      let elt_cost = solution_cost(elt)
      case maybe_curr_least {
        None -> Some(elt_cost)
        Some(curr_least) -> Some(int.min(curr_least, elt_cost))
      }
    },
  )
}

fn solution_cost(sol: DiophantineSolution) {
  3 * sol.x + sol.y
}

fn solve_diophantine(dio: DiophantineEq) {
  let #(g, x0, y0) = gcd_ext(dio.a, dio.b)
  case dio.c % g {
    0 -> {
      Ok(#(DiophantineSolution(x0 * { dio.c / g }, y0 * { dio.c / g }), g))
    }
    _ -> Error(Nil)
  }
}

fn shift_solution(
  dio: DiophantineEq,
  sol: DiophantineSolution,
  count: Int,
) -> DiophantineSolution {
  DiophantineSolution(sol.x + { count * dio.b }, sol.y - { count * dio.a })
}

fn get_diophantine_enumerator(
  dio: DiophantineEq,
  x_range: IntInterval,
  y_range: IntInterval,
) -> Result(DiophantineEnumerator, Nil) {
  solve_diophantine(dio)
  |> result.try(fn(sol_and_g) {
    let #(sol, g) = sol_and_g
    let reduced_dio = DiophantineEq(dio.a / g, dio.b / g, dio.c / g)

    let assert [sol_x_left, sol_x_right, sol_y_left, sol_y_right] =
      [
        #({ x_range.min - sol.x }, reduced_dio.b, Left),
        #({ x_range.max - sol.x }, reduced_dio.b, Right),
        #({ y_range.min - sol.y }, -reduced_dio.a, Left),
        #({ y_range.max - sol.y }, -reduced_dio.a, Right),
      ]
      |> list.map(fn(c) {
        let #(top, bottom, dir) = c
        let div = {
          int.to_float(top) /. int.to_float(bottom)
        }
        let positive = bottom > 0
        case dir, positive {
          // needs to be right above min
          Left, True -> div |> float.ceiling
          Left, False -> div |> float.floor
          // needs to be right below max
          Right, True -> div |> float.floor
          Right, False -> div |> float.ceiling
        }
        |> float.round
      })
      |> list.map(shift_solution(reduced_dio, sol, _))

    let broken =
      list.any(
        [
          sol_x_left.x > x_range.max,
          sol_x_right.x < x_range.min,
          sol_y_left.y > y_range.max,
          sol_y_right.y < y_range.min,
        ],
        fn(t) { t },
      )
    case broken {
      True -> Error(Nil)
      False -> {
        let lx1 = sol_x_left.x
        let rx1 = sol_x_right.x

        let #(lx2, rx2) = case sol_y_left.x > sol_y_right.x {
          True -> #(sol_y_right.x, sol_y_left.x)
          False -> #(sol_y_left.x, sol_y_right.x)
        }

        let lx = int.max(lx1, lx2)
        let rx = int.min(rx1, rx2)

        Ok(DiophantineEnumerator(sol, lx, rx, g))
      }
    }
  })
}

fn enumerate_diophantine(
  enumerator: DiophantineEnumerator,
  eqn: DiophantineEq,
  k: Int,
  curr: List(DiophantineSolution),
) {
  let x = enumerator.l + { k * { eqn.b / enumerator.g } }
  case x > enumerator.r {
    True -> curr
    False -> {
      let y = { eqn.c - eqn.a * x } / eqn.b
      enumerate_diophantine(enumerator, eqn, k + 1, [
        DiophantineSolution(x, y),
        ..curr
      ])
    }
  }
}

/// Extended Euclidean algorithm
/// Return d, x, y such that d = gcd(a, b) and ax + by = d
fn gcd_ext(a, b) {
  case a, b {
    _, 0 -> #(a, 1, 0)
    _, _ -> {
      let #(d, x1, y1) = gcd_ext(b, a % b)
      let x = y1
      let y = x1 - { y1 * { a / b } }
      #(d, x, y)
    }
  }
}

fn gcd(a, b) {
  case a, b {
    _, 0 -> a
    _, _ -> gcd(b, a % b)
  }
}
