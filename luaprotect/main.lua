local Parser = require("luaprotect.parser")
local Transpiler = require("luaprotect.transpiler")
local Obfuscator = require("luaprotect.obfuscator")

local input = arg[1] or "luaprotect/tests/simple.lua"
local output = arg[2] or "protected.lua"

local f = loadfile(input)
local bc = string.dump(f)
local proto = Parser.parse(bc)

local key = math.random(1, 255)
local op_offset = math.random(1, 40)
Obfuscator.obfuscate_strings(proto, key)

local function transpile_proto(p)
    local tp = Transpiler.transpile(p)
    local data = { c = {}, k = {}, p = {} }
    for _, ins in ipairs(tp.code) do
        table.insert(data.c, {(ins.op + op_offset) % 43, ins.a or 0, ins.b or 0, ins.c or 0})
    end
    for _, c in ipairs(tp.constants) do
        table.insert(data.k, {v = c.value, o = c.is_obfuscated})
    end
    for _, sp in ipairs(p.protos) do
        table.insert(data.p, transpile_proto(sp))
    end
    return data
end

local final_data = transpile_proto(proto)

local function serialize(t)
    if type(t) == "table" then
        local res = "{"
        for k, v in pairs(t) do
            local key_str = type(k) == "number" and "" or k.."="
            res = res .. key_str .. serialize(v) .. ","
        end
        return res .. "}"
    elseif type(t) == "string" then
        return string.format("%q", t)
    else
        return tostring(t)
    end
end

local data_str = serialize(final_data)
local vm_template = require("luaprotect.vm_engine_template")
local final_code = vm_template:gsub("_DATA_", data_str):gsub("_KEY_", tostring(key)):gsub("_OFF_", tostring(op_offset))

local out = io.open(output, "w")
out:write(final_code)
out:close()
print("Protected file saved to " .. output)
