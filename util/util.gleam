import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder.{type Yielder}

pub type Vec2(a) {
  Vec2(x: a, y: a)
}

pub type Vec2Int =
  Vec2(Int)

pub fn add_vec(v1: Vec2Int, v2: Vec2Int) {
  Vec2(v1.x + v2.x, v1.y + v2.y)
}

pub fn sub_vec(v1: Vec2Int, v2: Vec2Int) {
  Vec2(v1.x - v2.x, v1.y - v2.y)
}

pub fn additive_inv_vec(v: Vec2Int) {
  Vec2(-v.x, -v.y)
}

pub fn l1_distance(v1: Vec2Int, v2: Vec2Int) {
  int.absolute_value(v1.x - v2.x) + int.absolute_value(v1.y - v2.y)
}

pub fn result_expect(result: Result(a, b)) -> a {
  case result {
    Ok(a) -> a
    _ -> panic
  }
}

pub type VerboseGridCell(cell_type) {
  VerboseGridCell(pos: Vec2Int, cell: cell_type)
}

pub type Distance {
  Finite(int: Int)
  Infinite
}

pub type Move {
  Up
  Down
  Left
  Right
}

pub const moves = [Up, Down, Left, Right]

pub fn parse_grid_dict(
  str: String,
  parse_cell: fn(String) -> cell_type,
) -> Dict(Vec2Int, cell_type) {
  str
  |> string.split("\n")
  |> list.map(string.split(_, ""))
  |> list.index_map(fn(row, y) {
    row |> list.index_map(fn(cell_str, x) { #(x, y, cell_str) })
  })
  |> list.flatten
  |> list.map(fn(v) {
    let #(x, y, cell_str) = v
    let cell = parse_cell(cell_str)
    VerboseGridCell(Vec2(x, y), cell)
  })
  |> list.fold(dict.new(), fn(dict, v) {
    let VerboseGridCell(vec, cell) = v
    dict.insert(dict, vec, cell)
  })
}

pub fn search_grid_dict(
  grid_dict: Dict(Vec2Int, cell_type),
  one_that is_desired: fn(cell_type) -> Bool,
) -> Option(#(Vec2Int, cell_type)) {
  grid_dict
  |> dict.fold(None, fn(acc, v, c) {
    case acc, is_desired(c) {
      None, True -> Some(#(v, c))
      _, _ -> acc
    }
  })
}

pub fn get_grid_bounds(
  grid_dict: Dict(Vec2Int, cell_type),
) -> Option(#(Vec2Int, Vec2Int)) {
  grid_dict
  |> dict.fold(None, fn(bounds: Option(#(Vec2Int, Vec2Int)), key, _) {
    case bounds {
      None -> Some(#(key, key))
      Some(#(lo, hi)) ->
        Some(#(
          Vec2(int.min(lo.x, key.x), int.min(lo.y, key.y)),
          Vec2(int.max(hi.x, key.x), int.max(hi.y, key.y)),
        ))
    }
  })
}

pub type FlexGraph(vertex) {
  FlexGraph(
    vertices: Set(vertex),
    get_outbound_neighbors: fn(vertex) -> Set(vertex),
    get_distance: fn(vertex, vertex) -> Distance,
  )
}

pub fn dijkstra_rec(
  graph graph: FlexGraph(vertex),
  distances distances: Dict(vertex, Distance),
  visited visited: Set(vertex),
  queue queue: List(vertex),
  predecessors predecessors: Dict(vertex, Set(vertex)),
) {
  let get_distance = fn(a) {
    distances |> dict.get(a) |> result.unwrap(Infinite)
  }
  let queue =
    queue
    |> list.filter(fn(x) { !set.contains(visited, x) })

  let vertices = graph.vertices

  take_smallest(queue, fn(a, b) {
    compare_distance(get_distance(a), get_distance(b))
  })
  |> result.map(fn(v) {
    let #(vertex, rest_queue) = v
    let vertex_distance = get_distance(vertex)
    let updated_visited = visited |> set.insert(vertex)
    let neighbors =
      graph.get_outbound_neighbors(vertex) |> set.intersection(vertices)

    let #(updated_distances, updated_queue, updated_predecessors) =
      neighbors
      |> set.fold(#(distances, rest_queue, predecessors), fn(x, elt) {
        let #(distances, queue, predecessors) = x
        let potential_distance =
          add_distance(vertex_distance, graph.get_distance(vertex, elt))
        let existing_distance = get_distance(elt)

        case compare_distance(potential_distance, existing_distance) {
          order.Lt -> {
            #(
              distances |> dict.insert(elt, potential_distance),
              [elt, ..queue],
              predecessors |> dict.insert(elt, set.from_list([vertex])),
            )
          }
          order.Eq -> #(
            distances |> dict.insert(elt, potential_distance),
            [elt, ..queue],
            predecessors
              |> dict.upsert(elt, fn(x) {
                x |> option.unwrap(set.new()) |> set.insert(vertex)
              }),
          )
          _ -> x
        }
      })

    dijkstra_rec(
      graph,
      updated_distances,
      updated_visited,
      updated_queue,
      updated_predecessors,
    )
  })
  |> result.unwrap(#(distances, predecessors))
}

pub fn take_smallest(list: List(a), by: fn(a, a) -> Order) {
  list |> list.sort(by) |> list.pop(fn(_) { True })
}

pub fn compare_distance(da, db) {
  case da, db {
    Finite(fda), Finite(fdb) -> int.compare(fda, fdb)
    Finite(_), Infinite -> order.Lt
    Infinite, Finite(_) -> order.Gt
    Infinite, Infinite -> order.Eq
  }
}

pub fn add_distance(da: Distance, db: Distance) {
  case da, db {
    Finite(fda), Finite(fdb) -> Finite(fda + fdb)
    _, _ -> Infinite
  }
}

pub fn move_2_vec(move: Move) {
  case move {
    Up -> Vec2(0, -1)
    Down -> Vec2(0, 1)
    Left -> Vec2(-1, 0)
    Right -> Vec2(1, 0)
  }
}

pub fn backtrack(
  predecessors: Dict(vertex, Set(vertex)),
  vertex: vertex,
  curr_path: List(vertex),
) -> List(List(vertex)) {
  case predecessors |> dict.get(vertex) {
    Ok(these_predecessors) ->
      these_predecessors
      |> set.to_list
      |> list.flat_map(fn(a_vertex) {
        backtrack(predecessors, a_vertex, [vertex, ..curr_path])
      })
    Error(_) -> [curr_path]
  }
}

pub fn iterator_2d(start: Vec2Int, end: Vec2Int) {
  yielder.range(start.y, end.y)
  |> yielder.flat_map(fn(y) {
    yielder.range(start.x, end.x) |> yielder.map(fn(x) { Vec2(x, y) })
  })
}

pub fn xprod_same(l: Yielder(a), n: Int) -> Yielder(Yielder(a)) {
  case n {
    n if n < 0 -> panic as "n must be nonnegative"
    0 -> yielder.from_list([])
    1 -> yielder.from_list([l])
    2 ->
      l
      |> yielder.flat_map(fn(c1) {
        l |> yielder.map(fn(c2) { [c1, c2] |> yielder.from_list })
      })
    _ -> {
      xprod_same(l, n - 1)
      |> yielder.flat_map(fn(c1s) {
        l
        |> yielder.map(fn(c2) { yielder.append(c1s, yielder.from_list([c2])) })
      })
    }
  }
}
