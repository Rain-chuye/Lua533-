require "import"
import "android.widget.*"
import "android.view.*"

layout = {
  LinearLayout,
  orientation="vertical",
  layout_width="fill",
  layout_height="fill",
  padding="16dp",
  {
    TextView,
    text="Lua 5.3.3 Virtualization Protector",
    textSize="20sp",
    layout_gravity="center",
    padding="8dp",
  },
  {
    LinearLayout,
    orientation="horizontal",
    layout_width="fill",
    {
      EditText,
      id="input_path",
      hint="Input .luac file path",
      layout_weight="1",
    },
    {
      Button,
      text="Select",
      id="btn_select_input",
    },
  },
  {
    LinearLayout,
    orientation="horizontal",
    layout_width="fill",
    {
      EditText,
      id="output_path",
      hint="Output .lua file path",
      layout_weight="1",
    },
    {
      Button,
      text="Select",
      id="btn_select_output",
    },
  },
  {
    Button,
    text="START PROTECTION",
    id="btn_start",
    layout_width="fill",
    marginTop="16dp",
  },
  {
    TextView,
    text="Logs:",
    marginTop="16dp",
  },
  {
    ScrollView,
    layout_width="fill",
    layout_height="fill",
    layout_weight="1",
    backgroundColor="#f0f0f0",
    {
      TextView,
      id="log_output",
      text="Welcome to LuaProtect\n",
      padding="8dp",
      textSize="12sp",
      textColor="#333333",
    },
  },
}
