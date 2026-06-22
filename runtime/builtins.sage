# VB4 Built-in Functions mapped to Sage runtime

## Print: output to console
proc vb_print(items):
  for item in items:
    print str(item)

## MsgBox: show a message
proc vb_msgbox(prompt, buttons=0, title=""):
  print "[MsgBox] " + str(prompt)
  # TODO: native dialog when windowing system is ready

## InputBox: get user input
proc vb_inputbox(prompt, title="", default_val=""):
  return input()

## Len: string or array length
proc vb_len(v):
  return len(v)

## Asc: character code
proc vb_asc(s):
  if len(s) > 0:
    return ord(s[0])
  return 0

## Chr: code to character
proc vb_chr(n):
  return chr(n)

## Left: left substring
proc vb_left(s, n):
  return s[:n]

## Right: right substring
proc vb_right(s, n):
  return s[len(s) - n:]

## Mid: middle substring
proc vb_mid(s, start, length=nil):
  if length == nil:
    return s[start - 1:]
  return s[start - 1:start - 1 + length]

## UCase: uppercase
proc vb_ucase(s):
  return upper(s)

## LCase: lowercase
proc vb_lcase(s):
  return lower(s)

## Trim: strip whitespace
proc vb_trim(s):
  return strip(s)

## Replace: string replacement
proc vb_replace(s, old, new):
  return replace(s, old, new)

## Int: integer portion
proc vb_int(n):
  return tonumber(str(math.floor(n)))

## Fix: integer portion (towards zero)
proc vb_fix(n):
  if n >= 0:
    return tonumber(str(math.floor(n)))
  return tonumber(str(math.ceil(n)))

## Abs: absolute value
proc vb_abs(n):
  return math.abs(n)

## Sgn: sign
proc vb_sgn(n):
  if n > 0:
    return 1
  if n < 0:
    return -1
  return 0

## Rnd: random number
let _vb_rnd_seed = 0
proc vb_rnd():
  return math.random()

## Randomize: seed random
proc vb_randomize(seed):
  math.random(seed)

## Now: current date/time
proc vb_now():
  return str(clock())

## IsNumeric: check if string is numeric
proc vb_isnumeric(s):
  let n = tonumber(s)
  return n != nil

## CStr: convert to string
proc vb_cstr(v):
  return str(v)

## CInt: convert to integer
proc vb_cint(v):
  return tonumber(str(math.floor(tonumber(str(v)))))

## CLng: convert to long
proc vb_clng(v):
  return tonumber(str(math.floor(tonumber(str(v)))))

## CSng: convert to single
proc vb_csng(v):
  return tonumber(str(v))

## CDbl: convert to double
proc vb_cdbl(v):
  return tonumber(str(v))

## CBool: convert to boolean
proc vb_cbool(v):
  return v != 0

## Hex: to hex string
proc vb_hex(n):
  return str(n)  # TODO: proper hex formatting

## Oct: to octal string
proc vb_oct(n):
  return str(n)  # TODO: proper octal formatting

## Format: format number
proc vb_format(expr, fmt=""):
  return str(expr)

## Array creation
proc vb_array(values):
  return values

## UBound: upper bound of array
proc vb_ubound(arr, dimension=1):
  return len(arr) - 1

## LBound: lower bound of array
proc vb_lbound(arr, dimension=1):
  return 0
