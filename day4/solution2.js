const R = require('ramda')
const {passthroughLog, loadFile, aperture2d, zipN} = require('../util')

const input = __dirname + '/input1'

// type Grid = [[string]]

// Grid -> Grid
// pretty-prints the grid
const passthroughGrid = R.converge(R.unapply(R.head), [
  R.identity,
  R.pipe(
    R.map(R.join('')),
    R.join('\n'),
    R.concat(R.__, '\n'),
    passthroughLog,
  ),
])


R.pipe(
  // load input
  loadFile,
  // sanitize to a canonical grid
  R.split('\n'),
  R.init,
  R.map(R.split('')),
  // Grid -> [[Grid]]
  aperture2d(3,3),
  // [[Grid]] -> [Grid]
  R.unnest,
  // [Grid] -> [string]
  // make it easy for regex
  R.map(R.pipe(
    R.map(R.join('')),
    R.join(''),
  )),
  // [string] -> [string]
  // have to test nonsymmetries under D4
  R.filter(R.test(/M.S.A.M.S|M.M.A.S.S|S.S.A.M.M|S.M.A.S.M/)),
  R.length,
  passthroughLog,
)(input)

