import gleam/string
import gleam/list
import gleam/dict.{type Dict}

pub type Vec2(a) {
  Vec2(x: a, y: a)
}

pub type Vec2Int =
  Vec2(Int)

pub fn add_vec(v1: Vec2Int, v2: Vec2Int) {
  Vec2(v1.x + v2.x, v1.y + v2.y)
}

pub type VerboseGridCell(cell_type) {
  VerboseGridCell(pos: Vec2Int, cell: cell_type)
}

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
