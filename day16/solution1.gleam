import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import simplifile
import util.{type Vec2Int, Vec2}

type Grid {
  Grid(
    cells: Dict(Vec2Int, GridCell),
    start: VerboseGridCell,
    end: VerboseGridCell,
    max: Vec2Int,
  )
}

type GridCell {
  Wall
  Empty
  Start
  End
}

type VerboseGridCell {
  VerboseGridCell(pos: Vec2Int, cell: GridCell)
}

type Graph(a) {
  Graph(vertices: Set(a), edges: Dict(a, Set(a)))
}

type Vertex {
  Vertex(cell: VerboseGridCell, ori: Orientation)
}

type Orientation {
  Up
  Down
  Left
  Right
}

type Distance {
  Finite(int: Int)
  Infinite
}

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  let grid = content |> string.trim_end |> parse_grid
  let graph = grid |> grid_2_graph

  let distances = dijkstra(graph, Vertex(grid.start, Right))

  let assert Ok(smallest) =
    [Up, Down, Left, Right]
    |> list.map(Vertex(grid.end, _))
    |> take_smallest(fn(a, b) {
      let da = distances |> dict.get(a) |> result.unwrap(Infinite)
      let db = distances |> dict.get(b) |> result.unwrap(Infinite)
      compare_distance(da, db)
    })
    |> result.map(pair.first)

  distances
  |> dict.get(smallest)
  |> result.try(fn(x) {
    case x {
      Finite(d) -> Ok(d)
      Infinite -> Error(Nil)
    }
  })
  |> result.unwrap(-1)
}

fn parse_grid(str: String) -> Grid {
  let grid_dict =
    util.parse_grid_dict(str, fn(cell_str) {
      case cell_str {
        "#" -> Wall
        "." -> Empty
        "S" -> Start
        "E" -> End
        _ -> panic as "Unknown cell"
      }
    })
  let assert Some(reindeer) =
    grid_dict
    |> dict.fold(None, fn(acc, k, v) {
      case acc, v {
        None, Start -> Some(VerboseGridCell(k, v))
        _, _ -> acc
      }
    })
  let assert Some(end) =
    grid_dict
    |> dict.fold(None, fn(acc, k, v) {
      case acc, v {
        None, End -> Some(VerboseGridCell(k, v))
        _, _ -> acc
      }
    })
  let assert Some(bounds) =
    grid_dict
    |> dict.fold(None, fn(acc, k, _) {
      case acc {
        Some(Vec2(acc_x, acc_y)) ->
          Some(Vec2(int.max(acc_x, k.x), int.max(acc_y, k.y)))
        None -> Some(Vec2(k.x, k.y))
      }
    })

  Grid(grid_dict, reindeer, end, bounds)
}

fn iterator_2d(start: Vec2Int, end: Vec2Int) {
  yielder.range(start.y, end.y)
  |> yielder.flat_map(fn(y) {
    yielder.range(start.x, end.x) |> yielder.map(fn(x) { Vec2(x, y) })
  })
}

fn grid_2_graph(grid: Grid) {
  iterator_2d(Vec2(0, 0), grid.max)
  |> yielder.fold(Graph(set.new(), dict.new()), fn(graph, v) {
    let cell = grid.cells |> dict.get(v) |> result.unwrap(Empty)
    let oris = [Left, Right, Up, Down]

    let adjacent_edges =
      oris
      |> list.filter_map(fn(ori) {
        let vec_at_ori = util.add_vec(v, ori_2_vec(ori))
        let vec_at_ori_cell =
          grid.cells |> dict.get(vec_at_ori) |> result.unwrap(Wall)

        case vec_at_ori_cell {
          Wall -> Error(Nil)
          _ ->
            Ok(#(
              Vertex(VerboseGridCell(v, cell), ori),
              Vertex(VerboseGridCell(vec_at_ori, vec_at_ori_cell), ori),
            ))
        }
      })
    let rotation_edges =
      oris
      |> list.map(Vertex(VerboseGridCell(v, cell), _))
      |> list.combination_pairs
      |> list.flat_map(fn(pair) {
        let #(from, to) = pair
        [#(from, to), #(to, from)]
      })

    let edges = list.flatten([adjacent_edges, rotation_edges])

    let vertices =
      edges
      |> list.flat_map(fn(pair) {
        let #(from, to) = pair
        [from, to]
      })
      |> set.from_list

    graph |> add_vertices(vertices) |> add_edge_pairs(edges)
  })
}

fn dijkstra(graph: Graph(Vertex), start: Vertex) {
  dijkstra_rec(graph, dict.from_list([#(start, Finite(0))]), set.new(), [start])
}

fn dijkstra_rec(
  graph: Graph(Vertex),
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
      let #(updated_distances, updated_queue) =
        graph.edges
        |> dict.get(vertex)
        |> result.unwrap(set.new())
        |> set.fold(#(distances, rest_queue), fn(x, elt) {
          let #(distances, queue) = x
          let potential_distance =
            add_distance(vertex_distance, distance(vertex, elt))
          let existing_distance = get_distance(elt)

          case compare_distance(potential_distance, existing_distance) {
            order.Lt -> #(distances |> dict.insert(elt, potential_distance), [
              elt,
              ..queue
            ])
            _ -> x
          }
        })
      dijkstra_rec(graph, updated_distances, updated_visited, updated_queue)
    }
    Error(_) -> distances
  }
}

fn distance(v1: Vertex, v2: Vertex) {
  case v1.ori == v2.ori {
    True -> Finite(1)
    False -> Finite(1000)
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

fn add_vertices(graph: Graph(a), vertices: Set(a)) {
  let new_vertices = set.union(graph.vertices, vertices)
  Graph(new_vertices, graph.edges)
}

fn add_edge(graph: Graph(a), from: a, to: a) {
  let new_edges =
    graph.edges
    |> dict.upsert(from, fn(x) {
      x |> option.unwrap(set.new()) |> set.insert(to)
    })

  Graph(graph.vertices, new_edges)
}

fn add_edge_pairs(graph: Graph(a), edges: List(#(a, a))) {
  case edges {
    [] -> graph
    [#(from, to), ..rest_pairs] ->
      add_edge(graph, from, to) |> add_edge_pairs(rest_pairs)
  }
}

fn ori_2_vec(move: Orientation) {
  case move {
    Up -> Vec2(0, -1)
    Down -> Vec2(0, 1)
    Left -> Vec2(-1, 0)
    Right -> Vec2(1, 0)
  }
}
