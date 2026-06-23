# Phase 10: Financial, Line Input, Error Handling, Expanded Builtins

import compiler.lexer as lx
import compiler.parser as pr
import runtime.interpreter as ri
import io
import strings

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

## Financial: FV
proc test_fv():
  let ok = try_run("Sub Main\n  Dim r\n  r = FV(0.1, 10, -200, -1000, 0)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_fv"
    return true
  print "FAIL: test_fv"
  return false

## Financial: PV
proc test_pv():
  let ok = try_run("Sub Main\n  Dim r\n  r = PV(0.1, 5, -100, 0, 0)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_pv"
    return true
  print "FAIL: test_pv"
  return false

## Financial: PMT
proc test_pmt():
  let ok = try_run("Sub Main\n  Dim r\n  r = PMT(0.05, 10, 10000, 0, 0)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_pmt"
    return true
  print "FAIL: test_pmt"
  return false

## Financial: NPV
proc test_npv():
  let ok = try_run("Sub Main\n  Dim r\n  r = NPV(0.1, Array(-1000, 200, 300, 400, 500))\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_npv"
    return true
  print "FAIL: test_npv"
  return false

## Financial: SLN
proc test_sln():
  let ok = try_run("Sub Main\n  Dim r\n  r = SLN(10000, 1000, 5)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_sln"
    return true
  print "FAIL: test_sln"
  return false

## Financial: SYD
proc test_syd():
  let ok = try_run("Sub Main\n  Dim r\n  r = SYD(10000, 1000, 5, 1)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_syd"
    return true
  print "FAIL: test_syd"
  return false

## Financial: DDB
proc test_ddb():
  let ok = try_run("Sub Main\n  Dim r\n  r = DDB(10000, 1000, 5, 1, 2)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_ddb"
    return true
  print "FAIL: test_ddb"
  return false

## Line Input
proc test_line_input():
  io.writefile("/tmp/test_vb_line.txt", "hello\nworld\n")
  let ok = try_run("Sub Main\n  Open \"/tmp/test_vb_line.txt\" For Input As #1\n  Dim s As String\n  Line Input #1, s\n  Close #1\nEnd Sub")
  if ok:
    print "PASS: test_line_input"
    return true
  print "FAIL: test_line_input"
  return false

## On Error Resume Next
proc test_on_error_resume_next():
  let ok = try_run("Sub Main\n  On Error Resume Next\n  Print \"no error\"\nEnd Sub")
  if ok:
    print "PASS: test_on_error_resume_next"
    return true
  print "FAIL: test_on_error_resume_next"
  return false

## On Error GoTo 0
proc test_on_error_goto_0():
  let ok = try_run("Sub Main\n  On Error GoTo 0\n  Print \"ok\"\nEnd Sub")
  if ok:
    print "PASS: test_on_error_goto_0"
    return true
  print "FAIL: test_on_error_goto_0"
  return false

## EOF function
proc test_eof():
  io.writefile("/tmp/test_vb_eof.txt", "data")
  let ok = try_run("Sub Main\n  Open \"/tmp/test_vb_eof.txt\" For Input As #1\n  Dim r\n  r = EOF(1)\n  Close #1\nEnd Sub")
  if ok:
    print "PASS: test_eof"
    return true
  print "FAIL: test_eof"
  return false

## LOF function
proc test_lof():
  io.writefile("/tmp/test_vb_lof.txt", "hello")
  let ok = try_run("Sub Main\n  Open \"/tmp/test_vb_lof.txt\" For Input As #1\n  Dim r\n  r = LOF(1)\n  Close #1\nEnd Sub")
  if ok:
    print "PASS: test_lof"
    return true
  print "FAIL: test_lof"
  return false

## FreeFile
proc test_freefile():
  let ok = try_run("Sub Main\n  Dim r\n  r = FreeFile\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_freefile"
    return true
  print "FAIL: test_freefile"
  return false

## FileLen
proc test_filelen():
  io.writefile("/tmp/test_vb_filelen.txt", "12345")
  let ok = try_run("Sub Main\n  Dim r\n  r = FileLen(\"/tmp/test_vb_filelen.txt\")\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_filelen"
    return true
  print "FAIL: test_filelen"
  return false

## InStrRev
proc test_instrrev():
  let ok = try_run("Sub Main\n  Dim r\n  r = InStrRev(\"hello hello\", \"hello\")\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_instrrev"
    return true
  print "FAIL: test_instrrev"
  return false

## LTrim
proc test_ltrim():
  let ok = try_run("Sub Main\n  Dim r\n  r = LTrim(\"  hi\")\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_ltrim"
    return true
  print "FAIL: test_ltrim"
  return false

## RTrim
proc test_rtrim():
  let ok = try_run("Sub Main\n  Dim r\n  r = RTrim(\"hi  \")\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_rtrim"
    return true
  print "FAIL: test_rtrim"
  return false

## String function
proc test_string_fn():
  let ok = try_run("Sub Main\n  Dim r\n  r = String(5, \"*\")\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_string_fn"
    return true
  print "FAIL: test_string_fn"
  return false

## Split function
proc test_vb_split():
  let ok = try_run("Sub Main\n  Dim arr\n  arr = Split(\"a,b,c\", \",\")\n  Print arr\nEnd Sub")
  if ok:
    print "PASS: test_vb_split"
    return true
  print "FAIL: test_vb_split"
  return false

## Join function
proc test_vb_join():
  let ok = try_run("Sub Main\n  Dim r\n  r = Join(Array(\"a\", \"b\", \"c\"), \",\")\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_vb_join"
    return true
  print "FAIL: test_vb_join"
  return false

## Exp function
proc test_exp():
  let ok = try_run("Sub Main\n  Dim r\n  r = Exp(1)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_exp"
    return true
  print "FAIL: test_exp"
  return false

## Log function
proc test_log():
  let ok = try_run("Sub Main\n  Dim r\n  r = Log(2.71828)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_log"
    return true
  print "FAIL: test_log"
  return false

## Sqr function
proc test_sqr():
  let ok = try_run("Sub Main\n  Dim r\n  r = Sqr(9)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_sqr"
    return true
  print "FAIL: test_sqr"
  return false

## Fix function
proc test_fix():
  let ok = try_run("Sub Main\n  Dim r\n  r = Fix(3.7)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_fix"
    return true
  print "FAIL: test_fix"
  return false

## Int function
proc test_int():
  let ok = try_run("Sub Main\n  Dim r\n  r = Int(-3.7)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_int"
    return true
  print "FAIL: test_int"
  return false

## Sgn function
proc test_sgn():
  let ok = try_run("Sub Main\n  Dim r\n  r = Sgn(-5)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_sgn"
    return true
  print "FAIL: test_sgn"
  return false

## CStr
proc test_cstr():
  let ok = try_run("Sub Main\n  Dim r\n  r = CStr(42)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_cstr"
    return true
  print "FAIL: test_cstr"
  return false

## CInt
proc test_cint():
  let ok = try_run("Sub Main\n  Dim r\n  r = CInt(3.14)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_cint"
    return true
  print "FAIL: test_cint"
  return false

## CBool
proc test_cbool():
  let ok = try_run("Sub Main\n  Dim r\n  r = CBool(1)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_cbool"
    return true
  print "FAIL: test_cbool"
  return false

## Hex
proc test_hex():
  let ok = try_run("Sub Main\n  Dim r\n  r = Hex(255)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_hex"
    return true
  print "FAIL: test_hex"
  return false

## Oct
proc test_oct():
  let ok = try_run("Sub Main\n  Dim r\n  r = Oct(8)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_oct"
    return true
  print "FAIL: test_oct"
  return false

## FormatCurrency
proc test_formatcurrency():
  let ok = try_run("Sub Main\n  Dim r\n  r = FormatCurrency(1234.5)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_formatcurrency"
    return true
  print "FAIL: test_formatcurrency"
  return false

## FormatNumber
proc test_formatnumber():
  let ok = try_run("Sub Main\n  Dim r\n  r = FormatNumber(1234.5)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_formatnumber"
    return true
  print "FAIL: test_formatnumber"
  return false

## FormatPercent
proc test_formatpercent():
  let ok = try_run("Sub Main\n  Dim r\n  r = FormatPercent(0.25)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_formatpercent"
    return true
  print "FAIL: test_formatpercent"
  return false

## Environ
proc test_environ():
  let ok = try_run("Sub Main\n  Dim r\n  r = Environ(\"HOME\")\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_environ"
    return true
  print "FAIL: test_environ"
  return false

## Command
proc test_command():
  let ok = try_run("Sub Main\n  Dim r\n  r = Command\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_command"
    return true
  print "FAIL: test_command"
  return false

## GetSetting / SaveSetting (Registry-style settings)
proc test_settings():
  let ok = try_run("Sub Main\n  SaveSetting \"MyApp\", \"General\", \"Name\", \"test\"\n  Dim r\n  r = GetSetting(\"MyApp\", \"General\", \"Name\", \"\")\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_settings"
    return true
  print "FAIL: test_settings"
  return false

## TypeName
proc test_typename():
  let ok = try_run("Sub Main\n  Dim r\n  r = TypeName(42)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_typename"
    return true
  print "FAIL: test_typename"
  return false

## VarType
proc test_vartype():
  let ok = try_run("Sub Main\n  Dim r\n  r = VarType(42)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_vartype"
    return true
  print "FAIL: test_vartype"
  return false

## IsArray
proc test_isarray():
  let ok = try_run("Sub Main\n  Dim a\n  a = Array(1, 2, 3)\n  Dim r\n  r = IsArray(a)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_isarray"
    return true
  print "FAIL: test_isarray"
  return false

## IsDate
proc test_isdate():
  let ok = try_run("Sub Main\n  Dim r\n  r = IsDate(\"2024-01-01\")\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_isdate"
    return true
  print "FAIL: test_isdate"
  return false

## DoEvents
proc test_doevents():
  let ok = try_run("Sub Main\n  DoEvents\n  Print \"done\"\nEnd Sub")
  if ok:
    print "PASS: test_doevents"
    return true
  print "FAIL: test_doevents"
  return false

## Beep
proc test_beep():
  let ok = try_run("Sub Main\n  Beep\nEnd Sub")
  if ok:
    print "PASS: test_beep"
    return true
  print "FAIL: test_beep"
  return false

## UBound / LBound
proc test_bounds():
  let ok = try_run("Sub Main\n  Dim a\n  a = Array(10, 20, 30)\n  Dim u, l\n  u = UBound(a)\n  l = LBound(a)\n  Print u\n  Print l\nEnd Sub")
  if ok:
    print "PASS: test_bounds"
    return true
  print "FAIL: test_bounds"
  return false

## StrConv
proc test_str():
  let ok = try_run("Sub Main\n  Dim r\n  r = Str(123)\n  Print r\nEnd Sub")
  if ok:
    print "PASS: test_str"
    return true
  print "FAIL: test_str"
  return false

## Run all tests
proc run_tests():
  let passed = 0
  let failed = 0
  let tests = [test_fv, test_pv, test_pmt, test_npv, test_sln, test_syd, test_ddb,
               test_line_input,
               test_on_error_resume_next, test_on_error_goto_0,
               test_eof, test_lof, test_freefile, test_filelen,
               test_instrrev, test_ltrim, test_rtrim, test_string_fn,
               test_vb_split, test_vb_join,
               test_exp, test_log, test_sqr, test_fix, test_int, test_sgn,
               test_cstr, test_cint, test_cbool,
               test_hex, test_oct, test_str,
               test_formatcurrency, test_formatnumber, test_formatpercent,
               test_environ, test_command, test_settings,
               test_typename, test_vartype, test_isarray, test_isdate,
               test_doevents, test_beep, test_bounds]
  for t in tests:
    if t():
      passed = passed + 1
    else:
      failed = failed + 1
  print ""
  print "Results: " + str(passed) + " passed, " + str(failed) + " failed"
  return failed == 0

run_tests()
