# Form and control tests

import runtime.forms as f
import runtime.controls as c

## Test Form creation
proc test_form_create():
  let form = f.Form("TestForm", "Test")
  if form.name != "TestForm":
    print "FAIL: test_form_create: expected TestForm, got " + form.name
    return false
  if form.caption != "Test":
    print "FAIL: test_form_create: expected Test caption"
    return false
  if len(form.controls) != 0:
    print "FAIL: test_form_create: expected 0 controls"
    return false
  if form.visible != false:
    print "FAIL: test_form_create: form should be hidden"
    return false
  print "PASS: test_form_create"
  return true

## Test control creation
proc test_control_create():
  let btn = c.CommandButton("btnOK")
  btn.caption = "OK"
  btn.left = 10
  btn.top = 20
  btn.width = 100
  btn.height = 30
  if btn.name != "btnOK":
    print "FAIL: test_control_create"
    return false
  if btn.caption != "OK":
    print "FAIL: test_control_create: wrong caption"
    return false
  if btn.left != 10 or btn.top != 20:
    print "FAIL: test_control_create: wrong position"
    return false
  if btn.width != 100 or btn.height != 30:
    print "FAIL: test_control_create: wrong size"
    return false
  print "PASS: test_control_create"
  return true

## Test adding controls to form
proc test_form_add_control():
  let form = f.Form("Form1")
  let btn1 = c.CommandButton("btn1")
  let btn2 = c.CommandButton("btn2")
  let lbl = c.Label("lbl1")
  form.add_control(btn1)
  form.add_control(btn2)
  form.add_control(lbl)
  if len(form.controls) != 3:
    print "FAIL: test_form_add_control: expected 3 controls"
    return false
  print "PASS: test_form_add_control"
  return true

## Test TextBox
proc test_textbox():
  let tb = c.TextBox("txtName")
  tb.text = "hello"
  if tb.text != "hello":
    print "FAIL: test_textbox"
    return false
  print "PASS: test_textbox"
  return true

## Test CheckBox
proc test_checkbox():
  let cb = c.CheckBox("chkOption")
  cb.caption = "Enable"
  cb.value = 1
  if cb.caption != "Enable":
    print "FAIL: test_checkbox: wrong caption"
    return false
  if cb.value != 1:
    print "FAIL: test_checkbox: wrong value"
    return false
  print "PASS: test_checkbox"
  return true

## Test OptionButton
proc test_option():
  let ob = c.OptionButton("optYes")
  ob.caption = "Yes"
  ob.value = true
  if ob.value != true:
    print "FAIL: test_option"
    return false
  print "PASS: test_option"
  return true

## Test ListBox
proc test_listbox():
  let lb = c.ListBox("lstItems")
  lb.add_item("One")
  lb.add_item("Two")
  lb.add_item("Three")
  if len(lb.items) != 3:
    print "FAIL: test_listbox: expected 3 items"
    return false
  print "PASS: test_listbox"
  return true

## Test ComboBox
proc test_combobox():
  let cb = c.ComboBox("cboSelect")
  push(cb.items, "A")
  push(cb.items, "B")
  if len(cb.items) != 2:
    print "FAIL: test_combobox"
    return false
  print "PASS: test_combobox"
  return true

## Test Timer
proc test_timer():
  let t = c.Timer("tmrClock")
  t.interval = 500
  if t.interval != 500:
    print "FAIL: test_timer: wrong interval"
    return false
  if t.enabled != false:
    print "FAIL: test_timer: should be disabled"
    return false
  print "PASS: test_timer"
  return true

## Run all form tests
proc run_tests():
  let passed = 0
  let failed = 0
  let tests = [test_form_create, test_control_create, test_form_add_control, test_textbox, test_checkbox, test_option, test_listbox, test_combobox, test_timer]
  for t in tests:
    if t():
      passed = passed + 1
    else:
      failed = failed + 1
  print ""
  print "Results: " + str(passed) + " passed, " + str(failed) + " failed"
  return failed == 0
