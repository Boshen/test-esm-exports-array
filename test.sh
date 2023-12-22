echo 'From Node.js:'
echo
node -e "require('test-esm-exports-array')"

echo
echo '----------------------------------------'
echo 'From esbuild:'
echo
echo "import('test-esm-exports-array')" | ./node_modules/.bin/esbuild --bundle

echo
echo '----------------------------------------'
echo 'From enhanced-resolve:'
echo
node test-enhanced-resolve.js
