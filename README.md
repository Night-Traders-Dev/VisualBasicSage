# VisualBasicSage

A clean-room Visual Basic 4.0 inspired IDE and runtime written entirely in Sage.

## Goals

- Teach programming using classic VB4 workflows
- Follow textbook examples directly
- Provide drag-and-drop GUI development
- Generate and execute Sage-native applications
- Preserve the VB4 learning experience while modernizing the implementation

## Project Structure

```
VisualBasicSage/
├── compiler/       # VB4 → Sage compiler pipeline (lexer, parser, AST, IR)
├── runtime/        # Sage runtime (forms, controls, event loop, timers, I/O)
├── ide/            # IDE shell (menus, toolbars, code editor, project explorer)
├── designer/       # Form designer (visual drag-and-drop surface)
├── compatibility/  # VB4 file format parsers (.vbp, .frm, .bas, .cls)
├── samples/        # Example VB4-style programs
├── tests/          # Unit and integration tests
└── docs/           # Documentation and reference
```

## Development Phases

| Phase | Focus |
|-------|-------|
| 0     | Repository setup |
| 1     | Lexer and parser |
| 2     | Runtime engine |
| 3     | Windowing system |
| 4     | Form designer |
| 5     | IDE integration |
| 6     | Book compatibility testing |
| 7     | Debugger |
| 8     | Advanced compatibility |

## Controls (V1)

Form, Label, CommandButton, TextBox, CheckBox, OptionButton, Frame, ListBox, ComboBox, PictureBox, Timer

## Language Features

Sub, Function, Dim, Const, If/Then/Else, Select Case, For/Next, Do/Loop, While/Wend, Arrays, Variant, Integer, Long, Single, Double, String, Boolean

## License

MIT
