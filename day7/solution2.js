const R = require('ramda')
const {passthroughLog, loadFile, branches, convergeWith} = require('../util')

const input = __dirname + '/input1'

// the recursive implementation was a bit too inefficient :(
const xprodN = (...arrs) =>
  arrs.reduce((acc, curr) => acc.flatMap(a => curr.map(b => [...a, b])), [[]])

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
    if (acc == null) return () => val
    if (val == '+') return x => x + acc(val)
    if (val == '*') return x => x * acc(val)
    if (val == '||') return x => +`${acc(val)}${x}`
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
        xs => selections(xs.length - 1, ['+', '*', '||'])
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


