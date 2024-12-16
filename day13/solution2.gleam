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
  IntervalUpperRay(min: num)
}

type IntInterval =
  Interval(Int)

type ShiftToBoundary {
  AboveX(x_min: Int)
  BelowX(x_max: Int)
  AboveY(y_min: Int)
  BelowY(y_max: Int)
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
  // |> list.map(fn(claw) {
  // ClawMachine(
  // claw.a,
  // claw.b,
  // Vector2Int(
  // claw.prize.x + 10_000_000_000_000,
  // claw.prize.y + 10_000_000_000_000,
  // ),
  // )
  // })
  |> list.map(fn(claw) { claw |> solve_claw |> result.unwrap(0) })
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

  // let interval = IntervalUpperRay(min: 0)
  let interval = Interval(min: 0, max: 100)

  result.all([
    get_diophantine_enumerator(dio_x, interval, interval) |> io.debug,
    get_diophantine_enumerator(dio_y, interval, interval) |> io.debug,
  ])
  |> result.then(fn(enums) {
    let assert [
      DiophantineEnumerator(_, lxx, rxx, gx),
      DiophantineEnumerator(_, lxy, rxy, gy),
    ] = enums

    let assert [ex, ey] = enums

    let lyx = solve_y(dio_x, lxx)
    let lyy = solve_y(dio_y, lxy)

    let x_rkx = { { rxx - lxx } * gx } / dio_x.b
    let x_rky = { { rxy - lxy } * gy } / dio_y.b
    let dio_xk = DiophantineEq(dio_x.b / gx, -dio_y.b / gy, lxy - lxx)

    // get_diophantine_enumerator(
      // dio_xk,
      // Interval(int.min(0, x_rkx), int.max(0, x_rkx)),
      // Interval(int.min(0, x_rky), int.max(0, x_rky)),
    // )
    // |> io.debug
    // |> result.map(fn(x_comp_sols) {
      // io.debug(enumerate_diophantine(x_comp_sols, dio_xk, 0, []))
      // let k_x_upwards = 3 * dio_x.a > dio_x.b
      // let asdf =
        // case k_x_upwards {
          // // largest
          // True -> x_comp_sols.l
          // // smallest
          // False -> x_comp_sols.r
        // }
        // |> io.debug
        // |> enumerate_diophantine_at(x_comp_sols, dio_xk, _)

      // let x = lxx + { { asdf.x * dio_x.b } / gx }
      // let y = solve_y(dio_x, x)
      // let sol_k = DiophantineSolution(x, y) |> io.debug |> solution_cost
      // // io.debug(#("right befroe", x_comp_sols, asdf))
      // // enumerate_diophantine_at(ex, dio_x, asdf.x) |> io.debug |> solution_cost
    // })

    let y_rkx = solve_y(dio_x, x_rkx)
    let y_rky = solve_y(dio_y, x_rky)
    let dio_yk = DiophantineEq(-dio_y.a / gy, dio_x.a / gx, lyx - lyy)

    let x_comp_sols =
      get_diophantine_enumerator(
        dio_xk,
        Interval(int.min(0, x_rkx), int.max(0, x_rkx)),
        Interval(int.min(0, x_rky), int.max(0, x_rky)),
      )
      |> result.map(enumerate_diophantine(_, dio_xk, 0, []))
      |> result.unwrap([])
      |> io.debug

    // let y_comp_sols =
      // get_diophantine_enumerator(
        // dio_yk,
        // Interval(int.min(0, y_rkx), int.max(0, y_rkx)),
        // Interval(int.min(0, y_rky), int.max(0, y_rky)),
      // )
      // |> result.map(enumerate_diophantine(_, dio_yk, 0, []))
      // // swap them here. just trust
      // |> result.map(fn(sols) {
        // sols |> list.map(fn(a_sol) { DiophantineSolution(a_sol.y, a_sol.x) })
      // })
      // |> result.unwrap([])
      // |> io.debug

    // result.all([x_comp_sols, y_comp_sols])
    // |> result.map(fn(combined) {
      // let assert [x_comp_sols_real, y_comp_sols_real] = combined
      // // alright, now we gotta figure out the smallest or largest k
      // let k_x_upwards = 3 * dio_x.a > dio_x.b
      // let k_y_upwards = 3 * dio_y.a > dio_y.b

      // let k_x =
        // case k_x_upwards {
          // // largest
          // True -> int.min(x_comp_sols_real.r, y_comp_sols_real.r)
          // // smallest
          // False -> int.max(x_comp_sols_real.l, y_comp_sols_real.l)
        // }
        // |> enumerate_diophantine_at(x_comp_sols_real, dio_xk, _)
      // let k_y =
        // case k_y_upwards {
          // // largest
          // True -> int.min(x_comp_sols_real.r, y_comp_sols_real.r)
          // // smallest
          // False -> int.max(x_comp_sols_real.l, y_comp_sols_real.l)
        // }
        // |> enumerate_diophantine_at(x_comp_sols_real, dio_xk, _)
    // })
    let both =
      x_comp_sols
      |> set.from_list
      |> set.intersection(x_comp_sols |> set.from_list)
      // |> set.intersection(y_comp_sols |> set.from_list)
      |> set.to_list
      |> list.fold(
        over: _,
        from: Error(Nil),
        with: fn(maybe_curr_least: Result(Int, Nil), elt) {
          let k = elt.x
          let x = lxx + { { k * dio_x.b } / gx }
          let y = solve_y(dio_x, x)
          let sol_k = DiophantineSolution(x, y)

          let elt_cost = solution_cost(sol_k)
          case maybe_curr_least {
            Ok(curr_least) -> Ok(int.min(curr_least, elt_cost))
            Error(_) -> Ok(elt_cost)
          }
        },
      )
  })
  // Ok(1)
}

/// Solves for y. Assumes x is a valid solution
fn solve_y(dio: DiophantineEq, x) {
  { dio.c - { dio.a * x } } / dio.b
}

fn check_solution(dio: DiophantineEq, sol: DiophantineSolution) {
  { { dio.a * sol.x } + { dio.b * sol.y } } == dio.c
}

fn solution_cost(sol: DiophantineSolution) {
  3 * sol.x + sol.y
}

fn sign(x: Int) {
  case x, x > 0 {
    0, _ -> 0
    _, True -> 1
    _, False -> -1
  }
}

fn solve_diophantine(dio: DiophantineEq) {
  let #(g, x0, y0) = gcd_ext(dio.a, dio.b)
  let x0 = sign(dio.a) * x0
  let y0 = sign(dio.b) * y0
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

fn shift_to_boundary(
  dio: DiophantineEq,
  sol: DiophantineSolution,
  shift_to boundary: ShiftToBoundary,
) {
  let sign_a = sign(dio.a)
  let sign_b = sign(dio.b)

  let #(shift_count, reshift_condition, reshift_count) = case boundary {
    AboveX(x_min) -> #(
      { x_min - sol.x } / dio.b,
      fn(a_sol: DiophantineSolution) { a_sol.x < x_min },
      sign_b,
    )
    BelowX(x_max) -> #(
      { x_max - sol.x } / dio.b,
      fn(a_sol: DiophantineSolution) { a_sol.x > x_max },
      -sign_b,
    )
    AboveY(y_min) -> #(
      -{ y_min - sol.y } / dio.a,
      fn(a_sol: DiophantineSolution) { a_sol.y < y_min },
      -sign_a,
    )
    BelowY(y_max) -> #(
      -{ y_max - sol.y } / dio.a,
      fn(a_sol: DiophantineSolution) { a_sol.y > y_max },
      sign_b,
    )
  }

  let shifted_sol = shift_solution(dio, sol, shift_count)
  case reshift_condition(shifted_sol) {
    True -> shift_solution(dio, shifted_sol, reshift_count)
    False -> shifted_sol
  }
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

    case x_range, y_range {
      IntervalUpperRay(x_min), IntervalUpperRay(y_min) -> {
        let sol_x_left = shift_to_boundary(reduced_dio, sol, AboveX(x_min))
        let sol_y_left = shift_to_boundary(reduced_dio, sol, AboveY(y_min))

        let lx1 = sol_x_left.x
        let lx2 = sol_y_left.x

        Ok(DiophantineEnumerator(sol, int.min(lx1, lx2), int.max(lx1, lx2), g))
      }
      Interval(x_min, x_max), Interval(y_min, y_max) -> {
        let sol_x_left = shift_to_boundary(reduced_dio, sol, AboveX(x_min))
        let sol_x_right = shift_to_boundary(reduced_dio, sol, BelowX(x_max))
        let sol_y_left = shift_to_boundary(reduced_dio, sol, AboveY(y_min))
        let sol_y_right = shift_to_boundary(reduced_dio, sol, BelowY(y_max))

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
        let lx1 = sol_x_left.x
        let rx1 = sol_x_right.x

        let #(lx2, rx2) = case sol_y_left.x > sol_y_right.x {
          True -> #(sol_y_right.x, sol_y_left.x)
          False -> #(sol_y_left.x, sol_y_right.x)
        }

        let lx = int.max(lx1, lx2)
        let rx = int.min(rx1, rx2)
        case broken {
          True -> Error(Nil)
          False -> {
            Ok(DiophantineEnumerator(sol, lx, rx, g))
          }
        }
      }
      Interval(_, _), IntervalUpperRay(_) -> todo
      _, Interval(_, _) -> todo
    }
  })
}

fn enumerate_diophantine_at(
  enumerator: DiophantineEnumerator,
  eqn: DiophantineEq,
  k: Int,
) {
  let x = enumerator.l + { { k * eqn.b } / enumerator.g }
  let y = solve_y(eqn, x)

  DiophantineSolution(x, y)
}

fn enumerate_diophantine(
  enumerator: DiophantineEnumerator,
  eqn: DiophantineEq,
  k: Int,
  curr: List(DiophantineSolution),
) {
  let x = enumerator.l + { { k * eqn.b } / enumerator.g }
  let dir = sign(eqn.b / enumerator.g)
  let dir = case dir {
    0 -> 1
    _ -> dir
  }
  case int.absolute_value(x) > enumerator.r {
    True -> curr
    False -> {
      let y = { eqn.c - { eqn.a * x } } / eqn.b
      enumerate_diophantine(enumerator, eqn, k + dir, [
        DiophantineSolution(x, y),
        ..curr
      ])
    }
  }
}

/// Extended Euclidean algorithm
/// Return d, x, y such that d = gcd(a, b) and ax + by = d
fn gcd_ext(a, b) {
  let a = int.absolute_value(a)
  let b = int.absolute_value(b)
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
