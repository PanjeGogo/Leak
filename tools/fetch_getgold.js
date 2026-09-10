const fs = require('node:fs');
const path = require('node:path');

const URL = 'https://getgold.cc';
const OUT = path.join('output', 'getgold.lua');
const RAW = path.join('output', 'response.txt');

function extract(text, contentType) {
  if (/lua/i.test(contentType) || /^(\s*--|\s*local\s|\s*return\s|\s*function\s)/m.test(text)) return text;

  const candidates = [];
  const pre = text.match(/<pre[^>]*>([\s\S]*?)<\/pre>/gi) || [];
  const code = text.match(/<code[^>]*>([\s\S]*?)<\/code>/gi) || [];
  for (const block of [...pre, ...code]) {
    candidates.push(block.replace(/^<[^>]+>/, '').replace(/<\/[^>]+>$/, ''));
  }

  try {
    const json = JSON.parse(text);
    for (const key of ['content', 'script', 'source', 'raw', 'code']) {
      if (typeof json[key] === 'string') candidates.push(json[key]);
    }
  } catch {}

  return candidates.sort((a, b) => b.length - a.length)[0] || '';
}

(async () => {
  fs.mkdirSync('output', { recursive: true });
  const res = await fetch(URL, {
    redirect: 'follow',
    headers: {
      'User-Agent': 'Mozilla/5.0 (compatible; LuaSourceInspector/1.0)',
      'Accept': 'text/plain,text/html,application/json;q=0.9,*/*;q=0.8'
    }
  });
  const text = await res.text();
  fs.writeFileSync(RAW, text);
  const type = res.headers.get('content-type') || '';
  const lua = extract(text, type);

  console.log(`status: ${res.status}`);
  console.log(`final-url: ${res.url}`);
  console.log(`content-type: ${type}`);
  console.log(`response-bytes: ${Buffer.byteLength(text)}`);
  console.log(`lua-candidate: ${lua ? 'yes' : 'no'}`);

  if (!lua) {
    console.log('No Lua source was extracted. The endpoint may be returning an index, redirect, or anti-bot page.');
    process.exitCode = 2;
    return;
  }

  fs.writeFileSync(OUT, lua);
  console.log(`saved: ${OUT}`);
})();
