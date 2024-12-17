import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import simplifile

type Vector2Int {
  Vector2Int(x: Int, y: Int)
}

type Robot {
  Robot(pos: Vector2Int, vel: Vector2Int)
}

/// mins are inclusive, maxs are exclusive
type Grid {
  Grid(min_x: Int, min_y: Int, max_x: Int, max_y: Int)
}

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  let grid = Grid(0, 0, 101, 103)
  let seconds = 100

  content
  |> string.trim_end
  |> string.split("\n")
  |> list.map(fn(robot) { parse_robot(robot) |> update_robot(grid, seconds) })
  |> io.debug
  |> partition_by_quadrants(grid)
  |> list.map(list.length)
  |> io.debug
  |> list.reduce(int.multiply)
  |> result.unwrap(0)
}

fn parse_robot(line: String) -> Robot {
  let assert Ok(robot_regex) =
    regexp.from_string("^p=(-?\\d+),(-?\\d+)\\s+v=(-?\\d+),(-?\\d+)")
  let assert [
    regexp.Match(
      _,
      [
        option.Some(x_str),
        option.Some(y_str),
        option.Some(vx_str),
        option.Some(vy_str),
      ],
    ),
  ] = regexp.scan(robot_regex, line)

  let assert Ok([x, y, vx, vy]) =
    [x_str, y_str, vx_str, vy_str] |> list.map(int.parse) |> result.all

  Robot(Vector2Int(x, y), Vector2Int(vx, vy))
}

fn update_robot(robot: Robot, grid: Grid, times: Int) {
  let assert Ok(new_x) =
    int.modulo(robot.pos.x + { robot.vel.x * times }, grid.max_x)
  let assert Ok(new_y) =
    int.modulo(robot.pos.y + { robot.vel.y * times }, grid.max_y)

  Robot(Vector2Int(new_x, new_y), robot.vel)
}

fn partition_by_quadrants(robots: List(Robot), grid: Grid) {
  let top_left =
    Grid(0, 0, floor_divide(grid.max_x, 2), floor_divide(grid.max_y, 2))
  let top_right =
    Grid(ceil_divide(grid.max_x, 2), 0, grid.max_x, floor_divide(grid.max_y, 2))
  let bottom_left =
    Grid(0, ceil_divide(grid.max_y, 2), floor_divide(grid.max_x, 2), grid.max_y)
  let bottom_right =
    Grid(
      ceil_divide(grid.max_x, 2),
      ceil_divide(grid.max_y, 2),
      grid.max_x,
      grid.max_y,
    )

  let robots_top_left = robots |> list.filter(in_grid(_, top_left))
  let robots_top_right = robots |> list.filter(in_grid(_, top_right))
  let robots_bottom_left = robots |> list.filter(in_grid(_, bottom_left))
  let robots_bottom_right = robots |> list.filter(in_grid(_, bottom_right))

  [robots_top_left, robots_top_right, robots_bottom_left, robots_bottom_right]
}

fn in_grid(robot: Robot, grid: Grid) -> Bool {
  grid.min_x <= robot.pos.x
  && robot.pos.x < grid.max_x
  && grid.min_y <= robot.pos.y
  && robot.pos.y < grid.max_y
}

fn floor_divide(x: Int, y: Int) {
  let assert Ok(result) = int.floor_divide(x, y)
  result
}

fn ceil_divide(x: Int, y: Int) {
  let assert Ok(result) =
    float.divide(int.to_float(x), int.to_float(y))
    |> result.map(fn(divd) { float.ceiling(divd) |> float.round })
  result
}
