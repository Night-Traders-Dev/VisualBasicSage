# File format compatibility tests (.vbp, .frm, .bas, .cls)

import compatibility.vbp as vbp
import compatibility.frm as frm
import compatibility.bas as bas
import compatibility.cls as cls
import strings

## Make a sample .vbp string for testing
proc make_sample_vbp():
  return "Type=Standard EXE\nName=Project1\nStartup=Sub Main\nForm=Form1.frm\nModule=Module1.bas\nReference=*\\G{00020430-0000-0000-C000-000000000046}#2.0#0#C:\\Windows\\System32\\stdole2.tlb#OLE Automation\nTitle=My Project\nExeName32=Project1.exe\n"

## Test parsing .vbp
proc test_vbp_parse():
  let content = make_sample_vbp()
  io.writefile("/tmp/test.vbp", content)
  let proj = vbp.parse_vbp("/tmp/test.vbp")
  if proj["name"] != "Project1":
    print "FAIL: test_vbp_parse: name"
    return false
  if proj["startup"] != "Sub Main":
    print "FAIL: test_vbp_parse: startup"
    return false
  if len(proj["forms"]) != 1:
    print "FAIL: test_vbp_parse: forms"
    return false
  if len(proj["modules"]) != 1:
    print "FAIL: test_vbp_parse: modules"
    return false
  if proj["title"] != "My Project":
    print "FAIL: test_vbp_parse: title"
    return false
  print "PASS: test_vbp_parse"
  return true

## Test round-trip .vbp
proc test_vbp_roundtrip():
  let proj = {
    "type": "Standard EXE",
    "name": "TestProj",
    "startup": "Form1",
    "forms": ["Form1.frm"],
    "modules": [],
    "classes": [],
    "references": [],
    "title": "Test",
    "exe_name": "Test.exe"
  }
  vbp.write_vbp(proj, "/tmp/test_out.vbp")
  let loaded = vbp.parse_vbp("/tmp/test_out.vbp")
  if loaded["name"] != "TestProj":
    print "FAIL: test_vbp_roundtrip: name"
    return false
  if loaded["startup"] != "Form1":
    print "FAIL: test_vbp_roundtrip: startup"
    return false
  if len(loaded["forms"]) != 1:
    print "FAIL: test_vbp_roundtrip: forms"
    return false
  print "PASS: test_vbp_roundtrip"
  return true

## Test parsing .frm
proc test_frm_parse():
  let content = "VERSION 4.00\nBegin VB.Form Form1\n   Caption = \"My Form\"\n   ClientHeight = 3600\n   ClientWidth = 4800\n   Begin VB.CommandButton cmdOK\n      Caption = \"OK\"\n      Left = 100\n      Top = 100\n   End\nEnd\n"
  io.writefile("/tmp/test.frm", content)
  let form = frm.parse_frm("/tmp/test.frm")
  if form["name"] != "Form1":
    print "FAIL: test_frm_parse: name"
    return false
  if form["caption"] != "My Form":
    print "FAIL: test_frm_parse: caption"
    return false
  if len(form["controls"]) != 1:
    print "FAIL: test_frm_parse: controls"
    return false
  if form["controls"][0]["type"] != "VB.CommandButton":
    print "FAIL: test_frm_parse: control type"
    return false
  print "PASS: test_frm_parse"
  return true

## Test .bas round-trip
proc test_bas_roundtrip():
  let content = "Public Sub Test()\n  Print 42\nEnd Sub\n"
  io.writefile("/tmp/test.bas", content)
  let mod = bas.parse_bas("/tmp/test.bas")
  if mod["name"] != "/tmp/test.bas":
    print "FAIL: test_bas_roundtrip: name"
    return false
  if mod["content"] != content:
    print "FAIL: test_bas_roundtrip: content"
    return false
  bas.write_bas(mod, "/tmp/test_out.bas")
  let reloaded = io.readfile("/tmp/test_out.bas")
  if reloaded != content:
    print "FAIL: test_bas_roundtrip: write mismatch"
    return false
  print "PASS: test_bas_roundtrip"
  return true

## Test .cls parse
proc test_cls_parse():
  let content = "VERSION 4.00\nBegin VB.Class MyClass\n   Public Sub DoSomething\n   End Sub\nEnd\n"
  io.writefile("/tmp/test.cls", content)
  let c = cls.parse_cls("/tmp/test.cls")
  if c["name"] != "/tmp/test.cls":
    print "FAIL: test_cls_parse: name"
    return false
  print "PASS: test_cls_parse"
  return true

## Run all file format tests
proc run_tests():
  let passed = 0
  let failed = 0
  let tests = [test_vbp_parse, test_vbp_roundtrip, test_frm_parse, test_bas_roundtrip, test_cls_parse]
  for t in tests:
    if t():
      passed = passed + 1
    else:
      failed = failed + 1
  print ""
  print "Results: " + str(passed) + " passed, " + str(failed) + " failed"
  return failed == 0
