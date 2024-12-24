const graphviz = require('graphviz')
const R = require('ramda')
const {passthroughLog, loadFile, branches} = require('../util')

const input = __dirname + '/input1-modif'

const [inputs, wires] = R.pipe(
  // load input
  loadFile,
  R.trim,
  R.split("\n\n"),
  branches([
    inputs =>
      inputs
        .split("\n")
        .map(x => x.split(': ').map(([vari, bool]) => ({vari, val: !!+bool}))),
    wires =>
      wires
        .split("\n")
        .map(x => {
          const matches = x
            .match(/^([a-zA-Z0-9]+) (XOR|AND|OR) ([a-zA-Z0-9]+) -> ([a-zA-Z0-9]+)$/)
          return {
            left: matches[1],
            op: matches[2],
            right: matches[3],
            into: matches[4]
          }
        })
  ]),
  branches([
    inputs => R.zipObj(inputs.map(x => x.vari), inputs),
    wires => R.zipObj(wires.map(x => x.into), wires)
  ]),
)(input)

const g = graphviz.digraph("G")
// g.set("splines", "ortho")

const alreadyEdged = new Set()

const toTree = (wires, item) => {
  const node = wires[item]
  if (!node) {
    g.addNode(item)
    return {type: 'leaf', into: item}
  } else {
    const left = toTree(wires, node.left)
    const right = toTree(wires, node.right)
    const out = {type: 'node', left, right, op: node.op, into: item}

    g.addNode(node.into, {label: `${node.op} = ${node.into}`})
    if (!alreadyEdged.has(`${node.left}->${node.into}`)) {
      g.addEdge(node.left, node.into)
      alreadyEdged.add(`${node.left}->${node.into}`)
    }
    if (!alreadyEdged.has(`${node.right}->${node.into}`)) {
      g.addEdge(node.right, node.into)
      alreadyEdged.add(`${node.right}->${node.into}`)
    }

    return out
  }
}

const zs = Object.keys(wires).filter(x => x.startsWith("z"))
const zDict = R.zipObj(zs, zs.map(z => toTree(wires, z)))

const toIndex = x => {
  return x.match(/(x|y|z)(\d+)/)[2]
}

const oneOfChildrenMatching = (node, fn) =>
  node.type === 'leaf' ? null :
  fn(node.left) ? node.left :
  fn(node.right) ? node.right :
  null

// go through each and look structurally
const checkStructure = (zRoot) => {
  const weirds = []
  // level 0
  const XOR0 = zDict[zRoot]
  if (XOR0.op !== 'XOR') {
    weirds.push([XOR0, {type: 'immediate', expected: 'XOR'}])
    return weirds
  }

  // level 1
  const OR1 = oneOfChildrenMatching(XOR0, x => x.op === 'OR')
  const XOR1 = oneOfChildrenMatching(XOR0, x => x.op === 'XOR')

  if (!OR1) weirds.push([XOR0, {type: 'child', expected: 'OR'}])
  if (!XOR1) weirds.push([XOR0, {type: 'child', expected: 'XOR'}])

  // level 2: dig into xor
  if (XOR1) {
    g
      .edges
      .find(x => x.nodeTwo.id === XOR0.into && x.nodeOne.id === XOR1.into)
      ?.set('color', 'green')

    const x = oneOfChildrenMatching(XOR1, x => x.into.startsWith('x'))
    const y = oneOfChildrenMatching(XOR1, y => y.into.startsWith('y'))
    if (!x) weirds.push([XOR1, {type: 'child', expected: 'x'}])
    if (!y) weirds.push([XOR1, {type: 'child', expected: 'y'}])
  }

  if (OR1) {
    g
      .edges
      .find(x => x.nodeTwo.id === XOR0.into && x.nodeOne.id === OR1.into)
      ?.set('color', 'green')
    // the one on the right
    const AND21 = oneOfChildrenMatching(OR1,
      x => x.op === 'AND' &&
      oneOfChildrenMatching(x, y => y.into.startsWith('x')) &&
      oneOfChildrenMatching(x, y => y.into.startsWith('y'))
    )
    // the one on the left
    const AND22 = oneOfChildrenMatching(OR1,
      x => x.op === 'AND' &&
      oneOfChildrenMatching(x, y => y.op === 'XOR') &&
      oneOfChildrenMatching(x, y => y.op === 'OR')
    )

    if (!AND21) weirds.push([OR1, {type: 'child', expected: 'AND1'}])
    if (!AND22) weirds.push([OR1, {type: 'child', expected: 'AND2'}])

    if (AND21) {
      g
        .edges
        .find(x => x.nodeTwo.id === OR1.into && x.nodeOne.id === AND21.into)
        ?.set('color', 'green')
      g
        .edges
        .find(x => x.nodeTwo.id === AND21.into && x.nodeOne.id === AND21.left.into)
        .set('color', 'green')
      g
        .edges
        .find(x => x.nodeTwo.id === AND21.into && x.nodeOne.id === AND21.right.into)
        .set('color', 'green')
    }

    if (AND22) {
      g
        .edges
        .find(x => x.nodeTwo.id === OR1.into && x.nodeOne.id === AND22.into)
        ?.set('color', 'green')
      const XOR3 = oneOfChildrenMatching(AND22,
        x => x.op === 'XOR' &&
        oneOfChildrenMatching(x, y => y.into.startsWith('x')) &&
        oneOfChildrenMatching(x, y => y.into.startsWith('y'))
      )
      const idxBefore = `${toIndex(zRoot) - 1}`.padStart(2, '0')
      const zBefore = `z${idxBefore}`
      const zBeforeOR =
        zDict[zBefore] ? oneOfChildrenMatching(zDict[zBefore],
          x => x.op === 'OR'
        ) : null
      const OR3 = oneOfChildrenMatching(AND22,
        x => x.op === 'OR' && zBeforeOR?.into === x.into
      )

      if (XOR3) {
        g
          .edges
          .find(x => x.nodeTwo.id === AND22.into && x.nodeOne.id === XOR3.into)
          ?.set('color', 'green')
        g
          .edges
          .find(x => x.nodeTwo.id === XOR3.into && x.nodeOne.id === XOR3.left.into)
          ?.set('color', 'green')
        g
          .edges
          .find(x => x.nodeTwo.id === XOR3.into && x.nodeOne.id === XOR3.right.into)
          ?.set('color', 'green')
      }
      if (OR3) {
        g
          .edges
          .find(x => x.nodeTwo.id === AND22.into && x.nodeOne.id === OR3.into)
          ?.set('color', 'green')
      }

      if (!XOR3) weirds.push([AND22, {type: 'child', expected: 'XOR'}])
      if (!OR3) weirds.push([AND22, {type: 'child', expected: 'OR'}])
    }
  }

  return weirds
}

zs.flatMap(checkStructure).forEach((x) => {
  g.nodes.getItem(x[0].into).set('color', 'red')
})

g.output("png", "test02.png")
