import gleam/int
import gleam/io
import gleam/list
import gleam/result
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
  |> gather_components([])
  |> list.map(calculate_fencing_price)
  |> int.sum
}

fn cell_2_coord(cell: Cell) -> Coord {
  let #(_, x, y) = cell
  #(x, y)
}

fn calculate_fencing_price(component: List(Cell)) {
  let area = component |> list.length

  // the idea is that we extrude the boundary and count the number of
  // extrusions
  let perimeter =
    component
    |> list.flat_map(fn(cell) { cell |> cell_2_coord |> adjacents })
    |> list.unique
    // we want only extrusions of cells _outside_ of the component
    |> list.filter(fn(coord) {
      component
      |> list.find(fn(cell) {
        let #(_, cell_x, cell_y) = cell
        #(cell_x, cell_y) == coord
      })
      // when found, should be false
      |> result.map(fn(_) { False })
      // when not found, should be true
      |> result.unwrap(True)
    })
    |> list.length

  area * perimeter
}

fn gather_components(
  grid: List(Cell),
  components: List(List(Cell)),
) -> List(List(Cell)) {
  case list.find(grid, fn(_) { True }) {
    Ok(cell) -> {
      let #(updated_grid, this_component) = components_of(in: grid, of: cell)
      gather_components(updated_grid, [this_component, ..components])
    }
    _ -> components
  }
}

fn adjacents(a: Coord) -> List(Coord) {
  let #(ax, ay) = a
  [#(ax, ay + 1), #(ax, ay - 1), #(ax + 1, ay), #(ax - 1, ay)]
}

fn is_adjacent(centered at: Coord, other b: Coord) -> Bool {
  let #(ax, ay) = at
  let #(bx, by) = b

  #(ax, ay) == #(bx, by + 1)
  || #(ax, ay) == #(bx, by - 1)
  || #(ax, ay) == #(bx + 1, by)
  || #(ax, ay) == #(bx - 1, by)
}

fn components_of(
  in grid: List(Cell),
  of cell: Cell,
) -> #(List(Cell), List(Cell)) {
  let #(cell_value, x, y) = cell

  let #(adjacents, rest_grid) =
    grid
    |> list.partition(fn(inner_cell) {
      let #(inner_cell_value, inner_x, inner_y) = inner_cell
      {
        cell_value == inner_cell_value
        && {
          #(inner_x, inner_y) == #(x, y)
          || is_adjacent(#(x, y), #(inner_x, inner_y))
        }
      }
    })

  acc_components(adjacents, rest_grid, adjacents)
}

fn acc_components(for, curr_grid, curr_components) -> #(List(Cell), List(Cell)) {
  case for {
    [] -> #(curr_grid, curr_components)
    [this_cell, ..rest] -> {
      let #(next_grid, these_components) =
        components_of(in: curr_grid, of: this_cell)
      acc_components(
        rest,
        next_grid,
        list.flatten([curr_components, these_components]),
      )
    }
  }
}
