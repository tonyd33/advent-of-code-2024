const R = require('ramda')
const {passthroughLog, loadFile} = require('../util')

const input = __dirname + '/input1'

// [int] -> int -> int
const count = rights => left => R.count(R.equals(left), rights)

R.pipe(
  // load input
  loadFile,
  // sanitize
  R.split('\n'),
  R.filter(line => line.length > 0),
  R.map(line => line.replace(/\s+/, ' ').split(' ').map(v => +v)),
  // get occurrences
  // [[int, int]] -> [[int], [int]]
  R.transpose,
  passthroughLog,
  // [[int], [int]] -> [int]
  ([lefts, rights]) => lefts.map(R.converge(R.multiply, [count(rights), R.identity])),
  R.sum,
  passthroughLog,
)(input)
