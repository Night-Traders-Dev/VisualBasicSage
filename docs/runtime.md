# Runtime Engine

The VisualBasicSage runtime interprets VB4 AST and executes programs using SageLang primitives.

## Architecture

### Interpreter (`runtime/interpreter.sage`)

The `Interpreter` class walks the VB4 AST and executes it:

- **Environment**: Maintains variable scope chain with parent-child inheritance
- **Builtins**: Maps VB4 built-in functions (Print, MsgBox, Len, etc.) to Sage implementations
- **Statements**: Executes all VB4 statement types (If, For, While, Do, Select, etc.)
- **Expressions**: Evaluates binary/unary operators with VB4 semantics

### Built-in Functions (`runtime/builtins.sage`)

30+ VB4 built-in functions mapped to Sage:

| VB4 Function | Sage Implementation |
|---|---|
| Print | `vb_print` - stdout output |
| MsgBox | `vb_msgbox` - dialog (console fallback) |
| InputBox | `vb_inputbox` - stdin input |
| Len | `vb_len` - string/array length |
| Left, Right, Mid | String slicing |
| UCase, LCase | String case conversion |
| Trim, Replace | String manipulation |
| Int, Fix, Abs, Sgn | Numeric functions |
| Rnd, Randomize | Random number generation |
| CStr, CInt, CLng, etc. | Type conversion |

### Runtime Entry (`runtime/runtime.sage`)

```sage
import runtime.runtime as rt

# Run VB4 source code
rt.run_source("Sub Main\n  Print 42\nEnd Sub")

# Run VB4 file
rt.run_file("program.bas")
```

## Supported Features

### Statements
- Dim (variable declaration)
- Const (constant declaration)  
- Assignment
- If/Then/Else/ElseIf
- Select Case
- For/Next (with Step)
- While/Wend
- Do/Loop (While/Until, pre/post tested)
- With/End With
- Exit (Sub, Function, Do, For)
- GoTo
- On Error GoTo/Resume
- Call

### Expressions
- Arithmetic: `+` `-` `*` `/` `\` `^` `Mod`
- Comparison: `=` `<>` `<` `>` `<=` `>=`
- Logical: `And` `Or` `Not`
- String: `&` (concatenation)
- Function calls with parentheses
- Implicit call syntax (MsgBox "text")

### Variable Types
- Integer/Long (Sage number)
- Single/Double (Sage number)
- String (Sage string)
- Boolean (Sage bool)
- Variant (Sage Value)

## Testing

```bash
sage tests/test_runtime.sage
```
