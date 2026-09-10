#!/usr/bin/env node
/**
 * Static Lua URL-capture emulator.
 *
 * Purpose: inspect Lua source and identify URLs that would be passed to
 * common HTTP-loading APIs without executing the Lua program.
 *
 * This is intentionally NOT a Roblox runtime and does not execute arbitrary
 * Lua, loadstring, remote code, or filesystem/network side effects.
 */

const fs = require('fs');
const path = require('path');

const input = process.argv[2] || path.join(__dirname, '..', 'output', 'getgold.lua');
const text = fs.readFileSync(input, 'utf8');

const findings = [];
const seen = new Set();

function add(kind, url, index) {
  const key = `${kind}|${url}`;
  if (seen.has(key)) return;
  seen.add(key);
  findings.push({ kind, url, index });
}

// Direct string URLs.
const urlRe = /https?:\/\/[^\s"'<>\]\)}`]+/gi;
for (const m of text.matchAll(urlRe)) add('literal-url', m[0].replace(/[;,]+$/, ''), m.index);

// Common Roblox HTTP loaders. We capture both literal and simple concatenated
// string expressions; dynamic expressions are reported separately.
const callRe = /(?:game\s*:\s*)?(HttpGet|HttpGetAsync|HttpPost|HttpPostAsync|request|http_request|syn\.request|http\.request)\s*\(([^\n]{0,1000})\)/gi;
for (const m of text.matchAll(callRe)) {
  const expr = m[2].trim();
  const quoted = [...expr.matchAll(/(["'])(.*?)\1/g)].map(x => x[2]);
  const candidate = quoted.join('');
  if (/^https?:\/\//i.test(candidate)) add(m[1].toLowerCase(), candidate, m.index);
  else findings.push({ kind: `${m[1].toLowerCase()}-dynamic`, expression: expr.slice(0, 300), index: m.index });
}

// loadstring(HttpGet(...)) pattern, useful for identifying remote execution
// boundaries without executing anything.
const remoteExecRe = /loadstring\s*\(\s*(?:game\s*:\s*)?HttpGet(?:Async)?\s*\(([^\n]{0,1000})\)\s*\)/gi;
for (const m of text.matchAll(remoteExecRe)) {
  const expr = m[1].trim();
  const q = expr.match(/^(["'])(.*?)\1$/);
  findings.push({ kind: 'remote-loadstring', url: q ? q[2] : undefined, expression: q ? undefined : expr.slice(0, 300), index: m.index });
}

findings.sort((a, b) => a.index - b.index);

console.log(`Input: ${input}`);
console.log(`Bytes: ${Buffer.byteLength(text, 'utf8')}`);
console.log(`Lines: ${text.split(/\r?\n/).length}`);
console.log(`Findings: ${findings.length}`);
console.log('');

for (const f of findings) {
  const location = `offset=${f.index}`;
  if (f.url) console.log(`[${f.kind}] ${location} ${f.url}`);
  else console.log(`[${f.kind}] ${location} ${f.expression || '(dynamic URL)'}`);
}

if (findings.length === 0) {
  console.log('No URL/HTTP loader pattern found statically.');
}
