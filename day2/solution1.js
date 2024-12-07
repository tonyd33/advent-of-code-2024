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
const safe = R.either(
  R.all(R.both(inbound, R.gt(R.__, 0))),
  R.all(R.both(inbound, R.lt(R.__, 0)))
)

R.pipe(
  // load input
  loadFile,
  R.split('\n'),
  R.init,
  // [str] -> [[int]]
  R.map(xs => xs.split(' ').map(x => +x)),
  // map f :: [[int]] -> [[int]] where
  //   f :: [int] -> [int]
  //   f [x_i] -> [..., x_{i-1} - x_{i}, x_{i} - x{i+1}, ...]
  R.map(R.pipe(R.aperture(2), R.map(R.apply(R.subtract)))),
  R.map(safe),
  R.filter(R.identity),
  R.length,
  passthroughLog,
)(input)
