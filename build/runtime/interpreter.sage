# VB4 AST Interpreter - walks the AST and executes VB4 programs

import io
import strings
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
      "Print": [b.vb_print, -1],  # -1 = pass whole args array
      "MsgBox": [b.vb_msgbox, 3],
      "InputBox": [b.vb_inputbox, 3],
      "Len": [b.vb_len, 1],
      "Asc": [b.vb_asc, 1],
      "Chr": [b.vb_chr, 1],
      "Left": [b.vb_left, 2],
      "Right": [b.vb_right, 2],
      "Mid": [b.vb_mid, 3],
      "UCase": [b.vb_ucase, 1],
      "LCase": [b.vb_lcase, 1],
      "Trim": [b.vb_trim, 1],
      "Replace": [b.vb_replace, 3],
      "Int": [b.vb_int, 1],
      "Fix": [b.vb_fix, 1],
      "Abs": [b.vb_abs, 1],
      "Sgn": [b.vb_sgn, 1],
      "Rnd": [b.vb_rnd, 0],
      "Randomize": [b.vb_randomize, 1],
      "Now": [b.vb_now, 0],
      "IsNumeric": [b.vb_isnumeric, 1],
      "CStr": [b.vb_cstr, 1],
      "CInt": [b.vb_cint, 1],
      "CLng": [b.vb_clng, 1],
      "CSng": [b.vb_csng, 1],
      "CDbl": [b.vb_cdbl, 1],
      "CBool": [b.vb_cbool, 1],
      "Hex": [b.vb_hex, 1],
      "Oct": [b.vb_oct, 1],
      "Format": [b.vb_format, 2],
      "Array": [b.vb_array, 1],
      "UBound": [b.vb_ubound, 2],
      "LBound": [b.vb_lbound, 2],
      # File I/O
      "EOF": [b.vb_eof, 1],
      "LOF": [b.vb_lof, 1],
      "Loc": [b.vb_loc, 1],
      "FreeFile": [b.vb_freefile, 0],
      "FileLen": [b.vb_filelen, 1],
      "Dir": [b.vb_dir, 1],
      "CurDir": [b.vb_curdir, 0],
      "ChDir": [b.vb_chdir, 1],
      "MkDir": [b.vb_mkdir, 1],
      "RmDir": [b.vb_rmdir, 1],
      "Kill": [b.vb_kill, 1],
      "FileCopy": [b.vb_filecopy, 2],
      # Date/Time
      "Date": [b.vb_date, 0],
      "Time": [b.vb_time, 0],
      "Timer": [b.vb_timer, 0],
      "DateSerial": [b.vb_dateserial, 3],
      "DateValue": [b.vb_datevalue, 1],
      "TimeSerial": [b.vb_timeserial, 3],
      "TimeValue": [b.vb_timevalue, 1],
      "Weekday": [b.vb_weekday, 1],
      "Month": [b.vb_month, 1],
      "Year": [b.vb_year, 1],
      "Day": [b.vb_day, 1],
      "Hour": [b.vb_hour, 1],
      "Minute": [b.vb_minute, 1],
      "Second": [b.vb_second, 1],
      "MonthName": [b.vb_monthname, 1],
      "WeekdayName": [b.vb_weekdayname, 1],
      # String
      "InStr": [b.vb_instr, 3],
      "InStrRev": [b.vb_instrrev, 3],
      "StrReverse": [b.vb_strreverse, 1],
      "LTrim": [b.vb_ltrim, 1],
      "RTrim": [b.vb_rtrim, 1],
      "Space": [b.vb_space, 1],
      "String": [b.vb_string, 2],
      "Split": [b.vb_split, 2],
      "Join": [b.vb_join, 2],
      "Filter": [b.vb_filter, 3],
      "StrComp": [b.vb_strcomp, 3],
      # Math
      "Exp": [b.vb_exp, 1],
      "Log": [b.vb_log, 1],
      "Sqr": [b.vb_sqr, 1],
      "Round": [b.vb_round, 2],
      # Conversion
      "Val": [b.vb_val, 1],
      "Str": [b.vb_str, 1],
      "FormatCurrency": [b.vb_formatcurrency, 2],
      "FormatNumber": [b.vb_formatnumber, 2],
      "FormatPercent": [b.vb_formatpercent, 2],
      # Type info
      "TypeName": [b.vb_typename, 1],
      "VarType": [b.vb_vartype, 1],
      "IsArray": [b.vb_isarray, 1],
      "IsDate": [b.vb_isdate, 1],
      "IsEmpty": [b.vb_isempty, 1],
      "IsNull": [b.vb_isnull, 1],
      "IsObject": [b.vb_isobject, 1],
      # System
      "DoEvents": [b.vb_doevents, 0],
      "Beep": [b.vb_beep, 0],
      "Environ": [b.vb_environ, 1],
      "Command": [b.vb_command, 0],
      "IMEStatus": [b.vb_imestatus, 0],
      "Calendar": [b.vb_calendar, 0],
      "GetSetting": [b.vb_getsetting, 4],
      "GetAllSettings": [b.vb_getallsettings, 2],
      "SaveSetting": [b.vb_savesetting, 4],
      "DeleteSetting": [b.vb_deletesetting, 3],
      # Financial
      "FV": [b.vb_fv, 5],
      "PV": [b.vb_pv, 5],
      "NPV": [b.vb_npv, 2],
      "PMT": [b.vb_pmt, 5],
      "PPMT": [b.vb_ppmt, 6],
      "IPMT": [b.vb_ipmt, 6],
      "Rate": [b.vb_rate, 6],
      "NPer": [b.vb_nper, 5],
      "SLN": [b.vb_sln, 3],
      "SYD": [b.vb_syd, 4],
      "DDB": [b.vb_ddb, 5],
      # Other
      "RGB": [b.vb_rgb, 3],
      "QBColor": [b.vb_qbcolor, 1],
      "Choose": [b.vb_choose, -1],
      "IIf": [b.vb_iif, 3],
      "Switch": [b.vb_switch, -1]
    }
    self.current_return = nil
    self.current_exit = nil
    self.error_handler = nil
    self.error_raised = false
    self.error_number = 0
    self.error_description = ""
    self.err_object = nil
    self.open_files = {}
    self.gosub_stack = []
    self.with_object = nil
    self.def_types = {}
    self.labels = {}
    self.current_procedure_labels = {}
    self.error_resume_next = false

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
      return self.exec_goto(node)
    if type_ == "OnError":
      return self.exec_on_error(node)
    if type_ == "Resume":
      return self.exec_resume(node)
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
      self.exec_redim(node)
      return nil
    if type_ == "EraseStatement":
      for n in node.names:
        self.global_env.set(n, nil)
      return nil
    if type_ == "OpenStmt":
      return self.exec_open(node)
    if type_ == "CloseStmt":
      return self.exec_close(node)
    if type_ == "PutStmt":
      return self.exec_put(node)
    if type_ == "GetStmt":
      return self.exec_get(node)
    if type_ == "WriteStmt":
      return self.exec_write(node)
    if type_ == "PrintStmt":
      return self.exec_print(node)
    if type_ == "InputStmt":
      return self.exec_input(node)
    if type_ == "GoSubStmt":
      return self.exec_gosub(node)
    if type_ == "ReturnStmt":
      return self.exec_return(node)
    if type_ == "DefTypeStmt":
      return self.exec_deftype(node)
    if type_ == "LoadStmt":
      return nil
    if type_ == "UnloadStmt":
      return nil
    if type_ == "StopStmt":
      return nil
    if type_ == "LabelDef":
      return nil
    if type_ == "LineInputStmt":
      return self.exec_line_input(node)
    if type_ == "LineStmt":
      return nil
    if type_ == "CircleStmt":
      return nil
    if type_ == "PSetStmt":
      return nil
    if type_ == "ClsStmt":
      return nil
    return nil

  proc exec_block(self, node):
    let local_env = Environment(self.global_env)
    for stmt in node.statements:
      if self.jump_to_label != nil and self.jump_to_label != "":
        if self.get_type(stmt) == "LabelDef" and stmt.name == self.jump_to_label:
          self.jump_to_label = nil
        continue
      if self.current_exit != nil:
        break
      if self.get_type(stmt) == "LabelDef":
        continue
      self.exec_statement(stmt)
    return nil

  proc exec_assignment(self, node):
    let val = self.eval_expression(node.value)
    let target = node.target
    if self.get_type(target) == "MemberAccess":
      # TODO: set property on object
      return nil
    elif self.get_type(target) == "Identifier":
      self.global_env.set(target.name, val)
    return val

  proc dispatch_builtin(self, name, args):
    if name == "Print":
      return b.vb_print(args)
    elif name == "MsgBox":
      return b.vb_msgbox(args[0], args[1], args[2])
    elif name == "InputBox":
      return b.vb_inputbox(args[0], args[1], args[2])
    elif name == "Len":
      return b.vb_len(args[0])
    elif name == "Asc":
      return b.vb_asc(args[0])
    elif name == "Chr":
      return b.vb_chr(args[0])
    elif name == "Left":
      return b.vb_left(args[0], args[1])
    elif name == "Right":
      return b.vb_right(args[0], args[1])
    elif name == "Mid":
      return b.vb_mid(args[0], args[1], args[2])
    elif name == "UCase":
      return b.vb_ucase(args[0])
    elif name == "LCase":
      return b.vb_lcase(args[0])
    elif name == "Trim":
      return b.vb_trim(args[0])
    elif name == "Replace":
      return b.vb_replace(args[0], args[1], args[2])
    elif name == "Int":
      return b.vb_int(args[0])
    elif name == "Fix":
      return b.vb_fix(args[0])
    elif name == "Abs":
      return b.vb_abs(args[0])
    elif name == "Sgn":
      return b.vb_sgn(args[0])
    elif name == "Rnd":
      return b.vb_rnd()
    elif name == "Randomize":
      return b.vb_randomize(args[0])
    elif name == "Now":
      return b.vb_now()
    elif name == "IsNumeric":
      return b.vb_isnumeric(args[0])
    elif name == "CStr":
      return b.vb_cstr(args[0])
    elif name == "CInt":
      return b.vb_cint(args[0])
    elif name == "CLng":
      return b.vb_clng(args[0])
    elif name == "CSng":
      return b.vb_csng(args[0])
    elif name == "CDbl":
      return b.vb_cdbl(args[0])
    elif name == "CBool":
      return b.vb_cbool(args[0])
    elif name == "Hex":
      return b.vb_hex(args[0])
    elif name == "Oct":
      return b.vb_oct(args[0])
    elif name == "Format":
      return b.vb_format(args[0], args[1])
    elif name == "Array":
      return b.vb_array(args[0])
    elif name == "UBound":
      return b.vb_ubound(args[0], args[1])
    elif name == "LBound":
      return b.vb_lbound(args[0], args[1])
    elif name == "EOF":
      return b.vb_eof(args[0])
    elif name == "LOF":
      return b.vb_lof(args[0])
    elif name == "Loc":
      return b.vb_loc(args[0])
    elif name == "FreeFile":
      return b.vb_freefile()
    elif name == "FileLen":
      return b.vb_filelen(args[0])
    elif name == "Dir":
      return b.vb_dir(args[0])
    elif name == "CurDir":
      return b.vb_curdir()
    elif name == "ChDir":
      return b.vb_chdir(args[0])
    elif name == "MkDir":
      return b.vb_mkdir(args[0])
    elif name == "RmDir":
      return b.vb_rmdir(args[0])
    elif name == "Kill":
      return b.vb_kill(args[0])
    elif name == "FileCopy":
      return b.vb_filecopy(args[0], args[1])
    elif name == "Date":
      return b.vb_date()
    elif name == "Time":
      return b.vb_time()
    elif name == "Timer":
      return b.vb_timer()
    elif name == "DateSerial":
      return b.vb_dateserial(args[0], args[1], args[2])
    elif name == "DateValue":
      return b.vb_datevalue(args[0])
    elif name == "TimeSerial":
      return b.vb_timeserial(args[0], args[1], args[2])
    elif name == "TimeValue":
      return b.vb_timevalue(args[0])
    elif name == "Weekday":
      return b.vb_weekday(args[0])
    elif name == "Month":
      return b.vb_month(args[0])
    elif name == "Year":
      return b.vb_year(args[0])
    elif name == "Day":
      return b.vb_day(args[0])
    elif name == "Hour":
      return b.vb_hour(args[0])
    elif name == "Minute":
      return b.vb_minute(args[0])
    elif name == "Second":
      return b.vb_second(args[0])
    elif name == "MonthName":
      return b.vb_monthname(args[0])
    elif name == "WeekdayName":
      return b.vb_weekdayname(args[0])
    elif name == "InStr":
      return b.vb_instr(args[0], args[1], args[2])
    elif name == "InStrRev":
      return b.vb_instrrev(args[0], args[1], args[2])
    elif name == "StrReverse":
      return b.vb_strreverse(args[0])
    elif name == "LTrim":
      return b.vb_ltrim(args[0])
    elif name == "RTrim":
      return b.vb_rtrim(args[0])
    elif name == "Space":
      return b.vb_space(args[0])
    elif name == "String":
      return b.vb_string(args[0], args[1])
    elif name == "Split":
      return b.vb_split(args[0], args[1])
    elif name == "Join":
      return b.vb_join(args[0], args[1])
    elif name == "Filter":
      return b.vb_filter(args[0], args[1], args[2])
    elif name == "StrComp":
      return b.vb_strcomp(args[0], args[1], args[2])
    elif name == "Exp":
      return b.vb_exp(args[0])
    elif name == "Log":
      return b.vb_log(args[0])
    elif name == "Sqr":
      return b.vb_sqr(args[0])
    elif name == "Round":
      return b.vb_round(args[0], args[1])
    elif name == "Val":
      return b.vb_val(args[0])
    elif name == "Str":
      return b.vb_str(args[0])
    elif name == "FormatCurrency":
      return b.vb_formatcurrency(args[0], args[1])
    elif name == "FormatNumber":
      return b.vb_formatnumber(args[0], args[1])
    elif name == "FormatPercent":
      return b.vb_formatpercent(args[0], args[1])
    elif name == "TypeName":
      return b.vb_typename(args[0])
    elif name == "VarType":
      return b.vb_vartype(args[0])
    elif name == "IsArray":
      return b.vb_isarray(args[0])
    elif name == "IsDate":
      return b.vb_isdate(args[0])
    elif name == "IsEmpty":
      return b.vb_isempty(args[0])
    elif name == "IsNull":
      return b.vb_isnull(args[0])
    elif name == "IsObject":
      return b.vb_isobject(args[0])
    elif name == "DoEvents":
      return b.vb_doevents()
    elif name == "Beep":
      return b.vb_beep()
    elif name == "Environ":
      return b.vb_environ(args[0])
    elif name == "Command":
      return b.vb_command()
    elif name == "IMEStatus":
      return b.vb_imestatus()
    elif name == "Calendar":
      return b.vb_calendar()
    elif name == "GetSetting":
      return b.vb_getsetting(args[0], args[1], args[2], args[3])
    elif name == "GetAllSettings":
      return b.vb_getallsettings(args[0], args[1])
    elif name == "SaveSetting":
      return b.vb_savesetting(args[0], args[1], args[2], args[3])
    elif name == "DeleteSetting":
      return b.vb_deletesetting(args[0], args[1], args[2])
    elif name == "FV":
      return b.vb_fv(args[0], args[1], args[2], args[3], args[4])
    elif name == "PV":
      return b.vb_pv(args[0], args[1], args[2], args[3], args[4])
    elif name == "NPV":
      return b.vb_npv(args[0], args[1])
    elif name == "PMT":
      return b.vb_pmt(args[0], args[1], args[2], args[3], args[4])
    elif name == "PPMT":
      return b.vb_ppmt(args[0], args[1], args[2], args[3], args[4], args[5])
    elif name == "IPMT":
      return b.vb_ipmt(args[0], args[1], args[2], args[3], args[4], args[5])
    elif name == "Rate":
      return b.vb_rate(args[0], args[1], args[2], args[3], args[4], args[5])
    elif name == "NPer":
      return b.vb_nper(args[0], args[1], args[2], args[3], args[4])
    elif name == "SLN":
      return b.vb_sln(args[0], args[1], args[2])
    elif name == "SYD":
      return b.vb_syd(args[0], args[1], args[2], args[3])
    elif name == "DDB":
      return b.vb_ddb(args[0], args[1], args[2], args[3], args[4])
    elif name == "RGB":
      return b.vb_rgb(args[0], args[1], args[2])
    elif name == "QBColor":
      return b.vb_qbcolor(args[0])
    elif name == "Choose":
      return b.vb_choose(args)
    elif name == "IIf":
      return b.vb_iif(args[0], args[1], args[2])
    elif name == "Switch":
      return b.vb_switch(args)

  proc exec_call(self, node):
    let name = node.name
    let args = []
    for arg in node.args:
      push(args, self.eval_expression(arg))
    # Check builtins
    if dict_has(self.builtins, name):
      self.dispatch_builtin(name, args)
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
    # Bind parameters (with optional defaults)
    for i in range(len(params)):
      if i < len(args):
        local_env.set(params[i].name, args[i])
      else:
        let default_val = nil
        if params[i].default_value != nil:
          default_val = self.eval_expression(params[i].default_value)
        local_env.set(params[i].name, default_val)
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
        let default_val = nil
        if params[i].default_value != nil:
          default_val = self.eval_expression(params[i].default_value)
        local_env.set(params[i].name, default_val)
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
      if len(c.values) == 0:
        # Catch-all (Case Else)
        return self.exec_statement(c.body)
      for val_node in c.values:
        if self.get_type(val_node) == "RangeClause":
          let low = tonumber(str(self.eval_expression(val_node.low)))
          let high = tonumber(str(self.eval_expression(val_node.high)))
          let val = tonumber(str(expr))
          if val >= low and val <= high:
            return self.exec_statement(c.body)
        else:
          let case_val = self.eval_expression(val_node)
          if expr == case_val:
            return self.exec_statement(c.body)
    return nil

  # --- File I/O ---

  proc exec_open(self, node):
    let filepath = str(self.eval_expression(node.filepath))
    let filenum = str(tonumber(str(node.filenum)))
    let mode = node.mode
    if mode == "Output":
      io.writefile(filepath, "")
      self.open_files[filenum] = {"path": filepath, "mode": "Output", "content": ""}
    elif mode == "Append":
      let existing = io.readfile(filepath)
      if existing == nil:
        existing = ""
      self.open_files[filenum] = {"path": filepath, "mode": "Append", "content": existing}
    elif mode == "Binary":
      let content = io.readfile(filepath)
      if content == nil:
        content = ""
      self.open_files[filenum] = {"path": filepath, "mode": "Binary", "content": content, "pos": 0}
    else:
      let content = io.readfile(filepath)
      if content == nil:
        content = ""
      self.open_files[filenum] = {"path": filepath, "mode": "Input", "content": content, "pos": 0}
    return nil

  proc exec_close(self, node):
    if len(node.filenums) == 0:
      for fn in dict_keys(self.open_files):
        let f = self.open_files[fn]
        if type(f) == "dict" and dict_has(f, "content"):
          io.writefile(f["path"], f["content"])
        self.open_files[fn] = nil
      self.open_files = {}
    else:
      for fn in node.filenums:
        let fnum = str(tonumber(str(fn)))
        if dict_has(self.open_files, fnum):
          let f = self.open_files[fnum]
          if type(f) == "dict" and dict_has(f, "content"):
            io.writefile(f["path"], f["content"])
          self.open_files[fnum] = nil
    return nil

  proc exec_put(self, node):
    let filenum = str(tonumber(str(node.filenum)))
    let val = self.eval_expression(node.variable)
    if not dict_has(self.open_files, filenum):
      return nil
    let f = self.open_files[filenum]
    f["content"] = f["content"] + str(val)
    return nil

  proc exec_get(self, node):
    let filenum = str(tonumber(str(node.filenum)))
    if not dict_has(self.open_files, filenum):
      return nil
    let f = self.open_files[filenum]
    let result = f["content"]
    if node.variable != nil:
      let target = node.variable
      if self.get_type(target) == "Identifier":
        self.global_env.set(target.name, result)
    return result

  proc exec_write(self, node):
    let filenum = str(tonumber(str(node.filenum)))
    if not dict_has(self.open_files, filenum):
      return nil
    let f = self.open_files[filenum]
    let parts = []
    for e in node.exprs:
      push(parts, str(self.eval_expression(e)))
    let line_str = strings.join(parts, ",") + "\n"
    f["content"] = f["content"] + line_str
    return nil

  proc exec_print(self, node):
    let filenum = str(tonumber(str(node.filenum)))
    if not dict_has(self.open_files, filenum):
      return nil
    let f = self.open_files[filenum]
    let parts = []
    for e in node.exprs:
      push(parts, str(self.eval_expression(e)))
    let line_str = strings.join(parts, " ") + "\n"
    f["content"] = f["content"] + line_str
    return nil

  proc exec_input(self, node):
    let filenum = str(tonumber(str(node.filenum)))
    if not dict_has(self.open_files, filenum):
      return nil
    let f = self.open_files[filenum]
    let content = f["content"]
    if not dict_has(f, "pos"):
      f["pos"] = 0
    let pos = f["pos"]
    for var_name in node.variables:
      let comma_idx = strings.indexof(content, ",")
      let newline_idx = strings.indexof(content, "\n")
      let end_idx = -1
      if comma_idx >= 0 and comma_idx >= pos:
        end_idx = comma_idx
      if newline_idx >= 0 and newline_idx >= pos and (end_idx < 0 or newline_idx < end_idx):
        end_idx = newline_idx
      if end_idx < 0 or end_idx < pos:
        end_idx = len(content)
      let val_str = strings.strip(content[pos:end_idx])
      self.global_env.set(var_name, val_str)
      pos = end_idx + 1
    f["pos"] = pos
    return nil

  proc exec_line_input(self, node):
    let filenum = str(tonumber(str(node.filenum)))
    if not dict_has(self.open_files, filenum):
      return nil
    let f = self.open_files[filenum]
    let content = f["content"]
    if not dict_has(f, "pos"):
      f["pos"] = 0
    let pos = f["pos"]
    let remaining = content[pos:]
    let newline_idx = strings.indexof(remaining, "\n")
    let end_idx = len(content)
    if newline_idx >= 0:
      end_idx = pos + newline_idx
    let line = content[pos:end_idx]
    self.global_env.set(node.variable, line)
    f["pos"] = end_idx + 1
    return nil

  # --- GoSub / Return ---

  proc exec_gosub(self, node):
    push(self.gosub_stack, {"return_pos": nil})
    return nil

  proc exec_return(self, node):
    if len(self.gosub_stack) > 0:
      pop(self.gosub_stack)
    return nil

  # --- DefType ---

  proc exec_deftype(self, node):
    for r in node.letter_ranges:
      self.def_types[r["start"]] = node.type_name
      if r["end"] != r["start"]:
        self.def_types[r["end"]] = node.type_name
    return nil

  # --- Error Handling / GoTo ---

  proc exec_goto(self, node):
    self.jump_to_label = node.label
    return nil

  proc exec_on_error(self, node):
    self.error_handler = node
    self.error_raised = false
    self.error_number = 0
    self.error_description = ""
    return nil

  proc exec_resume(self, node):
    let target = node.target
    if target == "next":
      self.error_raised = false
      self.error_handler = nil
      self.error_resume_next = true
    elif target == "current" or target == nil:
      self.error_raised = false
      self.error_handler = nil
    else:
      self.error_raised = false
      self.error_handler = nil
      self.jump_to_label = target
    return nil

  proc raise_error(self, err_num, desc):
    self.error_number = err_num
    self.error_description = desc
    self.error_raised = true
    if self.error_handler != nil:
      let mode = self.error_handler.action
      if mode == "resume":
        self.error_resume_next = true
      elif mode == "goto":
        self.jump_to_label = self.error_handler.target
      return true
    return false

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
        if self.jump_to_label != nil:
          break
        if self.current_exit != nil:
          self.current_exit = nil
          break
        self.exec_statement(node.body)
        let cur = self.global_env.get(var_name)
        self.global_env.set(var_name, cur + step)
    else:
      while self.global_env.get(var_name) >= end:
        if self.jump_to_label != nil:
          break
        if self.current_exit != nil:
          self.current_exit = nil
          break
        self.exec_statement(node.body)
        let cur = self.global_env.get(var_name)
        self.global_env.set(var_name, cur + step)

  proc exec_foreach(self, node):
    let collection = self.eval_expression(node.collection)
    for item in collection:
      if self.jump_to_label != nil:
        break
      if self.current_exit != nil:
        self.current_exit = nil
        break
      self.global_env.set(node.variable, item)
      self.exec_statement(node.body)

  proc exec_redim(self, node):
    let dims = []
    for d in node.dimensions:
      push(dims, tonumber(str(self.eval_expression(d))))
    let size = 1
    for d in dims:
      size = size * d
    let arr = []
    for i in range(size):
      push(arr, nil)
    self.global_env.set(node.name, arr)
    return nil

  proc exec_do(self, node):
    if node.loop_type == "while":
      while true:
        if self.jump_to_label != nil:
          break
        if self.current_exit != nil:
          self.current_exit = nil
          break
        let cond = self.eval_expression(node.condition)
        if not self.is_truthy(cond):
          break
        self.exec_statement(node.body)
    elif node.loop_type == "until":
      while true:
        if self.jump_to_label != nil:
          break
        if self.current_exit != nil:
          self.current_exit = nil
          break
        let cond = self.eval_expression(node.condition)
        if self.is_truthy(cond):
          break
        self.exec_statement(node.body)

  proc exec_while(self, node):
    while true:
      if self.jump_to_label != nil:
        break
      if self.current_exit != nil:
        self.current_exit = nil
        break
      let cond = self.eval_expression(node.condition)
      if not self.is_truthy(cond):
        break
      self.exec_statement(node.body)

  proc exec_with(self, node):
    let saved = self.with_object
    self.with_object = self.eval_expression(node.object)
    self.exec_statement(node.body)
    self.with_object = saved

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
      return self.dispatch_builtin(name, args)
    let func_def = self.global_env.get_func(name)
    if func_def != nil:
      return self.exec_func_body(name, func_def["params"], func_def["body"], args)
    raise "Undefined function: " + name

  proc eval_member_access(self, node):
    let obj = self.eval_expression(node.object)
    if obj != nil:
      if type(obj) == "instance":
        return obj[node.member]
      return obj[node.member]
    if self.with_object != nil:
      if type(self.with_object) == "instance":
        return self.with_object[node.member]
      return self.with_object[node.member]
    return nil

  # --- Helpers ---

  proc is_truthy(self, val):
    if val == nil or val == false or val == 0:
      return false
    return true
