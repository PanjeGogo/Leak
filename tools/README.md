# Lua URL Emulator

`lua_url_emulator.js` is a **static-analysis emulator**, not a Lua/Roblox runtime.

It reads a Lua file as text and reports:

- literal `http://` and `https://` URLs;
- common Roblox HTTP API calls such as `HttpGet` and `HttpGetAsync`;
- simple literal URLs passed to those calls;
- dynamic HTTP expressions that require deeper analysis;
- direct `loadstring(HttpGet(...))` remote-execution boundaries.

## Run

```bash
node tools/lua_url_emulator.js path/to/script.lua
```

For the fetched GetGold source:

```bash
node tools/lua_url_emulator.js output/getgold.lua
```

## Safety

The emulator **never executes Lua** and never calls discovered URLs. This is deliberate: obfuscated scripts may contain arbitrary Roblox/executor behavior. The tool only tokenizes the source and extracts URL/HTTP patterns.

For heavily obfuscated code, URL construction may happen through decoded strings or runtime concatenation. Those cases are reported as dynamic expressions and require an additional static decoder/emulation layer rather than executing the script.
