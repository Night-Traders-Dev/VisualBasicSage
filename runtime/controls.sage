# Controls runtime - VB4 control implementations

class Control:
  proc init(self, name):
    self.name = name
    self.width = 100
    self.height = 30
    self.left = 0
    self.top = 0
    self.visible = true
    self.enabled = true
    self.tab_index = 0
    self.events = {}

  proc on_event(self, event_name, handler):
    self.events[event_name] = handler

class Label(Control):
  proc init(self, name):
    super.init(name)
    self.caption = ""
    self.alignment = 0  # 0=Left, 1=Right, 2=Center
    self.auto_size = false

class CommandButton(Control):
  proc init(self, name):
    super.init(name)
    self.caption = ""
    self.is_default = false
    self.cancel = false
    self.style = 0  # 0=Standard, 1=Graphical

class TextBox(Control):
  proc init(self, name):
    super.init(name)
    self.text = ""
    self.multi_line = false
    self.password_char = ""
    self.scroll_bars = 0
    self.max_length = 0
    self.locked = false

class CheckBox(Control):
  proc init(self, name):
    super.init(name)
    self.caption = ""
    self.value = 0  # 0=Unchecked, 1=Checked, 2=Grayed

class OptionButton(Control):
  proc init(self, name):
    super.init(name)
    self.caption = ""
    self.value = false

class Frame(Control):
  proc init(self, name):
    super.init(name)
    self.caption = ""
    self.controls = []

class ListBox(Control):
  proc init(self, name):
    super.init(name)
    self.items = []
    self.list_index = -1
    self.sorted = false
    self.multi_select = 0

  proc add_item(self, item):
    push(self.items, item)

  proc remove_item(self, index):
    # TODO: implement removal
    return nil

class ComboBox(Control):
  proc init(self, name):
    super.init(name)
    self.items = []
    self.text = ""
    self.list_index = -1
    self.style = 0  # 0=Dropdown, 1=Simple, 2=DropdownList

class PictureBox(Control):
  proc init(self, name):
    super.init(name)
    self.picture = nil
    self.auto_size = false
    self.auto_redraw = false
    self.scale_mode = 1

class Timer(Control):
  proc init(self, name):
    super.init(name)
    self.interval = 1000
    self.enabled = false
