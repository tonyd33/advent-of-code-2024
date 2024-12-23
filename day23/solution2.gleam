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
  |> list.fold(set.new(), fn(acc, clique) {
    case set.size(clique) > set.size(acc) {
      True -> clique
      False -> acc
    }
  })
  |> set.to_list
  |> list.sort(string.compare)
  |> string.join(",")
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
