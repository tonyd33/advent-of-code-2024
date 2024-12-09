const R = require('ramda')
const {passthroughLog, loadFile, branch, assert, assertEq} = require('../util')

// type Coord = [x, y] = [number, number]
// type Grid = [string, [number, number]]
// type Guard = [string, Coord]

const addVec = R.curryN(2, (v1, v2) => [v1[0] + v2[0], v1[1] + v2[1]])
const rotateVec90CW = ([x, y]) => [-y, x]

// number -> Grid -> Coord
const flatIdxToCoord = R.curryN(2, (idx, [, [xLen]]) =>
  [idx % xLen, Math.floor(idx / xLen)]
)
// Coord -> Grid -> number
const coordToFlatIdx = R.curryN(2, ([x, y], [, [xLen]]) => y * xLen + x)

// Coord -> Grid -> string
const accessGrid = R.curryN(2, ([x, y], [flat, [xLen]]) => flat[y * xLen + x])
// Coord -> string -> Grid -> Grid
const setGrid = R.curryN(3,
  (coord, repl, grid) => {
    const [flat, bounds] = grid
    const strArr = flat.split('')
    strArr[coordToFlatIdx(coord, grid)] = repl
    return [strArr.join(''), bounds]
  }
)
const passthroughGrid = (grid) => {
  const [flat, [xLen]] = grid
  console.log(`${R.splitEvery(xLen, flat).join('\n')}\n`)
  return grid
}

// Grid -> Guard
const findGuard = grid => {
  const [flat] = grid
  const {0: guardOri, index} = flat.match(/\^|v|>|</)
  return [guardOri, flatIdxToCoord(index, grid)]
}

// Grid -> bool
const done = grid => {
  const [, [maxX, maxY]] = grid
  const [ori, [x, y]] = findGuard(grid)
  if (ori === '^') return y === 0
  else if (ori === 'v') return y === maxY - 1
  else if (ori === '<') return x === 0
  else if (ori === '>') return x === maxX - 1
}

const oriToVec = x => (({
  '^': [0, -1],
  'v': [0, 1],
  '<': [-1, 0],
  '>': [1, 0]
})[x])

const vecToOri = R.cond([
  [([, y]) => y < 0, () => '^'],
  [([, y]) => y > 0, () => 'v'],
  [([x]) => x < 0, () => '<'],
  [([x]) => x > 0, () => '>'],
])

const getMoveVec = R.curryN(3, (grid, oriVec, pos) => {
  if (accessGrid(addVec(oriVec, pos), grid) === '#')
    return rotateVec90CW(oriVec)
  return oriVec
})
assertEq(
  getMoveVec(['>#', [2, 1]], [1, 0], [0, 0]),
  [-0, 1] // it's so stupid that [0, 1] fails the assertion
)

const updateGrid = grid => {
  const guard = findGuard(grid)

  const [guardOri, guardPos] = guard
  const oriVec = oriToVec(guardOri)
  const moveVec = getMoveVec(grid, oriVec, guardPos)

  const newOri = vecToOri(moveVec)
  const newPos = addVec(guardPos, moveVec)

  return R.flow(grid, [
    setGrid(guardPos, '.'),
    setGrid(newPos, newOri),
  ])
}

// [Coord] -> boolean
// checking for coord uniqueness is not enough. the orientation is needed for
// cycle checking. e.g. finding a [1, 2] while orientation is up and another
// [1, 2] while orientation is down does not guarantee a cycle. fortunately,
// the orientation is encoded in pairs of coordinates, so we can use that
// for uniqueness.
// it's called greedy not because it's incorrect, but because it leverages
// the cyclic property to skip checking pairwise uniqueness. if it's cyclic,
// the last node pair will have shown up earlier in the path, and that's all
// that's needed to check cycles.
const greedyCyclic = path => {
  if (path.length <= 2) return false

  const cyclicForm = R.flow(path, [
    R.aperture(2),
    R.map(R.pipe(
      R.map(R.join(',')),
      R.join(':')
    ))
  ])
  const last = R.last(cyclicForm)
  return cyclicForm.findIndex(elt => elt === last) !== cyclicForm.length - 1
}
assert(greedyCyclic([[1,2], [1, 1], ['whatever'], [1, 2], [1, 1]]))
assert(!greedyCyclic([[1,2], [1, 1], ['whatever'], [1, 2]]))

// node doesn't support TCO so we have to do a while loop unfortunately :(
const simulate = grid => {
  const [, guardOrigPos] = findGuard(grid)
  let currPath = [guardOrigPos]
  let currGrid = R.clone(grid)

  while (!done(currGrid)) {
    currGrid = updateGrid(currGrid)
    const [, newPos] = findGuard(currGrid)
    currPath = [...currPath, newPos]
  }
  return [currPath, currGrid]
}

const guardToCycleKey = guard => guard.flat().join(',')

const simulateSafe = grid => {
  const guardOrig = findGuard(grid)
  const [, guardOrigPos] = guardOrig
  const path = [guardOrigPos]
  const cycleSet = new Set([guardToCycleKey(guardOrig)])
  let currGrid = grid

  while (!done(currGrid)) {
    currGrid = updateGrid(currGrid)
    const guard = findGuard(currGrid)
    const [, newPos] = guard
    path.push(newPos)

    const cycleKey = guardToCycleKey(guard)

    if (cycleSet.has(cycleKey)) return [path, currGrid, true]
    cycleSet.add(cycleKey)
  }
  return [path, currGrid, false]
}


module.exports = {
  simulate,
  simulateSafe,
  setGrid,
  accessGrid,
  passthroughGrid,
}

