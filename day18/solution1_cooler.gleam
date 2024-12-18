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
import simplifile
import util.{type Vec2Int, Vec2, VerboseGridCell}

const bounds = Vec2(6, 6)

type Vertex {
  Vertex(pos: Vec2Int, t: Int)
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

  let vertices = all_vertices(corruptions)
  let #(distances, predecessors) = dijkstra(vertices, Vertex(Vec2(0, 0), 0))

  // yielder.range(0, yielder.length(corruptions))
  // |> yielder.each(fn(i) {
  // let vertices_at_i = vertices_at(corruptions, bounds, i)
  // let str =
  // iterator_2d(Vec2(0, 0), bounds)
  // |> yielder.fold("", fn(s, v) {
  // let Vec2(x, y) = v
  // let a = case set.contains(vertices_at_i, Vertex(v, i)) {
  // True -> "."
  // False -> "#"
  // }

  // case x == bounds.x {
  // True -> s <> a <> "\n"
  // False -> s <> a
  // }
  // })
  // io.println(int.to_string(i))
  // io.println(str)
  // })

  // let ends =
  // yielder.range(0, yielder.length(corruptions))
  // |> yielder.filter_map(fn(i) {
  // let d = distances |> dict.get(Vertex(bounds, i))
  // case d {
  // Ok(dr) -> Ok(#(i, dr, Vertex(bounds, i)))
  // _ -> Error(Nil)
  // }
  // })
  // |> yielder.map(fn(x) {
  // #(x.2, traverse_predecessors(predecessors, x.2, set.new()))
  // })
  // |> yielder.each(fn(x) {
  // io.debug(x)
  // io.println("")
  // })
  // |> io.debug

  let assert Ok(d) = pull_end(distances, bounds, 0, yielder.length(corruptions))
  d
}

fn traverse_predecessors(
  predecessors: Dict(Vertex, Set(Vertex)),
  curr: Vertex,
  vertices: Set(Vertex),
) {
  case vertices |> set.contains(curr) {
    True -> vertices
    False -> {
      let curr_predecessors =
        predecessors |> dict.get(curr) |> result.unwrap(set.new())
      let vertices = vertices |> set.insert(curr)

      curr_predecessors
      |> set.fold(vertices, fn(tiles, predecessor) {
        tiles
        |> set.insert(predecessor)
        |> set.union(traverse_predecessors(predecessors, predecessor, tiles))
      })
    }
  }
}

fn backtrack(
  predecessors: Dict(Vertex, Set(Vertex)),
  vertex: Vertex,
  curr_path: List(Vertex),
) {
  todo
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

fn pull_end(distances: Dict(Vertex, Distance), end: Vec2Int, t: Int, max_t: Int) {
  let distance =
    distances
    |> dict.get(Vertex(end, t))
    |> result.map(fn(x) {
      case x {
        Infinite -> Error(Nil)
        Finite(d) -> Ok(d)
      }
    })
  use <- bool.guard(when: t > max_t, return: Error(Nil))
  case distance {
    Error(_) -> pull_end(distances, end, t + 1, max_t)
    Ok(d) -> d
  }
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
    corruptions |> yielder.take(step) |> yielder.to_list |> set.from_list

  iterator_2d(Vec2(0, 0), bounds)
  |> yielder.filter_map(fn(v) {
    case set.contains(corruptions_at_step, v) {
      True -> Error(Nil)
      False -> Ok(Vertex(v, step))
    }
  })
  |> yielder.to_list
  |> set.from_list
}

fn all_vertices(corruptions: Yielder(Vec2Int)) -> Set(Vertex) {
  corruptions
  |> yielder.length
  |> yielder.range(0, _)
  |> yielder.fold(set.new(), fn(vertices, i) {
    vertices |> set.union(vertices_at(corruptions, bounds, i))
  })
}

fn dijkstra(vertices: Set(Vertex), start: Vertex) {
  dijkstra_rec(
    vertices,
    get_neighbors_timed,
    fn(v1, v2) { Finite(int.absolute_value(v1.t - v2.t)) },
    dict.from_list([#(start, Finite(0))]),
    set.new(),
    [start],
    dict.new(),
  )
}

fn get_neighbors_timed(vertex: Vertex) {
  let Vertex(Vec2(x, y), t) = vertex
  [Vec2(x + 1, y), Vec2(x - 1, y), Vec2(x, y + 1), Vec2(x, y - 1)]
  |> list.map(fn(v) { Vertex(v, t + 1) })
  |> set.from_list
}

fn dijkstra_rec(
  vertices: Set(Vertex),
  get_neighbors: fn(Vertex) -> Set(Vertex),
  edge_distance: fn(Vertex, Vertex) -> Distance,
  distances: Dict(Vertex, Distance),
  visited: Set(Vertex),
  queue: List(Vertex),
  predecessors: Dict(Vertex, Set(Vertex)),
) {
  // io.debug(distances)
  // io.println("")
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

      let #(updated_distances, updated_queue, updated_predecessors) =
        neighbors
        |> set.fold(#(distances, rest_queue, predecessors), fn(x, elt) {
          let #(distances, queue, predecessors) = x
          let potential_distance =
            add_distance(vertex_distance, edge_distance(vertex, elt))
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
        vertices,
        get_neighbors,
        edge_distance,
        updated_distances,
        updated_visited,
        updated_queue,
        updated_predecessors,
      )
    }
    Error(_) -> #(distances, predecessors)
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
