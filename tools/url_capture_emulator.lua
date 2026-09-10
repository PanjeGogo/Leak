-- Runtime URL Capture Emulator
-- Executes Lua inside a restricted VM-like environment and intercepts HTTP APIs.
-- Network is NEVER performed. Remote payloads returned by intercepted HTTP calls
-- are NEVER executed.

local input = arg[1] or "output/upstream.lua"
local fh = assert(io.open(input, "rb"))
local source = fh:read("*a")
fh:close()

local captured, seen = {}, {}
local function record(kind, url)
    if type(url) ~= "string" or url == "" then return end
    local key = kind .. "|" .. url
    if not seen[key] then
        seen[key] = true
        captured[#captured + 1] = { kind = kind, url = url }
        io.write("[CAPTURE] [", kind, "] ", url, "\n")
    end
end

local function proxy(path)
    local p = { __path = path }
    return setmetatable(p, {
        __index = function(self, key)
            if key == "Name" then return path end
            if key == "ClassName" then return "Instance" end
            return proxy(path .. "." .. tostring(key))
        end,
        __newindex = function() end,
        __call = function(self, ...) return proxy(path .. "()") end,
        __tostring = function() return path end
    })
end

local function http_get(url)
    record("HttpGet", url)
    return ""
end
local function http_post(url, ...)
    record("HttpPost", url)
    return ""
end
local function request(req)
    if type(req) == "string" then
        record("request", req)
    elseif type(req) == "table" then
        record("request", req.Url or req.URL or req.url)
    end
    return { StatusCode = 204, StatusMessage = "Intercepted", Body = "" }
end

local game = proxy("game")
game.HttpGet = http_get
game.HttpGetAsync = http_get
game.HttpPost = http_post
game.HttpPostAsync = http_post
game.GetService = function(_, name)
    return proxy("game:GetService(" .. tostring(name) .. ")")
end

local env = {}
for k,v in pairs(_G) do env[k] = v end

env.game = game
env.workspace = proxy("workspace")
env.Workspace = env.workspace
env.Instance = { new = function(className) return proxy("Instance.new(" .. tostring(className) .. ")") end }
env.request = request
env.http_request = request
env.syn = { request = request }
env.http = { request = request }
env.getgenv = function() return env end
env.getrenv = function() return env end
env.getfenv = function() return env end
env.setfenv = function(_, e) return e end
env.wait = function() return 0 end
env.delay = function(_, fn) if type(fn) == "function" then pcall(fn) end end
env.task = {
    wait = function() return 0 end,
    spawn = function(fn) if type(fn) == "function" then pcall(fn) end end,
    defer = function(fn) if type(fn) == "function" then pcall(fn) end end,
    delay = function(_, fn) if type(fn) == "function" then pcall(fn) end end
}

env.loadstring = function(code) return function() end end
env.load = env.loadstring
env.fireclickdetector = function() end
env.fireproximityprompt = function() end
env.getconnections = function() return {} end
env.hookfunction = function(original) return original end
env.hookmetamethod = function(_, _, original) return original end
env.newcclosure = function(fn) return fn end
env.checkcaller = function() return false end
env.identifyexecutor = function() return "RuntimeCapture", "1.0" end
env.isexecutorclosure = function() return false end
env.cloneref = function(x) return x end
env.gethui = function() return proxy("gethui()") end
env.gethiddenproperty = function() return nil end
env.sethiddenproperty = function() end

env.Enum = proxy("Enum")
env.Vector2 = { new = function(x,y) return { X=x or 0, Y=y or 0 } end }
env.Vector3 = { new = function(x,y,z) return { X=x or 0, Y=y or 0, Z=z or 0 } end }
env.CFrame = { new = function(...) return proxy("CFrame") end }
env.Color3 = { new = function(...) return proxy("Color3") end, fromRGB = function(...) return proxy("Color3.fromRGB") end }
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
