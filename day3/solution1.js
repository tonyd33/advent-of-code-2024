const R = require('ramda')
const {passthroughLog, loadFile} = require('../util')

const input = __dirname + '/input1'

R.pipe(
  // load input
  loadFile,
  R.match(/mul\(\d{1,3},\d{1,3}\)/g),
  R.map(R.pipe(
    x => x.match(/mul\((\d{1,3}),(\d{1,3})\)/).slice(1, 3),
    R.apply(R.multiply),
  )),
  R.sum,
  passthroughLog,
)(input)

