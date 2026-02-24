return [[
local function _PROTECT_(...)
    local _G = _G
    local _ENV = _ENV or _G
    local _D = debug
    local _S = string
    local _T = table
    local _U = unpack or _T.unpack

    local function _CH(f, n)
        if _D and _D.getinfo then
            local i = _D.getinfo(f)
            if i and i.what ~= "C" then error("Hook: "..n) end
        end
    end
    _CH(_G.print, "p")

    local function _VM(data, upvs, ...)
        local code = data.c
        local consts = data.k
        local protos = data.p
        local regs = {}
        local args = {...}
        for i=1,100 do regs[i] = args[i] end
        local stack = {}
        local top = 0
        local pc = 1

        while true do
            local ins = code[pc]
            if not ins then break end
            pc = pc + 1

            if (pc * 13 + 7) % 1 == 0 then
                local op = (ins[1] - _OFF_ + 43) % 43
                if op == 1 then -- PUSH_K
                    local c = consts[ins[2]+1]
                    local v = c.v
                    if c.o then
                        local r = {}
                        for i=1,#v do r[i] = _S.char(_S.byte(v,i) ~ _KEY_) end
                        v = _T.concat(r)
                    end
                    top = top + 1; stack[top] = v
                elseif op == 2 then -- PUSH_R
                    top = top + 1; stack[top] = regs[ins[2]+1]
                elseif op == 3 then -- POP_R
                    regs[ins[2]+1] = stack[top]; stack[top] = nil; top = top - 1
                elseif op == 4 then -- GET_TAB
                    local k = stack[top]; top = top - 1
                    local t = stack[top]; top = top - 1
                    top = top + 1; stack[top] = t[k]
                elseif op == 10 then -- CALL
                    local nargs = ins[2] == -1 and top-1 or ins[2]-1
                    local call_args = {}
                    for i=nargs,1,-1 do call_args[i] = stack[top]; top=top-1 end
                    local func = stack[top]; top=top-1
                    local res = {func(_U(call_args))}
                    if ins[3] == 0 then
                        for i=1,#res do top=top+1; stack[top]=res[i] end
                    elseif ins[3] > 1 then
                        for i=1,ins[3]-1 do top=top+1; stack[top]=res[i] end
                    end
                elseif op == 11 then -- RET
                    local res = {}
                    local n = (ins[2] == 0) and top or (ins[2] - 1)
                    for i=n,1,-1 do res[i] = stack[top]; top=top-1 end
                    return _U(res)
                elseif op == 12 then -- JMP
                    pc = ins[4]
                elseif op == 13 then -- JMP_IF
                    local b = stack[top]; top=top-1
                    local a = stack[top]; top=top-1
                    local cond = false
                    local typ = ins[2]
                    if typ == 31 then cond = (a == b)
                    elseif typ == 32 then cond = (a < b)
                    elseif typ == 33 then cond = (a <= b) end
                    if cond then pc = pc + 1 end
                elseif op == 6 then -- ADD
                    local b = stack[top]; top=top-1
                    local a = stack[top]; top=top-1
                    top=top+1; stack[top] = a + b
                elseif op == 17 then -- CONCAT
                    local n = ins[2]; local s = {}
                    for i=n,1,-1 do s[i] = stack[top]; top=top-1 end
                    top=top+1; stack[top] = _T.concat(s)
                elseif op == 14 then -- CLOSURE
                    local p = protos[ins[2]+1]
                    regs[ins[3]+1] = function(...) return _VM(p, upvs, ...) end
                elseif op == 21 then -- GET_TAB_UP
                    local up = upvs[ins[3]+1] or _ENV
                    local key = ins[4] >= 256 and consts[ins[4]-255].v or regs[ins[4]+1]
                    if ins[4] >= 256 and consts[ins[4]-255].o then
                       local r = {}
                       for i=1,#key do r[i] = _S.char(_S.byte(key,i) ~ _KEY_) end
                       key = _T.concat(r)
                    end
                    regs[ins[2]+1] = up[key]
                elseif op == 18 then -- FORPREP
                    regs[ins[2]+1] = regs[ins[2]+1] - regs[ins[2]+3]
                    pc = ins[4]
                elseif op == 19 then -- FORLOOP
                    local step = regs[ins[2]+3]
                    local idx = regs[ins[2]+1] + step
                    local limit = regs[ins[2]+2]
                    if (step > 0 and idx <= limit) or (step <= 0 and idx >= limit) then
                        regs[ins[2]+1] = idx; regs[ins[2]+4] = idx; pc = ins[4]
                    end
                end
            end
        end
    end

    local data = _DATA_
    return _VM(data, {_ENV}, ...)
end
return _PROTECT_(...)
]]
