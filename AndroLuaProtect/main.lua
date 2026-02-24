require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "java.io.File"

-- Load Layout
require "layout"
activity.setContentView(loadlayout(layout))

-- Imports for Protection Core
local Parser = require "libs.parser"
local Transpiler = require "libs.transpiler"
local Obfuscator = require "libs.obfuscator"
local vm_template = require "libs.vm_template"

-- UI Helper: Append to Log
local function appendLog(msg)
  activity.runOnUiThread(Runnable{
    run=function()
      log_output.append(os.date("[%H:%M:%S] ") .. tostring(msg) .. "\n")
    end
  })
end

-- File Selector (Simple implementation for AndroLua)
local function selectFile(callback)
  -- In a real AndroLua app, this would use a file picker.
  -- For this project, we'll prompt the user to enter the path or use a simple directory list if needed.
  -- But usually, users copy paths. We'll add a simple input dialog.
  local edit = EditText(activity)
  AlertDialog.Builder(activity)
  .setTitle("Enter File Path")
  .setView(edit)
  .setPositiveButton("OK", {
    onClick=function()
      callback(tostring(edit.text))
    end
  })
  .setNegativeButton("Cancel", nil)
  .show()
end

btn_select_input.onClick = function()
  selectFile(function(path) input_path.setText(path) end)
end

btn_select_output.onClick = function()
  selectFile(function(path) output_path.setText(path) end)
end

-- Core Protection Logic
local function runProtection(in_path, out_path)
  appendLog("Starting protection for: " .. in_path)

  local f = io.open(in_path, "rb")
  if not f then
    appendLog("Error: Could not open input file.")
    return
  end
  local bc = f:read("*a")
  f:close()

  appendLog("Parsing bytecode...")
  local status, proto = pcall(Parser.parse, bc)
  if not status then
    appendLog("Parser Error: " .. tostring(proto))
    return
  end

  appendLog("Applying obfuscation and transpilation...")
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

  appendLog("Serializing data...")
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

  appendLog("Generating protected file...")
  local final_code = vm_template:gsub("_DATA_", data_str)
                               :gsub("_KEY_", tostring(key))
                               :gsub("_OFF_", tostring(op_offset))

  local out = io.open(out_path, "w")
  if not out then
    appendLog("Error: Could not open output file for writing.")
    return
  end
  out:write("-- Protected by AndroLuaProtect\n")
  out:write(final_code)
  out:close()

  appendLog("Success! Protected file saved to: " .. out_path)
  Toast.makeText(activity, "Protection Finished!", Toast.LENGTH_SHORT).show()
end

btn_start.onClick = function()
  local in_path = tostring(input_path.text)
  local out_path = tostring(output_path.text)

  if in_path == "" or out_path == "" then
    appendLog("Error: Please specify both input and output paths.")
    return
  end

  -- Run in a separate thread to keep UI responsive
  thread(function(in_p, out_p)
    runProtection(in_p, out_p)
  end, in_path, out_path)
end
