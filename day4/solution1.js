const R = require('ramda')
const {passthroughLog, loadFile} = require('../util')

const input = __dirname + '/input1'

const horizontal = R.map(R.join(''))

const vertical = R.pipe(
  R.transpose,
  R.map(R.join(''))
)


// [0, 9]
// [0, 8] [1, 9]
// [0, 7] [1, 8] [2, 9]
// ...
// [9, 0]
// [8, 0], [9, 1]
const genMainDiagonalIndices = num => R.uniqBy(
  // lmao too lazy to figure out the right way to not duplicate diagonals XD
  xs => xs.map(ys => ys.join(',')).join(';'), [
  ...R.range(0, num)
  .map(i =>
    R.range(0, i + 1)
    .map(j => [j, num - i + j - 1])
  ),
  ...R.range(0, num)
  .map(i =>
    R.range(0, i + 1)
    .map(j => [num - i + j - 1, j])
  )
])

const accessGrid = grid => (col, row) => grid[row]?.[col]

const mainDiagonal = grid => {
  const cols = genMainDiagonalIndices(Math.max(grid[0].length, grid.length))
  return cols.map(diagonal => diagonal.map(R.apply(accessGrid(grid))).join(''))
}

const antiDiagonal = R.pipe(
  R.reverse,
  mainDiagonal,
)

R.pipe(
  // load input
  loadFile,
  // sanitize to a canonical grid
  R.split('\n'),
  R.init,
  R.map(R.split('')),
  // generate horizontal, vertical, diagonals. backwards will be implicitly
  // checked later
  R.pipe(
    R.applyTo,
    R.map(R.__, [
      horizontal, // rows 5
      vertical, // columns 3
      mainDiagonal, // top left to bottom right 5
      antiDiagonal, // top right to bottom left 5
    ]),
  ),
  R.flatten,
  R.map(R.pipe(
    R.applyTo,
    R.map(R.__, [
      R.pipe(R.match(/XMAS/g), R.length),
      R.pipe(R.match(/SAMX/g), R.length),
    ]),
    R.sum
  )),
  R.sum,
  passthroughLog,
)(input)
