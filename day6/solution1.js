const R = require('ramda')
const {passthroughLog, loadFile, branch, assert} = require('../util')
const {simulate} = require('./lib')

const input = __dirname + '/input1'

const update = (path, grid) => {
  const [guardOri, guardPos] = findGuard(grid)
}


R.pipe(
  // load input
  loadFile,
  R.split('\n'),
  R.init,
  R.map(R.split('')),
  // Grid -> [[Coord], Grid]
  simulate,
  R.head,
  R.uniq,
  R.length,
  passthroughLog,
)(input)
