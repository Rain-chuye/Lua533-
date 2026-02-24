# LuaProtect for Lua 5.3.3

一个能够将 Lua 5.3.3 代码进行虚拟化保护的工具。

## 功能特性
1. **代码虚拟化**：实现了一个完全用 Lua 编写的栈式虚拟机（Lua-in-Lua VM）。
2. **不魔改虚拟机**：完全在 Lua 层实现，兼容标准的官方 Lua 5.3.3 VM。
3. **防反编译**：使用自定义指令集，传统反编译器无法识别。
4. **指令隐流**：在 VM 循环中加入不透明谓词（Opaque Predicates）和垃圾代码。
5. **代码混淆**：对 VM 逻辑和数据结构进行混淆。
6. **防 Hook**：动态检测 `debug.getinfo` 和全局函数（如 `print`）是否被篡改。
7. **字节码偏移**：自定义 OpCode 映射，加入随机偏移量。
8. **数字控制流**：基于数字状态的控制流平坦化（Control Flow Flattening）。
9. **字符串混淆**：所有字符串常量均经过 XOR 加密，并在运行时动态解密。

## 使用方法
```bash
lua5.3 luaprotect/main.lua input.lua output.lua
```

## 结构说明
- `parser.lua`: Lua 5.3 字节码解析器。
- `transpiler.lua`: 将寄存器指令转换为自定义栈式指令。
- `obfuscator.lua`: 混淆和加密逻辑。
- `vm_engine_template.lua`: 受保护代码的运行时引擎模板。
- `main.lua`: 工具主入口。
