const R = require('ramda')
const {passthroughLog, loadFile} = require('../util')

const input = __dirname + '/input1'

const domuls = R.pipe(
  x => x.match(/mul\((\d{1,3}),(\d{1,3})\)/g),
  R.map(R.pipe(
    R.match(/mul\((\d{1,3}),(\d{1,3})\)/),
    R.slice(1,3),
    R.apply(R.multiply),
  )),
  R.sum,
)

R.pipe(
  // load input
  loadFile,
  R.split(/(do\(\)|don't\(\))/),
  // start with do()
  R.prepend("do()"),
  R.splitEvery(2),
  R.map(R.pipe(
    ([act, str]) => [act, domuls(str)],
    R.ifElse(
      R.pipe(R.head, R.equals("don't()")),
      R.always(0),
      R.last,
    )
  )),
  R.sum,
  passthroughLog,
)(input)

