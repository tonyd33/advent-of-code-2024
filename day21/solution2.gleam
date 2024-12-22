import gleam/float
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import gleam/yielder.{type Yielder}
import internal/ets/memo
import pprint
import simplifile
import util.{Vec2}

type DPadKey {
  Up
  Down
  Left
  Right
  DPadActivate
}

type NumPadKey {
  Zero
  One
  Two
  Three
  Four
  Five
  Six
  Seven
  Eight
  Nine
  NumPadActivate
}

const levels: Int = 25

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  use cache1 <- memo.create()
  use cache2 <- memo.create()

  content
  |> string.trim_end
  |> string.split("\n")
  |> list.map(fn(line) {
    line
    |> string.split("")
    |> list.map(fn(char) {
      case char {
        "0" -> Zero
        "1" -> One
        "2" -> Two
        "3" -> Three
        "4" -> Four
        "5" -> Five
        "6" -> Six
        "7" -> Seven
        "8" -> Eight
        "9" -> Nine
        "A" -> NumPadActivate
        _ -> panic
      }
    })
  })
  // take only last 5 i guess
  |> list.reverse
  |> list.take(5)
  |> list.reverse
  |> list.map(fn(n_keys) {
    // what needs to be pressed on dpad1 to achieve numpad
    let level1 =
      x_ascend(n_keys, NumPadActivate, DPadActivate, numpad_path_on_dpad)

    // let leveli_size =
    // {
    // use wpair <- ascend(level1)
    // ascend_pair(wpair, levels - 1, cache1)
    // }
    // |> list.length
    let leveli_size = {
      use wpair <- ascend_size_only(level1)
      ascend_pair_size_only(wpair, levels - 1, cache2)
    }

    let short_seq_length = leveli_size
    let numeric_part = extract_numeric_code(n_keys)

    short_seq_length * numeric_part
  })
  |> int.sum
  |> pprint.debug
}

fn x_ascend(
  keys: List(a),
  activate_a: a,
  activate_b: b,
  ascend_pair: fn(#(a, a)) -> List(b),
) {
  keys
  |> list.prepend(activate_a)
  |> list.append([activate_a])
  |> list.window_by_2
  |> list.map(ascend_pair)
  |> list.intersperse([activate_b])
  |> list.flatten
}

fn ascend_size_only(
  keys: List(DPadKey),
  ascend_pair: fn(#(DPadKey, DPadKey)) -> Int,
) -> Int {
  let sizes =
    keys
    |> list.prepend(DPadActivate)
    |> list.append([DPadActivate])
    |> list.window_by_2
    |> list.map(ascend_pair)

  let sizes_lower = sizes |> int.sum
  // simulate the intersperse and flatten
  sizes_lower + { list.length(sizes) - 1 }
}

fn ascend_pair_size_only(
  pair: #(DPadKey, DPadKey),
  remaining n: Int,
  cache cache,
) -> Int {
  use <- memo.memoize(cache, #(pair, n))
  let path = dpad_path_on_dpad(pair)
  case n {
    0 -> path |> list.length
    _ -> {
      use wpair <- ascend_size_only(path)
      ascend_pair_size_only(wpair, n - 1, cache)
    }
  }
}

fn ascend(
  keys: List(DPadKey),
  ascend_pair: fn(#(DPadKey, DPadKey)) -> List(DPadKey),
) {
  x_ascend(keys, DPadActivate, DPadActivate, ascend_pair)
}

fn ascend_pair(
  pair: #(DPadKey, DPadKey),
  remaining n: Int,
  cache cache,
) -> List(DPadKey) {
  let #(from_d_key, to_d_key) = pair
  use <- memo.memoize(cache, #(from_d_key, to_d_key, n))
  let path = dpad_path_on_dpad(pair)
  case n {
    0 -> path
    _ -> {
      use wpair <- ascend(path)
      ascend_pair(wpair, n - 1, cache)
    }
  }
}

fn numpad_path_on_dpad(pair: #(NumPadKey, NumPadKey)) -> List(DPadKey) {
  let #(from_n_key, to_n_key) = pair
  // Down < Left < Up < Right
  case from_n_key {
    Zero ->
      case to_n_key {
        Zero -> []
        One -> [Up, Left]
        Two -> [Up]
        Three -> [Left, Up]
        Four -> [Up, Up, Left]
        Five -> [Up, Up]
        Six -> [Up, Up, Right]
        Seven -> [Up, Up, Up, Left]
        Eight -> [Up, Up, Up]
        Nine -> [Up, Up, Up, Right]
        NumPadActivate -> [Right]
      }
    One ->
      case to_n_key {
        Zero -> [Right, Down]
        One -> []
        Two -> [Right]
        Three -> [Right, Right]
        Four -> [Up]
        Five -> [Up, Right]
        Six -> [Up, Right, Right]
        Seven -> [Up, Up]
        Eight -> [Up, Up, Right]
        Nine -> [Up, Up, Right, Right]
        NumPadActivate -> [Right, Right, Down]
      }
    Two ->
      case to_n_key {
        Zero -> [Down]
        One -> [Left]
        Two -> []
        Three -> [Right]
        Four -> [Left, Up]
        Five -> [Up]
        Six -> [Up, Right]
        Seven -> [Left, Up, Up]
        Eight -> [Up, Up]
        Nine -> [Up, Up, Right]
        NumPadActivate -> [Down, Right]
      }
    Three ->
      case to_n_key {
        Zero -> [Left, Down]
        One -> [Left, Left]
        Two -> [Left]
        Three -> []
        Four -> [Left, Left, Up]
        Five -> [Left, Up]
        Six -> [Up]
        Seven -> [Left, Left, Up, Up]
        Eight -> [Left, Up, Up]
        Nine -> [Up, Up]
        NumPadActivate -> [Down]
      }
    Four ->
      case to_n_key {
        Zero -> [Right, Down, Down]
        One -> [Down]
        Two -> [Down, Right]
        Three -> [Down, Right, Right]
        Four -> []
        Five -> [Right]
        Six -> [Right, Right]
        Seven -> [Up]
        Eight -> [Up, Right]
        Nine -> [Up, Right, Right]
        NumPadActivate -> [Right, Right, Down, Down]
      }
    Five ->
      case to_n_key {
        Zero -> [Down, Down]
        One -> [Left, Down]
        Two -> [Down]
        Three -> [Down, Right]
        Four -> [Left]
        Five -> []
        Six -> [Right]
        Seven -> [Left, Left, Up]
        Eight -> [Left, Up]
        Nine -> [Up]
        NumPadActivate -> [Down, Down]
      }
    Six ->
      case to_n_key {
        Zero -> [Left, Down, Down]
        One -> [Left, Down, Down]
        Two -> [Left, Down]
        Three -> [Down]
        Four -> [Left, Left]
        Five -> [Left]
        Six -> []
        Seven -> [Left, Left, Up]
        Eight -> [Left, Up]
        Nine -> [Up]
        NumPadActivate -> [Down, Down]
      }
    Seven ->
      case to_n_key {
        Zero -> [Right, Down, Down, Down]
        One -> [Down, Down]
        Two -> [Down, Down, Right]
        Three -> [Down, Down, Right, Right]
        Four -> [Down]
        Five -> [Down, Right]
        Six -> [Down, Right, Right]
        Seven -> []
        Eight -> [Right]
        Nine -> [Right, Right]
        NumPadActivate -> [Right, Right, Down, Down, Down]
      }
    Eight ->
      case to_n_key {
        Zero -> [Down, Down, Down]
        One -> [Left, Down, Down]
        Two -> [Down, Down]
        Three -> [Down, Down, Right]
        Four -> [Left, Down]
        Five -> [Down]
        Six -> [Down, Right]
        Seven -> [Left]
        Eight -> []
        Nine -> [Right]
        NumPadActivate -> [Down, Down, Down, Right]
      }
    Nine ->
      case to_n_key {
        Zero -> [Left, Down, Down, Down]
        One -> [Left, Left, Down, Down]
        Two -> [Left, Down, Down]
        Three -> [Down, Down]
        Four -> [Left, Left, Down]
        Five -> [Left, Down]
        Six -> [Down]
        Seven -> [Left, Left]
        Eight -> [Left]
        Nine -> []
        NumPadActivate -> [Down, Down, Down]
      }
    NumPadActivate ->
      case to_n_key {
        Zero -> [Left]
        One -> [Up, Left, Left]
        Two -> [Left, Up]
        Three -> [Up]
        Four -> [Up, Up, Left, Left]
        Five -> [Left, Up, Up]
        Six -> [Up, Up]
        Seven -> [Up, Up, Up, Left, Left]
        Eight -> [Up, Up, Up, Left]
        Nine -> [Up, Up, Up]
        NumPadActivate -> []
      }
  }
}

fn dpad_path_on_dpad(pair: #(DPadKey, DPadKey)) -> List(DPadKey) {
  let #(from_d_key, to_d_key) = pair
  // Down < Left < Up < Right
  case from_d_key {
    DPadActivate ->
      case to_d_key {
        DPadActivate -> []
        Down -> [Left, Down]
        Left -> [Down, Left, Left]
        Right -> [Down]
        Up -> [Left]
      }
    Down ->
      case to_d_key {
        DPadActivate -> [Up, Right]
        Down -> []
        Left -> [Left]
        Right -> [Right]
        Up -> [Up]
      }
    Left ->
      case to_d_key {
        DPadActivate -> [Right, Right, Up]
        Down -> [Right]
        Left -> []
        Right -> [Right, Right]
        Up -> [Right, Up]
      }
    Right ->
      case to_d_key {
        DPadActivate -> [Up]
        Down -> [Left]
        Left -> [Left, Left]
        Right -> []
        Up -> [Left, Up]
      }
    Up ->
      case to_d_key {
        DPadActivate -> [Right]
        Down -> [Down]
        Left -> [Down, Left]
        Right -> [Down, Right]
        Up -> []
      }
  }
}

fn extract_numeric_code(n_keys: List(NumPadKey)) {
  n_keys
  |> list.filter_map(fn(n_key) {
    case n_key {
      NumPadActivate -> Error(Nil)
      Zero -> Ok(0)
      One -> Ok(1)
      Two -> Ok(2)
      Three -> Ok(3)
      Four -> Ok(4)
      Five -> Ok(5)
      Six -> Ok(6)
      Seven -> Ok(7)
      Eight -> Ok(8)
      Nine -> Ok(9)
    }
  })
  |> list.reverse
  |> list.index_fold(0, fn(acc, x, i) {
    let assert Ok(mult) =
      int.power(10, i |> int.to_float) |> result.map(float.round)

    acc + { x * mult }
  })
}

fn dpad_to_string(d_key: DPadKey) {
  case d_key {
    Left -> "<"
    Right -> ">"
    Up -> "^"
    Down -> "v"
    DPadActivate -> "A"
  }
}

fn debug_dpad_list(d_keys: List(DPadKey)) -> List(DPadKey) {
  d_keys |> list.map(dpad_to_string) |> string.join("") |> pprint.debug
  d_keys
}
