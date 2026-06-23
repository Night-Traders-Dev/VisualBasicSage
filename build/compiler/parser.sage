# VB4 Parser - produces AST from token stream

import strings
import compiler.lexer as lx
import compiler.ast as ast

class Parser:
  proc init(self, tokens):
    self.pos = 0
    self.tokens = tokens
    self.tok_len = len(tokens)

  proc peek(self, offset):
    if offset == nil:
      offset = 0
    let idx = self.pos + offset
    if idx < self.tok_len:
      return self.tokens[idx]
    return nil

  proc advance(self):
    let tok = self.tokens[self.pos]
    self.pos = self.pos + 1
    return tok

  proc expect(self, type_, value=nil):
    let tok = self.advance()
    if tok["type"] != type_:
      raise "Expected " + type_ + " at L" + str(tok["line"]) + ":" + str(tok["col"]) + ", got " + tok["type"]
    if value != nil and tok["value"] != value:
      raise "Expected " + str(value) + " at L" + str(tok["line"]) + ":" + str(tok["col"]) + ", got " + str(tok["value"])
    return tok

  proc check(self, type_, value=nil):
    let tok = self.peek()
    if tok == nil:
      return false
    if tok["type"] != type_:
      return false
    if value != nil and tok["value"] != value:
      return false
    return true

  proc skip_newlines(self):
    while self.check(lx.TOKEN_NEWLINE) or self.check(lx.TOKEN_COMMENT):
      self.advance()

  # --- Expression parsing (12 precedence levels) ---

  proc parse_expression(self):
    return self.parse_logical_or()

  proc parse_logical_or(self):
    let left = self.parse_logical_and()
    while self.check(lx.TOKEN_KEYWORD, "Or"):
      self.advance()
      let right = self.parse_logical_and()
      left = ast.BinaryOp("Or", left, right)
    return left

  proc parse_logical_and(self):
    let left = self.parse_equality()
    while self.check(lx.TOKEN_KEYWORD, "And"):
      self.advance()
      let right = self.parse_equality()
      left = ast.BinaryOp("And", left, right)
    return left

  proc parse_equality(self):
    let left = self.parse_comparison()
    while self.check(lx.TOKEN_OPERATOR):
      let op = self.peek()["value"]
      if op == "=" or op == "<>":
        self.advance()
        let right = self.parse_comparison()
        left = ast.BinaryOp(op, left, right)
      else:
        break
    return left

  proc parse_comparison(self):
    let left = self.parse_addition()
    while self.check(lx.TOKEN_OPERATOR):
      let op = self.peek()["value"]
      if op == "<" or op == ">" or op == "<=" or op == ">=":
        self.advance()
        let right = self.parse_addition()
        left = ast.BinaryOp(op, left, right)
      else:
        break
    return left

  proc parse_addition(self):
    let left = self.parse_multiplication()
    while self.check(lx.TOKEN_OPERATOR):
      let op = self.peek()["value"]
      if op == "+" or op == "-" or op == "&":
        self.advance()
        let right = self.parse_multiplication()
        left = ast.BinaryOp(op, left, right)
      else:
        break
    return left

  proc parse_multiplication(self):
    let left = self.parse_unary()
    while self.check(lx.TOKEN_OPERATOR) or self.check(lx.TOKEN_KEYWORD, "Mod"):
      let op = self.peek()["value"]
      if op == "*" or op == "/" or op == "\\" or op == "^" or op == "Mod":
        self.advance()
        let right = self.parse_unary()
        left = ast.BinaryOp(op, left, right)
      else:
        break
    return left

  proc parse_unary(self):
    if self.check(lx.TOKEN_OPERATOR):
      let op = self.peek()["value"]
      if op == "+" or op == "-":
        self.advance()
        let operand = self.parse_unary()
        return ast.UnaryOp(op, operand)
    if self.check(lx.TOKEN_KEYWORD, "Not"):
      self.advance()
      let operand = self.parse_unary()
      return ast.UnaryOp("Not", operand)
    return self.parse_primary()

  proc parse_primary(self):
    if self.check(lx.TOKEN_INTEGER):
      let tok = self.advance()
      return ast.Literal("Integer", tok["value"])
    if self.check(lx.TOKEN_FLOAT):
      let tok = self.advance()
      return ast.Literal("Double", tok["value"])
    if self.check(lx.TOKEN_STRING):
      let tok = self.advance()
      return ast.Literal("String", tok["value"])
    if self.check(lx.TOKEN_KEYWORD, "True"):
      self.advance()
      return ast.Literal("Boolean", true)
    if self.check(lx.TOKEN_KEYWORD, "False"):
      self.advance()
      return ast.Literal("Boolean", false)
    if self.check(lx.TOKEN_KEYWORD, "Nothing"):
      self.advance()
      return ast.NothingExpr()
    if self.check(lx.TOKEN_KEYWORD, "Me"):
      self.advance()
      return ast.MeExpr()
    if self.check(lx.TOKEN_KEYWORD, "New"):
      self.advance()
      let name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
      return ast.NewExpr(name)
    if self.check(lx.TOKEN_DELIMITER, "("):
      self.advance()
      let expr = self.parse_expression()
      self.expect(lx.TOKEN_DELIMITER, ")")
      return expr
    if self.check(lx.TOKEN_KEYWORD):
      let tok = self.advance()
      let name = tok["value"]
      if self.check(lx.TOKEN_DELIMITER, "("):
        let args = self.parse_args()
        return ast.FunctionCall(name, args)
      return ast.Identifier(name)
    if self.check(lx.TOKEN_IDENTIFIER):
      let tok = self.advance()
      let name = tok["value"]
      if self.check(lx.TOKEN_DELIMITER, "("):
        let args = self.parse_args()
        return ast.FunctionCall(name, args)
      if self.check(lx.TOKEN_DELIMITER, "."):
        self.advance()
        let member = self.expect(lx.TOKEN_IDENTIFIER)["value"]
        return ast.MemberAccess(ast.Identifier(name), member)
      return ast.Identifier(name)
    raise "Unexpected token in expression: " + self.peek()["type"]

  proc parse_args(self):
    self.expect(lx.TOKEN_DELIMITER, "(")
    let args = []
    while not self.check(lx.TOKEN_DELIMITER, ")"):
      self.skip_newlines()
      push(args, self.parse_expression())
      if self.check(lx.TOKEN_DELIMITER, ","):
        self.advance()
    self.expect(lx.TOKEN_DELIMITER, ")")
    return args

  proc parse_params(self):
    self.expect(lx.TOKEN_DELIMITER, "(")
    let params = []
    while not self.check(lx.TOKEN_DELIMITER, ")"):
      self.skip_newlines()
      let by_ref = true
      let is_optional = false
      if self.check(lx.TOKEN_KEYWORD, "ByVal"):
        self.advance()
        by_ref = false
      elif self.check(lx.TOKEN_KEYWORD, "ByRef"):
        self.advance()
      elif self.check(lx.TOKEN_KEYWORD, "Optional"):
        self.advance()
        is_optional = true
      let name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
      let as_type = nil
      if self.check(lx.TOKEN_KEYWORD, "As"):
        self.advance()
        if self.check(lx.TOKEN_IDENTIFIER):
          as_type = self.advance()["value"]
        elif self.check(lx.TOKEN_KEYWORD):
          as_type = self.advance()["value"]
      let default_value = nil
      if is_optional and self.check(lx.TOKEN_OPERATOR, "="):
        self.advance()
        default_value = self.parse_expression()
      push(params, ast.Param(name, as_type, by_ref, default_value))
      if self.check(lx.TOKEN_DELIMITER, ","):
        self.advance()
    self.expect(lx.TOKEN_DELIMITER, ")")
    return params

  proc parse_dimensions(self):
    self.expect(lx.TOKEN_DELIMITER, "(")
    let dims = []
    while not self.check(lx.TOKEN_DELIMITER, ")"):
      self.skip_newlines()
      push(dims, self.parse_expression())
      if self.check(lx.TOKEN_DELIMITER, ","):
        self.advance()
    self.expect(lx.TOKEN_DELIMITER, ")")
    return dims

  # --- Block parsing ---

  proc parse_block(self, terminators):
    let stmts = []
    while not self.check(lx.TOKEN_EOF):
      self.skip_newlines()
      if self.check(lx.TOKEN_KEYWORD):
        let val = self.peek()["value"]
        let is_term = false
        for t in terminators:
          if t == val:
            is_term = true
            break
        if is_term:
          break
      let stmt = self.parse_statement()
      if stmt != nil:
        push(stmts, stmt)
      self.skip_newlines()
    return ast.Block(stmts)

  # --- Statement parsing ---

  proc parse_statement(self):
    if self.check(lx.TOKEN_KEYWORD, "Dim"):
      return self.parse_dim_stmt()
    if self.check(lx.TOKEN_KEYWORD, "Const"):
      return self.parse_const()
    if self.check(lx.TOKEN_KEYWORD, "If"):
      return self.parse_if()
    if self.check(lx.TOKEN_KEYWORD, "Select"):
      return self.parse_select()
    if self.check(lx.TOKEN_KEYWORD, "For"):
      return self.parse_for()
    if self.check(lx.TOKEN_KEYWORD, "Do"):
      return self.parse_do()
    if self.check(lx.TOKEN_KEYWORD, "While"):
      return self.parse_while()
    if self.check(lx.TOKEN_KEYWORD, "With"):
      return self.parse_with()
    if self.check(lx.TOKEN_KEYWORD, "Exit"):
      return self.parse_exit()
    if self.check(lx.TOKEN_KEYWORD, "GoTo"):
      return self.parse_goto()
    if self.check(lx.TOKEN_KEYWORD, "GoSub"):
      return self.parse_gosub()
    if self.check(lx.TOKEN_KEYWORD, "Return"):
      return self.parse_return()
    if self.check(lx.TOKEN_KEYWORD, "On"):
      return self.parse_on_error()
    if self.check(lx.TOKEN_KEYWORD, "Resume"):
      return self.parse_resume()
    if self.check(lx.TOKEN_KEYWORD, "RaiseEvent"):
      return self.parse_raise_event()
    if self.check(lx.TOKEN_KEYWORD, "ReDim"):
      return self.parse_redim()
    if self.check(lx.TOKEN_KEYWORD, "Erase"):
      return self.parse_erase()
    if self.check(lx.TOKEN_KEYWORD, "Set"):
      return self.parse_set_stmt()
    if self.check(lx.TOKEN_KEYWORD, "Call"):
      return self.parse_call_stmt()
    if self.check(lx.TOKEN_KEYWORD, "Open"):
      return self.parse_open()
    if self.check(lx.TOKEN_KEYWORD, "Close"):
      return self.parse_close()
    if self.check(lx.TOKEN_KEYWORD, "Put"):
      return self.parse_put()
    if self.check(lx.TOKEN_KEYWORD, "Get"):
      return self.parse_get()
    if self.check(lx.TOKEN_KEYWORD, "Write"):
      return self.parse_write()
    if self.check(lx.TOKEN_KEYWORD, "Print"):
      return self.parse_print_stmt()
    if self.check(lx.TOKEN_KEYWORD, "Input"):
      return self.parse_input()
    if self.check(lx.TOKEN_KEYWORD, "Line"):
      return self.parse_line()
    if self.check(lx.TOKEN_KEYWORD, "Circle"):
      return self.parse_circle()
    if self.check(lx.TOKEN_KEYWORD, "PSet"):
      return self.parse_pset()
    if self.check(lx.TOKEN_KEYWORD, "Cls"):
      return self.parse_cls()
    if self.check(lx.TOKEN_KEYWORD, "Load"):
      return self.parse_load()
    if self.check(lx.TOKEN_KEYWORD, "Unload"):
      return self.parse_unload()
    if self.check(lx.TOKEN_KEYWORD, "Stop"):
      return self.parse_stop()
    if self.check(lx.TOKEN_KEYWORD, "Rem"):
      self.skip_newlines()
      return nil
    if self.check(lx.TOKEN_KEYWORD):
      let kw = self.peek()["value"]
      if strings.startswith(kw, "Def"):
        return self.parse_deftype()
      return self.parse_identifier_stmt()
    if self.check(lx.TOKEN_IDENTIFIER):
      return self.parse_identifier_stmt()
    if self.check(lx.TOKEN_NEWLINE):
      self.advance()
      return nil
    raise "Unexpected token " + self.peek()["type"] + " at L" + str(self.peek()["line"])

  proc parse_dim_stmt(self):
    self.expect(lx.TOKEN_KEYWORD, "Dim")
    let vars = []
    while true:
      let name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
      let as_type = nil
      if self.check(lx.TOKEN_KEYWORD, "As"):
        self.advance()
        if self.check(lx.TOKEN_IDENTIFIER):
          as_type = self.advance()["value"]
        elif self.check(lx.TOKEN_KEYWORD):
          as_type = self.advance()["value"]
      push(vars, ast.VariableDecl(name, as_type))
      if not self.check(lx.TOKEN_DELIMITER, ","):
        break
      self.advance()
    return vars[0]

  proc parse_const(self):
    self.expect(lx.TOKEN_KEYWORD, "Const")
    let name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    let as_type = nil
    if self.check(lx.TOKEN_KEYWORD, "As"):
      self.advance()
      if self.check(lx.TOKEN_IDENTIFIER):
        as_type = self.advance()["value"]
      elif self.check(lx.TOKEN_KEYWORD):
        as_type = self.advance()["value"]
    self.expect(lx.TOKEN_OPERATOR, "=")
    let value = self.parse_expression()
    return ast.ConstDecl(name, as_type, value)

  proc parse_if(self):
    self.expect(lx.TOKEN_KEYWORD, "If")
    let condition = self.parse_expression()
    self.expect(lx.TOKEN_KEYWORD, "Then")

    # Check if single-line If (next token is not a newline)
    if not self.check(lx.TOKEN_NEWLINE):
      let stmts = []
      push(stmts, self.parse_statement())
      let then_body = ast.Block(stmts)
      return ast.IfStatement(condition, then_body, [], nil)

    # Block If
    self.skip_newlines()
    let then_body = self.parse_block(["Else", "ElseIf", "End", "End If"])
    let else_if_clauses = []
    let else_body = nil
    while self.check(lx.TOKEN_KEYWORD, "ElseIf"):
      self.advance()
      let cond = self.parse_expression()
      self.expect(lx.TOKEN_KEYWORD, "Then")
      self.skip_newlines()
      let body = self.parse_block(["Else", "ElseIf", "End", "End If"])
      push(else_if_clauses, ast.ElseIfClause(cond, body))
    if self.check(lx.TOKEN_KEYWORD, "Else"):
      self.advance()
      self.skip_newlines()
      else_body = self.parse_block(["End", "End If"])
    if self.check(lx.TOKEN_KEYWORD, "End"):
      self.advance()
      if self.check(lx.TOKEN_KEYWORD, "If"):
        self.advance()
    return ast.IfStatement(condition, then_body, else_if_clauses, else_body)

  proc parse_select(self):
    self.expect(lx.TOKEN_KEYWORD, "Select")
    self.expect(lx.TOKEN_KEYWORD, "Case")
    let expr = self.parse_expression()
    self.skip_newlines()
    let cases = []
    while self.check(lx.TOKEN_KEYWORD, "Case"):
      self.advance()
      let values = []
      if self.check(lx.TOKEN_KEYWORD, "Else"):
        self.advance()
      else:
        while not self.check(lx.TOKEN_NEWLINE) and not self.check(lx.TOKEN_EOF):
          let val = self.parse_expression()
          if self.check(lx.TOKEN_KEYWORD, "To"):
            self.advance()
            let range_end = self.parse_expression()
            push(values, ast.RangeClause(val, range_end))
          else:
            push(values, val)
          if self.check(lx.TOKEN_DELIMITER, ","):
            self.advance()
      self.skip_newlines()
      let body = self.parse_block(["Case", "End", "End Select"])
      push(cases, ast.CaseClause(values, body))
    if self.check(lx.TOKEN_KEYWORD, "End"):
      self.advance()
      if self.check(lx.TOKEN_KEYWORD, "Select"):
        self.advance()
    return ast.SelectCase(expr, cases)

  proc parse_for(self):
    self.expect(lx.TOKEN_KEYWORD, "For")
    let var_name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    if self.check(lx.TOKEN_KEYWORD, "Each"):
      self.advance()
      self.expect(lx.TOKEN_KEYWORD, "In")
      let collection = self.parse_expression()
      self.skip_newlines()
      let body = self.parse_block(["Next"])
      if self.check(lx.TOKEN_KEYWORD, "Next"):
        self.advance()
      return ast.ForEachLoop(var_name, collection, body)
    self.expect(lx.TOKEN_OPERATOR, "=")
    let start = self.parse_expression()
    self.expect(lx.TOKEN_KEYWORD, "To")
    let end = self.parse_expression()
    let step = nil
    if self.check(lx.TOKEN_KEYWORD, "Step"):
      self.advance()
      step = self.parse_expression()
    self.skip_newlines()
    let body = self.parse_block(["Next"])
    if self.check(lx.TOKEN_KEYWORD, "Next"):
      self.advance()
    return ast.ForLoop(var_name, start, end, step, body)

  proc parse_do(self):
    self.expect(lx.TOKEN_KEYWORD, "Do")
    if self.check(lx.TOKEN_KEYWORD, "While"):
      self.advance()
      let condition = self.parse_expression()
      self.skip_newlines()
      let body = self.parse_block(["Loop"])
      if self.check(lx.TOKEN_KEYWORD, "Loop"):
        self.advance()
      return ast.DoLoop(condition, "while", body)
    if self.check(lx.TOKEN_KEYWORD, "Until"):
      self.advance()
      let condition = self.parse_expression()
      self.skip_newlines()
      let body = self.parse_block(["Loop"])
      if self.check(lx.TOKEN_KEYWORD, "Loop"):
        self.advance()
      return ast.DoLoop(condition, "until", body)
    self.skip_newlines()
    let body = self.parse_block(["Loop"])
    if self.check(lx.TOKEN_KEYWORD, "Loop"):
      self.advance()
      if self.check(lx.TOKEN_KEYWORD, "While"):
        self.advance()
        let condition = self.parse_expression()
        return ast.DoLoop(condition, "while", body)
      if self.check(lx.TOKEN_KEYWORD, "Until"):
        self.advance()
        let condition = self.parse_expression()
        return ast.DoLoop(condition, "until", body)
    return ast.DoLoop(nil, "while", body)

  proc parse_while(self):
    self.expect(lx.TOKEN_KEYWORD, "While")
    let condition = self.parse_expression()
    self.skip_newlines()
    let body = self.parse_block(["Wend"])
    if self.check(lx.TOKEN_KEYWORD, "Wend"):
      self.advance()
    return ast.WhileLoop(condition, body)

  proc parse_with(self):
    self.expect(lx.TOKEN_KEYWORD, "With")
    let obj = self.parse_expression()
    self.skip_newlines()
    let body = self.parse_block(["End", "End With"])
    if self.check(lx.TOKEN_KEYWORD, "End"):
      self.advance()
      if self.check(lx.TOKEN_KEYWORD, "With"):
        self.advance()
    return ast.WithBlock(obj, body)

  proc parse_exit(self):
    self.expect(lx.TOKEN_KEYWORD, "Exit")
    let kind = self.expect(lx.TOKEN_KEYWORD)["value"]
    return ast.ExitStatement(kind)

  proc parse_goto(self):
    self.expect(lx.TOKEN_KEYWORD, "GoTo")
    let label = "0"
    if self.check(lx.TOKEN_INTEGER):
      label = str(self.expect(lx.TOKEN_INTEGER)["value"])
    else:
      label = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    return ast.GoToStatement(label)

  proc parse_on_error(self):
    self.expect(lx.TOKEN_KEYWORD, "On")
    self.expect(lx.TOKEN_KEYWORD, "Error")
    if self.check(lx.TOKEN_KEYWORD, "GoTo"):
      self.advance()
      let label = "0"
      if self.check(lx.TOKEN_INTEGER):
        label = str(self.expect(lx.TOKEN_INTEGER)["value"])
      else:
        label = self.expect(lx.TOKEN_IDENTIFIER)["value"]
      return ast.OnError("goto", label)
    if self.check(lx.TOKEN_KEYWORD, "Resume"):
      self.advance()
      if self.check(lx.TOKEN_KEYWORD, "Next"):
        self.advance()
      return ast.OnError("resume", nil)
    return ast.OnError("ignore", nil)

  proc parse_resume(self):
    self.expect(lx.TOKEN_KEYWORD, "Resume")
    if self.check(lx.TOKEN_KEYWORD, "Next"):
      self.advance()
      return ast.Resume("next")
    if self.check(lx.TOKEN_IDENTIFIER):
      let label = self.expect(lx.TOKEN_IDENTIFIER)["value"]
      return ast.Resume(label)
    return ast.Resume("current")

  proc parse_raise_event(self):
    self.expect(lx.TOKEN_KEYWORD, "RaiseEvent")
    let name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    let args = []
    if self.check(lx.TOKEN_DELIMITER, "("):
      args = self.parse_args()
    return ast.RaiseEvent(name, args)

  proc parse_redim(self):
    self.expect(lx.TOKEN_KEYWORD, "ReDim")
    let preserve = false
    if self.check(lx.TOKEN_KEYWORD, "Preserve"):
      self.advance()
      preserve = true
    let name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    let dims = self.parse_dimensions()
    return ast.RedimStatement(name, dims, preserve)

  proc parse_erase(self):
    self.expect(lx.TOKEN_KEYWORD, "Erase")
    let names = [self.expect(lx.TOKEN_IDENTIFIER)["value"]]
    while self.check(lx.TOKEN_DELIMITER, ","):
      self.advance()
      push(names, self.expect(lx.TOKEN_IDENTIFIER)["value"])
    return ast.EraseStatement(names)

  # --- File I/O ---

  proc parse_open(self):
    self.expect(lx.TOKEN_KEYWORD, "Open")
    let filepath = self.parse_expression()
    let mode = "Input"
    if self.check(lx.TOKEN_KEYWORD, "For"):
      self.advance()
      if self.check(lx.TOKEN_KEYWORD, "Input"):
        mode = "Input"
      elif self.check(lx.TOKEN_KEYWORD, "Output"):
        mode = "Output"
      elif self.check(lx.TOKEN_KEYWORD, "Append"):
        mode = "Append"
      elif self.check(lx.TOKEN_KEYWORD, "Binary"):
        mode = "Binary"
      elif self.check(lx.TOKEN_KEYWORD, "Random"):
        mode = "Random"
      if mode == "Input" or mode == "Output" or mode == "Append" or mode == "Binary" or mode == "Random":
        self.advance()
    let access = nil
    if self.check(lx.TOKEN_KEYWORD, "Read") or self.check(lx.TOKEN_KEYWORD, "Write") or self.check(lx.TOKEN_KEYWORD, "Read Write"):
      access = self.advance()["value"]
    let lock = nil
    if self.check(lx.TOKEN_KEYWORD, "Shared") or self.check(lx.TOKEN_KEYWORD, "Lock Read") or self.check(lx.TOKEN_KEYWORD, "Lock Write") or self.check(lx.TOKEN_KEYWORD, "Lock Read Write"):
      lock = self.advance()["value"]
    self.expect(lx.TOKEN_KEYWORD, "As")
    if self.check(lx.TOKEN_OPERATOR, "#"):
      self.advance()
    let filenum = self.expect(lx.TOKEN_INTEGER)["value"]
    let reclen = nil
    if self.check(lx.TOKEN_IDENTIFIER) and self.peek()["value"] == "Len":
      self.advance()
      if self.check(lx.TOKEN_OPERATOR, "="):
        self.advance()
      reclen = self.parse_expression()
    return ast.OpenStmt(filepath, mode, filenum, access, lock, reclen)

  proc parse_close(self):
    self.expect(lx.TOKEN_KEYWORD, "Close")
    let filenums = []
    if not self.check(lx.TOKEN_NEWLINE) and not self.check(lx.TOKEN_EOF):
      if self.check(lx.TOKEN_OPERATOR, "#"):
        self.advance()
      push(filenums, self.expect(lx.TOKEN_INTEGER)["value"])
      while self.check(lx.TOKEN_DELIMITER, ","):
        self.advance()
        if self.check(lx.TOKEN_OPERATOR, "#"):
          self.advance()
        push(filenums, self.expect(lx.TOKEN_INTEGER)["value"])
    return ast.CloseStmt(filenums)

  proc parse_put(self):
    self.expect(lx.TOKEN_KEYWORD, "Put")
    if self.check(lx.TOKEN_OPERATOR, "#"):
      self.advance()
    let filenum = self.expect(lx.TOKEN_INTEGER)["value"]
    if self.check(lx.TOKEN_DELIMITER, ","):
      self.advance()
    let recordnum = nil
    if not self.check(lx.TOKEN_DELIMITER, ",") and not self.check(lx.TOKEN_NEWLINE):
      recordnum = self.parse_expression()
    if self.check(lx.TOKEN_DELIMITER, ","):
      self.advance()
    let variable = self.parse_expression()
    return ast.PutStmt(filenum, recordnum, variable)

  proc parse_get(self):
    self.expect(lx.TOKEN_KEYWORD, "Get")
    if self.check(lx.TOKEN_OPERATOR, "#"):
      self.advance()
    let filenum = self.expect(lx.TOKEN_INTEGER)["value"]
    if self.check(lx.TOKEN_DELIMITER, ","):
      self.advance()
    let recordnum = nil
    if not self.check(lx.TOKEN_DELIMITER, ",") and not self.check(lx.TOKEN_NEWLINE):
      recordnum = self.parse_expression()
    if self.check(lx.TOKEN_DELIMITER, ","):
      self.advance()
    let variable = self.parse_expression()
    return ast.GetStmt(filenum, recordnum, variable)

  proc parse_write(self):
    self.expect(lx.TOKEN_KEYWORD, "Write")
    if self.check(lx.TOKEN_OPERATOR, "#"):
      self.advance()
    let filenum = self.expect(lx.TOKEN_INTEGER)["value"]
    if self.check(lx.TOKEN_DELIMITER, ","):
      self.advance()
    let exprs = []
    while not self.check(lx.TOKEN_NEWLINE) and not self.check(lx.TOKEN_EOF):
      push(exprs, self.parse_expression())
      if self.check(lx.TOKEN_DELIMITER, ","):
        self.advance()
    return ast.WriteStmt(filenum, exprs)

  proc parse_print_stmt(self):
    if self.peek() != nil and self.peek(1)["type"] == lx.TOKEN_OPERATOR and self.peek(1)["value"] == "#":
      self.advance()  # Print
      self.advance()  # #
      let filenum = self.expect(lx.TOKEN_INTEGER)["value"]
      if self.check(lx.TOKEN_DELIMITER, ","):
        self.advance()
      let exprs = []
      while not self.check(lx.TOKEN_NEWLINE) and not self.check(lx.TOKEN_EOF):
        push(exprs, self.parse_expression())
        if self.check(lx.TOKEN_DELIMITER, ","):
          self.advance()
      return ast.PrintStmt(filenum, exprs)
    # Console Print - treat as CallStatement("Print", args)
    let tok = self.advance()  # consume Print keyword
    let name = tok["value"]
    let args = []
    while not self.check(lx.TOKEN_NEWLINE) and not self.check(lx.TOKEN_EOF) and not self.check(lx.TOKEN_COMMENT):
      if self.check(lx.TOKEN_DELIMITER, ","):
        self.advance()
      push(args, self.parse_expression())
      if not self.check(lx.TOKEN_NEWLINE) and not self.check(lx.TOKEN_EOF) and not self.check(lx.TOKEN_COMMENT):
        if not self.check(lx.TOKEN_DELIMITER, ","):
          break
    return ast.CallStatement(name, args)

  proc parse_input(self):
    if self.peek() != nil and self.peek(1)["type"] == lx.TOKEN_OPERATOR and self.peek(1)["value"] == "#":
      self.advance()  # Input
      self.advance()  # #
      let filenum = self.expect(lx.TOKEN_INTEGER)["value"]
      if self.check(lx.TOKEN_DELIMITER, ","):
        self.advance()
      let variables = []
      while not self.check(lx.TOKEN_NEWLINE) and not self.check(lx.TOKEN_EOF):
        push(variables, self.expect(lx.TOKEN_IDENTIFIER)["value"])
        if self.check(lx.TOKEN_DELIMITER, ","):
          self.advance()
      return ast.InputStmt(filenum, variables)
    # Console Input - treat as CallStatement("Input", args)
    let tok = self.advance()
    let name = tok["value"]
    let args = []
    while not self.check(lx.TOKEN_NEWLINE) and not self.check(lx.TOKEN_EOF) and not self.check(lx.TOKEN_COMMENT):
      if self.check(lx.TOKEN_DELIMITER, ","):
        self.advance()
      push(args, self.parse_expression())
      if not self.check(lx.TOKEN_NEWLINE) and not self.check(lx.TOKEN_EOF) and not self.check(lx.TOKEN_COMMENT):
        if not self.check(lx.TOKEN_DELIMITER, ","):
          break
    return ast.CallStatement(name, args)

  # --- GoSub / Return ---

  proc parse_gosub(self):
    self.expect(lx.TOKEN_KEYWORD, "GoSub")
    let label = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    return ast.GoSubStmt(label)

  proc parse_return(self):
    self.expect(lx.TOKEN_KEYWORD, "Return")
    return ast.ReturnStmt()

  # --- Graphics ---

  proc parse_line(self):
    self.expect(lx.TOKEN_KEYWORD, "Line")
    # Check for Line Input #filenum, var
    if self.check(lx.TOKEN_KEYWORD, "Input"):
      self.advance()
      if self.check(lx.TOKEN_OPERATOR, "#"):
        self.advance()
      let filenum = self.expect(lx.TOKEN_INTEGER)["value"]
      if self.check(lx.TOKEN_DELIMITER, ","):
        self.advance()
      let variable = self.expect(lx.TOKEN_IDENTIFIER)["value"]
      return ast.LineInputStmt(filenum, variable)
    if self.check(lx.TOKEN_DELIMITER, "("):
      self.advance()
      let x1 = self.parse_expression()
      self.expect(lx.TOKEN_DELIMITER, ",")
      let y1 = self.parse_expression()
      self.expect(lx.TOKEN_DELIMITER, ")")
      self.expect(lx.TOKEN_OPERATOR, "-")
      self.expect(lx.TOKEN_DELIMITER, "(")
      let x2 = self.parse_expression()
      self.expect(lx.TOKEN_DELIMITER, ",")
      let y2 = self.parse_expression()
      self.expect(lx.TOKEN_DELIMITER, ")")
      let color = nil
      if self.check(lx.TOKEN_DELIMITER, ","):
        self.advance()
        color = self.parse_expression()
      let box = nil
      if self.check(lx.TOKEN_KEYWORD, "B"):
        self.advance()
        box = "B"
      return ast.LineStmt(x1, y1, x2, y2, color, box)
    if self.check(lx.TOKEN_OPERATOR, "-"):
      self.advance()
      self.expect(lx.TOKEN_DELIMITER, "(")
      let x2 = self.parse_expression()
      self.expect(lx.TOKEN_DELIMITER, ",")
      let y2 = self.parse_expression()
      self.expect(lx.TOKEN_DELIMITER, ")")
      return ast.LineStmt(nil, nil, x2, y2, nil, nil)
    return nil

  proc parse_circle(self):
    self.expect(lx.TOKEN_KEYWORD, "Circle")
    self.expect(lx.TOKEN_DELIMITER, "(")
    let x = self.parse_expression()
    self.expect(lx.TOKEN_DELIMITER, ",")
    let y = self.parse_expression()
    self.expect(lx.TOKEN_DELIMITER, ")")
    self.expect(lx.TOKEN_DELIMITER, ",")
    let radius = self.parse_expression()
    let color = nil
    if self.check(lx.TOKEN_DELIMITER, ","):
      self.advance()
      color = self.parse_expression()
    return ast.CircleStmt(x, y, radius, color)

  proc parse_pset(self):
    self.expect(lx.TOKEN_KEYWORD, "PSet")
    self.expect(lx.TOKEN_DELIMITER, "(")
    let x = self.parse_expression()
    self.expect(lx.TOKEN_DELIMITER, ",")
    let y = self.parse_expression()
    self.expect(lx.TOKEN_DELIMITER, ")")
    let color = nil
    if self.check(lx.TOKEN_DELIMITER, ","):
      self.advance()
      color = self.parse_expression()
    return ast.PSetStmt(x, y, color)

  proc parse_cls(self):
    self.expect(lx.TOKEN_KEYWORD, "Cls")
    return ast.ClsStmt()

  # --- DefType ---

  proc parse_deftype(self):
    let type_name = self.advance()["value"]
    let ranges = []
    while not self.check(lx.TOKEN_NEWLINE) and not self.check(lx.TOKEN_EOF):
      let start_letter = self.expect(lx.TOKEN_IDENTIFIER)["value"]
      let end_letter = start_letter
      if self.check(lx.TOKEN_OPERATOR, "-"):
        self.advance()
        end_letter = self.expect(lx.TOKEN_IDENTIFIER)["value"]
      push(ranges, {"start": start_letter, "end": end_letter})
      if self.check(lx.TOKEN_DELIMITER, ","):
        self.advance()
    return ast.DefTypeStmt(type_name, ranges)

  # --- Load / Unload ---

  proc parse_load(self):
    self.expect(lx.TOKEN_KEYWORD, "Load")
    let form_name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    return ast.LoadStmt(form_name)

  proc parse_unload(self):
    self.expect(lx.TOKEN_KEYWORD, "Unload")
    let form_name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    return ast.UnloadStmt(form_name)

  # --- Stop ---

  proc parse_stop(self):
    self.expect(lx.TOKEN_KEYWORD, "Stop")
    return ast.StopStmt()

  proc parse_set_stmt(self):
    self.expect(lx.TOKEN_KEYWORD, "Set")
    let target = self.parse_expression()
    self.expect(lx.TOKEN_OPERATOR, "=")
    let value = self.parse_expression()
    return ast.SetStatement(target, value)

  proc parse_call_stmt(self):
    self.expect(lx.TOKEN_KEYWORD, "Call")
    let name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    let args = []
    if self.check(lx.TOKEN_DELIMITER, "("):
      args = self.parse_args()
    return ast.CallStatement(name, args)

  proc parse_identifier_stmt(self):
    let tok = self.advance()
    let name = tok["value"]
    if self.check(lx.TOKEN_DELIMITER, "("):
      let args = self.parse_args()
      return ast.FunctionCall(name, args)
    if self.check(lx.TOKEN_OPERATOR, "="):
      self.advance()
      let value = self.parse_expression()
      return ast.Assignment(ast.Identifier(name), value)
    if self.check(lx.TOKEN_DELIMITER, ":"):
      self.advance()
      return ast.LabelDef(name)
    let args = []
    while not self.check(lx.TOKEN_NEWLINE) and not self.check(lx.TOKEN_EOF) and not self.check(lx.TOKEN_COMMENT):
      if self.check(lx.TOKEN_DELIMITER, ","):
        self.advance()
      push(args, self.parse_expression())
      if not self.check(lx.TOKEN_NEWLINE) and not self.check(lx.TOKEN_EOF) and not self.check(lx.TOKEN_COMMENT):
        if not self.check(lx.TOKEN_DELIMITER, ","):
          break
    return ast.CallStatement(name, args)

  # --- Top-level declarations ---

  proc parse_sub(self):
    self.expect(lx.TOKEN_KEYWORD, "Sub")
    let name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    let params = []
    if self.check(lx.TOKEN_DELIMITER, "("):
      params = self.parse_params()
    self.skip_newlines()
    let body = self.parse_block(["End", "End Sub"])
    if self.check(lx.TOKEN_KEYWORD, "End"):
      self.advance()
      if self.check(lx.TOKEN_KEYWORD, "Sub"):
        self.advance()
    self.skip_newlines()
    return ast.SubDecl(name, params, body)

  proc parse_function(self):
    self.expect(lx.TOKEN_KEYWORD, "Function")
    let name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    let params = []
    if self.check(lx.TOKEN_DELIMITER, "("):
      params = self.parse_params()
    let as_type = nil
    if self.check(lx.TOKEN_KEYWORD, "As"):
      self.advance()
      as_type = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    self.skip_newlines()
    let body = self.parse_block(["End", "End Function"])
    if self.check(lx.TOKEN_KEYWORD, "End"):
      self.advance()
      if self.check(lx.TOKEN_KEYWORD, "Function"):
        self.advance()
    self.skip_newlines()
    return ast.FunctionDecl(name, params, as_type, body)

  proc parse_property(self):
    self.expect(lx.TOKEN_KEYWORD, "Property")
    let kind = self.expect(lx.TOKEN_KEYWORD)["value"]
    let name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    let params = []
    if self.check(lx.TOKEN_DELIMITER, "("):
      params = self.parse_params()
    let as_type = nil
    if self.check(lx.TOKEN_KEYWORD, "As"):
      self.advance()
      as_type = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    self.skip_newlines()
    let body = self.parse_block(["End", "End Property"])
    if self.check(lx.TOKEN_KEYWORD, "End"):
      self.advance()
      if self.check(lx.TOKEN_KEYWORD, "Property"):
        self.advance()
    self.skip_newlines()
    if kind == "Get":
      return ast.PropertyGet(name, params, as_type, body)
    if kind == "Let":
      return ast.PropertyLet(name, params, body)
    return ast.PropertySet(name, params, body)

  proc parse_type(self):
    self.expect(lx.TOKEN_KEYWORD, "Type")
    let name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    let fields = []
    self.skip_newlines()
    while not self.check(lx.TOKEN_KEYWORD, "End") and not self.check(lx.TOKEN_EOF):
      let field_name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
      let as_type = nil
      if self.check(lx.TOKEN_KEYWORD, "As"):
        self.advance()
        as_type = self.expect(lx.TOKEN_IDENTIFIER)["value"]
      push(fields, ast.VariableDecl(field_name, as_type))
      self.skip_newlines()
    if self.check(lx.TOKEN_KEYWORD, "End"):
      self.advance()
      if self.check(lx.TOKEN_KEYWORD, "Type"):
        self.advance()
    self.skip_newlines()
    return ast.TypeDecl(name, fields)

  proc parse_enum(self):
    self.expect(lx.TOKEN_KEYWORD, "Enum")
    let name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
    let members = []
    self.skip_newlines()
    while not self.check(lx.TOKEN_KEYWORD, "End") and not self.check(lx.TOKEN_EOF):
      let member_name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
      let member_value = nil
      if self.check(lx.TOKEN_OPERATOR, "="):
        self.advance()
        member_value = self.parse_expression()
      push(members, {"name": member_name, "value": member_value})
      self.skip_newlines()
    if self.check(lx.TOKEN_KEYWORD, "End"):
      self.advance()
      if self.check(lx.TOKEN_KEYWORD, "Enum"):
        self.advance()
    self.skip_newlines()
    return ast.EnumDecl(name, members)

  # --- Main parse entry point ---

  proc run(self):
    self.skip_newlines()
    let module = ast.Module()
    while not self.check(lx.TOKEN_EOF):
      if self.check(lx.TOKEN_KEYWORD, "Sub"):
        push(module.declarations, self.parse_sub())
      elif self.check(lx.TOKEN_KEYWORD, "Function"):
        push(module.declarations, self.parse_function())
      elif self.check(lx.TOKEN_KEYWORD, "Property"):
        push(module.declarations, self.parse_property())
      elif self.check(lx.TOKEN_KEYWORD, "Type"):
        push(module.declarations, self.parse_type())
      elif self.check(lx.TOKEN_KEYWORD, "Enum"):
        push(module.declarations, self.parse_enum())
      elif self.check(lx.TOKEN_KEYWORD, "Declare"):
        self.advance()
        self.skip_newlines()
      elif self.check(lx.TOKEN_KEYWORD, "Event"):
        self.advance()
        let name = self.expect(lx.TOKEN_IDENTIFIER)["value"]
        let params = []
        if self.check(lx.TOKEN_DELIMITER, "("):
          params = self.parse_params()
        push(module.declarations, ast.EventDecl(name, params))
      elif self.check(lx.TOKEN_KEYWORD, "Option"):
        self.advance()
        self.skip_newlines()
      elif self.check(lx.TOKEN_KEYWORD, "Attribute"):
        self.advance()
        self.skip_newlines()
      else:
        break
    return module

## Parser: recursive descent parser for VB4
proc parse(tokens):
  let parser = Parser(tokens)
  return parser.run()
