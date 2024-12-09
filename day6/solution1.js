const R = require('ramda')
const {passthroughLog, loadFile, branch, assert} = require('../util')
const {simulate} = require('./lib')

const input = __dirname + '/input1'

R.pipe(
  // load input
  loadFile,
  R.split('\n'),
  R.init,
  lines => [lines.join(''), [lines[0].length, lines.length]],
  // Grid -> [[Coord], Grid]
  simulate,
  R.head,
  R.uniqBy(R.join(',')),
  R.length,
  passthroughLog,
)(input)
