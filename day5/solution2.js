const R = require('ramda')
const {
  passthroughLog,
  loadFile,
  branch,
  branches,
  convergeWith
} = require('../util')

const input = __dirname + '/input1'

// [string] -> ((a, b) -> number)
// compile a comparator function
const compileOrder = R.pipe(
  // [string] -> [[string, string]]
  R.map(R.split('|')),
  R.groupBy(R.head),
  // [[string, string]] -> {string: {string: boolean}}
  // this defines an order where obj[a][b] is truthy iff a < b
  R.map(R.pipe(
    R.map(R.last),
    R.converge(
      R.zipObj,
      [R.identity, R.pipe(R.length, R.range(0), R.map(R.always(true)))]
    )
  )),
  // {string: {string: boolean}} -> (a, b) -> boolean
  order => (a, b) => !!(order[a]?.[b]),
  // (a, b) -> boolean -> (a, b) -> number
  R.comparator,
)

const isSorted = comparator => R.converge(
  R.equals,
  [R.pipe(R.sort(comparator), R.join(',')), R.join(',')],
)

R.pipe(
  // load input
  loadFile,
  // string -> [string, string]
  R.split('\n\n'),
  // [string, string] -> [[string], [string]]
  branch([
    R.pipe(R.head, R.split('\n')),
    R.pipe(R.last, R.split('\n'), R.init)
  ]),
  // [[string], [string]] -> [comparator, [[string]]]
  branches([
    compileOrder,
    R.map(R.split(',')),
  ]),
  // [comparator, [[string]]] -> [[string], boolean]
  ([comparator, lines]) => R.map(
    branch([R.sort(comparator), R.complement(isSorted(comparator))]),
    lines
  ),
  R.filter(R.last),
  // [[string], boolean] -> [number]
  R.map(R.pipe(
    R.head,
    (xs) => +xs[Math.floor(xs.length / 2)]
  )),
  R.sum,
  passthroughLog,
)(input)
