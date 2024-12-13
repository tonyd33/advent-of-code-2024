const R = require('ramda')
const {passthroughLog, loadFile} = require('../util')

const input = __dirname + '/input1'

// type Node = [value, x, y]
// type Graph = {nodes: [Node], edges: {string: [Node]}}

const nodeKey = ([value, x, y]) => `${value}_${x}_${y}`
const edgesOfNode = R.curryN(2, (node, graph) =>
  graph.edges[nodeKey(node)] ?? []
)
const accessGrid = R.curryN(2, ([x, y], grid) => grid[y]?.[x])

const bfsPeaks = R.curryN(2, (start, graph) => {
  // we going imperative on this one. JS is really not optimized for recursion
  // (no TCO) and creating new objects like sets and arrays is slooow
  const visited = new Set([nodeKey(start)])
  const q = [start]
  const endNodes = new Set()

  while (q.length) {
    const currNode = q.shift()
    const [cellValue] = currNode
    if (cellValue === 9) endNodes.add(nodeKey(currNode))

    const unvisitedConnectedNodes =
      edgesOfNode(currNode, graph)
      .filter(node => !visited.has(nodeKey(node)))
    unvisitedConnectedNodes.forEach(node => {
      visited.add(nodeKey(node))
      q.push(node)
    })
  }

  return endNodes.size
})

R.pipe(
  // load input
  loadFile,
  R.split('\n'),
  R.init,
  R.map(R.pipe(R.split(''), R.map(x => +x))),
  // Grid -> Graph
  grid => {
    const nodes = grid.flatMap((row, y) => row.map((cell, x) => [cell, x, y]))
    const edgesFlat = grid.flatMap((row, y) =>
      row.flatMap((cell, x) =>
        [[x, y + 1], [x, y - 1], [x + 1, y], [x - 1, y]]
        .map(toCoord => [accessGrid(toCoord, grid), ...toCoord])
        .filter(([toCell]) => toCell !== undefined && toCell === cell + 1)
        .map(toNode => [nodeKey([cell, x, y]), toNode])
      )
    )
    const edges = R.flow(edgesFlat, [R.groupBy(R.head), R.map(R.map(R.last))])
    return {nodes, edges}
  },
  // find the starting nodes
  graph => graph.nodes.filter(([cell]) => cell === 0).map(node => [node, graph]),
  R.map(R.apply(bfsPeaks)),
  R.sum,
  passthroughLog,
)(input)
