# VB4 Built-in Functions mapped to Sage runtime

import math
import io
import strings

## Print: output to console
proc vb_print(items):
  for item in items:
    print str(item)

## MsgBox: show a message
proc vb_msgbox(prompt, buttons, title):
  print "[MsgBox] " + str(prompt)
  # TODO: native dialog when windowing system is ready

## InputBox: get user input
proc vb_inputbox(prompt, title, default_val):
  if title == nil or title == "":
    print "Input: " + str(prompt)
  else:
    print "[" + str(title) + "] Input: " + str(prompt)
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

# === File I/O Functions ===

## EOF: end of file
proc vb_eof(filenum):
  return true

## LOF: length of file
proc vb_lof(filenum):
  return 0

## Loc: current position
proc vb_loc(filenum):
  return 0

## FreeFile: next available file number
let _vb_next_file = 1
proc vb_freefile():
  let result = _vb_next_file
  _vb_next_file = _vb_next_file + 1
  return result

## FileLen: file length
proc vb_filelen(path):
  let content = io.readfile(str(path))
  if content == nil:
    return 0
  return len(content)

## Dir: file matching pattern
proc vb_dir(pattern=""):
  return ""

## CurDir: current directory
proc vb_curdir(drive=""):
  return "."

## ChDir: change directory
proc vb_chdir(path):
  return nil

## MkDir: create directory
proc vb_mkdir(path):
  return nil

## RmDir: remove directory
proc vb_rmdir(path):
  return nil

## Kill: delete file
proc vb_kill(path):
  return nil

## FileCopy: copy file
proc vb_filecopy(source, dest):
  return nil

# === Date/Time Functions ===

## Now: current date/time
proc vb_now():
  return str(clock())

## Date: current date
proc vb_date():
  return str(clock())

## Time: current time
proc vb_time():
  return str(clock())

## Timer: seconds since midnight
proc vb_timer():
  return tonumber(str(clock()))

## DateSerial: date from year, month, day
proc vb_dateserial(year, month, day):
  return str(year) + "/" + str(month) + "/" + str(day)

## DateValue: date from string
proc vb_datevalue(datestr):
  return str(datestr)

## TimeSerial: time from hour, minute, second
proc vb_timeserial(hour, minute, second):
  return str(hour) + ":" + str(minute) + ":" + str(second)

## TimeValue: time from string
proc vb_timevalue(timestr):
  return str(timestr)

## Weekday: day of week (1=Sunday)
proc vb_weekday(dateval):
  return 1

## Month: month number
proc vb_month(dateval):
  return 1

## Year: year number
proc vb_year(dateval):
  return 1900

## Day: day of month
proc vb_day(dateval):
  return 1

## Hour: hour of day
proc vb_hour(timeval):
  return 0

## Minute: minute of hour
proc vb_minute(timeval):
  return 0

## Second: second of minute
proc vb_second(timeval):
  return 0

## MonthName: name of month
proc vb_monthname(month):
  let names = ["January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December"]
  if month >= 1 and month <= 12:
    return names[month - 1]
  return ""

## WeekdayName: name of weekday
proc vb_weekdayname(weekday):
  let names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  if weekday >= 1 and weekday <= 7:
    return names[weekday - 1]
  return ""

# === String Functions ===

## InStr: find substring
proc vb_instr(start, s1, s2=nil):
  if s2 == nil:
    s2 = s1
    s1 = start
    start = 1
  let idx = strings.indexof(s1, s2)
  if idx >= 0:
    return idx + 1
  return 0

## InStrRev: reverse find substring
proc vb_instrrev(s1, s2, start=nil):
  return 0

## StrReverse: reverse string
proc vb_strreverse(s):
  let result = ""
  let n = len(s)
  let i = n - 1
  while i >= 0:
    result = result + s[i]
    i = i - 1
  return result

## LTrim: trim leading spaces
proc vb_ltrim(s):
  return strings.lstrip(str(s))

## RTrim: trim trailing spaces
proc vb_rtrim(s):
  return strings.rstrip(str(s))

## Space: string of spaces
proc vb_space(n):
  let result = ""
  let i = 0
  while i < n:
    result = result + " "
    i = i + 1
  return result

## String: repeating character
proc vb_string(n, ch):
  let result = ""
  let c = ch
  if type(ch) == "number":
    c = chr(ch)
  let i = 0
  while i < n:
    result = result + str(c)
    i = i + 1
  return result

## Split: split string into array
proc vb_split(expr, delim=" "):
  return strings.split(expr, delim)

## Join: join array into string
proc vb_join(arr, delim=" "):
  return strings.join(arr, delim)

## Filter: filter array by substring
proc vb_filter(arr, match, include=true):
  let result = []
  for item in arr:
    let s = str(item)
    if strings.contains(s, match):
      if include:
        push(result, item)
    else:
      if not include:
        push(result, item)
  return result

## StrComp: string comparison
proc vb_strcomp(s1, s2, mode=0):
  if s1 == s2:
    return 0
  if s1 < s2:
    return -1
  return 1

# === Math Functions ===

## Exp: e^x
proc vb_exp(n):
  return math.exp(n)

## Log: natural logarithm
proc vb_log(n):
  return math.log(n)

## Sqr: square root
proc vb_sqr(n):
  return math.sqrt(n)

## Round: round number
proc vb_round(n, places=0):
  let factor = math.pow(10, places)
  return math.floor(n * factor + 0.5) / factor

# === Conversion Functions ===

## Val: convert string to number
proc vb_val(s):
  let result = ""
  let i = 0
  let n = len(s)
  while i < n:
    let ch = s[i]
    if (ch >= "0" and ch <= "9") or ch == "." or ch == "-" or ch == "+":
      result = result + ch
      i = i + 1
    else:
      break
  if result == "":
    return 0
  return tonumber(result)

## Str: convert number to string
proc vb_str(n):
  return str(n)

## Hex: to hex string (proper)
proc vb_hex(n):
  let val = tonumber(str(n))
  if val == nil:
    return "0"
  let digits = "0123456789ABCDEF"
  let result = ""
  let v = val
  if v < 0:
    v = -v
  while v > 0:
    let rem = v % 16
    result = digits[rem] + result
    v = v / 16
    v = math.floor(v)
  if val < 0:
    result = "-" + result
  if result == "":
    result = "0"
  return result

## Oct: to octal string (proper)
proc vb_oct(n):
  let val = tonumber(str(n))
  if val == nil:
    return "0"
  let result = ""
  let v = val
  if v < 0:
    v = -v
  while v > 0:
    let rem = v % 8
    result = str(rem) + result
    v = v / 8
    v = math.floor(v)
  if val < 0:
    result = "-" + result
  if result == "":
    result = "0"
  return result

## FormatCurrency: format as currency
proc vb_formatcurrency(expr, places=2):
  return "$" + vb_formatnumber(expr, places)

## FormatNumber: format as number
proc vb_formatnumber(expr, places=2):
  return str(vb_round(expr, places))

## FormatPercent: format as percent
proc vb_formatpercent(expr, places=2):
  return str(vb_round(expr * 100, places)) + "%"

# === Type Information ===

## TypeName: type name of value
proc vb_typename(v):
  return type(v)

## VarType: variable type code
proc vb_vartype(v):
  if v == nil:
    return 0
  if type(v) == "number":
    return 3
  if type(v) == "string":
    return 8
  if type(v) == "bool":
    return 11
  if type(v) == "array" or type(v) == "list":
    return 8192
  return 0

## IsArray: check if value is array
proc vb_isarray(v):
  return type(v) == "array" or type(v) == "list"

## IsDate: check if value is date
proc vb_isdate(v):
  return false

## IsEmpty: check if value is empty
proc vb_isempty(v):
  return v == nil

## IsNull: check if value is null
proc vb_isnull(v):
  return v == nil

## IsNumeric: check if string is numeric
proc vb_isnumeric(v):
  let n = tonumber(str(v))
  return n != nil

## IsObject: check if value is object
proc vb_isobject(v):
  return type(v) == "instance"

# === Other ===

## RGB: build color value
proc vb_rgb(r, g, b):
  return r + g * 256 + b * 65536

## QBColor: QuickBasic color
proc vb_qbcolor(c):
  let colors = [0, 8388608, 32768, 8421376, 128, 8388736, 32896, 12632256,
                8421504, 16711680, 65280, 16776960, 255, 16711935, 65535, 16777215]
  if c >= 0 and c < len(colors):
    return colors[c]
  return 0

## Choose: select from list (receives whole args array: [index, arg1, arg2, ...])
proc vb_choose(args):
  if len(args) < 2:
    return nil
  let index = args[0]
  let i = tonumber(str(index)) - 1
  if i >= 0 and i < len(args) - 1:
    return args[i + 1]
  return nil

## IIf: immediate if
proc vb_iif(expr, truepart, falsepart):
  if expr:
    return truepart
  return falsepart

## Switch: evaluate pairs (receives whole args array: [expr1, val1, expr2, val2, ...])
proc vb_switch(args):
  for i in range(0, len(args) - 1, 2):
    if args[i]:
      return args[i + 1]
  return nil

# === System Functions ===

## DoEvents: yield to OS
proc vb_doevents():
  return 0

## Beep: system beep
proc vb_beep():
  return nil

## Environ: environment variable
let _vb_environ_cache = nil
proc vb_environ(v):
  if _vb_environ_cache == nil:
    _vb_environ_cache = {}
    let raw = io.readfile("/proc/self/environ")
    if raw != nil:
      let entries = strings.split(raw, "\0")
      for entry in entries:
        let eq_pos = strings.indexof(entry, "=")
        if eq_pos >= 0:
          _vb_environ_cache[entry[:eq_pos]] = entry[eq_pos + 1:]
  if type(v) == "number":
    return ""
  let name = str(v)
  if dict_has(_vb_environ_cache, name):
    return _vb_environ_cache[name]
  return ""

## Command: command line arguments
proc vb_command():
  return ""

## IMEStatus: IME status (stub)
proc vb_imestatus():
  return 0

## Calendar: calendar type (stub)
proc vb_calendar():
  return 0

## GetSetting: registry value (stub)
proc vb_getsetting(appname, section, key, default_val=""):
  return default_val

## GetAllSettings: all registry values (stub)
proc vb_getallsettings(appname, section):
  return []

## SaveSetting: save registry value (stub)
proc vb_savesetting(appname, section, key, setting_val):
  return nil

## DeleteSetting: delete registry value (stub)
proc vb_deletesetting(appname, section, key_val=""):
  return nil

# === Financial Functions ===

## FV: Future Value
proc vb_fv(rate, nper, pmt, pv=0, ptype=0):
  if rate == 0:
    return -(pv + pmt * nper)
  let r = rate
  let n = nper
  let fv = -(pv * math.pow(1 + r, n) + pmt * (1 + r * ptype) * ((math.pow(1 + r, n) - 1) / r))
  return fv

## PV: Present Value
proc vb_pv(rate, nper, pmt, fv=0, ptype=0):
  if rate == 0:
    return -(fv + pmt * nper)
  let r = rate
  let n = nper
  let pv = -(fv * math.pow(1 + r, -n) + pmt * (1 + r * ptype) * ((1 - math.pow(1 + r, -n)) / r))
  return pv

## NPV: Net Present Value
proc vb_npv(rate, values):
  let r = rate
  let npv = 0
  for i in range(len(values)):
    npv = npv + values[i] / math.pow(1 + r, i + 1)
  return npv

## PMT: Payment
proc vb_pmt(rate, nper, pv, fv=0, ptype=0):
  if rate == 0:
    return -(pv + fv) / nper
  let r = rate
  let n = nper
  let pmt = -(pv * math.pow(1 + r, n) + fv) / ((1 + r * ptype) * ((math.pow(1 + r, n) - 1) / r))
  return pmt

## PPMT: Principal Payment
proc vb_ppmt(rate, per, nper, pv, fv=0, ptype=0):
  let pmt = vb_pmt(rate, nper, pv, fv, ptype)
  let ipmt = vb_ipmt(rate, per, nper, pv, fv, ptype)
  return pmt - ipmt

## IPMT: Interest Payment
proc vb_ipmt(rate, per, nper, pv, fv=0, ptype=0):
  let r = rate
  let n = nper
  let p = per
  if r == 0:
    return 0
  let fv_factor = 1
  if ptype == 1:
    fv_factor = 1 + r
  let pmt = vb_pmt(r, n, pv, fv, ptype)
  let interest = 0
  if p == 1:
    interest = -pv * r
  else:
    interest = -(pv * math.pow(1 + r, p - 1) + pmt * (1 + r * ptype) * ((math.pow(1 + r, p - 1) - 1) / r)) * r
  return interest

## Rate: Interest Rate per period
proc vb_rate(nper, pmt, pv, fv=0, ptype=0, guess=0.1):
  return guess

## NPer: Number of Periods
proc vb_nper(rate, pmt, pv, fv=0, ptype=0):
  if rate == 0:
    return -(pv + fv) / pmt
  let r = rate
  return math.log((pmt * (1 + r * ptype) / r - fv) / (pmt * (1 + r * ptype) / r + pv)) / math.log(1 + r)

## SLN: Straight-Line Depreciation
proc vb_sln(cost, salvage, life):
  return (cost - salvage) / life

## SYD: Sum-of-Years Digits Depreciation
proc vb_syd(cost, salvage, life, period):
  return ((cost - salvage) * (life - period + 1) * 2) / (life * (life + 1))

## DDB: Double-Declining Balance Depreciation
proc vb_ddb(cost, salvage, life, period, factor=2):
  let book_value = cost
  for p in range(1, period + 1):
    let depr1 = book_value - salvage
    let depr2 = book_value * factor / life
    let depreciation = depr1
    if depr2 < depr1:
      depreciation = depr2
    if p == period:
      return depreciation
    book_value = book_value - depreciation
  return 0
