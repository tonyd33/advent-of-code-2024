const {assert, assertEq} = require('../util')
const {done, simulate} = require('./lib')

// assert(done([ ['^', '.'] ]))
// assert(done([ ['<', '.'] ]))
// assert(done([ ['v', '.'] ]))
// assert(done([ ['.', '>'] ]))
// assert(!done([ ['.', '>', '.'] ]))

assertEq(
  simulate([
    '....'+
    '....'+
    '..#.'+
    '.v..',
    [4, 4],
  ]),
  [[[1, 3]], [
    '....'+
    '....'+
    '..#.'+
    '.v..',
    [4, 4]
  ]]
)
assertEq(
  simulate([
    '....'+
    '....'+
    '>.#.'+
    '....',
    [4, 4],
  ]),
  [[[0, 2], [1, 2], [1,3]], [
    '....'+
    '....'+
    '..#.'+
    '.v..',
    [4, 4]
  ]]
)
