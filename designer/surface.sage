# Form Designer - drag-and-drop visual form editing surface

import runtime.controls as ctrl

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
    self.drag_start_x = 0
    self.drag_start_y = 0
    self.zoom = 1.0
    self.resize_handle = nil  # "nw", "ne", "sw", "se", "n", "s", "e", "w"
    self.mouse_x = 0
    self.mouse_y = 0
    self.surface_width = 800
    self.surface_height = 600

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
      control = ctrl.CommandButton(name)
    elif control_type == "Label":
      control = ctrl.Label(name)
    elif control_type == "TextBox":
      control = ctrl.TextBox(name)
    elif control_type == "CheckBox":
      control = ctrl.CheckBox(name)
    elif control_type == "OptionButton":
      control = ctrl.OptionButton(name)
    elif control_type == "Frame":
      control = ctrl.Frame(name)
    elif control_type == "ListBox":
      control = ctrl.ListBox(name)
    elif control_type == "ComboBox":
      control = ctrl.ComboBox(name)
    elif control_type == "PictureBox":
      control = ctrl.PictureBox(name)
    elif control_type == "Timer":
      control = ctrl.Timer(name)
    else:
      return nil

    control.left = self.snap_x(x)
    control.top = self.snap_y(y)
    self.form.add_control(control)
    self.selection = control
    return control

  proc snap_x(self, x):
    if self.align_to_grid:
      return int(x / self.grid_width) * self.grid_width
    return x

  proc snap_y(self, y):
    if self.align_to_grid:
      return int(y / self.grid_height) * self.grid_height
    return y

  # Mouse down on surface
  proc on_mouse_down(self, x, y):
    self.mouse_x = x
    self.mouse_y = y

    # Check resize handles first
    if self.selection != nil:
      let handle = self.hit_test_resize(x, y)
      if handle != nil:
        self.resize_handle = handle
        return

    # Check if clicking on a control
    let clicked = self.hit_test_control(x, y)
    if clicked != nil:
      self.selection = clicked
      self.drag_control = clicked
      self.drag_offset_x = x - clicked.left
      self.drag_offset_y = y - clicked.top
      self.drag_start_x = clicked.left
      self.drag_start_y = clicked.top
    else:
      self.selection = nil
      self.drag_control = nil

  # Mouse move on surface
  proc on_mouse_move(self, x, y):
    self.mouse_x = x
    self.mouse_y = y

    if self.resize_handle != nil and self.selection != nil:
      self.do_resize(self.selection, self.resize_handle, x, y)
      return

    if self.drag_control != nil:
      let new_x = x - self.drag_offset_x
      let new_y = y - self.drag_offset_y
      self.move_control(self.drag_control, new_x, new_y)

  # Mouse up on surface
  proc on_mouse_up(self, x, y):
    self.drag_control = nil
    self.resize_handle = nil

  # Hit test: find control at given coordinates
  proc hit_test_control(self, x, y):
    if self.form == nil:
      return nil
    # Check in reverse order (top-most first)
    let idx = len(self.form.controls) - 1
    while idx >= 0:
      let c = self.form.controls[idx]
      if x >= c.left and x <= c.left + c.width:
        if y >= c.top and y <= c.top + c.height:
          return c
      idx = idx - 1
    return nil

  # Hit test: check if position is on a resize handle
  proc hit_test_resize(self, x, y):
    if self.selection == nil:
      return nil
    let s = self.selection
    let handle_size = 6

    # Corner handles
    if x >= s.left - handle_size and x <= s.left + handle_size:
      if y >= s.top - handle_size and y <= s.top + handle_size:
        return "nw"
      if y >= s.top + s.height - handle_size and y <= s.top + s.height + handle_size:
        return "sw"
    if x >= s.left + s.width - handle_size and x <= s.left + s.width + handle_size:
      if y >= s.top - handle_size and y <= s.top + handle_size:
        return "ne"
      if y >= s.top + s.height - handle_size and y <= s.top + s.height + handle_size:
        return "se"

    # Edge handles
    if x >= s.left + handle_size and x <= s.left + s.width - handle_size:
      if y >= s.top - handle_size and y <= s.top + handle_size:
        return "n"
      if y >= s.top + s.height - handle_size and y <= s.top + s.height + handle_size:
        return "s"
    if y >= s.top + handle_size and y <= s.top + s.height - handle_size:
      if x >= s.left - handle_size and x <= s.left + handle_size:
        return "w"
      if x >= s.left + s.width - handle_size and x <= s.left + s.width + handle_size:
        return "e"

    return nil

  proc do_resize(self, control, handle, x, y):
    if handle == "nw":
      control.left = self.snap_x(x)
      control.top = self.snap_y(y)
    elif handle == "ne":
      control.top = self.snap_y(y)
    elif handle == "sw":
      control.left = self.snap_x(x)
    elif handle == "se":
      pass
    elif handle == "n":
      control.top = self.snap_y(y)
    elif handle == "s":
      pass
    elif handle == "w":
      control.left = self.snap_x(x)
    elif handle == "e":
      pass

  proc move_control(self, control, x, y):
    if self.align_to_grid:
      x = self.snap_x(x)
      y = self.snap_y(y)
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
        push(new_controls, c)
    self.form.controls = new_controls
    self.selection = nil

  # Draw grid dots/stars on the surface
  proc draw_grid(self, draw_line_fn):
    if not self.grid_enabled:
      return
    let gw = self.grid_width
    let gh = self.grid_height
    let x = 0
    while x <= self.surface_width:
      let y = 0
      while y <= self.surface_height:
        draw_line_fn(x, y, x, y)
        y = y + gh
      x = x + gw

  # Draw a single control on the surface
  proc draw_control(self, c, draw_rect_fn, draw_text_fn):
    let color = [0.4, 0.4, 0.6, 1.0]
    if c == self.selection:
      color = [0.5, 0.6, 0.9, 1.0]

    draw_rect_fn(c.left, c.top, c.width, c.height, color)

    # Draw type-dependent content
    let label = c.name
    if c.caption != nil and c.caption != "":
      label = c.caption
    elif c.text != nil and c.text != "":
      label = c.text
    draw_text_fn(c.left + 4, c.top + 4, label)

  # Draw selection handles for the selected control
  proc draw_selection_handles(self, draw_rect_fn):
    if self.selection == nil:
      return
    let s = self.selection
    let hs = 6
    let handle_color = [0.2, 0.4, 0.8, 1.0]

    # 8 handles: 4 corners + 4 edges
    let handles = [
      [s.left - hs, s.top - hs], [s.left + s.width - hs, s.top - hs],
      [s.left - hs, s.top + s.height - hs], [s.left + s.width - hs, s.top + s.height - hs],
      [s.left + s.width / 2 - hs / 2, s.top - hs], [s.left + s.width / 2 - hs / 2, s.top + s.height - hs],
      [s.left - hs, s.top + s.height / 2 - hs / 2], [s.left + s.width - hs, s.top + s.height / 2 - hs / 2]
    ]
    for h in handles:
      draw_rect_fn(h[0], h[1], hs * 2, hs * 2, handle_color)

  # Render the entire designer surface
  proc render(self, draw_line_fn, draw_rect_fn, draw_text_fn):
    if self.form == nil:
      return
    self.draw_grid(draw_line_fn)
    for c in self.form.controls:
      self.draw_control(c, draw_rect_fn, draw_text_fn)
    self.draw_selection_handles(draw_rect_fn)
