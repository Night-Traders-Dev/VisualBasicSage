# Windower tests (import check only - GPU tests need display)

import runtime.windower as w

## Test windower module loads
proc test_windower_import():
  if w == nil:
    print "FAIL: test_windower_import: windower is nil"
    return false
  print "PASS: test_windower_import"
  return true

## Test windower has required procs
proc test_windower_procs():
  if w.show_form == nil:
    print "FAIL: test_windower_procs: show_form missing"
    return false
  if w.run_form_loop == nil:
    print "FAIL: test_windower_procs: run_form_loop missing"
    return false
  if w.render_control == nil:
    print "FAIL: test_windower_procs: render_control missing"
    return false
  print "PASS: test_windower_procs"
  return true

## Run all windower tests
proc run_tests():
  let passed = 0
  let failed = 0
  let tests = [test_windower_import, test_windower_procs]
  for t in tests:
    if t():
      passed = passed + 1
    else:
      failed = failed + 1
  print ""
  print "Results: " + str(passed) + " passed, " + str(failed) + " failed"
  return failed == 0

run_tests()
