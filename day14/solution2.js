const fs = require('fs')
const R = require('ramda')
const {createCanvas} = require('canvas')
const {passthroughLog, loadFile} = require('../util')

const input = __dirname + '/input1'

const grid = [101, 103]
const cellSize = 1

const canvasSize = [(grid[0] ** 2) * cellSize, (grid[1] ** 2) * cellSize]
const canvas = createCanvas(...canvasSize)
const canvasCtx = canvas.getContext('2d')
// canvasCtx.fillStyle = 'white'
// canvasCtx.fillRect(0, 0, ...canvasSize)
// canvasCtx.fillStyle = 'black'

// number-theoretic modulo
const mod = (n, m) => ((n % m) + m) % m

// type Robot = [x, y, vx, vy]
// type Grid = [maxX, maxY]

const updateRobot = R.curryN(3, ([x, y, vx, vy], [maxX, maxY], times) => {
  const newX = mod(x + vx * times, maxX)
  const newY = mod(y + vy * times, maxY)

  return [newX, newY, maxX, maxY]
})

const updateRobots = R.curryN(3, (robots, grid, times) =>
  R.map(updateRobot(R.__, grid, times), robots)
)

// string -> Robot
const parseRobot = line =>
  line
  .match(/^p=(-?\d+),(-?\d+)\s+v=(-?\d+),(-?\d+)/)
  .slice(1, 5)
  .map(x => +x)

const drawGrid = R.curryN(3, (robots, [maxX, maxY], index) => {
  const baseX = (index % maxX) * maxX
  const baseY = Math.floor(index / maxX) * maxY
  robots.map(([x, y]) => {
    const realX = (x + baseX) * cellSize
    const realY = (y + baseY) * cellSize

    if (realX === 2359 && realY === 7233) {
      console.log(index)
    }
    canvasCtx.fillRect(realX, realY, cellSize, cellSize)
  })
})

R.pipe(
  // load input
  loadFile,
  R.trim,
  R.split('\n'),
  R.map(parseRobot),
  robots =>
    R.range(0, grid[0] * grid[1])
    .map(i => {
      const updatedRobots = updateRobots(robots, grid, i)
      drawGrid(updatedRobots, grid, i)
    }),
)(input)

fs.writeFileSync(__dirname + '/img.png', canvas.toBuffer('image/png'))
