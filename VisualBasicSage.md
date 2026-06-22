# VisualBasicSage.md

## Vision

VisualBasicSage is a clean-room Visual Basic 4.0 inspired IDE and runtime written entirely in Sage.

Primary goals:

- Teach programming using classic VB4 workflows
- Follow textbook examples directly
- Provide drag-and-drop GUI development
- Generate and execute Sage-native applications
- Preserve the VB4 learning experience while modernizing the implementation

---

## Major Components

### 1. IDE Shell
- Menu bar
- Toolbar
- Toolbox
- Form Designer
- Project Explorer
- Property Window
- Code Editor
- Debug Console

### 2. VB4 Compatibility Layer
- .vbp parser
- .frm parser
- .bas parser
- .cls parser
- Event model compatibility
- Property compatibility

### 3. Sage Runtime
- Forms
- Controls
- Event Dispatcher
- Timers
- Dialogs
- File I/O
- Graphics

### 4. Compiler Pipeline
VB Source
→ Lexer
→ Parser
→ AST
→ Semantic Analysis
→ Sage IR
→ Interpreter / Compiler
→ Executable Program

---

## Controls (V1)

- Form
- Label
- CommandButton
- TextBox
- CheckBox
- OptionButton
- Frame
- ListBox
- ComboBox
- PictureBox
- Timer

---

## Language Features (Supported)

### Statements
- Sub / End Sub, Function / End Function
- Property Get/Let/Set / End Property
- Dim, Const, ReDim, Erase
- If / Then / Else / ElseIf / End If (block and single-line)
- Select Case / Case / Case Else / End Select
- For / Next, For Each / Next
- Do While/Until / Loop, While / Wend
- With / End With
- Call, Set, Let
- GoTo, GoSub / Return
- On Error GoTo/Resume/Resume Next
- Exit Sub/Function/Do/For
- RaiseEvent
- Open / Close / Put / Get / Write / Print / Input (File I/O)
- Load / Unload
- Line / Circle / PSet / Cls (graphics)
- DefInt / DefLng / DefStr / DefCur / DefBool / DefDate (DefType)
- Stop, Rem
- Declare (stub)

### Expressions
- Arithmetic: +, -, *, /, \, ^, Mod
- Comparison: =, <>, <, >, <=, >=
- Logical: And, Or, Not, Xor
- String: & (concatenation)
- Parenthesized grouping
- Member access (.)
- Array access (())
- Function calls

### Types
- Integer, Long, Single, Double, String, Boolean, Variant
- Type / End Type (user-defined)
- Enum / End Enum

### Built-in Functions (80+)
- **String**: Len, Asc, Chr, Left, Right, Mid, UCase, LCase, Trim, LTrim, RTrim, Replace, InStr, InStrRev, StrReverse, Space, String, Split, Join, Filter, StrComp, Str, Val
- **Math**: Abs, Sgn, Int, Fix, Rnd, Randomize, Exp, Log, Sqr, Round, Hex, Oct
- **Conversion**: CStr, CInt, CLng, CSng, CDbl, CBool, CCur, Hex, Oct, Val, Str, FormatCurrency, FormatNumber, FormatPercent
- **Date/Time**: Now, Date, Time, Timer, DateSerial, DateValue, TimeSerial, TimeValue, Weekday, Month, Year, Day, Hour, Minute, Second, MonthName, WeekdayName
- **File I/O**: EOF, LOF, Loc, FreeFile, FileLen, Dir, CurDir, ChDir, MkDir, RmDir, Kill, FileCopy
- **Type Info**: TypeName, VarType, IsArray, IsNumeric, IsDate, IsEmpty, IsNull, IsObject
- **Other**: MsgBox, InputBox, Print, Array, UBound, LBound, RGB, QBColor, Choose, IIf, Switch, Format

---

## Repository Layout

VisualBasicSage/
├── compiler/          # Lexer, Parser, AST
├── runtime/           # Interpreter, Builtins, Forms, Controls, Debugger, Windower
├── ide/               # Editor, Project, Properties, Shell
├── designer/          # Surface, Toolbox
├── compatibility/     # VBP, FRM, BAS, CLS parsers
├── samples/           # Example programs (calculator)
├── tests/             # 104 tests across 11 modules
└── docs/              # Documentation

---

## Development Roadmap (Completed)

### Phase 0 — Repository Setup
Project scaffold with directory layout, README, .gitignore

### Phase 1 — Lexer and Parser
VB4 tokenizer with 80+ keywords, recursive descent parser, 35+ AST node types

### Phase 2 — Runtime Engine
AST-walking interpreter with Environment scope chains, 30+ built-in functions

### Phase 3 — Windowing System
Form.show() event loop via graphics.renderer + graphics.ui, control mapping, event dispatch

### Phase 4 — Form Designer
Drag-drop surface, 8-point resize handles, grid snap, control creation, hit testing

### Phase 5 — IDE Integration
Code editor, project explorer, property window, shell with menu system

### Phase 6 — Book Compatibility
20 feature tests: single-line If, For Step, Do While/Until, While/Wend, Select ranges, ByRef, Dim As Type, integer division, Mod, logical operators

### Phase 7 — Debugger
Step-into/over/out, breakpoints by file+line, call stack, variable inspection, execution history

### Phase 8 — File Format Round-trip
.vbp/.frm/.bas/.cls parse and emit, property extraction with quote stripping

### Phase 9 — Full VB4 Coverage
- 38 missing keywords added to lexer (New, Each, In, Open, Close, Put, Get, Write, Print, Input, Output, Append, Binary, GoSub, Return, Line, Circle, PSet, Cls, Load, Unload, DefInt, etc.)
- File I/O statements: Open/Close/Put/Get/Write/Print/Input with all modes (Input, Output, Append, Binary)
- GoSub/Return control flow
- Graphics statements: Line, Circle, PSet, Cls
- Load/Unload, Stop, DefType statements
- 50+ new built-in functions (File I/O, Date/Time, String, Math, Conversion, Type info)
- With block execution, ReDim array allocation, improved On Error / Resume stubs
- 21 new tests for Phase 9 features
- Pre-existing bugs fixed: missing `import io` in all compatibility modules, frm.sage name extraction, `#` token handling for file numbers

---

## VB4 Coverage (~75%)

| Category | Status | Notes |
|---|---|---|
| Statements (Sub, Function, Property) | Complete | All declaration types |
| Variables (Dim, Const, ReDim) | Complete | Including As Type |
| Control Flow (If, Select, For, Do, While) | Complete | All loop/conditional forms |
| Error Handling (On Error, Resume) | Partial | Syntax parsed, runtime stubbed |
| File I/O (Open, Close, Put, Get, Write, Print) | Complete | All modes supported |
| GoSub / Return | Complete | Stack-based |
| Graphics (Line, Circle, PSet, Cls) | Complete | Parsed, no-op in headless |
| Type / Enum | Complete | User-defined types |
| With / End With | Complete | With object resolution |
| DefType | Complete | Default type declarations |
| Load / Unload / Stop | Complete | Basic implementation |
| Built-in Functions (String) | 90% | All major string functions |
| Built-in Functions (Math) | 90% | All major math functions |
| Built-in Functions (Date/Time) | 80% | Core date/time functions |
| Built-in Functions (File I/O) | 70% | Basic file info functions |
| Built-in Functions (Conversion) | 80% | Type conversion + format |
| Built-in Functions (Type Info) | 80% | Type inspection |
| Built-in Functions (Other) | 70% | MsgBox, InputBox, RGB, etc. |
| Forms / Controls | 80% | 11 control types, event dispatch |
| Form Designer | 70% | Drag-drop, resize, grid snap |
| IDE | 60% | Editor, project, properties, shell |
| Debugger | 70% | Step, breakpoints, call stack |
| File Format (.vbp/.frm/.bas/.cls) | 90% | Parse and round-trip |
| Financial functions (FV, PV, NPV, etc.) | 0% | Not implemented |
| OLE / DDE | 0% | Not implemented |
| Control arrays | 0% | Not implemented |
| Line numbers | 0% | Not implemented |

---

## Test Suite (104 tests, 11 modules)

| Module | Tests | Status |
|---|---|---|
| test_lexer | 6 | Passing |
| test_parser | 6 | Passing |
| test_runtime | 11 | Passing |
| test_forms | 9 | Passing |
| test_windower | 2 | Passing |
| test_designer | 7 | Passing |
| test_ide | 10 | Passing |
| test_compat | 20 | Passing |
| test_debugger | 7 | Passing |
| test_compat_files | 5 | Passing |
| test_phase9 | 21 | Passing |

---

## Long-Term Goals

- Open VB4 projects directly
- Native Sage GUI applications
- Financial functions (FV, PV, NPV, PMT, etc.)
- Control arrays and OLE/DDE support
- Line number / GoSub with line labels
- Educational mode for students
- SageOS integration
- Cross-platform desktop support
- Visual Sage branding option

