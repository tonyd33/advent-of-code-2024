const R = require('ramda')
const {passthroughLog, loadFile, branch, assert, assertEq} = require('../util')

// type Coord = [x, y] = [number, number]
// type Grid = [[string]]
// type Guard = [string, Coord]

const accessGrid = R.curryN(2, (grid, [x, y]) => grid[y]?.[x])

// number -> number -> Coord
// flatIdx -> nCols -> Coord
const flatPosToGridPos = branch([R.modulo, R.pipe(R.divide, Math.floor)])

const addVect = R.curryN(2, (v1, v2) => [v1[0] + v2[0], v1[1] + v2[1]])
const rotateVect90CW = ([x, y]) => [-y, x]

const findGuardPos = R.converge(flatPosToGridPos, [
  R.pipe(R.map(R.join('')), R.join(''), R.findIndex(R.test(/\^|v|>|</))),
  R.pipe(R.head, R.length),
])

// Grid -> Guard
const findGuard = R.converge(
  branch([R.call, R.unapply(R.last)]),
  [grid => accessGrid(grid), findGuardPos]
)

const done = R.pipe(
  // Grid -> [Guard, [number, number]] for max x, max y
  branch([
    findGuard,
    branch([
      R.pipe(R.head, R.length, R.subtract(R.__, 1)),
      R.pipe(R.length, R.subtract(R.__, 1)),
    ])
  ]),
  ([[guardOri, [guardX, guardY]], [maxX, maxY]]) =>
    ({ guardOri, guardX, guardY, maxX, maxY }),
  R.cond([
    [({guardOri}) => guardOri === '^', ({guardY}) => guardY === 0],
    [({guardOri}) => guardOri === 'v', ({guardY, maxY}) => guardY === maxY],
    [({guardOri}) => guardOri === '<', ({guardX}) => guardX === 0],
    [({guardOri}) => guardOri === '>', ({guardX, maxX}) => guardX === maxX],
  ])
)

const getMoveVect = R.curryN(3, (grid, oriVect, pos) => {
  if (accessGrid(grid, addVect(oriVect, pos)) === '#')
    return rotateVect90CW(oriVect)
  return oriVect
})
assertEq(
  getMoveVect( [['>', '#']], [1, 0], [0, 0]),
  [-0, 1] // it's so stupid that [0, 1] fails the assertion
)

const oriToVect = R.cond([
  [R.equals('^'), R.always([0, -1])],
  [R.equals('v'), R.always([0, 1])],
  [R.equals('<'), R.always([-1, 0])],
  [R.equals('>'), R.always([1, 0])],
])

const vectToOri = R.cond([
  [([, y]) => y < 0, () => '^'],
  [([, y]) => y > 0, () => 'v'],
  [([x]) => x < 0, () => '<'],
  [([x]) => x > 0, () => '>'],
])

// const updateRec = R.curryN(2, (path, grid) => {
  // if (done(grid)) return [path, grid]

  // const guard = findGuard(grid)

  // const [guardOri, guardPos] = guard
  // const oriVect = oriToVect(guardOri)
  // const moveVect = getMoveVect(grid, oriVect, guardPos)

  // const newOri = vectToOri(moveVect)
  // const newPos = addVect(guardPos, moveVect)

  // const nextGrid = R.flow(grid, [
    // R.set(R.lensPath(R.reverse(guardPos)), '.'),
    // R.set(R.lensPath(R.reverse(newPos)), newOri)
  // ])
  // return updateRec([...path, newPos], nextGrid)
// })

const updateGrid = grid => {
  const guard = findGuard(grid)

  const [guardOri, guardPos] = guard
  const oriVect = oriToVect(guardOri)
  const moveVect = getMoveVect(grid, oriVect, guardPos)

  const newOri = vectToOri(moveVect)
  const newPos = addVect(guardPos, moveVect)

  return R.flow(grid, [
    R.set(R.lensPath(R.reverse(guardPos)), '.'),
    R.set(R.lensPath(R.reverse(newPos)), newOri)
  ])
}

// node doesn't support TCO so we have to do a while loop unfortunately :(
const simulate = grid => {
  const [, guardOrigPos] = findGuard(grid)
  let currPath = [guardOrigPos]
  let currGrid = R.clone(grid)

  while (!done(currGrid)) {
    currGrid = updateGrid(currGrid)
    const [, newPos] = findGuard(currGrid)
    currPath = [...currPath, newPos]
    console.log(currPath.length)
  }
  return [currPath, currGrid]
}


module.exports = {
  simulate,
}
