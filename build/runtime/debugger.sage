# Debugger - step-through execution, breakpoints, variable inspection

import runtime.interpreter as ri

let DEBUG_STEP_NONE = 0
let DEBUG_STEP_INTO = 1
let DEBUG_STEP_OVER = 2
let DEBUG_STEP_OUT = 3
let DEBUG_STATE_STOPPED = 0
let DEBUG_STATE_RUNNING = 1
let DEBUG_STATE_PAUSED = 2

## Wraps an Interpreter with debugging capabilities
class Debugger:
  proc init(self):
    self.interp = nil
    self.state = DEBUG_STATE_STOPPED
    self.step_mode = DEBUG_STEP_NONE
    self.breakpoints = {}
    self.call_stack = []
    self.variables = {}
    self.current_node = nil
    self.current_line = 0
    self.current_file = ""
    self.on_pause = nil  # callback when paused
    self.history = []

  proc attach(self, interp):
    self.interp = interp
    self.state = DEBUG_STATE_RUNNING
    self.call_stack = []
    self.variables = {}
    self.current_node = nil

  proc set_breakpoint(self, file_path, line_number):
    if not dict_has(self.breakpoints, file_path):
      self.breakpoints[file_path] = {}
    self.breakpoints[file_path][str(line_number)] = true

  proc clear_breakpoint(self, file_path, line_number):
    if dict_has(self.breakpoints, file_path):
      self.breakpoints[file_path][str(line_number)] = nil

  proc has_breakpoint(self, file_path, line):
    if dict_has(self.breakpoints, file_path):
      if dict_has(self.breakpoints[file_path], str(line)):
        return self.breakpoints[file_path][str(line)] == true
    return false

  proc step_into(self):
    self.step_mode = DEBUG_STEP_INTO
    self.state = DEBUG_STATE_RUNNING

  proc step_over(self):
    self.step_mode = DEBUG_STEP_OVER
    self.state = DEBUG_STATE_RUNNING

  proc step_out(self):
    self.step_mode = DEBUG_STEP_OUT
    self.state = DEBUG_STATE_RUNNING

  proc pause(self):
    self.state = DEBUG_STATE_PAUSED

  proc resume(self):
    self.step_mode = DEBUG_STEP_NONE
    self.state = DEBUG_STATE_RUNNING

  proc stop(self):
    self.state = DEBUG_STATE_STOPPED
    self.step_mode = DEBUG_STEP_NONE

  proc notify_exec(self, node, file_path="", stack_depth=0):
    if self.state == DEBUG_STATE_STOPPED:
      return
    self.current_node = node
    self.current_line = 0
    if type(node) == "instance":
      if node.line != nil:
        self.current_line = node.line
    elif type(node) == "dict":
      if node["line"] != nil:
        self.current_line = node["line"]
    self.current_file = file_path
    let node_type = ""
    if type(node) == "instance":
      node_type = node.type
    elif type(node) == "dict":
      node_type = node["type"]
    push(self.history, [file_path, self.current_line, node_type])

    # Check breakpoints
    if self.has_breakpoint(file_path, self.current_line):
      self.state = DEBUG_STATE_PAUSED
      if self.on_pause != nil:
        self.on_pause(self)
      return

    # Check step mode
    if self.step_mode == DEBUG_STEP_INTO:
      self.state = DEBUG_STATE_PAUSED
      if self.on_pause != nil:
        self.on_pause(self)
    elif self.step_mode == DEBUG_STEP_OVER:
      if stack_depth <= self._step_base_depth:
        self.state = DEBUG_STATE_PAUSED
        if self.on_pause != nil:
          self.on_pause(self)

  proc notify_call(self, proc_name):
    push(self.call_stack, proc_name)

  proc notify_return(self):
    if len(self.call_stack) > 0:
      self.call_stack = self.call_stack[:len(self.call_stack) - 1]

  proc get_variables(self):
    if self.interp == nil:
      return {}
    let result = {}
    # Collect variables from current environment scope
    let env = self.interp.global_env
    while env != nil:
      for key in dict_keys(env.variables):
        if not dict_has(result, key):
          result[key] = env.variables[key]
      env = env.parent
    return result

  proc get_call_stack(self):
    return self.call_stack

  proc get_history(self, count=50):
    if count >= len(self.history):
      return self.history
    return self.history[len(self.history) - count:]

## Create a debugger-attached interpreter
proc create_debug():
  let d = Debugger()
  let interp = ri.Interpreter()
  d.attach(interp)
  return d
