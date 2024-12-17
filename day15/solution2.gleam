import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Grid {
  Grid(cells: Dict(Vec2Int, GridCell), robot: VerboseGridCell)
}

type GridCell {
  Wall
  Robot
  BoxL
  BoxR
  /// Not technically required, but makes things a lot easier since we can
  /// handle empty results natively
  Empty
}

type Vec2Int {
  Vec2Int(x: Int, y: Int)
}

type VerboseGridCell {
  VerboseGridCell(pos: Vec2Int, cell: GridCell)
}

type Move {
  Up
  Down
  Left
  Right
}

/// Semantics: The cell at `pos` intends to move `move`
type Intent {
  Intent(pos: Vec2Int, move: Move)
}

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  let assert [grid_str, move_list_str] =
    content
    |> string.trim_end
    |> string.split("\n\n")

  let grid = parse_grid(grid_str)
  let moves = parse_moves(move_list_str)

  debug_grid(grid)

  simulate(grid, moves) |> debug_grid |> gps_sum
}

fn update_grid(grid: Grid, intent: Intent) -> #(Grid, Bool) {
  let assert Ok(cell) = grid.cells |> dict.get(intent.pos)

  let intended_pos = add_vec(intent.pos, move_2_vec(intent.move))
  let intended_cell = grid.cells |> dict.get(intended_pos)

  debug_grid(grid)

  case intended_cell {
    // nothing in the way, just move it then
    Ok(Empty) -> {
      let updated_cells =
        grid.cells
        |> dict.insert(intent.pos, Empty)
        |> dict.insert(intended_pos, cell)
      case cell {
        Robot -> #(
          Grid(updated_cells, VerboseGridCell(intended_pos, Robot)),
          True,
        )
        _ -> #(Grid(updated_cells, grid.robot), True)
      }
    }
    // a box
    Ok(BoxL) | Ok(BoxR) -> {
      let #(box_left_pos, box_right_pos) = case intended_cell {
        Ok(BoxL) -> #(intended_pos, add_vec(intended_pos, move_2_vec(Right)))
        _ -> #(add_vec(intended_pos, move_2_vec(Left)), intended_pos)
      }

      // order matters here. if moving left, we have to update the left box
      // first. if moving right, we have to update the right box first
      let #(update_first, update_second) = case intent.move, intended_cell {
        Left, _ -> #(box_left_pos, box_right_pos)
        _, _ -> #(box_right_pos, box_left_pos)
      }

      update_grid_result(grid, Intent(update_first, intent.move))
      |> result.try(update_grid_result(_, Intent(update_second, intent.move)))
      |> result.map(update_grid(_, intent))
      |> result.unwrap(#(grid, False))
    }
    // everything else shouldn't be allowed to move
    _ -> #(grid, False)
  }
}

fn update_grid_result(grid: Grid, intent: Intent) -> Result(Grid, Nil) {
  case update_grid(grid, intent) {
    #(updated_grid, True) -> Ok(updated_grid)
    _ -> Error(Nil)
  }
}

fn simulate(grid: Grid, moves: List(Move)) {
  case moves {
    [] -> grid
    [move, ..rest_moves] -> {
      let #(new_grid, _) = update_grid(grid, Intent(grid.robot.pos, move))
      simulate(new_grid, rest_moves)
    }
  }
}

fn gps_sum(grid: Grid) {
  grid.cells
  |> dict.fold(0, fn(acc, k, v) {
    case v {
      BoxL -> acc + { { 100 * k.y } + k.x }
      _ -> acc
    }
  })
}

fn debug_grid(grid: Grid) -> Grid {
  let assert Some(Vec2Int(x_max, y_max)) =
    grid.cells
    |> dict.fold(None, fn(acc, k, _) {
      case acc {
        Some(Vec2Int(acc_x, acc_y)) ->
          Some(Vec2Int(int.max(acc_x, k.x), int.max(acc_y, k.y)))
        None -> Some(Vec2Int(k.x, k.y))
      }
    })

  list.range(0, y_max)
  |> list.map(fn(y) {
    list.range(0, x_max) |> list.map(fn(x) { Vec2Int(x, y) })
  })
  |> list.flatten
  |> list.fold("", fn(acc, v) {
    let out = case dict.get(grid.cells, v) |> result.unwrap(Empty) {
      BoxL -> "["
      BoxR -> "]"
      Empty -> "."
      Robot -> "@"
      Wall -> "#"
    }
    case v.x == x_max {
      True -> acc <> out <> "\n"
      False -> acc <> out
    }
  })
  |> io.println

  grid
}

fn add_vec(v1: Vec2Int, v2: Vec2Int) {
  Vec2Int(v1.x + v2.x, v1.y + v2.y)
}

fn move_2_vec(move: Move) {
  case move {
    Up -> Vec2Int(0, -1)
    Down -> Vec2Int(0, 1)
    Left -> Vec2Int(-1, 0)
    Right -> Vec2Int(1, 0)
  }
}

fn parse_grid(str: String) -> Grid {
  let cells_list =
    string.split(str, "\n")
    |> list.map(string.split(_, ""))
    |> list.index_map(fn(row, y) {
      row |> list.index_map(fn(cell_str, x) { #(x, y, cell_str) })
    })
    |> list.flatten
    |> list.flat_map(fn(v) {
      let #(x, y, cell_str) = v
      let #(cell_l, cell_r) = case cell_str {
        "O" -> #(BoxL, BoxR)
        "#" -> #(Wall, Wall)
        "@" -> #(Robot, Empty)
        "." -> #(Empty, Empty)
        _ -> panic as "Unknown cell"
      }

      [
        VerboseGridCell(Vec2Int(2 * x, y), cell_l),
        VerboseGridCell(Vec2Int(2 * x + 1, y), cell_r),
      ]
    })

  let cells =
    cells_list
    |> list.fold(dict.new(), fn(dict, v) {
      let VerboseGridCell(vec, cell) = v
      dict.insert(dict, vec, cell)
    })

  let assert Ok(robit) =
    cells_list
    |> list.find(fn(x) {
      let VerboseGridCell(_, typ) = x
      typ == Robot
    })

  Grid(cells, robit)
}

fn parse_moves(str: String) -> List(Move) {
  str
  |> string.replace("\n", "")
  |> string.split("")
  |> list.map(fn(x) {
    case x {
      ">" -> Right
      "^" -> Up
      "v" -> Down
      "<" -> Left
      _ -> panic as "Unknown move"
    }
  })
}
