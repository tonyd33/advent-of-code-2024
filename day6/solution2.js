const R = require('ramda')
const {passthroughLog, loadFile, branch, assert} = require('../util')
const {simulateSafe, setGrid, accessGrid, passthroughGrid} = require('./lib')

const input = __dirname + '/input1'

R.pipe(
  // load input
  loadFile,
  R.split('\n'),
  R.init,
  lines => [lines.join(''), [lines[0].length, lines.length]],
  grid => {
    const [, [xLen, yLen]] = grid
    return R.range(0, yLen)
      .map(y => R.range(0, xLen)
      .map(x => [x, y]))
      .flat()
      // cull out values that are already set to obstacle or is the guard
      .filter(R.pipe(accessGrid(R.__, grid), R.complement(R.test(/\^|v|>|<|\#/))))
      .map(setGrid(R.__, '#', grid))
  },
  grids => grids.reduce(([totalTime, results], grid, idx) => {
    const start = Date.now()
    const [,, ret] = simulateSafe(grid)
    const duration = Date.now() - start
    const newTotalTime = totalTime + duration
    const remaining = grids.length - idx + 1
    const avgTime = newTotalTime / (idx + 1)
    console.log(`iter ${idx + 1}/${grids.length}: ${Math.floor(duration / 1000)}s. Total: ${Math.floor(newTotalTime / 1000)}s. Avg: ${Math.floor(avgTime / 1000)}s. Expected remaining: ${Math.floor(avgTime * remaining / 1000)}s`)
    return [newTotalTime, [...results, ret]]
  }, [0, []]),
  R.nth(1),
  R.filter(R.identity),
  R.length,
  passthroughLog,
)(input)

