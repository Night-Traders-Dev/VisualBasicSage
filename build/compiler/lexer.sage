# VB4 Lexer - tokenizes Visual Basic 4.0 source code

let TOKEN_EOF = "EOF"
let TOKEN_IDENTIFIER = "IDENTIFIER"
let TOKEN_INTEGER = "INTEGER"
let TOKEN_FLOAT = "FLOAT"
let TOKEN_STRING = "STRING"
let TOKEN_KEYWORD = "KEYWORD"
let TOKEN_OPERATOR = "OPERATOR"
let TOKEN_DELIMITER = "DELIMITER"
let TOKEN_NEWLINE = "NEWLINE"
let TOKEN_COMMENT = "COMMENT"

let KEYWORDS = [
  "Sub", "End", "Function", "Dim", "As", "Const",
  "If", "Then", "Else", "ElseIf", "EndIf",
  "Select", "Case", "End Select",
  "For", "To", "Step", "Next",
  "Do", "While", "Until", "Loop",
  "Wend",
  "Public", "Private", "Static",
  "Call", "Set", "Let",
  "ByVal", "ByRef", "Optional",
  "Integer", "Long", "Single", "Double",
  "String", "Boolean", "Variant",
  "ReDim", "Preserve",
  "Exit For", "Exit Do", "Exit Function", "Exit Sub",
  "Me", "Nothing", "True", "False", "Null",
  "And", "Or", "Not", "Xor", "Mod",
  "Type", "End Type",
  "Property", "Get", "Let", "Set",
  "Friend", "Global",
  "Option", "Explicit", "Base", "Compare",
  "On", "Error", "GoTo", "Resume", "Resume Next",
  "With", "End With",
  "Event", "RaiseEvent",
  "Implements",
  "New", "Each", "In",
  "Open", "Close", "Put", "Get", "Write", "Print", "Input",
  "Output", "Append", "Binary", "Random",
  "Read", "Shared", "Lock",
  "GoSub", "Return",
  "Line", "Circle", "PSet", "Cls",
  "Load", "Unload",
  "DefInt", "DefLng", "DefStr", "DefCur", "DefBool", "DefDate", "DefDbl", "DefSng",
  "Rem", "Stop",
  "Declare", "Lib", "Alias",
  "ParamArray", "Empty",
  "TypeOf", "AddressOf"
]

## Make a Token object
proc make_token(type_, value, line, col):
  return {"type": type_, "value": value, "line": line, "col": col}

## Check if a string is a VB4 keyword
proc is_keyword(s):
  for kw in KEYWORDS:
    if kw == s:
      return true
  return false

class Lexer:
  proc init(self, source):
    self.source = source
    self.pos = 0
    self.line = 1
    self.col = 1
    self.tokens = []
    self.src_len = len(source)

  proc peek(self, offset):
    if offset == nil:
      offset = 0
    let idx = self.pos + offset
    if idx < self.src_len:
      return self.source[idx]
    return "\0"

  proc advance(self):
    let ch = self.source[self.pos]
    self.pos = self.pos + 1
    if ch == "\n":
      self.line = self.line + 1
      self.col = 1
    else:
      self.col = self.col + 1
    return ch

  proc skip_whitespace(self):
    while self.pos < self.src_len:
      let ch = self.peek()
      if ch == " " or ch == "\t" or ch == "\r":
        self.advance()
      else:
        break

  proc read_string(self, delim):
    let value = ""
    while self.pos < self.src_len:
      let ch = self.advance()
      if ch == delim:
        return value
      if ch == "\n":
        raise "Unterminated string at line " + str(self.line)
      value = value + ch
    raise "Unterminated string at line " + str(self.line)

  proc read_number(self):
    let value = ""
    let is_float = false
    while self.pos < self.src_len:
      let ch = self.peek()
      if ch >= "0" and ch <= "9":
        value = value + self.advance()
      elif ch == "." and not is_float:
        is_float = true
        value = value + self.advance()
      else:
        break
    let type_ = TOKEN_INTEGER
    if is_float:
      type_ = TOKEN_FLOAT
    let start_col = self.col - len(value)
    push(self.tokens, make_token(type_, value, self.line, start_col))

  proc read_identifier(self):
    let value = ""
    while self.pos < self.src_len:
      let ch = self.peek()
      if (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9") or ch == "_":
        value = value + self.advance()
      else:
        break
    let start_col = self.col - len(value)
    let type_ = TOKEN_IDENTIFIER
    if is_keyword(value):
      type_ = TOKEN_KEYWORD
    push(self.tokens, make_token(type_, value, self.line, start_col))

  proc read_operator(self):
    let start_col = self.col
    let ch = self.advance()
    let value = ch
    if ch == "<" and self.peek() == ">":
      value = value + self.advance()
    elif (ch == "=" or ch == "<" or ch == ">" or ch == "!") and self.peek() == "=":
      value = value + self.advance()
    elif (ch == "&" or ch == "@") and (self.peek() == "&" or self.peek() == "@"):
      value = value + self.advance()
    push(self.tokens, make_token(TOKEN_OPERATOR, value, self.line, start_col))

  proc tokenize(self):
    while self.pos < self.src_len:
      self.skip_whitespace()
      if self.pos >= self.src_len:
        break

      let ch = self.peek()
      let start_col = self.col

      if ch == "'":
        self.advance()
        let comment = ""
        while self.pos < self.src_len and self.peek() != "\n":
          comment = comment + self.advance()
        push(self.tokens, make_token(TOKEN_COMMENT, comment, self.line, start_col))

      elif ch == "\"":
        self.advance()
        let value = self.read_string("\"")
        push(self.tokens, make_token(TOKEN_STRING, value, self.line, start_col))

      elif ch >= "0" and ch <= "9":
        self.read_number()

      elif (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or ch == "_":
        self.read_identifier()

      elif ch == "\n":
        self.advance()
        push(self.tokens, make_token(TOKEN_NEWLINE, "\n", self.line - 1, self.col))

      elif ch == "+" or ch == "-" or ch == "*" or ch == "/" or ch == "^" or ch == "\\" or ch == "=" or ch == "<" or ch == ">" or ch == "!" or ch == "&" or ch == "@" or ch == "#":
        self.read_operator()

      elif ch == "(" or ch == ")" or ch == "," or ch == "." or ch == "{" or ch == ":":
        push(self.tokens, make_token(TOKEN_DELIMITER, self.advance(), self.line, start_col))

      else:
        raise "Unexpected character " + ch + " at line " + str(self.line)

    push(self.tokens, make_token(TOKEN_EOF, "", self.line, self.col))
    return self.tokens

## Lexer: tokenizes VB4 source into a token list (backward-compatible wrapper)
proc lex(source):
  let lexer = Lexer(source)
  return lexer.tokenize()
