# Phase 6: Book compatibility tests
# Tests VB4 language features based on common textbook examples

import compiler.lexer as lx
import compiler.parser as pr
import runtime.interpreter as ri

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

## Test arithmetic operators
proc test_arithmetic_ops():
  let ok = try_run("Sub Main\n  Dim a, b, c\n  a = 10 + 5\n  b = 20 - 3\n  c = a * b / 2\n  Print c\nEnd Sub")
  if ok:
    print "PASS: test_arithmetic_ops"
  else:
    print "FAIL: test_arithmetic_ops"
  return ok

## Test string concatenation
proc test_string_concat():
  let ok = try_run("Sub Main\n  Dim s\n  s = \"Hello\" & \" \" & \"World\"\n  Print s\nEnd Sub")
  if ok:
    print "PASS: test_string_concat"
  else:
    print "FAIL: test_string_concat"
  return ok

## Test comparison operators
proc test_comparison():
  let ok = try_run("Sub Main\n  Dim a, b\n  a = 10\n  b = 20\n  If a < b Then Print \"less\"\n  If a <> b Then Print \"not equal\"\n  If a = 10 Then Print \"equal\"\nEnd Sub")
  if ok:
    print "PASS: test_comparison"
  else:
    print "FAIL: test_comparison"
  return ok

## Test nested If-ElseIf-Else
proc test_nested_if():
  let ok = try_run("Sub Main\n  Dim x\n  x = 5\n  If x > 10 Then\n    Print \"big\"\n  ElseIf x > 0 Then\n    Print \"positive\"\n  Else\n    Print \"non-positive\"\n  End If\nEnd Sub")
  if ok:
    print "PASS: test_nested_if"
  else:
    print "FAIL: test_nested_if"
  return ok

## Test For loop with Step
proc test_for_step():
  let ok = try_run("Sub Main\n  Dim i\n  For i = 1 To 10 Step 2\n    Print i\n  Next\nEnd Sub")
  if ok:
    print "PASS: test_for_step"
  else:
    print "FAIL: test_for_step"
  return ok

## Test Do While loop
proc test_do_while():
  let ok = try_run("Sub Main\n  Dim i\n  i = 0\n  Do While i < 3\n    Print i\n    i = i + 1\n  Loop\nEnd Sub")
  if ok:
    print "PASS: test_do_while"
  else:
    print "FAIL: test_do_while"
  return ok

## Test Do Until loop
proc test_do_until():
  let ok = try_run("Sub Main\n  Dim i\n  i = 0\n  Do Until i >= 3\n    Print i\n    i = i + 1\n  Loop\nEnd Sub")
  if ok:
    print "PASS: test_do_until"
  else:
    print "FAIL: test_do_until"
  return ok

## Test While-Wend loop
proc test_while_wend():
  let ok = try_run("Sub Main\n  Dim i\n  i = 0\n  While i < 3\n    Print i\n    i = i + 1\n  Wend\nEnd Sub")
  if ok:
    print "PASS: test_while_wend"
  else:
    print "FAIL: test_while_wend"
  return ok

## Test Select Case with ranges
proc test_select_ranges():
  let ok = try_run("Sub Main\n  Dim x\n  x = 7\n  Select Case x\n    Case 1 To 5\n      Print \"low\"\n    Case 6 To 10\n      Print \"medium\"\n    Case Else\n      Print \"high\"\n  End Select\nEnd Sub")
  if ok:
    print "PASS: test_select_ranges"
  else:
    print "FAIL: test_select_ranges"
  return ok

## Test function return value
proc test_function_return():
  let ok = try_run("Sub Main\n  Dim r\n  r = Square(5)\n  Print r\nEnd Sub\nFunction Square(n)\n  Square = n * n\nEnd Function")
  if ok:
    print "PASS: test_function_return"
  else:
    print "FAIL: test_function_return"
  return ok

## Test ByRef parameter mutation
proc test_byref():
  let ok = try_run("Sub Main\n  Dim x\n  x = 10\n  DoubleIt x\n  Print x\nEnd Sub\nSub DoubleIt(ByRef n)\n  n = n * 2\nEnd Sub")
  if ok:
    print "PASS: test_byref"
  else:
    print "FAIL: test_byref"
  return ok

## Test string functions
proc test_string_fns():
  let ok = try_run("Sub Main\n  Dim s\n  s = \"hello world\"\n  Print UCase(s)\n  Print Left(s, 5)\n  Print Len(s)\nEnd Sub")
  if ok:
    print "PASS: test_string_fns"
  else:
    print "FAIL: test_string_fns"
  return ok

## Test math functions
proc test_math_fns():
  let ok = try_run("Sub Main\n  Print Abs(-5)\n  Print Int(3.7)\n  Print Sgn(-10)\nEnd Sub")
  if ok:
    print "PASS: test_math_fns"
  else:
    print "FAIL: test_math_fns"
  return ok

## Test IsNumeric
proc test_isnumeric():
  let ok = try_run("Sub Main\n  Dim a, b\n  a = IsNumeric(\"123\")\n  b = IsNumeric(\"abc\")\n  Print a\n  Print b\nEnd Sub")
  if ok:
    print "PASS: test_isnumeric"
  else:
    print "FAIL: test_isnumeric"
  return ok

## Test variable declaration with types
proc test_dim_types():
  let ok = try_run("Sub Main\n  Dim i As Integer\n  Dim s As String\n  Dim b As Boolean\n  i = 42\n  s = \"test\"\n  b = True\n  Print i\n  Print s\n  Print b\nEnd Sub")
  if ok:
    print "PASS: test_dim_types"
  else:
    print "FAIL: test_dim_types"
  return ok

## Test multiple Dim on one line
proc test_dim_multi():
  let ok = try_run("Sub Main\n  Dim a, b, c\n  a = 1\n  b = 2\n  c = 3\n  Print a + b + c\nEnd Sub")
  if ok:
    print "PASS: test_dim_multi"
  else:
    print "FAIL: test_dim_multi"
  return ok

## Test built-in constants (True, False)
proc test_constants():
  let ok = try_run("Sub Main\n  Dim t, f\n  t = True\n  f = False\n  Print t\n  Print f\n  If t Then Print \"true!\"\nEnd Sub")
  if ok:
    print "PASS: test_constants"
  else:
    print "FAIL: test_constants"
  return ok

## Test integer division with backslash operator
proc test_int_division():
  let ok = try_run("Sub Main\n  Dim r\n  r = 10 \\ 3\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_int_division"
  else:
    print "FAIL: test_int_division"
  return ok

## Test Mod operator
proc test_mod():
  let ok = try_run("Sub Main\n  Dim r\n  r = 10 Mod 3\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_mod"
  else:
    print "FAIL: test_mod"
  return ok

## Test logical operators
proc test_logical():
  let ok = try_run("Sub Main\n  Dim a, b\n  a = 5\n  b = 10\n  If a > 0 And b > 0 Then Print \"both positive\"\n  If a > 0 Or b < 0 Then Print \"at least one\"\n  If Not (a < 0) Then Print \"not negative\"\nEnd Sub")
  if ok:
    print "PASS: test_logical"
  else:
    print "FAIL: test_logical"
  return ok

## Run all compatibility tests
proc run_tests():
  let passed = 0
  let failed = 0
  let tests = [test_arithmetic_ops, test_string_concat, test_comparison, test_nested_if, test_for_step, test_do_while, test_do_until, test_while_wend, test_select_ranges, test_function_return, test_byref, test_string_fns, test_math_fns, test_isnumeric, test_dim_types, test_dim_multi, test_constants, test_int_division, test_mod, test_logical]
  for t in tests:
    if t():
      passed = passed + 1
    else:
      failed = failed + 1
  print ""
  print "Results: " + str(passed) + " passed, " + str(failed) + " failed"
  return failed == 0
