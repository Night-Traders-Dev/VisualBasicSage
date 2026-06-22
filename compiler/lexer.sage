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
  "ByVal", "ByRef",
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
  "On", "Error", "GoTo", "Resume",
  "With", "End With",
  "Event", "RaiseEvent",
  "Implements"
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

## Lexer: tokenizes VB4 source into a token list
proc lex(source):
  let tokens = []
  let pos = 0
  let line = 1
  let col = 1
  let src_len = len(source)

  ## Peek at current character
  proc peek(offset=0):
    let idx = pos + offset
    if idx < src_len:
      return source[idx]
    return "\0"

  ## Advance one character, tracking position
  proc advance():
    let ch = source[pos]
    pos = pos + 1
    if ch == "\n":
      line = line + 1
      col = 1
    else:
      col = col + 1
    return ch

  ## Skip whitespace (spaces and tabs)
  proc skip_whitespace():
    while pos < src_len:
      let ch = peek()
      if ch == " " or ch == "\t" or ch == "\r":
        advance()
      else:
        break

  ## Read a string literal
  proc read_string(delim):
    let value = ""
    while pos < src_len:
      let ch = advance()
      if ch == delim:
        return value
      if ch == "\n":
        raise "Unterminated string at line " + str(line)
      value = value + ch
    raise "Unterminated string at line " + str(line)

  ## Read a number literal
  proc read_number():
    let value = ""
    let is_float = false
    while pos < src_len:
      let ch = peek()
      if ch >= "0" and ch <= "9":
        value = value + advance()
      elif ch == "." and not is_float:
        is_float = true
        value = value + advance()
      else:
        break
    let type_ = TOKEN_INTEGER
    if is_float:
      type_ = TOKEN_FLOAT
    let start_col = col - len(value)
    push(tokens, make_token(type_, value, line, start_col))

  ## Read an identifier or keyword
  proc read_identifier():
    let value = ""
    while pos < src_len:
      let ch = peek()
      if (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or (ch >= "0" and ch <= "9") or ch == "_":
        value = value + advance()
      else:
        break
    let start_col = col - len(value)
    let type_ = TOKEN_IDENTIFIER
    if is_keyword(value):
      type_ = TOKEN_KEYWORD
    push(tokens, make_token(type_, value, line, start_col))

  ## Read an operator
  proc read_operator():
    let start_col = col
    let ch = advance()
    let value = ch
    if ch == "<" and peek() == ">":
      value = value + advance()
    elif (ch == "=" or ch == "<" or ch == ">" or ch == "!") and peek() == "=":
      value = value + advance()
    elif (ch == "&" or ch == "@") and (peek() == "&" or peek() == "@"):
      value = value + advance()
    push(tokens, make_token(TOKEN_OPERATOR, value, line, start_col))

  ## Main tokenization loop
  while pos < src_len:
    skip_whitespace()
    if pos >= src_len:
      break

    let ch = peek()
    let start_col = col

    if ch == "'":
      # Comment
      advance()
      let comment = ""
      while pos < src_len and peek() != "\n":
        comment = comment + advance()
      push(tokens, make_token(TOKEN_COMMENT, comment, line, start_col))

    elif ch == "\"":
      # String literal
      advance()
      let value = read_string("\"")
      push(tokens, make_token(TOKEN_STRING, value, line, start_col))

    elif ch >= "0" and ch <= "9":
      read_number()

    elif (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or ch == "_":
      read_identifier()

    elif ch == "\n":
      advance()
      push(tokens, make_token(TOKEN_NEWLINE, "\n", line - 1, col))

    elif ch == "+" or ch == "-" or ch == "*" or ch == "/" or ch == "^" or ch == "\\" or ch == "=" or ch == "<" or ch == ">" or ch == "!" or ch == "&" or ch == "@":
      read_operator()

    elif ch == "(" or ch == ")" or ch == "," or ch == "." or ch == "{" or ch == ":":
      push(tokens, make_token(TOKEN_DELIMITER, advance(), line, start_col))

    else:
      raise "Unexpected character " + ch + " at line " + str(line)

  push(tokens, make_token(TOKEN_EOF, "", line, col))
  return tokens
