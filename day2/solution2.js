const R = require('ramda')
const {passthroughLog, loadFile} = require('../util')

const input = __dirname + '/input1'

const [lower,upper] = [1,3]

const inbound = R.pipe(
  Math.abs,
  R.and(R.gte(R.__, lower), R.lte(R.__, upper))
)
// map f :: [[int]] -> [bool] where
//   f :: [int] -> bool
//   f [x_i] -> (all(x_i > 0) || all(x_i < 0)) && all(inbound(x_i))
const safe1 = R.either(
  R.all(R.both(inbound, R.gt(R.__, 0))),
  R.all(R.both(inbound, R.lt(R.__, 0)))
)

// [int] -> [[int] \ int[i]]
// [1,2,3] -> [[1,2], [1,3], [2,3]]
const removedArrs = R.pipe(
  x => R.range(0, x.length).map(i => [i, x]),
  R.map(R.apply(R.remove(R.__, 1, R.__))),
)

// for each row, see what happens if you remove an element.
// each row will map to true iff removing an element makes it safe1
// in otw, each row is true iff it's safe2
const safe2 = R.pipe(
  // [int] -> [[int]]
  removedArrs,
  // same thing as before on each of the "virtual" arrays
  // map f :: [[int]] -> [[int]] where
  //   f :: [int] -> [int]
  //   f [x_i] -> [..., x_{i-1} - x_{i}, x_{i} - x{i+1}, ...]
  R.map(R.pipe(R.aperture(2), R.map(R.apply(R.subtract)))),
  // [[int]] -> [bool]
  R.map(safe1),
  // now, elt i of the array is true iff removing elt i of the row makes the
  // row safe1. if any of these elts are true, then this row is safe2
  // [bool] -> bool
  R.any(R.identity),
)

R.pipe(
  // load input
  loadFile,
  R.split('\n'),
  R.init,
  // [str] -> [[int]]
  R.map(xs => xs.split(' ').map(x => +x)),
  // [[int]] -> [bool]
  R.map(safe2),
  // [bool] -> [bool]
  R.filter(R.identity),
  // [bool] -> int
  R.length,
  passthroughLog,
)(input)
