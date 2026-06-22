# Windowing system - renders VB4 forms using graphics.ui

import graphics.ui as ui
import graphics.renderer as renderer

let _windower_initialized = false

## Initialize the windowing system
proc init_windower():
  if not _windower_initialized:
    renderer.init()
    _windower_initialized = true

## Render a VB4 Form using the graphics UI
proc render_form(form):
  init_windower()
  let ctx = ui.ui_create()
  ui.theme = ui.ui_default_theme()

  let form_title = form.caption
  if form_title == "":
    form_title = form.name

  # Create the form as a window panel
  ui.begin_window(ctx, form_title, form.left, form.top, form.width, form.height)

  # Render each control
  for ctrl in form.controls:
    render_control(ctx, ctrl)

  ui.end_window(ctx)
  renderer.present()

## Render a single control
proc render_control(ctx, ctrl):
  let ctrl_type = type(ctrl)
  # All controls store x/y as left/top
  let x = ctrl.left
  let y = ctrl.top
  let w = ctrl.width
  let h = ctrl.height

  if ctrl_type == "instance":
    # Determine control type by class
    let class_name = str(ctrl.__class__)
    if contains(class_name, "Label"):
      let caption = ""
      if ctrl.caption != nil:
        caption = ctrl.caption
      ui.label(ctx, caption, x, y)
    elif contains(class_name, "CommandButton"):
      let caption = ""
      if ctrl.caption != nil:
        caption = ctrl.caption
      ui.button(ctx, caption, x, y, w, h)
    elif contains(class_name, "TextBox"):
      let text = ""
      if ctrl.text != nil:
        text = ctrl.text
      ui.text_input(ctx, text, x, y, w, h)
    elif contains(class_name, "CheckBox"):
      let caption = ""
      if ctrl.caption != nil:
        caption = ctrl.caption
      let checked = false
      if ctrl.value != nil and ctrl.value != 0:
        checked = true
      ui.checkbox(ctx, caption, checked)
    elif contains(class_name, "Frame"):
      let caption = ""
      if ctrl.caption != nil:
        caption = ctrl.caption
      ui.panel(ctx, caption, x, y, w, h)
