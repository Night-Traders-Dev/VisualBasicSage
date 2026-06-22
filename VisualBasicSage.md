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

## Language Features

- Sub
- Function
- Dim
- Const
- If / Then / Else
- Select Case
- For / Next
- Do / Loop
- While / Wend
- Arrays
- Variant
- Integer
- Long
- Single
- Double
- String
- Boolean

---

## Repository Layout

VisualBasicSage/
├── compiler/
├── runtime/
├── ide/
├── designer/
├── compatibility/
├── samples/
├── tests/
└── docs/

---

## Development Roadmap

### Phase 0
Repository setup

### Phase 1
Lexer and parser

### Phase 2
Runtime engine

### Phase 3
Windowing system

### Phase 4
Form designer

### Phase 5
IDE integration

### Phase 6
Book compatibility testing

### Phase 7
Debugger

### Phase 8
Advanced compatibility

---

## Long-Term Goals

- Open VB4 projects directly
- Native Sage GUI applications
- Educational mode for students
- SageOS integration
- Cross-platform desktop support
- Visual Sage branding option

