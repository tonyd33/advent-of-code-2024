let rax = 8 ** 15
let rbx = 0
let rcx = 0

let out = []
let outSim = []

const mod = (n, m) => ((n % m) + m) % m

function phi(n) {
  const tmp = mod(rax, 8) ^ 1
  return mod(tmp ^ Math.floor(rax / (2 ** tmp)) ^ 4, 8)
}

do {
  outSim.push(phi(rax))
  // bst
  rbx = rax % 8
  // bxl
  rbx = rbx ^ 1
  // cdv
  rcx = Math.floor(rax / (2 ** rbx))
  // bxc
  rbx = rbx ^ rcx
  // bxl
  rbx = rbx ^ 4
  // adv
  rax = Math.floor(rax / (2 ** 3))
  // out
  out.push(rbx % 8)
} while (rax != 0)

console.log(out, out2)
