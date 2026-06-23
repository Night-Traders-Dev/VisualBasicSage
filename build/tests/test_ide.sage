# IDE integration tests

import ide.editor as ed
import ide.project as pr
import ide.properties as pw
import ide.shell as sh

## Test CodeEditor
proc test_editor_create():
  let e = ed.CodeEditor()
  if len(e.lines) != 1:
    print "FAIL: test_editor_create: expected 1 line"
    return false
  if e.lines[0] != "":
    print "FAIL: test_editor_create: expected empty line"
    return false
  print "PASS: test_editor_create"
  return true

proc test_editor_insert():
  let e = ed.CodeEditor()
  e.insert_text("hello")
  if e.lines[0] != "hello":
    print "FAIL: test_editor_insert: expected hello"
    return false
  if e.cursor_col != 5:
    print "FAIL: test_editor_insert: wrong cursor"
    return false
  print "PASS: test_editor_insert"
  return true

proc test_editor_newline():
  let e = ed.CodeEditor()
  e.insert_text("hello")
  e.new_line()
  if len(e.lines) != 2:
    print "FAIL: test_editor_newline: expected 2 lines"
    return false
  if e.lines[0] != "hello":
    print "FAIL: test_editor_newline: line 0 changed"
    return false
  if e.lines[1] != "":
    print "FAIL: test_editor_newline: line 1 should be empty"
    return false
  print "PASS: test_editor_newline"
  return true

proc test_editor_delete():
  let e = ed.CodeEditor()
  e.insert_text("hello")
  e.cursor_col = 1
  e.delete_char()
  if e.lines[0] != "hllo":
    print "FAIL: test_editor_delete: expected hllo, got " + e.lines[0]
    return false
  print "PASS: test_editor_delete"
  return true

## Test Project
proc test_project_create():
  let p = pr.Project()
  if len(p.forms) != 0:
    print "FAIL: test_project_create: forms should be empty"
    return false
  if len(p.modules) != 0:
    print "FAIL: test_project_create: modules should be empty"
    return false
  print "PASS: test_project_create"
  return true

proc test_project_add():
  let p = pr.Project()
  p.add_form("Form1.frm")
  p.add_module("Module1.bas")
  p.add_class("Class1.cls")
  p.add_reference("stdole32.tlb")
  if len(p.forms) != 1:
    print "FAIL: test_project_add: expected 1 form"
    return false
  if len(p.modules) != 1:
    print "FAIL: test_project_add: expected 1 module"
    return false
  if len(p.classes) != 1:
    print "FAIL: test_project_add: expected 1 class"
    return false
  if len(p.references) != 1:
    print "FAIL: test_project_add: expected 1 reference"
    return false
  print "PASS: test_project_add"
  return true

## Test ProjectExplorer
proc test_explorer():
  let ex = pr.ProjectExplorer()
  if ex.selected != nil:
    print "FAIL: test_explorer: no initial selection"
    return false
  ex.set_selected("test")
  if ex.selected != "test":
    print "FAIL: test_explorer: set_selected failed"
    return false
  print "PASS: test_explorer"
  return true

## Test PropertyWindow
proc test_property_window():
  let pw_inst = pw.PropertyWindow()
  if len(pw_inst.get_properties()) != 0:
    print "FAIL: test_property_window: no object should give empty"
    return false
  let obj = {}
  obj["name"] = "TestObj"
  obj["value"] = 42
  pw_inst.select_object(obj)
  let props = pw_inst.get_properties()
  if len(props) == 0:
    print "FAIL: test_property_window: should have properties"
    return false
  print "PASS: test_property_window"
  return true

## Test IdeShell
proc test_shell_create():
  let shell = sh.IdeShell()
  if len(shell.menus) != 0:
    print "FAIL: test_shell_create: expected no menus"
    return false
  if shell.status_text != "Ready":
    print "FAIL: test_shell_create: wrong status"
    return false
  print "PASS: test_shell_create"
  return true

proc test_shell_menus():
  let shell = sh.IdeShell()
  let file_menu = shell.create_menu("File")
  if len(shell.menus) != 1:
    print "FAIL: test_shell_menus: expected 1 menu"
    return false
  if shell.menus[0]["caption"] != "File":
    print "FAIL: test_shell_menus: wrong caption"
    return false
  shell.add_menu_item(file_menu, "Open", "Ctrl+O")
  if len(file_menu["items"]) != 1:
    print "FAIL: test_shell_menus: expected 1 item"
    return false
  print "PASS: test_shell_menus"
  return true

## Run all IDE tests
proc run_tests():
  let passed = 0
  let failed = 0
  let tests = [test_editor_create, test_editor_insert, test_editor_newline, test_editor_delete, test_project_create, test_project_add, test_explorer, test_property_window, test_shell_create, test_shell_menus]
  for t in tests:
    if t():
      passed = passed + 1
    else:
      failed = failed + 1
  print ""
  print "Results: " + str(passed) + " passed, " + str(failed) + " failed"
  return failed == 0
