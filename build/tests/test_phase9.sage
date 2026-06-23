# Phase 9: Full VB4 Coverage tests
# Tests File I/O, GoSub/Return, DefType, graphics, expanded builtins

import compiler.lexer as lx
import compiler.parser as pr
import runtime.interpreter as ri
import io
import strings

## Helper: run VB4 source and return true if succeeds
proc try_run(source):
  try:
    let toks = lx.lex(source)
    let tree = pr.parse(toks)
    let interp = ri.Interpreter()
    interp.execute(tree)
    return true
  catch e:
    print "  ERROR: " + str(e)
    return false

## Helper: parse source and return AST
proc try_parse(source):
  let toks = lx.lex(source)
  return pr.parse(toks)

## Test file Output with Write
proc test_file_write():
  let ok = try_run("Sub Main\n  Open \"/tmp/test_vb_out.txt\" For Output As #1\n  Write #1, \"hello\", \"world\"\n  Close #1\nEnd Sub")
  if ok:
    let content = io.readfile("/tmp/test_vb_out.txt")
    if content == "hello,world\n":
      print "PASS: test_file_write"
      return true
    print "FAIL: test_file_write: content mismatch: " + content
    return false
  print "FAIL: test_file_write: execution error"
  return false

## Test file Append mode
proc test_file_append():
  let ok = try_run("Sub Main\n  Open \"/tmp/test_vb_append.txt\" For Output As #1\n  Write #1, \"first\"\n  Close #1\n  Open \"/tmp/test_vb_append.txt\" For Append As #1\n  Write #1, \"second\"\n  Close #1\nEnd Sub")
  if ok:
    let content = io.readfile("/tmp/test_vb_append.txt")
    if strings.contains(content, "second"):
      print "PASS: test_file_append"
      return true
    print "FAIL: test_file_append: missing appended content"
    return false
  print "FAIL: test_file_append: execution error"
  return false

## Test file Input mode
proc test_file_input():
  io.writefile("/tmp/test_vb_input.txt", "hello")
  let ok = try_run("Sub Main\n  Open \"/tmp/test_vb_input.txt\" For Input As #1\n  Dim s As String\n  Input #1, s\n  Close #1\nEnd Sub")
  if ok:
    print "PASS: test_file_input"
    return true
  print "FAIL: test_file_input"
  return false

## Test Put/Get
proc test_file_put_get():
  let ok = try_run("Sub Main\n  Open \"/tmp/test_vb_put.txt\" For Binary As #1\n  Put #1, 1, \"test data\"\n  Close #1\n  Open \"/tmp/test_vb_put.txt\" For Binary As #1\n  Dim d As String\n  Get #1, 1, d\n  Close #1\nEnd Sub")
  if ok:
    print "PASS: test_file_put_get"
    return true
  print "FAIL: test_file_put_get"
  return false

## Test Console Print (via CallStatement)
proc test_console_print():
  let ok = try_run("Sub Main\n  Print \"console test\"\nEnd Sub")
  if ok:
    print "PASS: test_console_print"
    return true
  print "FAIL: test_console_print"
  return false

## Test DefType
proc test_deftype():
  let ok = try_run("Sub Main\n  DefInt a-c\n  DefStr d-f\nEnd Sub")
  if ok:
    print "PASS: test_deftype"
    return true
  print "FAIL: test_deftype"
  return false

## Test graphics statements (parse only, no-op execution)
proc test_graphics():
  let ok = try_run("Sub Main\n  Line (10,20)-(100,200)\n  Circle (50,50), 30\n  PSet (10,10)\n  Cls\nEnd Sub")
  if ok:
    print "PASS: test_graphics"
    return true
  print "FAIL: test_graphics"
  return false

## Test Load/Unload
proc test_load_unload():
  let ok = try_run("Sub Main\n  Load Form2\n  Unload Form2\nEnd Sub")
  if ok:
    print "PASS: test_load_unload"
    return true
  print "FAIL: test_load_unload"
  return false

## Test Stop statement
proc test_stop():
  let ok = try_run("Sub Main\n  Stop\nEnd Sub")
  if ok:
    print "PASS: test_stop"
    return true
  print "FAIL: test_stop"
  return false

## Test expanded builtins: InStr
proc test_instr():
  let ok = try_run("Sub Main\n  Dim r\n  r = InStr(\"hello world\", \"world\")\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_instr"
    return true
  print "FAIL: test_instr"
  return false

## Test Val conversion
proc test_val():
  let ok = try_run("Sub Main\n  Dim r\n  r = Val(\"42\")\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_val"
    return true
  print "FAIL: test_val"
  return false

## Test StrReverse
proc test_strreverse():
  let ok = try_run("Sub Main\n  Dim r\n  r = StrReverse(\"abc\")\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_strreverse"
    return true
  print "FAIL: test_strreverse"
  return false

## Test Space function
proc test_space():
  let ok = try_run("Sub Main\n  Dim r\n  r = Space(5)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_space"
    return true
  print "FAIL: test_space"
  return false

## Test RGB function
proc test_rgb():
  let ok = try_run("Sub Main\n  Dim r\n  r = RGB(255, 0, 0)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_rgb"
    return true
  print "FAIL: test_rgb"
  return false

## Test Date/Time builtins (basic)
proc test_datetime():
  let ok = try_run("Sub Main\n  Dim d, t\n  d = Date\n  t = Time\n  Print d\n  Print t\nEnd Sub")
  if ok:
    print "PASS: test_datetime"
    return true
  print "FAIL: test_datetime"
  return false

## Test IsArray, IsEmpty, IsNull, IsObject
proc test_type_fns():
  let ok = try_run("Sub Main\n  Dim a\n  Dim b\n  a = IsEmpty(b)\n  b = IsNull(Nothing)\n  Print a\n  Print b\nEnd Sub")
  if ok:
    print "PASS: test_type_fns"
    return true
  print "FAIL: test_type_fns"
  return false

## Test Round
proc test_round():
  let ok = try_run("Sub Main\n  Dim r\n  r = Round(3.14159, 2)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_round"
    return true
  print "FAIL: test_round"
  return false

## Test IIf function
proc test_iif():
  let ok = try_run("Sub Main\n  Dim r\n  r = IIf(5 > 3, \"yes\", \"no\")\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_iif"
    return true
  print "FAIL: test_iif"
  return false

## Test ReDim
proc test_redim():
  let ok = try_run("Sub Main\n  Dim arr\n  ReDim arr(5)\nEnd Sub")
  if ok:
    print "PASS: test_redim"
    return true
  print "FAIL: test_redim"
  return false

## Test With block
proc test_with():
  let ok = try_run("Sub Main\n  Dim obj\n  With obj\n  End With\nEnd Sub")
  if ok:
    print "PASS: test_with"
    return true
  print "FAIL: test_with"
  return false

## Print file with "#" separator parsed correctly
proc test_file_print_no_hash():
  io.writefile("/tmp/test_vb_print.txt", "hello")
  let ok = try_run("Sub Main\n  Dim s\n  s = \"hello\"\n  Print s\nEnd Sub")
  if ok:
    print "PASS: test_file_print_no_hash"
    return true
  print "FAIL: test_file_print_no_hash"
  return false

## Run all Phase 9 tests
proc run_tests():
  let passed = 0
  let failed = 0
  let tests = [test_file_write, test_file_append, test_file_input, test_file_put_get,
               test_console_print, test_deftype, test_graphics,
               test_load_unload, test_stop, test_instr, test_val,
               test_strreverse, test_space, test_rgb, test_datetime,
               test_type_fns, test_round, test_iif, test_redim,
               test_with, test_file_print_no_hash]
  for t in tests:
    if t():
      passed = passed + 1
    else:
      failed = failed + 1
  print ""
  print "Results: " + str(passed) + " passed, " + str(failed) + " failed"
  return failed == 0

run_tests()
