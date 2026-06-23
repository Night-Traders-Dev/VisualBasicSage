# Debugger tests

import runtime.debugger as db

## Test Debugger creation
proc test_debugger_create():
  let d = db.Debugger()
  if d.state != db.DEBUG_STATE_STOPPED:
    print "FAIL: test_debugger_create: wrong initial state"
    return false
  if len(d.call_stack) != 0:
    print "FAIL: test_debugger_create: call stack not empty"
    return false
  if len(d.breakpoints) != 0:
    print "FAIL: test_debugger_create: breakpoints not empty"
    return false
  print "PASS: test_debugger_create"
  return true

## Test breakpoint set/clear
proc test_breakpoints():
  let d = db.Debugger()
  d.set_breakpoint("test.bas", 10)
  d.set_breakpoint("test.bas", 20)
  d.set_breakpoint("other.bas", 5)
  if not d.has_breakpoint("test.bas", 10):
    print "FAIL: test_breakpoints: bp 10 not found"
    return false
  if not d.has_breakpoint("test.bas", 20):
    print "FAIL: test_breakpoints: bp 20 not found"
    return false
  if not d.has_breakpoint("other.bas", 5):
    print "FAIL: test_breakpoints: bp 5 not found"
    return false
  if d.has_breakpoint("test.bas", 15):
    print "FAIL: test_breakpoints: bp 15 should not exist"
    return false
  d.clear_breakpoint("test.bas", 10)
  if d.has_breakpoint("test.bas", 10):
    print "FAIL: test_breakpoints: bp 10 should be cleared"
    return false
  print "PASS: test_breakpoints"
  return true

## Test state transitions
proc test_states():
  let d = db.Debugger()
  d.step_into()
  if d.state != db.DEBUG_STATE_RUNNING:
    print "FAIL: test_states: step_into should set running"
    return false
  if d.step_mode != db.DEBUG_STEP_INTO:
    print "FAIL: test_states: step_into should set mode"
    return false
  d.pause()
  if d.state != db.DEBUG_STATE_PAUSED:
    print "FAIL: test_states: pause should set paused"
    return false
  d.resume()
  if d.state != db.DEBUG_STATE_RUNNING:
    print "FAIL: test_states: resume should set running"
    return false
  d.stop()
  if d.state != db.DEBUG_STATE_STOPPED:
    print "FAIL: test_states: stop should set stopped"
    return false
  print "PASS: test_states"
  return true

## Test call stack
proc test_call_stack():
  let d = db.Debugger()
  d.notify_call("Main")
  d.notify_call("Foo")
  d.notify_call("Bar")
  if len(d.call_stack) != 3:
    print "FAIL: test_call_stack: expected 3 calls"
    return false
  if d.call_stack[2] != "Bar":
    print "FAIL: test_call_stack: wrong top"
    return false
  d.notify_return()
  if len(d.call_stack) != 2:
    print "FAIL: test_call_stack: expected 2 after return"
    return false
  print "PASS: test_call_stack"
  return true

## Create a mock node with a line number
proc make_mock_node(line_num, type_="Statement"):
  let n = {}
  n["line"] = line_num
  n["type"] = type_
  return n

## Test breakpoint causes pause
proc test_breakpoint_pause():
  let d = db.Debugger()
  d.attach(nil)
  d.set_breakpoint("test.bas", 5)
  let node = make_mock_node(5)
  d.notify_exec(node, "test.bas", 0)
  if d.state != db.DEBUG_STATE_PAUSED:
    print "FAIL: test_breakpoint_pause: state should be paused, got " + str(d.state)
    return false
  print "PASS: test_breakpoint_pause"
  return true

## Test step into causes pause
proc test_step_into():
  let d = db.Debugger()
  d.attach(nil)
  d.step_into()
  let node = make_mock_node(1)
  d.notify_exec(node, "test.bas", 0)
  if d.state != db.DEBUG_STATE_PAUSED:
    print "FAIL: test_step_into: state should be paused, got " + str(d.state)
    return false
  print "PASS: test_step_into"
  return true

## Test history recording
proc test_history():
  let d = db.Debugger()
  d.attach(nil)
  let n1 = make_mock_node(1)
  let n2 = make_mock_node(2)
  let n3 = make_mock_node(3)
  d.notify_exec(n1, "test.bas", 0)
  d.notify_exec(n2, "test.bas", 0)
  d.notify_exec(n3, "test.bas", 0)
  let hist = d.get_history(10)
  if len(hist) != 3:
    print "FAIL: test_history: expected 3 entries, got " + str(len(hist))
    return false
  print "PASS: test_history"
  return true

## Run all debugger tests
proc run_tests():
  let passed = 0
  let failed = 0
  let tests = [test_debugger_create, test_breakpoints, test_states, test_call_stack, test_breakpoint_pause, test_step_into, test_history]
  for t in tests:
    if t():
      passed = passed + 1
    else:
      failed = failed + 1
  print ""
  print "Results: " + str(passed) + " passed, " + str(failed) + " failed"
  return failed == 0
