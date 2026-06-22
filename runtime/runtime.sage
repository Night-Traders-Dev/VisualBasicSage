# Runtime entry point - run VB4 programs from source

import compiler.lexer as lx
import compiler.parser as pr
import runtime.interpreter as ri

## Run a VB4 source string
proc run_source(source):
  let tokens = lx.lex(source)
  let ast = pr.parse(tokens)
  let interp = ri.Interpreter()
  interp.execute(ast)

## Run a VB4 source file
proc run_file(path):
  let content = io.readfile(path)
  run_source(content)
