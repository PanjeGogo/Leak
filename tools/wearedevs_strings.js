#!/usr/bin/env node
/**
 * Layer-2 static decoder for WeAreDevs-style Lua string tables.
 *
 * It only parses the literal string table near `local m={...}` and decodes
 * Lua numeric escapes. It never evaluates Lua, invokes loadstring, or makes
 * network requests.
 */

const fs = require('fs');
const path = require('path');

const input = process.argv[2] || path.join(__dirname, '..', 'output', 'upstream.lua');
const text = fs.readFileSync(input, 'utf8');

function findTableStart(src) {
  const m = src.match(/\blocal\s+m\s*=\s*\{/);
  if (!m) throw new Error('Could not locate `local m={` string table.');
  return m.index + m[0].length;
}

function findTableEnd(src, start) {
  let depth = 1;
  let quote = null;
  let escaped = false;
  for (let i = start; i < src.length; i++) {
    const c = src[i];
    if (quote) {
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === quote) quote = null;
      continue;
    }
    if (c === '"' || c === "'") { quote = c; continue; }
    if (c === '{') depth++;
    else if (c === '}' && --depth === 0) return i;
  }
  throw new Error('Unterminated string table.');
}

function decodeLuaEscapes(s) {
  return s.replace(/\\([0-9]{1,3})/g, (_, digits) => {
    const n = Number(digits);
    return n <= 255 ? String.fromCharCode(n) : `\\${digits}`;
  });
}

function parseStrings(src, baseOffset) {
  const out = [];
  let quote = null, escaped = false, start = -1;
  for (let i = 0; i < src.length; i++) {
    const c = src[i];
    if (!quote) {
      if (c === '"' || c === "'") { quote = c; start = i + 1; escaped = false; }
      continue;
    }
    if (escaped) { escaped = false; continue; }
    if (c === '\\') { escaped = true; continue; }
    if (c === quote) {
      const raw = src.slice(start, i);
      out.push({ raw, decoded: decodeLuaEscapes(raw), index: baseOffset + start - 1 });
      quote = null;
    }
  }
  return out;
}

const tableStart = findTableStart(text);
const tableEnd = findTableEnd(text, tableStart);
const tableText = text.slice(tableStart, tableEnd);
const strings = parseStrings(tableText, tableStart);

const urlRe = /https?:\/\/[^\s"'<>\]\)}`]+/gi;
const urls = [];
const seen = new Set();
for (const item of strings) {
  for (const m of item.decoded.matchAll(urlRe)) {
    const url = m[0].replace(/[;,]+$/, '');
    if (!seen.has(url)) {
      seen.add(url);
      urls.push({ url, tableOffset: item.index });
    }
  }
}

console.log(`Input: ${input}`);
console.log(`String table bytes: ${Buffer.byteLength(tableText, 'utf8')}`);
console.log(`Encoded strings: ${strings.length}`);
console.log(`Decoded strings containing URLs: ${urls.length}`);
console.log('');

for (const item of urls) console.log(`[decoded-url] offset=${item.tableOffset} ${item.url}`);

const interesting = strings.filter(x => /https?:\/\/|HttpGet|HttpPost|loadstring|request|webhook|discord\.gg/i.test(x.decoded));
console.log('');
console.log(`Interesting decoded strings: ${interesting.length}`);
for (const item of interesting.slice(0, 200)) {
  console.log(`[decoded-string] offset=${item.index} ${JSON.stringify(item.decoded)}`);
}

if (interesting.length > 200) console.log(`... ${interesting.length - 200} more omitted`);
