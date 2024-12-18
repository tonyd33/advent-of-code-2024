const R = require('ramda')
const {xprodN} = require('../util')

// number-theoretic modulo
const mod = (n, m) => ((n % m) + m) % m

const phi = rax => {
  const tmp = mod(rax, 8) ^ 1
  return mod(tmp ^ Math.floor(rax / (2 ** tmp)) ^ 4, 8)
}

const simulate = rax => {
  const out = []
  do {
    out.push(phi(rax))
    rax = Math.floor(rax / 8)
  } while(rax != 0)
  return out
}

const buildPhiInv = R.pipe(
  R.range(0, R.__),
  xs => xs.map((val, idx) => [idx, phi(idx)]),
  R.groupBy(([idx, val]) => val),
  R.map(R.map(([idx, val]) => idx)),
  obj => n => obj[n]
)

const fromBase8Arr =
  xs => xs.reduce((acc, value, idx) => acc + value * 8 ** idx)

const _toBase8ArrRec = n => {
  if (n === 0) return []
  return [n % 8, ..._toBase8ArrRec(Math.floor(n / 8))]
}
const toBase8Arr = num => {
  if (num === 0) return [0]
  return _toBase8ArrRec(num)
}

const zeroFillBase8Arr = R.curryN(2, (n, arr) => {
  if (arr.length >= n) return arr
  const remaining = n - arr.length
  return [...arr, ...R.times(() => 0, remaining)]
})

// digitsAgree(3, [_, 1, 2, 3], [1, 2, 3, _]) === true
// digitsAgree(2, [_, _, 2, 3], [1, 2, _, _]) === true
const digitsAgree = R.curryN(3, (n, starts, ends) => {
  const endSlice = ends.slice(0, n)
  const startSlice = starts.slice(starts.length - n)
  return endSlice.join(",") === startSlice.join(",")
})

// can obtain analytically by analyzing phi.
// or just brute force computations until the cycle length is found :)
const cycleLen = 8 ** 4
const phiInv = buildPhiInv(cycleLen)

// immutable JS array manipulation is kind of annoying here... imperative is
// not so bad
const constrainBackward = possibilities => {
  for (let i = possibilities.length - 1; i >= 0; i--) {
    const {values} = possibilities[i]
    for (let j = i - 1; j >= Math.max(i - 4, 0); j--) {
      const {values: valuesJ} = possibilities[j]
      possibilities[j].values = possibilities[j].values
        .filter(v => values.some(v0 => digitsAgree(4 - i + j, v, v0)))
    }
  }
  return possibilities
}

const constrainForward = possibilities => {
  for (let i = 0; i < possibilities.length; i++) {
    const {values} = possibilities[i]
    for (let j = i + 1; j < Math.min(i + 4, possibilities.length); j++) {
      const {values: valuesJ} = possibilities[j]
      possibilities[j].values = possibilities[j].values
        .filter(v => values.some(v0 => digitsAgree(4 - j + i, v0, v)))
    }
  }
  return possibilities
}

function main() {
  const target = [2,4,1,1,7,5,4,7,1,4,0,3,5,5,3,0]
  const targetStr = target.join("")

  let possibilities = target
    .map((t, i) => {
      const modulo = 8 ** (Math.max(target.length - i, 4))
      return ({
        i, t,
        values: R.flow(phiInv(t), [
          R.map(R.pipe(x => mod(x, modulo))),
          R.uniq,
          R.map(R.pipe(toBase8Arr, zeroFillBase8Arr(4))),
        ])
    })})
  possibilities = constrainBackward(possibilities)
  possibilities = constrainForward(possibilities)

  let digitPossibilities = R.transpose(possibilities[0].values)
  digitPossibilities = [
    ...digitPossibilities,
    // the last three digits don't actually exist
    ...possibilities.slice(1, -3).map(({values}) => values.map(v => v[3]))
  ]
  digitPossibilities = digitPossibilities.map(digits => R.uniq(digits))
  let digitPossibilitiesProd = xprodN(...digitPossibilities)

  let base10Possibilities = digitPossibilitiesProd
    .map(fromBase8Arr)
  // we have to filter here. i *think* my constraining logic was mostly fine,
  // it's just that i didn't restrict the last few values enough.
  // it's a small enough search space anyway, so w/e
  let workingPossibilities = base10Possibilities
    .filter(pos => {
      const sim = simulate(pos)
      return sim.join("") === targetStr
    })

  let smallest = R.sort(R.subtract, workingPossibilities)[0]
  console.log(smallest)
}

main()

