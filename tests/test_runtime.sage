# Runtime interpreter tests

import compiler.lexer as lx
import compiler.parser as pr
import runtime.interpreter as ri

proc test_simple_print():
  let code = "Sub Main\n  Print 42\nEnd Sub"
  let tokens = lx.lex(code)
  let ast = pr.parse(tokens)
  let interp = ri.Interpreter()
  try:
    interp.execute(ast)
    print "PASS: test_simple_print"
    return true
  catch e:
    print "FAIL: test_simple_print - " + str(e)
    return false

proc test_variable_assignment():
  let code = "Sub Main\n  Dim x\n  x = 10\n  Print x\nEnd Sub"
  let tokens = lx.lex(code)
  let ast = pr.parse(tokens)
  let interp = ri.Interpreter()
  try:
    interp.execute(ast)
    print "PASS: test_variable_assignment"
    return true
  catch e:
    print "FAIL: test_variable_assignment - " + str(e)
    return false

proc test_if_statement():
  let code = "Sub Main\n  Dim x\n  x = 10\n  If x = 10 Then\n    Print 1\n  End If\nEnd Sub"
  let tokens = lx.lex(code)
  let ast = pr.parse(tokens)
  let interp = ri.Interpreter()
  try:
    interp.execute(ast)
    print "PASS: test_if_statement"
    return true
  catch e:
    print "FAIL: test_if_statement - " + str(e)
    return false

proc test_if_else():
  let code = "Sub Main\n  Dim x\n  x = 5\n  If x = 10 Then\n    Print 1\n  Else\n    Print 2\n  End If\nEnd Sub"
  let tokens = lx.lex(code)
  let ast = pr.parse(tokens)
  let interp = ri.Interpreter()
  try:
    interp.execute(ast)
    print "PASS: test_if_else"
    return true
  catch e:
    print "FAIL: test_if_else - " + str(e)
    return false

proc test_for_loop():
  let code = "Sub Main\n  Dim i\n  Dim total\n  total = 0\n  For i = 1 To 5\n    total = total + i\n  Next\n  Print total\nEnd Sub"
  let tokens = lx.lex(code)
  let ast = pr.parse(tokens)
  let interp = ri.Interpreter()
  try:
    interp.execute(ast)
    print "PASS: test_for_loop"
    return true
  catch e:
    print "FAIL: test_for_loop - " + str(e)
    return false

proc test_while_loop():
  let code = "Sub Main\n  Dim x\n  x = 0\n  While x < 3\n    Print x\n    x = x + 1\n  Wend\nEnd Sub"
  let tokens = lx.lex(code)
  let ast = pr.parse(tokens)
  let interp = ri.Interpreter()
  try:
    interp.execute(ast)
    print "PASS: test_while_loop"
    return true
  catch e:
    print "FAIL: test_while_loop - " + str(e)
    return false

proc test_do_while():
  let code = "Sub Main\n  Dim x\n  x = 0\n  Do While x < 3\n    Print x\n    x = x + 1\n  Loop\nEnd Sub"
  let tokens = lx.lex(code)
  let ast = pr.parse(tokens)
  let interp = ri.Interpreter()
  try:
    interp.execute(ast)
    print "PASS: test_do_while"
    return true
  catch e:
    print "FAIL: test_do_while - " + str(e)
    return false

proc test_select_case():
  let code = "Sub Main\n  Dim x\n  x = 2\n  Select Case x\n    Case 1\n      Print 10\n    Case 2\n      Print 20\n  End Select\nEnd Sub"
  let tokens = lx.lex(code)
  let ast = pr.parse(tokens)
  let interp = ri.Interpreter()
  try:
    interp.execute(ast)
    print "PASS: test_select_case"
    return true
  catch e:
    print "FAIL: test_select_case - " + str(e)
    return false

proc test_string_concat():
  let code = "Sub Main\n  Dim s\n  s = \"Hello\" & \" World\"\n  Print s\nEnd Sub"
  let tokens = lx.lex(code)
  let ast = pr.parse(tokens)
  let interp = ri.Interpreter()
  try:
    interp.execute(ast)
    print "PASS: test_string_concat"
    return true
  catch e:
    print "FAIL: test_string_concat - " + str(e)
    return false

proc test_arithmetic():
  let code = "Sub Main\n  Dim x\n  x = 10 + 20 * 3\n  Print x\nEnd Sub"
  let tokens = lx.lex(code)
  let ast = pr.parse(tokens)
  let interp = ri.Interpreter()
  try:
    interp.execute(ast)
    print "PASS: test_arithmetic"
    return true
  catch e:
    print "FAIL: test_arithmetic - " + str(e)
    return false

proc test_function_call():
  let code = "Sub Main\n  Dim result\n  result = Add(3, 4)\n  Print result\nEnd Sub\n\nFunction Add(a, b)\n  Add = a + b\nEnd Function"
  let tokens = lx.lex(code)
  let ast = pr.parse(tokens)
  let interp = ri.Interpreter()
  try:
    interp.execute(ast)
    print "PASS: test_function_call"
    return true
  catch e:
    print "FAIL: test_function_call - " + str(e)
    return false

proc run_tests():
  let passed = 0
  let failed = 0
  let tests = [test_simple_print, test_variable_assignment,
               test_if_statement, test_if_else,
               test_for_loop, test_while_loop,
               test_do_while, test_select_case,
               test_string_concat, test_arithmetic,
               test_function_call]
  for t in tests:
    if t():
      passed = passed + 1
    else:
      failed = failed + 1
  print ""
  print "Results: " + str(passed) + " passed, " + str(failed) + " failed"
  return failed == 0

run_tests()
