import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import gleam/yielder
import pprint
import simplifile
import util.{type Vec2, type Vec2Int, Finite, Infinite, Vec2}

type Cell {
  Wall
  Empty
  Start
  End
}

type Vertex {
  Vertex(cell: Vec2Int)
}

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  let grid =
    content
    |> string.trim_end
    |> util.parse_grid_dict(fn(str) {
      case str {
        "S" -> Start
        "E" -> End
        "#" -> Wall
        "." -> Empty
        _ -> panic as "Unknown cell"
      }
    })

  let assert Some(#(start, _)) =
    util.search_grid_dict(grid, fn(c) { c == Start })
  let assert Some(#(end, _)) = util.search_grid_dict(grid, fn(c) { c == End })

  let #(distances, predecessors) = dijkstra(grid, Vertex(start))
  let assert [canonical_path] =
    util.backtrack(predecessors, Vertex(end), [])
    |> list.map(fn(path) { [Vertex(start), ..path] })

  let cheats =
    canonical_path
    |> list.flat_map(fn(start_cheat_vert) {
      let start_cheat = start_cheat_vert.cell
      let end_cheats =
        util.iterator_2d(
          util.add_vec(start_cheat, Vec2(-20, -20)),
          util.add_vec(start_cheat, Vec2(20, 20)),
        )
        |> yielder.filter(fn(e) { util.l1_distance(start_cheat, e) <= 20 })
        |> yielder.filter(fn(end_cheat) {
          case grid |> dict.get(end_cheat) {
            Ok(Wall) | Error(_) -> False
            _ -> True
          }
        })
        |> yielder.to_list
        |> list.unique

      end_cheats |> list.map(fn(end_cheat) { #(start_cheat, end_cheat) })
    })

  let times_saved =
    cheats
    |> list.map(time_saved_on_cheat(distances, _))

  let _for_debug =
    times_saved
    |> list.group(fn(x) { x })
    |> dict.map_values(fn(_, y) { list.length(y) })
    |> dict.to_list
    |> list.map(pair.swap)
    |> list.sort(fn(x, y) { int.compare(x.1, y.1) })
    |> pprint.debug

  times_saved
  |> list.filter(fn(x) { x >= 100 })
  |> list.length
  |> pprint.debug
}

fn time_saved_on_cheat(distances: Dict(Vertex, util.Distance), cheat_pair) {
  let #(start_cheat, end_cheat) = cheat_pair
  let num_moves = util.l1_distance(end_cheat, start_cheat)

  let assert Finite(dist_to_end_cheat) =
    distances
    |> dict.get(Vertex(end_cheat))
    |> result.unwrap(Infinite)
  let assert Finite(dist_to_start_cheat) =
    distances
    |> dict.get(Vertex(start_cheat))
    |> result.unwrap(Infinite)

  let time_saved = dist_to_end_cheat - { dist_to_start_cheat + num_moves }
  int.max(0, time_saved)
}

fn dijkstra(grid: Dict(Vec2Int, Cell), start: Vertex) {
  let assert Some(#(_, grid_bounds)) = grid |> util.get_grid_bounds
  let vertices =
    util.iterator_2d(Vec2(0, 0), grid_bounds)
    |> yielder.map(Vertex(_))
    |> yielder.to_list
    |> set.from_list

  let get_neighbors = fn(vertex: Vertex) {
    util.moves
    |> list.filter_map(fn(move) {
      let vec = util.add_vec(vertex.cell, util.move_2_vec(move))
      let cell_result = grid |> dict.get(vec)
      case cell_result {
        Ok(Wall) -> Error(Nil)
        _ -> Ok(Vertex(vec))
      }
    })
    |> set.from_list
  }

  util.dijkstra_rec(
    graph: util.FlexGraph(
      vertices,
      get_outbound_neighbors: get_neighbors,
      get_distance: fn(_, _) { Finite(1) },
    ),
    distances: dict.from_list([#(start, Finite(0))]),
    visited: set.new(),
    queue: [start],
    predecessors: dict.new(),
  )
}
