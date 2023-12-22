const resolve = require('enhanced-resolve')

const dir = __dirname
const specifier = 'test-esm-exports-array'

console.log('dir:', dir)
console.log('specifier:', specifier)

resolve(dir, specifier, (err, res) => {
  console.log('resolved: ', err || res)
});
