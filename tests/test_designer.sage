# Designer tests

import designer.surface as ds
import runtime.forms as f
import runtime.controls as c

## Test surface creation
proc test_surface_create():
  let surf = ds.DesignerSurface()
  if surf == nil:
    print "FAIL: test_surface_create: nil surface"
    return false
  if surf.grid_enabled != true:
    print "FAIL: test_surface_create: grid should be enabled"
    return false
  if surf.selection != nil:
    print "FAIL: test_surface_create: no initial selection"
    return false
  print "PASS: test_surface_create"
  return true

## Test setting form
proc test_set_form():
  let surf = ds.DesignerSurface()
  let form = f.Form("Form1")
  surf.set_form(form)
  if surf.form != form:
    print "FAIL: test_set_form: form not set"
    return false
  print "PASS: test_set_form"
  return true

## Test adding controls
proc test_add_control():
  let surf = ds.DesignerSurface()
  let form = f.Form("Form1")
  surf.set_form(form)
  let btn = surf.add_control("CommandButton", 10, 10)
  if btn == nil:
    print "FAIL: test_add_control: nil control"
    return false
  if btn.name != "CommandButton1":
    print "FAIL: test_add_control: wrong name: " + btn.name
    return false
  if len(form.controls) != 1:
    print "FAIL: test_add_control: expected 1 control"
    return false
  if surf.selection != btn:
    print "FAIL: test_add_control: should be selected"
    return false
  print "PASS: test_add_control"
  return true

## Test grid snapping
proc test_snap():
  let surf = ds.DesignerSurface()
  surf.align_to_grid = true
  surf.grid_width = 120
  surf.grid_height = 120
  let snapped_x = surf.snap_x(150)
  let snapped_y = surf.snap_y(200)
  if snapped_x != 120:
    print "FAIL: test_snap: expected 120, got " + str(snapped_x)
    return false
  if snapped_y != 120:
    print "FAIL: test_snap: expected 120, got " + str(snapped_y)
    return false
  print "PASS: test_snap"
  return true

## Test hit test
proc test_hit_test():
  let surf = ds.DesignerSurface()
  let form = f.Form("Form1")
  surf.set_form(form)
  let btn = surf.add_control("CommandButton", 10, 10)
  btn.width = 100
  btn.height = 30

  # Inside the button
  let hit = surf.hit_test_control(20, 20)
  if hit != btn:
    print "FAIL: test_hit_test: should hit button"
    return false

  # Outside
  let miss = surf.hit_test_control(200, 200)
  if miss != nil:
    print "FAIL: test_hit_test: should miss"
    return false
  print "PASS: test_hit_test"
  return true

## Test delete selected
proc test_delete():
  let surf = ds.DesignerSurface()
  let form = f.Form("Form1")
  surf.set_form(form)
  let btn = surf.add_control("CommandButton", 10, 10)
  surf.add_control("Label", 20, 20)
  if len(form.controls) != 2:
    print "FAIL: test_delete: expected 2 before delete"
    return false
  surf.selection = btn
  surf.delete_selected()
  if len(form.controls) != 1:
    print "FAIL: test_delete: expected 1 after delete"
    return false
  if form.controls[0].name != "Label2":
    print "FAIL: test_delete: wrong remaining control: " + form.controls[0].name
    return false
  print "PASS: test_delete"
  return true

## Test mouse interaction
proc test_mouse():
  let surf = ds.DesignerSurface()
  surf.align_to_grid = false
  let form = f.Form("Form1")
  surf.set_form(form)
  let btn = surf.add_control("CommandButton", 50, 50)
  btn.width = 100
  btn.height = 30

  # Click on control (should be at 50,50 now since grid snap is off)
  surf.on_mouse_down(60, 60)
  if surf.selection != btn:
    print "FAIL: test_mouse: should select on click"
    return false

  # Drag the control
  surf.on_mouse_move(70, 70)
  if btn.left == 50 and btn.top == 50:
    print "FAIL: test_mouse: should move"
    return false

  # Release
  surf.on_mouse_up(70, 70)
  if surf.drag_control != nil:
    print "FAIL: test_mouse: drag should be cleared"
    return false
  print "PASS: test_mouse"
  return true

## Run all designer tests
proc run_tests():
  let passed = 0
  let failed = 0
  let tests = [test_surface_create, test_set_form, test_add_control, test_snap, test_hit_test, test_delete, test_mouse]
  for t in tests:
    if t():
      passed = passed + 1
    else:
      failed = failed + 1
  print ""
  print "Results: " + str(passed) + " passed, " + str(failed) + " failed"
  return failed == 0
