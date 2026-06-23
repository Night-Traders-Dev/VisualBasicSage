# Parser tests

import compiler.lexer as lx
import compiler.parser as pr

proc test_parse_sub():
  let tokens = lx.lex("Sub Hello\nMsgBox \"Hi\"\nEnd Sub")
  let ast = pr.parse(tokens)
  if ast.type != "Module":
    print "FAIL: test_parse_sub: expected Module"
    return false
  if len(ast.declarations) != 1:
    print "FAIL: test_parse_sub: expected 1 declaration, got " + str(len(ast.declarations))
    return false
  let decl = ast.declarations[0]
  if decl.type != "SubDecl":
    print "FAIL: test_parse_sub: expected SubDecl, got " + decl.type
    return false
  print "PASS: test_parse_sub"
  return true

proc test_parse_if():
  let tokens = lx.lex("If x = 10 Then\nPrint \"Ten\"\nEnd If")
  let ast = pr.parse(tokens)
  if ast.type != "Module":
    print "FAIL: test_parse_if: expected Module"
    return false
  print "PASS: test_parse_if"
  return true

proc test_parse_for():
  let tokens = lx.lex("For i = 1 To 10\nPrint i\nNext")
  let ast = pr.parse(tokens)
  if ast.type != "Module":
    print "FAIL: test_parse_for: expected Module"
    return false
  print "PASS: test_parse_for"
  return true

proc test_parse_while():
  let tokens = lx.lex("While x < 10\nx = x + 1\nWend")
  let ast = pr.parse(tokens)
  if ast.type != "Module":
    print "FAIL: test_parse_while: expected Module"
    return false
  print "PASS: test_parse_while"
  return true

proc test_parse_do_loop():
  let tokens = lx.lex("Do While x < 10\nx = x + 1\nLoop")
  let ast = pr.parse(tokens)
  if ast.type != "Module":
    print "FAIL: test_parse_do_loop: expected Module"
    return false
  print "PASS: test_parse_do_loop"
  return true

proc test_parse_select():
  let tokens = lx.lex("Select Case x\nCase 1\nPrint \"One\"\nCase 2\nPrint \"Two\"\nEnd Select")
  let ast = pr.parse(tokens)
  if ast.type != "Module":
    print "FAIL: test_parse_select: expected Module"
    return false
  print "PASS: test_parse_select"
  return true

proc run_tests():
  let passed = 0
  let failed = 0
  let tests = [test_parse_sub, test_parse_if, test_parse_for,
               test_parse_while, test_parse_do_loop, test_parse_select]
  for t in tests:
    if t():
      passed = passed + 1
    else:
      failed = failed + 1
  print ""
  print "Results: " + str(passed) + " passed, " + str(failed) + " failed"
  return failed == 0

run_tests()
