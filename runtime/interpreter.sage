# VB4 AST Interpreter - walks the AST and executes VB4 programs

import compiler.ast as ast
import runtime.builtins as b

# Environment: maintains variable scope
class Environment:
  proc init(self, parent=nil):
    self.variables = {}
    self.parent = parent
    self.procedures = {}
    self.functions = {}

  proc get(self, name):
    let val = self.variables[name]
    if val != nil:
      return val
    if self.parent != nil:
      return self.parent.get(name)
    return nil

  proc set(self, name, value):
    self.variables[name] = value

  proc has(self, name):
    if dict_has(self.variables, name):
      return true
    if self.parent != nil:
      return self.parent.has(name)
    return false

  proc define_proc(self, name, params, body):
    self.procedures[name] = {"params": params, "body": body}

  proc define_func(self, name, params, return_type, body):
    self.functions[name] = {"params": params, "return_type": return_type, "body": body}

  proc get_proc(self, name):
    if dict_has(self.procedures, name):
      return self.procedures[name]
    if self.parent != nil:
      return self.parent.get_proc(name)
    return nil

  proc get_func(self, name):
    if dict_has(self.functions, name):
      return self.functions[name]
    if self.parent != nil:
      return self.parent.get_func(name)
    return nil

# Interpreter: walks the AST and executes
class Interpreter:
  proc init(self):
    self.global_env = Environment()
    self.builtins = {
      "Print": b.vb_print,
      "MsgBox": b.vb_msgbox,
      "InputBox": b.vb_inputbox,
      "Len": b.vb_len,
      "Asc": b.vb_asc,
      "Chr": b.vb_chr,
      "Left": b.vb_left,
      "Right": b.vb_right,
      "Mid": b.vb_mid,
      "UCase": b.vb_ucase,
      "LCase": b.vb_lcase,
      "Trim": b.vb_trim,
      "Replace": b.vb_replace,
      "Int": b.vb_int,
      "Fix": b.vb_fix,
      "Abs": b.vb_abs,
      "Sgn": b.vb_sgn,
      "Rnd": b.vb_rnd,
      "Randomize": b.vb_randomize,
      "Now": b.vb_now,
      "IsNumeric": b.vb_isnumeric,
      "CStr": b.vb_cstr,
      "CInt": b.vb_cint,
      "CLng": b.vb_clng,
      "CSng": b.vb_csng,
      "CDbl": b.vb_cdbl,
      "CBool": b.vb_cbool,
      "Hex": b.vb_hex,
      "Oct": b.vb_oct,
      "Format": b.vb_format,
      "Array": b.vb_array,
      "UBound": b.vb_ubound,
      "LBound": b.vb_lbound
    }
    self.current_return = nil
    self.current_exit = nil
    self.error_handler = nil

  # Main entry point: execute a Module AST node
  proc execute(self, node):
    if node == nil:
      return nil
    let type_ = self.get_type(node)
    if type_ == "Module":
      return self.exec_module(node)
    return self.exec_statement(node)

  proc get_type(self, node):
    if type(node) == "instance":
      return node.type
    return ""

  # --- Module execution ---

  proc exec_module(self, node):
    # First pass: register all declarations
    for decl in node.declarations:
      let dt = self.get_type(decl)
      if dt == "SubDecl":
        self.global_env.define_proc(decl.name, decl.params, decl.body)
      elif dt == "FunctionDecl":
        self.global_env.define_func(decl.name, decl.params, decl.return_type, decl.body)
    # Second pass: find and execute startup
    # Look for Sub Main, Form_Load, or first Sub
    let startup = self.global_env.get_proc("Main")
    if startup == nil:
      startup = self.global_env.get_proc("Form_Load")
    if startup == nil:
      # Find first sub
      for name in dict_keys(self.global_env.procedures):
        startup = self.global_env.get_proc(name)
        break
    if startup != nil:
      self.exec_proc_body(startup["params"], startup["body"], [])
    return nil

  # --- Statement execution ---

  proc exec_statement(self, node):
    let type_ = self.get_type(node)
    if type_ == "Block":
      return self.exec_block(node)
    if type_ == "Assignment":
      return self.exec_assignment(node)
    if type_ == "SetStatement":
      return self.exec_assignment(node)
    if type_ == "CallStatement":
      return self.exec_call(node)
    if type_ == "IfStatement":
      return self.exec_if(node)
    if type_ == "SelectCase":
      return self.exec_select(node)
    if type_ == "ForLoop":
      return self.exec_for(node)
    if type_ == "ForEachLoop":
      return self.exec_foreach(node)
    if type_ == "DoLoop":
      return self.exec_do(node)
    if type_ == "WhileLoop":
      return self.exec_while(node)
    if type_ == "WithBlock":
      return self.exec_with(node)
    if type_ == "ExitStatement":
      self.current_exit = node.kind
      return nil
    if type_ == "GoToStatement":
      # TODO: implement GoTo
      return nil
    if type_ == "VariableDecl":
      # Dim statement - register variable
      if node.type_name != nil:
        self.global_env.set(node.name, 0)
      else:
        self.global_env.set(node.name, nil)
      return nil
    if type_ == "ConstDecl":
      let val = self.eval_expression(node.value)
      self.global_env.set(node.name, val)
      return nil
    if type_ == "RaiseEvent":
      return nil
    if type_ == "RedimStatement":
      return nil
    if type_ == "EraseStatement":
      for n in node.names:
        self.global_env.set(n, nil)
      return nil
    return nil

  proc exec_block(self, node):
    let local_env = Environment(self.global_env)
    for stmt in node.statements:
      if self.current_exit != nil:
        break
      self.exec_statement(stmt)
    return nil

  proc exec_assignment(self, node):
    let val = self.eval_expression(node.value)
    let target = node.target
    if self.get_type(target) == "MemberAccess":
      # TODO: set property on object
      pass
    elif self.get_type(target) == "Identifier":
      self.global_env.set(target.name, val)
    return val

  proc exec_call(self, node):
    let name = node.name
    let args = []
    for arg in node.args:
      push(args, self.eval_expression(arg))
    # Check builtins
    if dict_has(self.builtins, name):
      self.builtins[name](args)
      return nil
    # Check defined procedures
    let proc_def = self.global_env.get_proc(name)
    if proc_def != nil:
      self.exec_proc_body(proc_def["params"], proc_def["body"], args)
      return nil
    return nil

  proc exec_proc_body(self, params, body, args):
    let local_env = Environment(self.global_env)
    let saved_env = self.global_env
    self.global_env = local_env
    # Bind parameters
    for i in range(len(params)):
      if i < len(args):
        local_env.set(params[i].name, args[i])
      else:
        local_env.set(params[i].name, nil)
    # Execute body
    let old_exit = self.current_exit
    self.current_exit = nil
    self.exec_block(body)
    self.current_exit = old_exit
    self.global_env = saved_env

  proc exec_func_body(self, func_name, params, body, args):
    let local_env = Environment(self.global_env)
    let saved_env = self.global_env
    self.global_env = local_env
    for i in range(len(params)):
      if i < len(args):
        local_env.set(params[i].name, args[i])
      else:
        local_env.set(params[i].name, nil)
    let old_return = self.current_return
    let old_exit = self.current_exit
    self.current_return = nil
    self.current_exit = nil
    self.exec_block(body)
    let result = self.current_return
    # VB4 functions assign to the function name as the return value
    if result == nil:
      result = local_env.get(func_name)
    self.current_return = old_return
    self.current_exit = old_exit
    self.global_env = saved_env
    return result

  proc exec_if(self, node):
    let cond = self.eval_expression(node.condition)
    if self.is_truthy(cond):
      return self.exec_statement(node.then_body)
    for clause in node.else_if_clauses:
      let elif_cond = self.eval_expression(clause.condition)
      if self.is_truthy(elif_cond):
        return self.exec_statement(clause.body)
    if node.else_body != nil:
      return self.exec_statement(node.else_body)
    return nil

  proc exec_select(self, node):
    let expr = self.eval_expression(node.expression)
    for c in node.cases:
      for val_node in c.values:
          let case_val = self.eval_expression(val_node)
          if expr == case_val:
            return self.exec_statement(c.body)
    return nil

  proc exec_for(self, node):
    let start = tonumber(str(self.eval_expression(node.start)))
    let end = tonumber(str(self.eval_expression(node.end)))
    let step = 1
    if node.step != nil:
      step = tonumber(str(self.eval_expression(node.step)))
    self.global_env.set(node.variable, start)
    let var_name = node.variable
    if step > 0:
      while self.global_env.get(var_name) <= end:
        if self.current_exit != nil:
          self.current_exit = nil
          break
        self.exec_statement(node.body)
        let cur = self.global_env.get(var_name)
        self.global_env.set(var_name, cur + step)
    else:
      while self.global_env.get(var_name) >= end:
        if self.current_exit != nil:
          self.current_exit = nil
          break
        self.exec_statement(node.body)
        let cur = self.global_env.get(var_name)
        self.global_env.set(var_name, cur + step)

  proc exec_foreach(self, node):
    let collection = self.eval_expression(node.collection)
    for item in collection:
      if self.current_exit != nil:
        self.current_exit = nil
        break
      self.global_env.set(node.variable, item)
      self.exec_statement(node.body)

  proc exec_do(self, node):
    if node.loop_type == "while":
      while true:
        if self.current_exit != nil:
          self.current_exit = nil
          break
        let cond = self.eval_expression(node.condition)
        if not self.is_truthy(cond):
          break
        self.exec_statement(node.body)
    elif node.loop_type == "until":
      while true:
        if self.current_exit != nil:
          self.current_exit = nil
          break
        let cond = self.eval_expression(node.condition)
        if self.is_truthy(cond):
          break
        self.exec_statement(node.body)

  proc exec_while(self, node):
    while true:
      if self.current_exit != nil:
        self.current_exit = nil
        break
      let cond = self.eval_expression(node.condition)
      if not self.is_truthy(cond):
        break
      self.exec_statement(node.body)

  proc exec_with(self, node):
    # TODO: implement With block
    self.exec_statement(node.body)

  # --- Expression evaluation ---

  proc eval_expression(self, node):
    if node == nil:
      return nil
    let type_ = self.get_type(node)
    if type_ == "Literal":
      return self.eval_literal(node)
    if type_ == "Identifier":
      return self.eval_identifier(node)
    if type_ == "BinaryOp":
      return self.eval_binary(node)
    if type_ == "UnaryOp":
      return self.eval_unary(node)
    if type_ == "FunctionCall":
      return self.eval_func_call(node)
    if type_ == "MemberAccess":
      return self.eval_member_access(node)
    if type_ == "NothingExpr":
      return nil
    if type_ == "MeExpr":
      return nil
    if type_ == "NewExpr":
      return nil
    return nil

  proc eval_literal(self, node):
    if node.literal_type == "Integer":
      return tonumber(str(node.value))
    if node.literal_type == "Double":
      return tonumber(str(node.value))
    if node.literal_type == "String":
      return node.value
    if node.literal_type == "Boolean":
      return node.value
    return node.value

  proc eval_identifier(self, node):
    return self.global_env.get(node.name)

  proc eval_binary(self, node):
    let left = self.eval_expression(node.left)
    let right = self.eval_expression(node.right)
    let op = node.op
    if op == "+":
      return left + right
    if op == "-":
      return left - right
    if op == "*":
      return left * right
    if op == "/":
      return left / right
    if op == "\\":
      return tonumber(str(math.floor(left / right)))
    if op == "^":
      return math.pow(left, right)
    if op == "Mod":
      return left % right
    if op == "&":
      return str(left) + str(right)
    if op == "=":
      return left == right
    if op == "<>":
      return left != right
    if op == "<":
      return left < right
    if op == ">":
      return left > right
    if op == "<=":
      return left <= right
    if op == ">=":
      return left >= right
    if op == "And":
      return self.is_truthy(left) and self.is_truthy(right)
    if op == "Or":
      return self.is_truthy(left) or self.is_truthy(right)
    return nil

  proc eval_unary(self, node):
    let operand = self.eval_expression(node.operand)
    let op = node.op
    if op == "-":
      return -operand
    if op == "+":
      return operand
    if op == "Not":
      return not self.is_truthy(operand)
    return operand

  proc eval_func_call(self, node):
    let name = node.name
    let args = []
    for arg in node.args:
      push(args, self.eval_expression(arg))
    if dict_has(self.builtins, name):
      return self.builtins[name](args)
    let func_def = self.global_env.get_func(name)
    if func_def != nil:
      return self.exec_func_body(name, func_def["params"], func_def["body"], args)
    raise "Undefined function: " + name

  proc eval_member_access(self, node):
    let obj = self.eval_expression(node.object)
    if obj != nil:
      return obj[node.member]
    return nil

  # --- Helpers ---

  proc is_truthy(self, val):
    if val == nil or val == false or val == 0:
      return false
    return true
