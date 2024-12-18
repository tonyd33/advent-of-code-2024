const fs = require('fs')
const R = require("ramda")

const passthroughLog = R.tap(console.log)

const stringifiedPassthroughLog = (...stringifyArgs) => x => R.pipe(
  R.partialRight(JSON.stringify, [...stringifyArgs]),
  passthroughLog,
)(x)

const loadFile = R.partialRight(fs.readFileSync, ["utf8"])

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
    R.transpose,
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

const xprodN = (first, ...rest) => {
  if (rest.length === 0) return first.map(x => [x])
  if (rest.length === 1) return R.xprod(first, rest[0])
  else {
    return R.flow(
      xprodN(...rest),
      [R.xprod(first), R.flatten(), R.splitEvery(rest.length + 1)]
    )
  }
}

const assert = bool => {
  if (!bool) throw new Error('Assertion failed')
}
const assertEq = (v1, v2) => {
  if (!R.equals(v1, v2))
    throw new Error(`Assertion failed.
${JSON.stringify(v1, null, 2)} !== ${JSON.stringify(v2, null, 2)}
`)
}

module.exports = {
  passthroughLog,
  stringifiedPassthroughLog,
  loadFile,
  aperture2d,
  branch,
  branches,
  convergeWith,
  xprodN,
  assert,
  assertEq
};
