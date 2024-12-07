const fs = require("fs");
const R = require("ramda");

const passthroughLog = (x) => {
  console.log(x);
  return x;
};

const takeAndSort = (m) => R.pipe(R.map(m), R.sort(R.subtract))

R.pipe(
  // load input
  R.partialRight(fs.readFileSync, ['utf8']),
  // sanitize
  R.split('\n'),
  R.filter(line => line.length > 0),
  R.map(line => line.replace(/\s+/, ' ').split(' ').map(v => +v)),
  // put left and right into own buckets and sort them
  R.converge(R.zip, [takeAndSort(R.head), takeAndSort(R.last)]),
  // take diff
  R.map(R.pipe(R.apply(R.subtract), Math.abs)),
  // sum
  R.sum,
  passthroughLog,
)('./input1');
