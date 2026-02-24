local Transpiler = {}

local OP = {
    PUSH_K = 1, PUSH_R = 2, POP_R = 3,
    GET_TAB = 4, SET_TAB = 5, ADD = 6, SUB = 7, MUL = 8, DIV = 9,
    CALL = 10, RET = 11, JMP = 12, JMP_IF = 13,
    CLOSURE = 14, GET_UP = 15, SET_UP = 16, CONCAT = 17,
    FORPREP = 18, FORLOOP = 19, NEW_TAB = 20,
    GET_TAB_UP = 21, SET_TAB_UP = 22
}
Transpiler.OP = OP

function Transpiler.transpile(proto)
    local code = {}
    local pc_map = {}

    local function emit(op, a, b, c, target)
        table.insert(code, {op = op, a = a, b = b, c = c, target = target})
    end

    local function push_rk(rk)
        if rk >= 256 then emit(OP.PUSH_K, rk - 256)
        else emit(OP.PUSH_R, rk) end
    end

    for i, ins in ipairs(proto.code) do
        pc_map[i] = #code + 1
        local op = ins.op
        if op == 0 then -- MOVE
            emit(OP.PUSH_R, ins.b); emit(OP.POP_R, ins.a)
        elseif op == 1 then -- LOADK
            emit(OP.PUSH_K, ins.bx); emit(OP.POP_R, ins.a)
        elseif op == 6 then -- GETTABUP
            emit(OP.GET_TAB_UP, ins.a, ins.b, ins.c)
        elseif op == 7 then -- GETTABLE
            emit(OP.PUSH_R, ins.b); push_rk(ins.c); emit(OP.GET_TAB); emit(OP.POP_R, ins.a)
        elseif op >= 13 and op <= 18 then -- Arith
            push_rk(ins.b); push_rk(ins.c); emit(OP.ADD + (op-13)); emit(OP.POP_R, ins.a)
        elseif op == 29 then -- CONCAT
            for j = ins.b, ins.c do emit(OP.PUSH_R, j) end
            emit(OP.CONCAT, ins.c - ins.b + 1); emit(OP.POP_R, ins.a)
        elseif op == 30 then -- JMP
            emit(OP.JMP, nil, nil, nil, i + 1 + ins.sbx)
        elseif op >= 31 and op <= 33 then -- EQ, LT, LE
            push_rk(ins.b); push_rk(ins.c); emit(OP.JMP_IF, op)
        elseif op == 36 then -- CALL
            emit(OP.PUSH_R, ins.a)
            if ins.b ~= 1 then
                local n = ins.b == 0 and -1 or ins.b - 1
                for j = 1, n do emit(OP.PUSH_R, ins.a + j) end
            end
            emit(OP.CALL, ins.b, ins.c)
            if ins.c ~= 1 then
                for j = ins.c - 1, 1, -1 do emit(OP.POP_R, ins.a + j - 1) end
            end
        elseif op == 38 then -- RETURN
            if ins.b ~= 1 then
                for j = 1, ins.b - 1 do emit(OP.PUSH_R, ins.a + j - 1) end
            end
            emit(OP.RET, ins.b)
        elseif op == 39 then -- FORLOOP
            emit(OP.FORLOOP, ins.a, nil, nil, i + 1 + ins.sbx)
        elseif op == 40 then -- FORPREP
            emit(OP.FORPREP, ins.a, nil, nil, i + 1 + ins.sbx)
        elseif op == 44 then -- CLOSURE
            emit(OP.CLOSURE, ins.bx, ins.a)
        end
    end

    -- Second pass: resolve targets
    for _, ins in ipairs(code) do
        if ins.target then
            ins.c = pc_map[ins.target]
        end
    end

    local new_proto = {
        code = code,
        constants = proto.constants,
        protos = {}
    }
    for i, p in ipairs(proto.protos) do new_proto.protos[i] = Transpiler.transpile(p) end
    return new_proto
end

return Transpiler
