import gleam/bool
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set.{type Set}
import gleam/string
import pprint
import simplifile

type Graph {
  Graph(vertices: Set(String), edges: Dict(String, Set(String)))
}

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  content
  |> string.trim_end
  |> parse_graph
  |> find_cliques
  |> list.filter_map(fn(clique) {
    // subcliques of size 3 count, which we'll split out later
    case set.size(clique) >= 3 {
      True -> Ok(set.to_list(clique))
      False -> Error(Nil)
    }
  })
  |> list.flat_map(list.combinations(_, 3))
  |> list.map(set.from_list)
  |> set.from_list
  |> set.filter(fn(clique) {
    clique
    |> set.to_list
    |> list.any(fn(vert) { vert |> string.starts_with("t") })
  })
  |> set.size
  |> pprint.debug

  1
}

fn parse_graph(str: String) -> Graph {
  str
  |> string.split("\n")
  |> list.map(fn(line) {
    let assert [x, y] = line |> string.split("-")
    #(x, y)
  })
  |> list.fold(Graph(set.new(), dict.new()), fn(graph, edge_pair) {
    let #(x, y) = edge_pair
    Graph(
      graph.vertices |> set.union([x, y] |> set.from_list),
      graph.edges
        |> upsert_dict_set(x, y)
        |> upsert_dict_set(y, x),
    )
  })
}

fn upsert_dict_set(d: Dict(a, Set(b)), k: a, v: b) {
  d
  |> dict.upsert(k, fn(s) {
    s
    |> option.unwrap(set.new())
    |> set.insert(v)
  })
}

fn bron_kerbosch(graph: Graph, r: Set(String), p: Set(String), x: Set(String)) {
  let done = set.is_empty(p) && set.is_empty(x)
  use <- bool.guard(done, [r])

  let #(_, _, all_cliques) =
    p
    |> set.to_list
    |> list.fold(#(p, x, []), fn(acc, v) {
      let #(p, x, curr_cliques) = acc
      let neighbors = graph.edges |> dict.get(v) |> result.unwrap(set.new())

      #(
        set.delete(p, v),
        set.insert(x, v),
        list.flatten([
          bron_kerbosch(
            graph,
            set.insert(r, v),
            set.intersection(p, neighbors),
            set.intersection(x, neighbors),
          ),
          curr_cliques,
        ]),
      )
    })

  all_cliques
}

fn find_cliques(graph: Graph) {
  bron_kerbosch(graph, set.new(), graph.vertices, set.new())
}
