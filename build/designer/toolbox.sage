# Designer Toolbox - available controls palette

let TOOLBOX_CONTROLS = [
  {"name": "Pointer", "icon": "pointer"},
  {"name": "Label", "icon": "label"},
  {"name": "TextBox", "icon": "textbox"},
  {"name": "CommandButton", "icon": "button"},
  {"name": "CheckBox", "icon": "checkbox"},
  {"name": "OptionButton", "icon": "option"},
  {"name": "Frame", "icon": "frame"},
  {"name": "ListBox", "icon": "listbox"},
  {"name": "ComboBox", "icon": "combobox"},
  {"name": "PictureBox", "icon": "picture"},
  {"name": "Timer", "icon": "timer"}
]

class Toolbox:
  proc init(self):
    self.selected_tool = "Pointer"
    self.controls = TOOLBOX_CONTROLS

  proc select_tool(self, tool_name):
    self.selected_tool = tool_name

  proc get_selected_tool(self):
    return self.selected_tool
