import gleam/bool
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/pair
import gleam/regexp
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder.{type Yielder}
import internal/ets/memo
import simplifile
import util.{type Vec2Int, Vec2, VerboseGridCell}

const bounds = Vec2(70, 70)

type Vertex {
  Vertex(pos: Vec2Int)
}

type Distance {
  Finite(int: Int)
  Infinite
}

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  let corruptions =
    content
    |> string.trim_end
    |> parse_corruptions

  // shouldn't be needed if binary search is working correctly but nice for
  // debugging
  use cache <- memo.create()

  let get_distance_cached = fn(i, cache) {
    use <- memo.memoize(cache, #(i))
    let vertices = vertices_at(corruptions, bounds, i)
    let distances = dijkstra(vertices, Vertex(Vec2(0, 0)))

    distances
    |> dict.get(Vertex(bounds))
    |> result.unwrap(Infinite)
  }

  let get_distance = fn(i) { get_distance_cached(i, cache) }

  let i =
    binary_search(get_distance, yielder.length(corruptions), 432) |> io.debug

  io.debug(corruptions |> yielder.at(i))
  1
}

/// lower_i is smallest i that fails so far
/// upper_i is largest i that passes so far
fn binary_search(get_distance: fn(Int) -> Distance, lower_i: Int, upper_i: Int) {
  let remaining_range = lower_i - upper_i
  let curr_i = upper_i + { remaining_range / 2 }

  use <- bool.guard(when: remaining_range <= 1, return: curr_i)

  let distance = get_distance(curr_i)
  case distance {
    Finite(_) -> {
      let new_upper_i = int.max(curr_i, upper_i)
      binary_search(get_distance, lower_i, new_upper_i)
    }
    Infinite -> {
      let new_lower_i = int.min(curr_i, lower_i)
      binary_search(get_distance, new_lower_i, upper_i)
    }
  }
}

fn parse_corruptions(str: String) {
  str
  |> string.split("\n")
  |> list.map(fn(line) {
    let assert Ok([x, y]) =
      line |> string.split(",") |> list.map(int.parse) |> result.all
    Vec2(x, y)
  })
  |> yielder.from_list
}

fn iterator_2d(start: Vec2Int, end: Vec2Int) {
  yielder.range(start.y, end.y)
  |> yielder.flat_map(fn(y) {
    yielder.range(start.x, end.x) |> yielder.map(fn(x) { Vec2(x, y) })
  })
}

fn vertices_at(
  corruptions: Yielder(Vec2Int),
  bounds: Vec2Int,
  step: Int,
) -> Set(Vertex) {
  let corruptions_at_step =
    corruptions
    |> yielder.take(step)
    |> yielder.to_list
    |> set.from_list

  iterator_2d(Vec2(0, 0), bounds)
  |> yielder.filter_map(fn(v) {
    case set.contains(corruptions_at_step, v) {
      True -> Error(Nil)
      False -> Ok(Vertex(v))
    }
  })
  |> yielder.to_list
  |> set.from_list
}

fn dijkstra(vertices: Set(Vertex), start: Vertex) {
  dijkstra_rec(
    vertices,
    get_neighbors_timed,
    fn(_, _) { Finite(1) },
    dict.from_list([#(start, Finite(0))]),
    set.new(),
    [start],
  )
}

fn get_neighbors_timed(vertex: Vertex) {
  let Vertex(Vec2(x, y)) = vertex
  [Vec2(x + 1, y), Vec2(x - 1, y), Vec2(x, y + 1), Vec2(x, y - 1)]
  |> list.map(fn(v) { Vertex(v) })
  |> set.from_list
}

fn dijkstra_rec(
  vertices: Set(Vertex),
  get_neighbors: fn(Vertex) -> Set(Vertex),
  edge_distance: fn(Vertex, Vertex) -> Distance,
  distances: Dict(Vertex, Distance),
  visited: Set(Vertex),
  queue: List(Vertex),
) {
  let get_distance = fn(a) {
    distances |> dict.get(a) |> result.unwrap(Infinite)
  }
  let queue =
    queue
    |> list.filter(fn(x) { !set.contains(visited, x) })

  let smallest =
    take_smallest(queue, fn(a, b) {
      compare_distance(get_distance(a), get_distance(b))
    })

  case smallest {
    Ok(#(vertex, rest_queue)) -> {
      let vertex_distance = get_distance(vertex)
      let updated_visited = visited |> set.insert(vertex)
      let neighbors = get_neighbors(vertex) |> set.intersection(vertices)

      let #(updated_distances, updated_queue) =
        neighbors
        |> set.fold(#(distances, rest_queue), fn(x, elt) {
          let #(distances, queue) = x
          let potential_distance =
            add_distance(vertex_distance, edge_distance(vertex, elt))
          let existing_distance = get_distance(elt)

          case compare_distance(potential_distance, existing_distance) {
            order.Lt -> {
              #(distances |> dict.insert(elt, potential_distance), [
                elt,
                ..queue
              ])
            }
            _ -> x
          }
        })

      dijkstra_rec(
        vertices,
        get_neighbors,
        edge_distance,
        updated_distances,
        updated_visited,
        updated_queue,
      )
    }
    Error(_) -> distances
  }
}

fn compare_distance(da, db) {
  case da, db {
    Finite(fda), Finite(fdb) -> int.compare(fda, fdb)
    Finite(_), Infinite -> order.Lt
    Infinite, Finite(_) -> order.Gt
    Infinite, Infinite -> order.Eq
  }
}

fn add_distance(da: Distance, db: Distance) {
  case da, db {
    Finite(fda), Finite(fdb) -> Finite(fda + fdb)
    _, _ -> Infinite
  }
}

fn take_smallest(list: List(a), by: fn(a, a) -> order.Order) {
  list |> list.sort(by) |> list.pop(fn(_) { True })
}
