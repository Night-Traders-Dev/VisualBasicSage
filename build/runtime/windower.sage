# Windowing system - renders VB4 forms using graphics.ui

import graphics.ui as ui
import graphics.renderer as gr
import runtime.forms as forms
import runtime.events as evt

## Map UI return codes to VB4 events
let WINDOWER_CLICK = 1
let WINDOWER_CHANGED = 2
let WINDOWER_CHECKED = 3

## Start the windowing event loop for a form
proc run_form_loop(form):
  let w = form.width
  let h = form.height
  let title = form.caption
  if title == "":
    title = form.name

  let r = gr.create_renderer(w, h, title)
  if r == nil:
    return nil

  let ctx = ui.ui_create()
  let font = nil
  let form_should_close = false

  while not form_should_close:
    let frame = gr.begin_frame(r)
    if frame == nil:
      form_should_close = true
      break

    ui.ui_begin_frame(ctx)

    # Render the form as a UI window
    ui.ui_window(ctx, 0, 0, w, h, title)

    # Render all controls
    for ctrl in form.controls:
      render_control(ctx, ctrl, frame)

    ui.ui_end_frame(ctx)
    ui.ui_render(ctx, frame["cmd"], font)

    gr.end_frame(r, frame)

  gr.shutdown_renderer(r)

## Render a single control to the UI
proc render_control(ctx, ctrl, frame):
  let ctrl_type = type(ctrl)
  if ctrl_type != "instance":
    return

  let class_str = str(ctrl.__class__)
  let x = ctrl.left
  let y = ctrl.top
  let w = ctrl.width
  let h = ctrl.height

  if contains(class_str, "Label"):
    let text = ""
    if ctrl.caption != nil:
      text = ctrl.caption
    ui.ui_label(ctx, x, y, text)

  elif contains(class_str, "CommandButton"):
    let label = ""
    if ctrl.caption != nil:
      label = ctrl.caption
    if ui.ui_button(ctx, x, y, w, h, label):
      evt.GLOBAL_DISPATCHER.dispatch(ctrl.name, "Click", ctrl)

  elif contains(class_str, "TextBox"):
    let text = ""
    if ctrl.text != nil:
      text = ctrl.text
    let result = ui.ui_text_input(ctx, x, y, w, ctrl.name, text)
    if result != text:
      ctrl.text = result
      evt.GLOBAL_DISPATCHER.dispatch(ctrl.name, "Change", ctrl)

  elif contains(class_str, "CheckBox"):
    let label = ""
    if ctrl.caption != nil:
      label = ctrl.caption
    let checked = ctrl.value != 0
    let new_checked = ui.ui_checkbox(ctx, x, y, label, checked)
    if new_checked != checked:
      if new_checked:
        ctrl.value = 1
      else:
        ctrl.value = 0
      evt.GLOBAL_DISPATCHER.dispatch(ctrl.name, "Click", ctrl)

## Render loop for multiple forms (MDI-style)
let _open_forms = []

proc show_form(form):
  push(_open_forms, form)
  run_form_loop(form)
