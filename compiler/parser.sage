# VB4 Parser - produces AST from token stream

import strings
import compiler.lexer as lx
import compiler.ast as ast

## Parser: recursive descent parser for VB4
proc parse(tokens):
  let pos = 0
  let tok_len = len(tokens)

  proc peek(offset=0):
    let idx = pos + offset
    if idx < tok_len:
      return tokens[idx]
    return nil

  proc advance():
    let tok = tokens[pos]
    pos = pos + 1
    return tok

  proc expect(type_, value=nil):
    let tok = advance()
    if tok["type"] != type_:
      raise "Expected " + type_ + " at L" + str(tok["line"]) + ":" + str(tok["col"]) + ", got " + tok["type"]
    if value != nil and tok["value"] != value:
      raise "Expected " + str(value) + " at L" + str(tok["line"]) + ":" + str(tok["col"]) + ", got " + str(tok["value"])
    return tok

  proc check(type_, value=nil):
    let tok = peek()
    if tok == nil:
      return false
    if tok["type"] != type_:
      return false
    if value != nil and tok["value"] != value:
      return false
    return true

  proc skip_newlines():
    while check(lx.TOKEN_NEWLINE) or check(lx.TOKEN_COMMENT):
      advance()

  # --- Expression parsing (12 precedence levels) ---

  proc parse_expression():
    return parse_logical_or()

  proc parse_logical_or():
    let left = parse_logical_and()
    while check(lx.TOKEN_KEYWORD, "Or"):
      advance()
      let right = parse_logical_and()
      left = ast.BinaryOp("Or", left, right)
    return left

  proc parse_logical_and():
    let left = parse_equality()
    while check(lx.TOKEN_KEYWORD, "And"):
      advance()
      let right = parse_equality()
      left = ast.BinaryOp("And", left, right)
    return left

  proc parse_equality():
    let left = parse_comparison()
    while check(lx.TOKEN_OPERATOR):
      let op = peek()["value"]
      if op == "=" or op == "<>":
        advance()
        let right = parse_comparison()
        left = ast.BinaryOp(op, left, right)
      else:
        break
    return left

  proc parse_comparison():
    let left = parse_addition()
    while check(lx.TOKEN_OPERATOR):
      let op = peek()["value"]
      if op == "<" or op == ">" or op == "<=" or op == ">=":
        advance()
        let right = parse_addition()
        left = ast.BinaryOp(op, left, right)
      else:
        break
    return left

  proc parse_addition():
    let left = parse_multiplication()
    while check(lx.TOKEN_OPERATOR):
      let op = peek()["value"]
      if op == "+" or op == "-" or op == "&":
        advance()
        let right = parse_multiplication()
        left = ast.BinaryOp(op, left, right)
      else:
        break
    return left

  proc parse_multiplication():
    let left = parse_unary()
    while check(lx.TOKEN_OPERATOR) or check(lx.TOKEN_KEYWORD, "Mod"):
      let op = peek()["value"]
      if op == "*" or op == "/" or op == "\\" or op == "^" or op == "Mod":
        advance()
        let right = parse_unary()
        left = ast.BinaryOp(op, left, right)
      else:
        break
    return left

  proc parse_unary():
    if check(lx.TOKEN_OPERATOR):
      let op = peek()["value"]
      if op == "+" or op == "-":
        advance()
        let operand = parse_unary()
        return ast.UnaryOp(op, operand)
    if check(lx.TOKEN_KEYWORD, "Not"):
      advance()
      let operand = parse_unary()
      return ast.UnaryOp("Not", operand)
    return parse_primary()

  proc parse_primary():
    if check(lx.TOKEN_INTEGER):
      let tok = advance()
      return ast.Literal("Integer", tok["value"])
    if check(lx.TOKEN_FLOAT):
      let tok = advance()
      return ast.Literal("Double", tok["value"])
    if check(lx.TOKEN_STRING):
      let tok = advance()
      return ast.Literal("String", tok["value"])
    if check(lx.TOKEN_KEYWORD, "True"):
      advance()
      return ast.Literal("Boolean", true)
    if check(lx.TOKEN_KEYWORD, "False"):
      advance()
      return ast.Literal("Boolean", false)
    if check(lx.TOKEN_KEYWORD, "Nothing"):
      advance()
      return ast.NothingExpr()
    if check(lx.TOKEN_KEYWORD, "Me"):
      advance()
      return ast.MeExpr()
    if check(lx.TOKEN_KEYWORD, "New"):
      advance()
      let name = expect(lx.TOKEN_IDENTIFIER)["value"]
      return ast.NewExpr(name)
    if check(lx.TOKEN_DELIMITER, "("):
      advance()
      let expr = parse_expression()
      expect(lx.TOKEN_DELIMITER, ")")
      return expr
    if check(lx.TOKEN_IDENTIFIER):
      let tok = advance()
      let name = tok["value"]
      if check(lx.TOKEN_DELIMITER, "("):
        let args = parse_args()
        return ast.FunctionCall(name, args)
      if check(lx.TOKEN_DELIMITER, "."):
        advance()
        let member = expect(lx.TOKEN_IDENTIFIER)["value"]
        return ast.MemberAccess(ast.Identifier(name), member)
      return ast.Identifier(name)
    raise "Unexpected token in expression: " + peek()["type"]

  proc parse_args():
    expect(lx.TOKEN_DELIMITER, "(")
    let args = []
    while not check(lx.TOKEN_DELIMITER, ")"):
      skip_newlines()
      push(args, parse_expression())
      if check(lx.TOKEN_DELIMITER, ","):
        advance()
    expect(lx.TOKEN_DELIMITER, ")")
    return args

  proc parse_params():
    expect(lx.TOKEN_DELIMITER, "(")
    let params = []
    while not check(lx.TOKEN_DELIMITER, ")"):
      skip_newlines()
      let by_ref = true
      if check(lx.TOKEN_KEYWORD, "ByVal"):
        advance()
        by_ref = false
      elif check(lx.TOKEN_KEYWORD, "ByRef"):
        advance()
      elif check(lx.TOKEN_KEYWORD, "Optional"):
        advance()
      let name = expect(lx.TOKEN_IDENTIFIER)["value"]
      let as_type = nil
      if check(lx.TOKEN_KEYWORD, "As"):
        advance()
        as_type = expect(lx.TOKEN_IDENTIFIER)["value"]
      push(params, ast.Param(name, as_type, by_ref))
      if check(lx.TOKEN_DELIMITER, ","):
        advance()
    expect(lx.TOKEN_DELIMITER, ")")
    return params

  proc parse_dimensions():
    expect(lx.TOKEN_DELIMITER, "(")
    let dims = []
    while not check(lx.TOKEN_DELIMITER, ")"):
      skip_newlines()
      push(dims, parse_expression())
      if check(lx.TOKEN_DELIMITER, ","):
        advance()
    expect(lx.TOKEN_DELIMITER, ")")
    return dims

  # --- Block parsing ---

  proc parse_block(terminators):
    let stmts = []
    while not check(lx.TOKEN_EOF):
      skip_newlines()
      if check(lx.TOKEN_KEYWORD):
        let val = peek()["value"]
        let is_term = false
        for t in terminators:
          if t == val:
            is_term = true
            break
        if is_term:
          break
      let stmt = parse_statement()
      if stmt != nil:
        push(stmts, stmt)
      skip_newlines()
    return ast.Block(stmts)

  # --- Statement parsing ---

  proc parse_statement():
    if check(lx.TOKEN_KEYWORD, "Dim"):
      return parse_dim_stmt()
    if check(lx.TOKEN_KEYWORD, "Const"):
      return parse_const()
    if check(lx.TOKEN_KEYWORD, "If"):
      return parse_if()
    if check(lx.TOKEN_KEYWORD, "Select"):
      return parse_select()
    if check(lx.TOKEN_KEYWORD, "For"):
      return parse_for()
    if check(lx.TOKEN_KEYWORD, "Do"):
      return parse_do()
    if check(lx.TOKEN_KEYWORD, "While"):
      return parse_while()
    if check(lx.TOKEN_KEYWORD, "With"):
      return parse_with()
    if check(lx.TOKEN_KEYWORD, "Exit"):
      return parse_exit()
    if check(lx.TOKEN_KEYWORD, "GoTo"):
      return parse_goto()
    if check(lx.TOKEN_KEYWORD, "GoSub"):
      return parse_gosub()
    if check(lx.TOKEN_KEYWORD, "Return"):
      return parse_return()
    if check(lx.TOKEN_KEYWORD, "On"):
      return parse_on_error()
    if check(lx.TOKEN_KEYWORD, "Resume"):
      return parse_resume()
    if check(lx.TOKEN_KEYWORD, "RaiseEvent"):
      return parse_raise_event()
    if check(lx.TOKEN_KEYWORD, "ReDim"):
      return parse_redim()
    if check(lx.TOKEN_KEYWORD, "Erase"):
      return parse_erase()
    if check(lx.TOKEN_KEYWORD, "Set"):
      return parse_set_stmt()
    if check(lx.TOKEN_KEYWORD, "Call"):
      return parse_call_stmt()
    if check(lx.TOKEN_KEYWORD, "Open"):
      return parse_open()
    if check(lx.TOKEN_KEYWORD, "Close"):
      return parse_close()
    if check(lx.TOKEN_KEYWORD, "Put"):
      return parse_put()
    if check(lx.TOKEN_KEYWORD, "Get"):
      return parse_get()
    if check(lx.TOKEN_KEYWORD, "Write"):
      return parse_write()
    if check(lx.TOKEN_KEYWORD, "Print"):
      return parse_print_stmt()
    if check(lx.TOKEN_KEYWORD, "Input"):
      return parse_input()
    if check(lx.TOKEN_KEYWORD, "Line"):
      return parse_line()
    if check(lx.TOKEN_KEYWORD, "Circle"):
      return parse_circle()
    if check(lx.TOKEN_KEYWORD, "PSet"):
      return parse_pset()
    if check(lx.TOKEN_KEYWORD, "Cls"):
      return parse_cls()
    if check(lx.TOKEN_KEYWORD, "Load"):
      return parse_load()
    if check(lx.TOKEN_KEYWORD, "Unload"):
      return parse_unload()
    if check(lx.TOKEN_KEYWORD, "Stop"):
      return parse_stop()
    if check(lx.TOKEN_KEYWORD, "Rem"):
      skip_newlines()
      return nil
    if check(lx.TOKEN_KEYWORD):
      let kw = peek()["value"]
      if strings.startswith(kw, "Def"):
        return parse_deftype()
    if check(lx.TOKEN_IDENTIFIER):
      return parse_identifier_stmt()
    if check(lx.TOKEN_NEWLINE):
      advance()
      return nil
    raise "Unexpected token " + peek()["type"] + " at L" + str(peek()["line"])

  proc parse_dim_stmt():
    expect(lx.TOKEN_KEYWORD, "Dim")
    let vars = []
    while true:
      let name = expect(lx.TOKEN_IDENTIFIER)["value"]
      let as_type = nil
      if check(lx.TOKEN_KEYWORD, "As"):
        advance()
        if check(lx.TOKEN_IDENTIFIER):
          as_type = advance()["value"]
        elif check(lx.TOKEN_KEYWORD):
          as_type = advance()["value"]
      push(vars, ast.VariableDecl(name, as_type))
      if not check(lx.TOKEN_DELIMITER, ","):
        break
      advance()
    return vars[0]

  proc parse_const():
    expect(lx.TOKEN_KEYWORD, "Const")
    let name = expect(lx.TOKEN_IDENTIFIER)["value"]
    let as_type = nil
    if check(lx.TOKEN_KEYWORD, "As"):
      advance()
      if check(lx.TOKEN_IDENTIFIER):
        as_type = advance()["value"]
      elif check(lx.TOKEN_KEYWORD):
        as_type = advance()["value"]
    expect(lx.TOKEN_OPERATOR, "=")
    let value = parse_expression()
    return ast.ConstDecl(name, as_type, value)

  proc parse_if():
    expect(lx.TOKEN_KEYWORD, "If")
    let condition = parse_expression()
    expect(lx.TOKEN_KEYWORD, "Then")

    # Check if single-line If (next token is not a newline)
    if not check(lx.TOKEN_NEWLINE):
      # Single-line If: parse one statement as the body
      let stmts = []
      push(stmts, parse_statement())
      let then_body = ast.Block(stmts)
      # No Else or End If for single-line
      return ast.IfStatement(condition, then_body, [], nil)

    # Block If
    skip_newlines()
    let then_body = parse_block(["Else", "ElseIf", "End", "End If"])
    let else_if_clauses = []
    let else_body = nil
    while check(lx.TOKEN_KEYWORD, "ElseIf"):
      advance()
      let cond = parse_expression()
      expect(lx.TOKEN_KEYWORD, "Then")
      skip_newlines()
      let body = parse_block(["Else", "ElseIf", "End", "End If"])
      push(else_if_clauses, ast.ElseIfClause(cond, body))
    if check(lx.TOKEN_KEYWORD, "Else"):
      advance()
      skip_newlines()
      else_body = parse_block(["End", "End If"])
    if check(lx.TOKEN_KEYWORD, "End"):
      advance()
      if check(lx.TOKEN_KEYWORD, "If"):
        advance()
    return ast.IfStatement(condition, then_body, else_if_clauses, else_body)

  proc parse_select():
    expect(lx.TOKEN_KEYWORD, "Select")
    expect(lx.TOKEN_KEYWORD, "Case")
    let expr = parse_expression()
    skip_newlines()
    let cases = []
    while check(lx.TOKEN_KEYWORD, "Case"):
      advance()
      let values = []
      # Handle "Case Else" (catch-all)
      if check(lx.TOKEN_KEYWORD, "Else"):
        advance()
        # values stays empty to indicate catch-all
      else:
        while not check(lx.TOKEN_NEWLINE) and not check(lx.TOKEN_EOF):
          let val = parse_expression()
          # Handle "To" range operator in case values
          if check(lx.TOKEN_KEYWORD, "To"):
            advance()
            let range_end = parse_expression()
            push(values, ast.RangeClause(val, range_end))
          else:
            push(values, val)
          if check(lx.TOKEN_DELIMITER, ","):
            advance()
      skip_newlines()
      let body = parse_block(["Case", "End", "End Select"])
      push(cases, ast.CaseClause(values, body))
    if check(lx.TOKEN_KEYWORD, "End"):
      advance()
      if check(lx.TOKEN_KEYWORD, "Select"):
        advance()
    return ast.SelectCase(expr, cases)

  proc parse_for():
    expect(lx.TOKEN_KEYWORD, "For")
    let var_name = expect(lx.TOKEN_IDENTIFIER)["value"]
    if check(lx.TOKEN_KEYWORD, "Each"):
      advance()
      expect(lx.TOKEN_KEYWORD, "In")
      let collection = parse_expression()
      skip_newlines()
      let body = parse_block(["Next"])
      if check(lx.TOKEN_KEYWORD, "Next"):
        advance()
      return ast.ForEachLoop(var_name, collection, body)
    expect(lx.TOKEN_OPERATOR, "=")
    let start = parse_expression()
    expect(lx.TOKEN_KEYWORD, "To")
    let end = parse_expression()
    let step = nil
    if check(lx.TOKEN_KEYWORD, "Step"):
      advance()
      step = parse_expression()
    skip_newlines()
    let body = parse_block(["Next"])
    if check(lx.TOKEN_KEYWORD, "Next"):
      advance()
    return ast.ForLoop(var_name, start, end, step, body)

  proc parse_do():
    expect(lx.TOKEN_KEYWORD, "Do")
    if check(lx.TOKEN_KEYWORD, "While"):
      advance()
      let condition = parse_expression()
      skip_newlines()
      let body = parse_block(["Loop"])
      if check(lx.TOKEN_KEYWORD, "Loop"):
        advance()
      return ast.DoLoop(condition, "while", body)
    if check(lx.TOKEN_KEYWORD, "Until"):
      advance()
      let condition = parse_expression()
      skip_newlines()
      let body = parse_block(["Loop"])
      if check(lx.TOKEN_KEYWORD, "Loop"):
        advance()
      return ast.DoLoop(condition, "until", body)
    skip_newlines()
    let body = parse_block(["Loop"])
    if check(lx.TOKEN_KEYWORD, "Loop"):
      advance()
      if check(lx.TOKEN_KEYWORD, "While"):
        advance()
        let condition = parse_expression()
        return ast.DoLoop(condition, "while", body)
      if check(lx.TOKEN_KEYWORD, "Until"):
        advance()
        let condition = parse_expression()
        return ast.DoLoop(condition, "until", body)
    return ast.DoLoop(nil, "while", body)

  proc parse_while():
    expect(lx.TOKEN_KEYWORD, "While")
    let condition = parse_expression()
    skip_newlines()
    let body = parse_block(["Wend"])
    if check(lx.TOKEN_KEYWORD, "Wend"):
      advance()
    return ast.WhileLoop(condition, body)

  proc parse_with():
    expect(lx.TOKEN_KEYWORD, "With")
    let obj = parse_expression()
    skip_newlines()
    let body = parse_block(["End", "End With"])
    if check(lx.TOKEN_KEYWORD, "End"):
      advance()
      if check(lx.TOKEN_KEYWORD, "With"):
        advance()
    return ast.WithBlock(obj, body)

  proc parse_exit():
    expect(lx.TOKEN_KEYWORD, "Exit")
    let kind = expect(lx.TOKEN_KEYWORD)["value"]
    return ast.ExitStatement(kind)

  proc parse_goto():
    expect(lx.TOKEN_KEYWORD, "GoTo")
    let label = expect(lx.TOKEN_IDENTIFIER)["value"]
    return ast.GoToStatement(label)

  proc parse_on_error():
    expect(lx.TOKEN_KEYWORD, "On")
    expect(lx.TOKEN_KEYWORD, "Error")
    if check(lx.TOKEN_KEYWORD, "GoTo"):
      advance()
      let label = expect(lx.TOKEN_IDENTIFIER)["value"]
      return ast.OnError("goto", label)
    if check(lx.TOKEN_KEYWORD, "Resume"):
      advance()
      return ast.OnError("resume", nil)
    return ast.OnError("ignore", nil)

  proc parse_resume():
    expect(lx.TOKEN_KEYWORD, "Resume")
    if check(lx.TOKEN_KEYWORD, "Next"):
      advance()
      return ast.Resume("next")
    if check(lx.TOKEN_IDENTIFIER):
      let label = expect(lx.TOKEN_IDENTIFIER)["value"]
      return ast.Resume(label)
    return ast.Resume("current")

  proc parse_raise_event():
    expect(lx.TOKEN_KEYWORD, "RaiseEvent")
    let name = expect(lx.TOKEN_IDENTIFIER)["value"]
    let args = []
    if check(lx.TOKEN_DELIMITER, "("):
      args = parse_args()
    return ast.RaiseEvent(name, args)

  proc parse_redim():
    expect(lx.TOKEN_KEYWORD, "ReDim")
    let preserve = false
    if check(lx.TOKEN_KEYWORD, "Preserve"):
      advance()
      preserve = true
    let name = expect(lx.TOKEN_IDENTIFIER)["value"]
    let dims = parse_dimensions()
    return ast.RedimStatement(name, dims, preserve)

  proc parse_erase():
    expect(lx.TOKEN_KEYWORD, "Erase")
    let names = [expect(lx.TOKEN_IDENTIFIER)["value"]]
    while check(lx.TOKEN_DELIMITER, ","):
      advance()
      push(names, expect(lx.TOKEN_IDENTIFIER)["value"])
    return ast.EraseStatement(names)

  # --- File I/O ---

  proc parse_open():
    expect(lx.TOKEN_KEYWORD, "Open")
    let filepath = parse_expression()
    let mode = "Input"
    if check(lx.TOKEN_KEYWORD, "For"):
      advance()
      if check(lx.TOKEN_KEYWORD, "Input"):
        mode = "Input"
      elif check(lx.TOKEN_KEYWORD, "Output"):
        mode = "Output"
      elif check(lx.TOKEN_KEYWORD, "Append"):
        mode = "Append"
      elif check(lx.TOKEN_KEYWORD, "Binary"):
        mode = "Binary"
      elif check(lx.TOKEN_KEYWORD, "Random"):
        mode = "Random"
      if mode == "Input" or mode == "Output" or mode == "Append" or mode == "Binary" or mode == "Random":
        advance()
    let access = nil
    if check(lx.TOKEN_KEYWORD, "Read") or check(lx.TOKEN_KEYWORD, "Write") or check(lx.TOKEN_KEYWORD, "Read Write"):
      access = advance()["value"]
    let lock = nil
    if check(lx.TOKEN_KEYWORD, "Shared") or check(lx.TOKEN_KEYWORD, "Lock Read") or check(lx.TOKEN_KEYWORD, "Lock Write") or check(lx.TOKEN_KEYWORD, "Lock Read Write"):
      lock = advance()["value"]
    expect(lx.TOKEN_KEYWORD, "As")
    if check(lx.TOKEN_OPERATOR, "#"):
      advance()
    let filenum = expect(lx.TOKEN_INTEGER)["value"]
    let reclen = nil
    if check(lx.TOKEN_IDENTIFIER) and peek()["value"] == "Len":
      advance()
      if check(lx.TOKEN_OPERATOR, "="):
        advance()
      reclen = parse_expression()
    return ast.OpenStmt(filepath, mode, filenum, access, lock, reclen)

  proc parse_close():
    expect(lx.TOKEN_KEYWORD, "Close")
    let filenums = []
    if not check(lx.TOKEN_NEWLINE) and not check(lx.TOKEN_EOF):
      if check(lx.TOKEN_OPERATOR, "#"):
        advance()
      push(filenums, expect(lx.TOKEN_INTEGER)["value"])
      while check(lx.TOKEN_DELIMITER, ","):
        advance()
        if check(lx.TOKEN_OPERATOR, "#"):
          advance()
        push(filenums, expect(lx.TOKEN_INTEGER)["value"])
    return ast.CloseStmt(filenums)

  proc parse_put():
    expect(lx.TOKEN_KEYWORD, "Put")
    if check(lx.TOKEN_OPERATOR, "#"):
      advance()
    let filenum = expect(lx.TOKEN_INTEGER)["value"]
    if check(lx.TOKEN_DELIMITER, ","):
      advance()
    let recordnum = nil
    if not check(lx.TOKEN_DELIMITER, ",") and not check(lx.TOKEN_NEWLINE):
      recordnum = parse_expression()
    if check(lx.TOKEN_DELIMITER, ","):
      advance()
    let variable = parse_expression()
    return ast.PutStmt(filenum, recordnum, variable)

  proc parse_get():
    expect(lx.TOKEN_KEYWORD, "Get")
    if check(lx.TOKEN_OPERATOR, "#"):
      advance()
    let filenum = expect(lx.TOKEN_INTEGER)["value"]
    if check(lx.TOKEN_DELIMITER, ","):
      advance()
    let recordnum = nil
    if not check(lx.TOKEN_DELIMITER, ",") and not check(lx.TOKEN_NEWLINE):
      recordnum = parse_expression()
    if check(lx.TOKEN_DELIMITER, ","):
      advance()
    let variable = parse_expression()
    return ast.GetStmt(filenum, recordnum, variable)

  proc parse_write():
    expect(lx.TOKEN_KEYWORD, "Write")
    if check(lx.TOKEN_OPERATOR, "#"):
      advance()
    let filenum = expect(lx.TOKEN_INTEGER)["value"]
    if check(lx.TOKEN_DELIMITER, ","):
      advance()
    let exprs = []
    while not check(lx.TOKEN_NEWLINE) and not check(lx.TOKEN_EOF):
      push(exprs, parse_expression())
      if check(lx.TOKEN_DELIMITER, ","):
        advance()
    return ast.WriteStmt(filenum, exprs)

  proc parse_print_stmt():
    # Check for file print (Print #filenum, ...) vs console Print
    if peek(1) != nil and peek(1)["type"] == lx.TOKEN_OPERATOR and peek(1)["value"] == "#":
      advance()
      advance()
      let filenum = expect(lx.TOKEN_INTEGER)["value"]
      if check(lx.TOKEN_DELIMITER, ","):
        advance()
      let exprs = []
      while not check(lx.TOKEN_NEWLINE) and not check(lx.TOKEN_EOF):
        push(exprs, parse_expression())
        if check(lx.TOKEN_DELIMITER, ","):
          advance()
      return ast.PrintStmt(filenum, exprs)
    # Console Print - treat as CallStatement("Print", args)
    let tok = advance()
    let name = tok["value"]
    let args = []
    while not check(lx.TOKEN_NEWLINE) and not check(lx.TOKEN_EOF) and not check(lx.TOKEN_COMMENT):
      if check(lx.TOKEN_DELIMITER, ","):
        advance()
      push(args, parse_expression())
      if not check(lx.TOKEN_NEWLINE) and not check(lx.TOKEN_EOF) and not check(lx.TOKEN_COMMENT):
        if not check(lx.TOKEN_DELIMITER, ","):
          break
    return ast.CallStatement(name, args)

  proc parse_input():
    if peek(1) != nil and peek(1)["type"] == lx.TOKEN_OPERATOR and peek(1)["value"] == "#":
      advance()
      advance()
      let filenum = expect(lx.TOKEN_INTEGER)["value"]
      if check(lx.TOKEN_DELIMITER, ","):
        advance()
      let variables = []
      while not check(lx.TOKEN_NEWLINE) and not check(lx.TOKEN_EOF):
        push(variables, expect(lx.TOKEN_IDENTIFIER)["value"])
        if check(lx.TOKEN_DELIMITER, ","):
          advance()
      return ast.InputStmt(filenum, variables)
    # Console Input - treat as CallStatement("Input", args)
    let tok = advance()
    let name = tok["value"]
    let args = []
    while not check(lx.TOKEN_NEWLINE) and not check(lx.TOKEN_EOF) and not check(lx.TOKEN_COMMENT):
      if check(lx.TOKEN_DELIMITER, ","):
        advance()
      push(args, parse_expression())
      if not check(lx.TOKEN_NEWLINE) and not check(lx.TOKEN_EOF) and not check(lx.TOKEN_COMMENT):
        if not check(lx.TOKEN_DELIMITER, ","):
          break
    return ast.CallStatement(name, args)

  # --- GoSub / Return ---

  proc parse_gosub():
    expect(lx.TOKEN_KEYWORD, "GoSub")
    let label = expect(lx.TOKEN_IDENTIFIER)["value"]
    return ast.GoSubStmt(label)

  proc parse_return():
    expect(lx.TOKEN_KEYWORD, "Return")
    return ast.ReturnStmt()

  # --- Graphics ---

  proc parse_line():
    expect(lx.TOKEN_KEYWORD, "Line")
    if check(lx.TOKEN_DELIMITER, "("):
      advance()
      let x1 = parse_expression()
      expect(lx.TOKEN_DELIMITER, ",")
      let y1 = parse_expression()
      expect(lx.TOKEN_DELIMITER, ")")
      expect(lx.TOKEN_OPERATOR, "-")
      expect(lx.TOKEN_DELIMITER, "(")
      let x2 = parse_expression()
      expect(lx.TOKEN_DELIMITER, ",")
      let y2 = parse_expression()
      expect(lx.TOKEN_DELIMITER, ")")
      let color = nil
      if check(lx.TOKEN_DELIMITER, ","):
        advance()
        color = parse_expression()
      let box = nil
      if check(lx.TOKEN_KEYWORD, "B"):
        advance()
        box = "B"
      return ast.LineStmt(x1, y1, x2, y2, color, box)
    # Step method: Line - (x2, y2)
    let tok = advance()
    if check(lx.TOKEN_OPERATOR, "-"):
      advance()
      expect(lx.TOKEN_DELIMITER, "(")
      let x2 = parse_expression()
      expect(lx.TOKEN_DELIMITER, ",")
      let y2 = parse_expression()
      expect(lx.TOKEN_DELIMITER, ")")
      return ast.LineStmt(nil, nil, x2, y2, nil, nil)

  proc parse_circle():
    expect(lx.TOKEN_KEYWORD, "Circle")
    expect(lx.TOKEN_DELIMITER, "(")
    let x = parse_expression()
    expect(lx.TOKEN_DELIMITER, ",")
    let y = parse_expression()
    expect(lx.TOKEN_DELIMITER, ")")
    expect(lx.TOKEN_DELIMITER, ",")
    let radius = parse_expression()
    let color = nil
    if check(lx.TOKEN_DELIMITER, ","):
      advance()
      color = parse_expression()
    return ast.CircleStmt(x, y, radius, color)

  proc parse_pset():
    expect(lx.TOKEN_KEYWORD, "PSet")
    expect(lx.TOKEN_DELIMITER, "(")
    let x = parse_expression()
    expect(lx.TOKEN_DELIMITER, ",")
    let y = parse_expression()
    expect(lx.TOKEN_DELIMITER, ")")
    let color = nil
    if check(lx.TOKEN_DELIMITER, ","):
      advance()
      color = parse_expression()
    return ast.PSetStmt(x, y, color)

  proc parse_cls():
    expect(lx.TOKEN_KEYWORD, "Cls")
    return ast.ClsStmt()

  # --- DefType ---

  proc parse_deftype():
    let type_name = advance()["value"]
    let ranges = []
    while not check(lx.TOKEN_NEWLINE) and not check(lx.TOKEN_EOF):
      let start_letter = expect(lx.TOKEN_IDENTIFIER)["value"]
      let end_letter = start_letter
      if check(lx.TOKEN_OPERATOR, "-"):
        advance()
        end_letter = expect(lx.TOKEN_IDENTIFIER)["value"]
      push(ranges, {"start": start_letter, "end": end_letter})
      if check(lx.TOKEN_DELIMITER, ","):
        advance()
    return ast.DefTypeStmt(type_name, ranges)

  # --- Load / Unload ---

  proc parse_load():
    expect(lx.TOKEN_KEYWORD, "Load")
    let form_name = expect(lx.TOKEN_IDENTIFIER)["value"]
    return ast.LoadStmt(form_name)

  proc parse_unload():
    expect(lx.TOKEN_KEYWORD, "Unload")
    let form_name = expect(lx.TOKEN_IDENTIFIER)["value"]
    return ast.UnloadStmt(form_name)

  # --- Stop ---

  proc parse_stop():
    expect(lx.TOKEN_KEYWORD, "Stop")
    return ast.StopStmt()

  proc parse_set_stmt():
    expect(lx.TOKEN_KEYWORD, "Set")
    let target = parse_expression()
    expect(lx.TOKEN_OPERATOR, "=")
    let value = parse_expression()
    return ast.SetStatement(target, value)

  proc parse_call_stmt():
    expect(lx.TOKEN_KEYWORD, "Call")
    let name = expect(lx.TOKEN_IDENTIFIER)["value"]
    let args = []
    if check(lx.TOKEN_DELIMITER, "("):
      args = parse_args()
    return ast.CallStatement(name, args)

  proc parse_identifier_stmt():
    let tok = advance()
    let name = tok["value"]
    if check(lx.TOKEN_DELIMITER, "("):
      let args = parse_args()
      return ast.FunctionCall(name, args)
    if check(lx.TOKEN_OPERATOR, "="):
      advance()
      let value = parse_expression()
      return ast.Assignment(ast.Identifier(name), value)
    # Implicit call with arguments (VB4: MsgBox "Hello")
    # Parse comma-separated expressions until newline
    let args = []
    while not check(lx.TOKEN_NEWLINE) and not check(lx.TOKEN_EOF) and not check(lx.TOKEN_COMMENT):
      if check(lx.TOKEN_DELIMITER, ","):
        advance()
      push(args, parse_expression())
      if not check(lx.TOKEN_NEWLINE) and not check(lx.TOKEN_EOF) and not check(lx.TOKEN_COMMENT):
        if not check(lx.TOKEN_DELIMITER, ","):
          break
    return ast.CallStatement(name, args)

  # --- Top-level declarations ---

  proc parse_sub():
    expect(lx.TOKEN_KEYWORD, "Sub")
    let name = expect(lx.TOKEN_IDENTIFIER)["value"]
    let params = []
    if check(lx.TOKEN_DELIMITER, "("):
      params = parse_params()
    skip_newlines()
    let body = parse_block(["End", "End Sub"])
    if check(lx.TOKEN_KEYWORD, "End"):
      advance()
      if check(lx.TOKEN_KEYWORD, "Sub"):
        advance()
    skip_newlines()
    return ast.SubDecl(name, params, body)

  proc parse_function():
    expect(lx.TOKEN_KEYWORD, "Function")
    let name = expect(lx.TOKEN_IDENTIFIER)["value"]
    let params = []
    if check(lx.TOKEN_DELIMITER, "("):
      params = parse_params()
    let as_type = nil
    if check(lx.TOKEN_KEYWORD, "As"):
      advance()
      as_type = expect(lx.TOKEN_IDENTIFIER)["value"]
    skip_newlines()
    let body = parse_block(["End", "End Function"])
    if check(lx.TOKEN_KEYWORD, "End"):
      advance()
      if check(lx.TOKEN_KEYWORD, "Function"):
        advance()
    skip_newlines()
    return ast.FunctionDecl(name, params, as_type, body)

  proc parse_property():
    expect(lx.TOKEN_KEYWORD, "Property")
    let kind = expect(lx.TOKEN_KEYWORD)["value"]
    let name = expect(lx.TOKEN_IDENTIFIER)["value"]
    let params = []
    if check(lx.TOKEN_DELIMITER, "("):
      params = parse_params()
    let as_type = nil
    if check(lx.TOKEN_KEYWORD, "As"):
      advance()
      as_type = expect(lx.TOKEN_IDENTIFIER)["value"]
    skip_newlines()
    let body = parse_block(["End", "End Property"])
    if check(lx.TOKEN_KEYWORD, "End"):
      advance()
      if check(lx.TOKEN_KEYWORD, "Property"):
        advance()
    skip_newlines()
    if kind == "Get":
      return ast.PropertyGet(name, params, as_type, body)
    if kind == "Let":
      return ast.PropertyLet(name, params, body)
    return ast.PropertySet(name, params, body)

  proc parse_type():
    expect(lx.TOKEN_KEYWORD, "Type")
    let name = expect(lx.TOKEN_IDENTIFIER)["value"]
    let fields = []
    skip_newlines()
    while not check(lx.TOKEN_KEYWORD, "End") and not check(lx.TOKEN_EOF):
      let field_name = expect(lx.TOKEN_IDENTIFIER)["value"]
      let as_type = nil
      if check(lx.TOKEN_KEYWORD, "As"):
        advance()
        as_type = expect(lx.TOKEN_IDENTIFIER)["value"]
      push(fields, ast.VariableDecl(field_name, as_type))
      skip_newlines()
    if check(lx.TOKEN_KEYWORD, "End"):
      advance()
      if check(lx.TOKEN_KEYWORD, "Type"):
        advance()
    skip_newlines()
    return ast.TypeDecl(name, fields)

  proc parse_enum():
    expect(lx.TOKEN_KEYWORD, "Enum")
    let name = expect(lx.TOKEN_IDENTIFIER)["value"]
    let members = []
    skip_newlines()
    while not check(lx.TOKEN_KEYWORD, "End") and not check(lx.TOKEN_EOF):
      let member_name = expect(lx.TOKEN_IDENTIFIER)["value"]
      let member_value = nil
      if check(lx.TOKEN_OPERATOR, "="):
        advance()
        member_value = parse_expression()
      push(members, {"name": member_name, "value": member_value})
      skip_newlines()
    if check(lx.TOKEN_KEYWORD, "End"):
      advance()
      if check(lx.TOKEN_KEYWORD, "Enum"):
        advance()
    skip_newlines()
    return ast.EnumDecl(name, members)

  # --- Main parse entry point ---

  skip_newlines()
  let module = ast.Module()
  while not check(lx.TOKEN_EOF):
    if check(lx.TOKEN_KEYWORD, "Sub"):
      push(module.declarations, parse_sub())
    elif check(lx.TOKEN_KEYWORD, "Function"):
      push(module.declarations, parse_function())
    elif check(lx.TOKEN_KEYWORD, "Property"):
      push(module.declarations, parse_property())
    elif check(lx.TOKEN_KEYWORD, "Type"):
      push(module.declarations, parse_type())
    elif check(lx.TOKEN_KEYWORD, "Enum"):
      push(module.declarations, parse_enum())
    elif check(lx.TOKEN_KEYWORD, "Declare"):
      # Skip Declare statements for now
      advance()
      skip_newlines()
    elif check(lx.TOKEN_KEYWORD, "Event"):
      advance()
      let name = expect(lx.TOKEN_IDENTIFIER)["value"]
      let params = []
      if check(lx.TOKEN_DELIMITER, "("):
        params = parse_params()
      push(module.declarations, ast.EventDecl(name, params))
    elif check(lx.TOKEN_KEYWORD, "Option"):
      advance()
      skip_newlines()
    elif check(lx.TOKEN_KEYWORD, "Attribute"):
      advance()
      skip_newlines()
    else:
      break

  return module
