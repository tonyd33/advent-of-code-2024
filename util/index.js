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

const aperture2d = (rowSize, colSize) => R.pipe(
  // Grid -> [Grid]
  // each entry is a grid with a 3 row window of the original grid
  R.aperture(rowSize),
  // [Grid] -> [[Grid]]
  // take each 3 row window and turn it into an array of 3x3 windows
  R.map(R.pipe(
    // Grid -> [[[string]]]
    // each entry is a [[string]] corresponding to a row of the grid.
    // the [[string]] entries are windows of the row.
    R.map(R.aperture(colSize)),
    // [[[string]]] -> [Grid]
    R.apply(zipN),
  )),
)


module.exports = {
  passthroughLog,
  stringifiedPassthroughLog,
  loadFile,
  zipN,
  aperture2d,
};
