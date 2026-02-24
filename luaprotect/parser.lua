local Parser = {}

function Parser.parse(bytecode)
    local pos = 1
    local function read_byte() local b = bytecode:byte(pos); pos = pos + 1; return b end
    local function read_str(n) local s = bytecode:sub(pos, pos + n - 1); pos = pos + n; return s end
    local function read_int(n)
        local v = 0; local b = 1
        for i = 1, n do v = v + read_byte() * b; b = b * 256 end
        return v
    end
    local function read_sint(n)
        local v = read_int(n)
        local m = 256^n
        return (v >= m/2) and (v - m) or v
    end

    -- Header
    read_str(4) -- signature
    read_byte() -- version
    read_byte() -- format
    read_str(6) -- data
    local sz_int = read_byte()
    local sz_size_t = read_byte()
    local sz_inst = read_byte()
    local sz_num = read_byte()
    local sz_int_lua = read_byte()
    read_int(sz_int_lua) -- luac_int
    read_str(sz_num) -- luac_num

    local function read_string()
        local s = read_byte()
        if s == 0xFF then s = read_int(sz_size_t) end
        if s == 0 then return nil end
        return read_str(s - 1)
    end

    local function read_proto()
        local p = {}
        read_string() -- source
        read_int(sz_int); read_int(sz_int) -- line defined
        p.num_params = read_byte()
        p.is_vararg = read_byte()
        p.max_stack = read_byte()

        local sz_code = read_int(sz_int)
        p.code = {}
        for i = 1, sz_code do
            local ins = read_int(sz_inst)
            p.code[i] = {
                op = ins & 0x3F,
                a = (ins >> 6) & 0xFF,
                c = (ins >> 14) & 0x1FF,
                b = (ins >> 23) & 0x1FF,
                bx = (ins >> 14) & 0x3FFFF,
                sbx = ((ins >> 14) & 0x3FFFF) - 131071
            }
        end

        local sz_const = read_int(sz_int)
        p.constants = {}
        for i = 1, sz_const do
            local t = read_byte()
            if t == 0 then p.constants[i] = {type="nil"}
            elseif t == 1 then p.constants[i] = {type="bool", value=(read_byte() ~= 0)}
            elseif t == 3 then p.constants[i] = {type="num", value=string.unpack("d", read_str(8))}
            elseif t == 19 then p.constants[i] = {type="int", value=read_sint(8)}
            elseif t == 4 or t == 20 then p.constants[i] = {type="str", value=read_string()}
            end
        end

        local sz_up = read_int(sz_int)
        p.upvalues = {}
        for i = 1, sz_up do p.upvalues[i] = {instack=read_byte(), idx=read_byte()} end

        local sz_p = read_int(sz_int)
        p.protos = {}
        for i = 1, sz_p do p.protos[i] = read_proto() end

        -- Skip debug
        local sz_line = read_int(sz_int); pos = pos + sz_line * sz_int
        local sz_loc = read_int(sz_int)
        for i = 1, sz_loc do read_string(); read_int(sz_int); read_int(sz_int) end
        local sz_upn = read_int(sz_int)
        for i = 1, sz_upn do read_string() end

        return p
    end

    read_byte() -- num upvalues
    return read_proto()
end

return Parser
