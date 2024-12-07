const R = require('ramda')
const {passthroughLog, loadFile} = require('../util')

const input = __dirname + '/input1'

R.pipe(
  // load input
  loadFile,
  passthroughLog,
)(input)
