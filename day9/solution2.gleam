import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import simplifile

/// Really, this is just a Maybe monad (or Option in gleam) on an Int, but I
/// want to get the hang of gleam types.
pub type BlockGroup {
  Filled(length: Int, id: Int)
  Empty(length: Int)
}

pub type BlockContent {
  BlockFilled(id: Int)
  BlockEmpty
}

fn rec2(
  blocks: List(BlockGroup),
  remaining: List(BlockGroup),
) -> List(BlockGroup) {
  case remaining {
    [Filled(length, id), ..rest] -> {
      let blocks_zipped =
        blocks
        |> fn(b) { list.zip(list.range(0, list.length(b)), b) }

      // find first empty space in blocks and insert it in there.
      let index =
        blocks_zipped
        |> list.find_map(fn(other_block) {
          case other_block {
            #(index, Empty(other_length)) if other_length >= length -> Ok(index)
            #(_, _) -> Error(Nil)
          }
        })
        |> result.unwrap(list.length(blocks))

      // but ensure that the empty space we'd be moving to is BEFORE the
      // original file's location!!
      let assert Ok(orig_index) =
        blocks_zipped
        |> list.find_map(fn(other_block) {
          case other_block {
            #(index, Filled(_, other_id)) if other_id == id -> Ok(index)
            #(_, _) -> Error(Nil)
          }
        })

      let new_blocks = case orig_index < index {
        True -> blocks
        False -> {
          let assert #(before, [Empty(other_length), ..after]) =
            list.split(blocks, index)
          list.flatten([
            before,
            [Filled(length, id), Empty(other_length - length)],
            after
              |> list.map(fn(x) {
                case x {
                  Filled(other_length, other_id)
                    if other_length == length && other_id == id
                  -> Empty(length)
                  otw -> otw
                }
              }),
          ])
        }
      }

      rec2(new_blocks, rest)
    }
    _ -> blocks
  }
}

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  let block_groups =
    content
    |> string.split("")
    |> list.filter_map(int.base_parse(_, 10))
    // the last block implicitly has no free space. but we must be explicit.
    |> list.append([0])
    // [int] -> [[int, int]]
    // pairs of block size, empty size
    |> list.sized_chunk(2)
    |> list.index_fold(from: [], with: fn(acc, val, id) -> List(BlockGroup) {
      case val {
        [blk_size, empty_size] ->
          acc
          |> list.append([Filled(blk_size, id), Empty(empty_size)])
        _ -> panic as "Expected 2 sized chunks"
      }
    })
  let sorted =
    block_groups
    |> list.sort(fn(a, b) {
      case a, b {
        Filled(_, id_a), Filled(_, id_b) -> int.compare(id_b, id_a)
        Filled(_, _), Empty(_) -> order.Lt
        _, _ -> order.Gt
      }
    })

  rec2(block_groups, sorted)
  |> list.flat_map(fn(x) {
    case x {
      Filled(length, id) -> list.repeat(BlockFilled(id), length)
      Empty(length) -> list.repeat(BlockEmpty, length)
    }
  })
  |> list.index_map(fn(x, index) {
    case x {
      BlockEmpty -> 0
      BlockFilled(id) -> index * id
    }
  })
  |> list.reduce(fn(a, b) { a + b })
  |> result.unwrap(or: 0)
}
