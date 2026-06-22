# Form Designer - drag-and-drop visual form editing surface

class DesignerSurface:
  proc init(self):
    self.form = nil
    self.grid_enabled = true
    self.grid_width = 120
    self.grid_height = 120
    self.align_to_grid = true
    self.selection = nil
    self.drag_control = nil
    self.drag_offset_x = 0
    self.drag_offset_y = 0
    self.zoom = 1.0

  proc set_form(self, form):
    self.form = form
    self.selection = nil

  proc select_control(self, control):
    self.selection = control

  proc add_control(self, control_type, x, y):
    if self.form == nil:
      return nil
    let name = control_type + str(len(self.form.controls) + 1)
    let control = nil
    if control_type == "CommandButton":
      control = runtime.controls.CommandButton(name)
    elif control_type == "Label":
      control = runtime.controls.Label(name)
    elif control_type == "TextBox":
      control = runtime.controls.TextBox(name)
    elif control_type == "CheckBox":
      control = runtime.controls.CheckBox(name)
    elif control_type == "OptionButton":
      control = runtime.controls.OptionButton(name)
    elif control_type == "Frame":
      control = runtime.controls.Frame(name)
    elif control_type == "ListBox":
      control = runtime.controls.ListBox(name)
    elif control_type == "ComboBox":
      control = runtime.controls.ComboBox(name)
    elif control_type == "PictureBox":
      control = runtime.controls.PictureBox(name)
    elif control_type == "Timer":
      control = runtime.controls.Timer(name)
    else:
      return nil

    control.left = x
    control.top = y
    self.form.add_control(control)
    self.selection = control
    return control

  proc move_control(self, control, x, y):
    if self.align_to_grid:
      let gw = self.grid_width
      let gh = self.grid_height
      x = (x / gw) * gw
      y = (y / gh) * gh
    control.left = x
    control.top = y

  proc resize_control(self, control, width, height):
    control.width = width
    control.height = height

  proc delete_selected(self):
    if self.selection == nil or self.form == nil:
      return
    let new_controls = []
    for c in self.form.controls:
      if c != self.selection:
        new_controls = push(new_controls, c)
    self.form.controls = new_controls
    self.selection = nil

  proc render(self):
    if self.form == nil:
      return
    # Draw form background
    # Draw grid
    # Draw controls
    for c in self.form.controls:
      # TODO: render each control on the surface
      pass
