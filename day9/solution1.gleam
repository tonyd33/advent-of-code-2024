import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

/// Really, this is just a Maybe monad (or Option in gleam) on an Int, but I
/// want to get the hang of gleam types.
pub type BlockContent {
  Filled(id: Int)
  Empty
}

fn rec(blocks: List(BlockContent)) -> List(BlockContent) {
  case blocks {
    [Filled(id), ..rest] -> [Filled(id), ..rec(rest)]
    [Empty, ..rest] -> {
      let x =
        rest
        // ah, the reverse is slow because the linked list implementation
        // isn't doubly-linked and doesn't contain the end ptr, forcing a
        // linear traversal... but it's good enough
        |> list.reverse
        |> list.pop(fn(block) {
          case block {
            Filled(_) -> True
            _ -> False
          }
        })

      case x {
        Ok(#(block, popped_rest)) -> [block, ..rec(list.reverse(popped_rest))]
        Error(_) -> [Empty, ..rec(rest)]
      }
    }
    [] -> []
  }
}

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  content
  |> string.split("")
  |> list.filter_map(int.base_parse(_, 10))
  // the last block implicitly has no free space. but we must be explicit.
  |> list.append([0])
  // [int] -> [[int, int]]
  // pairs of block size, empty size
  |> list.sized_chunk(2)
  |> list.index_fold(from: [], with: fn(acc, val, id) -> List(BlockContent) {
    case val {
      [blk_size, empty_size] ->
        acc
        |> list.append(list.repeat(Filled(id), times: blk_size))
        |> list.append(list.repeat(Empty, times: empty_size))
      _ -> panic as "Expected 2 sized chunks"
    }
  })
  |> rec
  |> list.filter_map(fn(x) {
    case x {
      Filled(id) -> Ok(id)
      _ -> Error(Nil)
    }
  })
  |> list.index_map(fn(x, index) { x * index })
  |> list.reduce(fn(a, b) { a + b })
  |> result.unwrap(or: 0)
}
