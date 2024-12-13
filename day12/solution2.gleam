import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Cell =
  #(String, Int, Int)

type Coord =
  #(Int, Int)

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  content
  |> string.split("\n")
  |> list.index_map(fn(line, y) {
    string.split(line, "")
    |> list.index_map(fn(cell_value, x) { #(cell_value, x, y) })
  })
  |> list.flatten
  |> set.from_list
  |> gather_components([], connected_component_strategy)
  |> list.map(calculate_fencing_price)
  |> int.sum
}

fn calculate_fencing_price(component: set.Set(Cell)) {
  let component = component |> set.to_list
  let area = component |> list.length

  let is_extrusion = fn(coord: #(Int, Int)) {
    component
    |> list.find(fn(cell) {
      let #(_, cell_x, cell_y) = cell
      #(cell_x, cell_y) == coord
    })
    // when found, should be false
    |> result.map(fn(_) { False })
    // when not found, should be true
    |> result.unwrap(True)
  }

  let potentially_extrude = fn(coord: Coord, ori) {
    let #(coord_x, coord_y) = coord

    let by = case ori {
      "R" -> #(1, 0)
      "L" -> #(-1, 0)
      "D" -> #(0, 1)
      "U" -> #(0, -1)
      _ -> panic as "Unknown ori"
    }

    let #(by_x, by_y) = by
    let new_coord = #(coord_x + by_x, coord_y + by_y)

    case is_extrusion(#(coord_x + by_x, coord_y + by_y)) {
      True -> Ok(#(ori, new_coord.0, new_coord.1))
      False -> Error(Nil)
    }
  }

  let extrusions =
    component
    |> list.flat_map(fn(cell) {
      let #(_, x, y) = cell
      ["U", "D", "L", "R"] |> list.filter_map(potentially_extrude(#(x, y), _))
    })

  let num_perimeter_components =
    gather_components(
      extrusions |> set.from_list,
      [],
      connected_component_strategy,
    )
    |> list.length

  area * num_perimeter_components
}

fn connected_component_strategy(this_cell: Cell) {
  let #(this_cell_value, this_x, this_y) = this_cell
  adjacents(#(this_x, this_y))
  |> list.map(fn(coord) {
    let #(coord_x, coord_y) = coord
    #(this_cell_value, coord_x, coord_y)
  })
}

fn gather_components(
  grid: set.Set(Cell),
  components: List(set.Set(Cell)),
  strategy: fn(Cell) -> List(Cell),
) -> List(set.Set(Cell)) {
  let #(this_component, next_grid) = pop_component(grid, strategy)
  case this_component |> set.size {
    0 -> components
    _ -> gather_components(next_grid, [this_component, ..components], strategy)
  }
}

/// Pops the component.
/// Returns the component and the grid without the component
fn pop_component(
  grid: set.Set(Cell),
  strategy: fn(Cell) -> List(Cell),
) -> #(set.Set(Cell), set.Set(Cell)) {
  case grid |> set.to_list |> list.find(fn(_) { True }) {
    Ok(cell) -> {
      let component =
        bfs(
          grid: grid,
          queue: [cell],
          component: set.new(),
          visited: set.new(),
          strategy: strategy,
        )
      let grid =
        grid
        |> set.filter(fn(other_cell) { !set.contains(component, other_cell) })
      #(component, grid)
    }
    _ -> #(set.new(), grid)
  }
}

fn bfs(
  grid grid: set.Set(Cell),
  queue queue: List(Cell),
  component component: set.Set(Cell),
  visited visited: set.Set(Cell),
  strategy strategy: fn(Cell) -> List(Cell),
) {
  case queue {
    [] -> component
    [this_cell, ..rest_queue] -> {
      let visited = visited |> set.insert(this_cell)
      let component = component |> set.insert(this_cell)
      let adjacents =
        strategy(this_cell)
        |> list.filter(fn(other_cell) {
          grid |> set.contains(other_cell)
          && !{ visited |> set.contains(other_cell) }
        })
      let queue = list.flatten([adjacents, rest_queue])
      let visited = visited |> set_bulk_insert(adjacents)

      bfs(grid, queue, set_bulk_insert(component, adjacents), visited, strategy)
    }
  }
}

fn adjacents(a: Coord) -> List(Coord) {
  let #(ax, ay) = a
  [#(ax, ay + 1), #(ax, ay - 1), #(ax + 1, ay), #(ax - 1, ay)]
}

fn set_bulk_insert(set: set.Set(a), elts: List(a)) {
  elts
  |> list.fold(from: set, with: fn(curr_set, elt) {
    curr_set |> set.insert(elt)
  })
}
