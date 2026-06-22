# Lexer tests

import compiler.lexer as lx

## Run all lexer tests
proc test_simple_tokens():
  let result = lx.lex("Sub Main\nEnd Sub")
  let expected_types = [
    lx.TOKEN_KEYWORD, lx.TOKEN_IDENTIFIER, lx.TOKEN_NEWLINE,
    lx.TOKEN_KEYWORD, lx.TOKEN_KEYWORD, lx.TOKEN_EOF
  ]
  if len(result) != len(expected_types):
    print "FAIL: test_simple_tokens: expected " + str(len(expected_types)) + " tokens, got " + str(len(result))
    return false
  for i in range(len(expected_types)):
    if result[i]["type"] != expected_types[i]:
      print "FAIL: test_simple_tokens: token[" + str(i) + "] expected " + expected_types[i] + ", got " + result[i]["type"]
      return false
  print "PASS: test_simple_tokens"
  return true

proc test_keyword_recognition():
  let result = lx.lex("If Then Else EndIf While Wend")
  let expected = ["KEYWORD", "KEYWORD", "KEYWORD", "KEYWORD", "KEYWORD", "KEYWORD", "EOF"]
  if len(result) != len(expected):
    print "FAIL: test_keyword_recognition: count mismatch"
    return false
  for i in range(len(expected)):
    if result[i]["type"] != expected[i]:
      print "FAIL: test_keyword_recognition: token[" + str(i) + "]=" + result[i]["type"]
      return false
  print "PASS: test_keyword_recognition"
  return true

proc test_string_literal():
  let result = lx.lex("MsgBox \"Hello, World!\"")
  if len(result) < 3:
    print "FAIL: test_string_literal: too few tokens"
    return false
  if result[0]["type"] != lx.TOKEN_IDENTIFIER or result[0]["value"] != "MsgBox":
    print "FAIL: test_string_literal: expected MsgBox"
    return false
  if result[1]["type"] != lx.TOKEN_STRING or result[1]["value"] != "Hello, World!":
    print "FAIL: test_string_literal: string value mismatch"
    return false
  print "PASS: test_string_literal"
  return true

proc test_number_literals():
  let result = lx.lex("42 3.14")
  if result[0]["type"] != lx.TOKEN_INTEGER or result[0]["value"] != "42":
    print "FAIL: test_number_literals: integer"
    return false
  if result[1]["type"] != lx.TOKEN_FLOAT or result[1]["value"] != "3.14":
    print "FAIL: test_number_literals: float"
    return false
  print "PASS: test_number_literals"
  return true

proc test_comment():
  let result = lx.lex("' This is a comment\n")
  if result[0]["type"] != lx.TOKEN_COMMENT or result[0]["value"] != " This is a comment":
    print "FAIL: test_comment: comment value mismatch"
    return false
  print "PASS: test_comment"
  return true

proc test_operators():
  let result = lx.lex("= + - * / ^ \\ < > <= >= <> &")
  let expected_values = ["=", "+", "-", "*", "/", "^", "\\", "<", ">", "<=", ">=", "<>", "&"]
  if len(result) != len(expected_values) + 1:
    print "FAIL: test_operators: count mismatch"
    return false
  for i in range(len(expected_values)):
    if result[i]["value"] != expected_values[i]:
      print "FAIL: test_operators: op[" + str(i) + "] expected " + expected_values[i] + ", got " + result[i]["value"]
      return false
  print "PASS: test_operators"
  return true

## Run all tests
proc run_tests():
  let passed = 0
  let failed = 0
  let tests = [test_simple_tokens, test_keyword_recognition, test_string_literal,
               test_number_literals, test_comment, test_operators]
  for t in tests:
    if t():
      passed = passed + 1
    else:
      failed = failed + 1
  print ""
  print "Results: " + str(passed) + " passed, " + str(failed) + " failed"
  return failed == 0

run_tests()
