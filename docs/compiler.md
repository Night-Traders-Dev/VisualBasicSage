# Compiler Pipeline

The VisualBasicSage compiler transforms VB4 source code into executable Sage programs through a multi-phase pipeline.

## Phases

### 1. Lexer (`compiler/lexer.sage`)

The lexer tokenizes VB4 source code into a flat token stream. It handles:

- **Identifiers**: Variable, function, and control names
- **Keywords**: All VB4 reserved words (Sub, Function, If, For, etc.)
- **Literals**: Integer, float, and string literals
- **Operators**: Arithmetic, comparison, and logical operators (including `<>`, `<=`, `>=`)
- **Delimiters**: Parentheses, commas, dots, braces
- **Comments**: Single-line comments starting with `'`
- **Newlines**: Significant as statement terminators

### 2. Parser (`compiler/parser.sage`)

The recursive descent parser converts the token stream into an AST. It supports:

- **Declarations**: Sub, Function, Property (Get/Let/Set), Type, Enum, Event
- **Statements**: Dim, Const, If/Then/Else, Select Case, For/Next, Do/Loop, While/Wend
- **Expressions**: Binary ops (12 precedence levels), unary ops, function calls, member access
- **VB4-specific patterns**: Implicit call syntax (`MsgBox "text"`), Set statements, GoTo

### 3. AST (`compiler/ast.sage`)

35+ AST node types representing the full VB4 language grammar:

- **Declarations**: Module, SubDecl, FunctionDecl, PropertyGet/Let/Set, TypeDecl, EnumDecl
- **Statements**: Assignment, IfStatement, SelectCase, ForLoop, DoLoop, WhileLoop, WithBlock
- **Expressions**: BinaryOp, UnaryOp, Literal, Identifier, MemberAccess, FunctionCall

## Running

```bash
sage -c '
import compiler.lexer as lx
import compiler.parser as pr
let tokens = lx.lex("Sub Main\nMsgBox \"Hello\"\nEnd Sub")
let ast = pr.parse(tokens)
print ast.type
'
```

## Tests

```bash
sage tests/test_lexer.sage
sage tests/test_parser.sage
```
