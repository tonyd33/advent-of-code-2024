const fs = require('fs')
const R = require("ramda")

const passthroughLog = x => {
  console.log(x)
  return x
}

const stringifiedPassthroughLog = (...stringifyArgs) => x => R.pipe(
  R.partialRight(JSON.stringify, [...stringifyArgs]),
  passthroughLog,
)(x)

const loadFile = R.partialRight(fs.readFileSync, ["utf8"])

// like zip, but works for any number of arrays to zip.
// e.g. [1, 2], [3, 4], [5, 6], [7, 8] -> [1, 3, 5, 7], [2, 4, 6, 8]
// indices = [0, 1]
const zipN = R.converge(
  (indices, xss) => indices.map(idx => xss.map(xs => xs[idx])),
  R.map(R.unapply, [
    R.pipe(R.map(R.length), R.apply(Math.min), R.range(0)),
    R.identity
  ])
)

// like aperture, but works on a 2d array to create 2d windows
const aperture2d = (rowSize, colSize) => R.pipe(
  // Grid -> [Grid]
  // each entry is a grid with a rowSize3 row window of the original grid
  R.aperture(rowSize),
  // [Grid] -> [[Grid]]
  // take each colSize row window and turn it into an array of
  // rowSize x colSize windows
  R.map(R.pipe(
    // Grid -> [[[string]]]
    // each entry is a [[string]] corresponding to a row of the grid.
    // the [[string]] entries are windows of the row.
    R.map(R.aperture(colSize)),
    // [[[string]]] -> [Grid]
    R.apply(zipN),
  )),
)

// [x -> y1, x -> y2, ..., x -> yn] -> [y1, y2, ..., yn]
// takes in x-fns :: x -> yi and applies them to get yi's
const branch = R.converge(R.unapply(R.identity))

// [x1 -> y1, x2 -> y2, ..., xn -> yn] ->
//   [x1, x2, ..., xn] -> [y1, y2, ..., yn]
// continue branching. branch and branches can be done in a single converge,
// but splitting the branches during a pipe may be useful
const branches = R.curryN(2, R.pipe(
  R.zip,
  R.map(R.apply(R.call))
))

// (([x1, x2, ..., xn]) -> y) -> [x1, x2, ..., xn] -> y
// after branching, converge the branches back
const convergeWith = fn => arr => fn(arr)

module.exports = {
  passthroughLog,
  stringifiedPassthroughLog,
  loadFile,
  zipN,
  aperture2d,
  branch,
  branches,
  convergeWith
};
