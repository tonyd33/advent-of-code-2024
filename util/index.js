const fs = require('fs')
const R = require("ramda")

const passthroughLog = (x) => {
  console.log(x)
  return x
}

const loadFile = R.partialRight(fs.readFileSync, ["utf8"])

module.exports = {
  passthroughLog,
  loadFile,
};
