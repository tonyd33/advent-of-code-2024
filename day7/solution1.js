const R = require('ramda')
const {passthroughLog, loadFile, branches, convergeWith} = require('../util')

const input = __dirname + '/input1'

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

// number -> [a] -> [[a]]
// selections(3, [a, b]) ->
//  [[a, a, a], [a, a, b], ..., [b, b, b]]
const selections = R.curryN(2, (n, arr) =>
  R.flow(n, [
    R.times(R.always(arr)),
    R.apply(xprodN)
  ])
)

// [a] -> [a] -> [a]
// sprinkle(['+', '*'], [1, 3, 5]) -> [1, '+', 3, '*', 5]
const sprinkle = R.curryN(2, (sprinklers, arr) => sprinklers.reduce(
  (currArr, val, index) => R.insert(2 * index + 1, val, currArr),
  arr
))

const l2reval = arr => R.reduce(
  (acc, val) => {
    if (val == '+') return x => x + acc(val)
    if (val == '*') return x => x * acc(val)
    if (acc == null) return () => val
    else return () => acc(val)
  },
  null,
  arr
)()


R.pipe(
  // load input
  loadFile,
  R.split('\n'),
  R.init,
  R.map(R.pipe(
    R.split(':'),
    branches([
      x => +x,
      R.pipe(
        R.trim,
        R.split(' '),
        R.map(x => +x),
        xs => selections(xs.length - 1, ['+', '*'])
              .map(operatorPerm => sprinkle(operatorPerm, xs)),
        R.map(l2reval),
      )
    ]),
  )),
  R.filter(([num, vals]) => R.any(R.equals(num), vals)),
  R.map(R.head),
  R.sum,
  passthroughLog,
)(input)

