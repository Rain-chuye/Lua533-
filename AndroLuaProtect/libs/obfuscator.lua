local Obfuscator = {}

function Obfuscator.obfuscate_strings(proto, key)
    for _, c in ipairs(proto.constants) do
        if c.type == "string" then
            local s = c.value
            local res = {}
            for i = 1, #s do
                res[i] = string.char(string.byte(s, i) ~ key)
            end
            c.value = table.concat(res)
            c.is_obfuscated = true
        end
    end
    for _, p in ipairs(proto.protos) do
        Obfuscator.obfuscate_strings(p, key)
    end
end

function Obfuscator.apply_cff(proto)
    local code = proto.code
    local new_code = {}
    local ids = {}
    for i = 1, #code do
        ids[i] = math.random(1000, 999999)
    end

    for i, ins in ipairs(code) do
        ins.id = ids[i]
        ins.next_id = ids[i+1] or 0 -- 0 means exit/return
        -- Handle Jumps
        if ins.target_pc then
            ins.next_id = ids[ins.target_pc]
        end
    end

    -- Shuffle code to break linear flow
    local shuffled = {}
    local indices = {}
    for i = 1, #code do indices[i] = i end
    for i = #indices, 2, -1 do
        local j = math.random(i)
        indices[i], indices[j] = indices[j], indices[i]
    end

    for i, idx in ipairs(indices) do
        shuffled[i] = code[idx]
    end

    proto.code = shuffled
    proto.entry_id = ids[1]
end

return Obfuscator
