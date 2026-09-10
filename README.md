# Leak

Tooling for safely inspecting remote Lua loader endpoints.

## Target

```lua
loadstring(game:HttpGet("https://getgold.cc"))()
```

The project retrieves and inspects source text **without executing it**.

## Files

- `getgold_loader.lua` — reference for the loader URL.
- `tools/fetch_getgold.js` — downloads the HTTP response and attempts to extract Lua source from HTML/JSON responses.
- `tools/analyze_lua.js` — basic static analysis of retrieved Lua source.

## Usage

Requires Node.js 18+.

```bash
node tools/fetch_getgold.js
node tools/analyze_lua.js output/getgold.lua
```

The fetcher follows redirects and records the final URL, status, content type, and response. It never calls `loadstring`, executes Roblox code, or evaluates the downloaded script.

If `getgold.cc` serves an index/anti-bot page instead of the script, the fetcher reports that no Lua source could be recovered and preserves the raw response in `output/response.txt` for inspection.
