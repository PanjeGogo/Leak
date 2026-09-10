const fs = require('node:fs');

const file = process.argv[2] || 'output/getgold.lua';
if (!fs.existsSync(file)) {
  console.error(`File not found: ${file}`);
  process.exit(1);
}

const src = fs.readFileSync(file, 'utf8');
const count = (re) => (src.match(re) || []).length;

console.log(`file: ${file}`);
console.log(`bytes: ${Buffer.byteLength(src)}`);
console.log(`lines: ${src.split(/\r?\n/).length}`);
console.log(`functions: ${count(/\bfunction\b/g)}`);
console.log(`loadstring: ${count(/\bloadstring\b/g)}`);
console.log(`HttpGet: ${count(/\bHttpGet\b/g)}`);
console.log(`HttpRequest: ${count(/\bHttpRequest\b/g)}`);
console.log(`require: ${count(/\brequire\s*\(/g)}`);
console.log(`getgenv: ${count(/\bgetgenv\b/g)}`);
console.log(`hookfunction: ${count(/\bhookfunction\b/g)}`);
console.log(`setclipboard: ${count(/\bsetclipboard\b/g)}`);
console.log(`webhook URLs: ${count(/https?:\/\/[^\s"']+/gi)}`);

const urls = [...src.matchAll(/https?:\/\/[^\s"']+/gi)].map(m => m[0]);
if (urls.length) {
  console.log('\nURLs:');
  for (const url of [...new Set(urls)]) console.log(`- ${url}`);
}
