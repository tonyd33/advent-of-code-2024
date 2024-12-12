const R = require('ramda')
const {passthroughLog, loadFile, branches} = require('../util')

const input = __dirname + '/input0'

// type Antenna = [f, x, y]
// type Coord = [x, y]

// Grid -> [Antenna]
const collectAntennas = 
  rows => rows.reduce((rowAcc, row, y) => [
    ...rowAcc, 
    ...row.reduce((colAcc, col, x) => 
      col !== '.' ? [...colAcc, [col, x, y]] : colAcc , [])
  ] , [])

// math: X -> X^2 \ {(x,x)|x\in X}
const set2SubDiagonal = R.pipe(
  x => R.xprod(x, x),
  R.filter(R.apply(R.complement(R.equals)))
)

const addVec = ([x1, y1], [x2, y2]) => [x1 + x2, y1 + y2]
const subVec = ([x1, y1], [x2, y2]) => [x1 - x2, y1 - y2]

// [Coord, Coord] -> [Coord, Coord]
const antinodes = ([a1, a2]) => {
  const diff1 = subVec(a1, a2) // a1 - a2
  const diff2 = subVec(a2, a1) // a2 - a1
  return [addVec(a1, diff1), addVec(a2, diff2)]
}

const inbound = R.curryN(2, (grid, [x, y]) => {
  const xLen = grid[0].length
  const yLen = grid.length
  return 0 <= x && x < xLen &&
         0 <= y && y < yLen
})

const gridAntinodes = R.pipe(
  // Grid -> [Antenna]
  collectAntennas,
  R.collectBy(R.head),
  R.chain(R.pipe(
    R.map(([, x, y]) => [x, y]),
    set2SubDiagonal,
    R.chain(antinodes),
  )),
)

R.pipe(
  // load input
  loadFile,
  R.split('\n'),
  R.init,
  R.map(R.split('')),
  grid => R.flow(grid, [
    gridAntinodes,
    R.uniq,
    R.filter(inbound(grid))
  ]),
  R.length,
  passthroughLog,
)(input)
