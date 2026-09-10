-- URL Capture Emulator
-- Runs Lua in a restricted local Lua runtime and intercepts common HTTP APIs.
-- It never performs network requests and never executes code returned by HTTP.

local input = arg[1] or "output/upstream.lua"
local source = assert(io.open(input, "rb")):read("*a")
local captured = {}
local seen = {}

local function record(kind, url)
    if type(url) ~= "string" then return end
    local key = kind .. "|" .. url
    if not seen[key] then
        seen[key] = true
        captured[#captured + 1] = { kind = kind, url = url }
        io.write("[CAPTURE] [", kind, "] ", url, "\n")
    end
end

local function blocked_response()
    return ""
end

local function http_get(url)
    record("HttpGet", url)
    return blocked_response()
end

local function http_post(url, ...)
    record("HttpPost", url)
    return blocked_response()
end

local game = {
    HttpGet = http_get,
    HttpGetAsync = http_get,
    HttpPost = http_post,
    HttpPostAsync = http_post
}

local function request(req)
    if type(req) == "string" then
        record("request", req)
    elseif type(req) == "table" then
        record("request", req.Url or req.URL or req.url)
    end
    return { StatusCode = 204, StatusMessage = "Intercepted", Body = "" }
end

local env = {
    game = game,
    request = request,
    http_request = request,
    loadstring = function(code)
        -- Do not execute downloaded/remote code. Return a harmless function so
        -- common loadstring(HttpGet(...)) chains can continue locally.
        return function() end
    end,
    load = function(code)
        return function() end
    end,
    getgenv = function() return {} end,
    getrenv = function() return {} end,
    syn = { request = request },
    http = { request = request },
    print = print,
    pairs = pairs,
    ipairs = ipairs,
    next = next,
    type = type,
    tostring = tostring,
    tonumber = tonumber,
    string = string,
    table = table,
    math = math,
    coroutine = coroutine,
    select = select,
    unpack = table.unpack,
    _VERSION = _VERSION
}

env._G = env

local chunk, err = load(source, "@" .. input, "t", env)
if not chunk then
    io.stderr:write("[LOAD-ERROR] ", tostring(err), "\n")
    os.exit(2)
end

local ok, runtime_err = pcall(chunk)
if not ok then
    io.stderr:write("[RUNTIME-STOP] ", tostring(runtime_err), "\n")
end

io.write("\nCaptured URLs: ", tostring(#captured), "\n")
for i, item in ipairs(captured) do
    io.write(i, ". ", item.kind, " -> ", item.url, "\n")
end

if #captured == 0 then
    io.write("No HTTP URL reached an intercepted API.\n")
end
