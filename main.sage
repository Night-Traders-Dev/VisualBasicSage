# VisualBasicSage - VB4 IDE and Runtime
# Usage: sage main.sage [run <file> | ide]

import compiler.lexer as lx
import compiler.parser as pr
import runtime.interpreter as ri
import runtime.builtins as b
import ide.shell as sh

import strings
import io
import sys

let VERSION = "0.1.0"

proc show_banner():
  print "VisualBasicSage v" + VERSION + " - VB4 Compatible IDE & Runtime"
  print ""

proc run_file(path):
  let source = io.readfile(path)
  if source == nil:
    print "Error: could not read " + path
    return 1
  let tokens = lx.lex(source)
  let tree = pr.parse(tokens)
  if tree == nil:
    print "Error: parse failed"
    return 1
  let interp = ri.Interpreter()
  interp.execute(tree)
  return 0

proc run_headless_ide():
  print "Starting IDE (headless mode)..."
  let shell = sh.IdeShell()
  shell.new_project()
  shell.show_status("VisualBasicSage v" + VERSION + " ready")
  print ""
  print "Commands: new, open <file>, run, stop, exit"
  print ""
  while true:
    let line = strings.strip(input())
    if line == "exit" or line == "quit":
      break
    elif strings.startswith(line, "open "):
      let path = strings.strip(line[5:])
      shell.open_project(path)
    elif line == "new":
      shell.new_project()
    elif line == "run":
      shell.run_project()
    elif line == "stop":
      shell.stop_project()
    elif line == "":
      # nothing
    else:
      print "Unknown command: " + line

proc launch_gui_ide():
  print "Starting VisualBasicSage GUI IDE..."
  import ide.gui as gui
  gui.launch_gui_ide()

proc main(args):
  show_banner()
  if len(args) == 0:
    print "Usage: sage main.sage [command]"
    print ""
    print "Commands:"
    print "  run <file>     Run a VB4 source file"
    print "  ide            Start the IDE (graphical)"
    print "  headless       Start the IDE (headless/text mode)"
    print "  version        Show version"
    return 0
  let cmd = args[0]
  if cmd == "run":
    if len(args) < 2:
      print "Usage: sage main.sage run <file>"
      return 1
    return run_file(args[1])
  elif cmd == "ide":
    launch_gui_ide()
    return 0
  elif cmd == "headless":
    run_headless_ide()
    return 0
  elif cmd == "version":
    print VERSION
    return 0
  else:
    print "Unknown command: " + cmd
    return 1

# Entry point
let all_args = sys.args()
let script_args = []
if len(all_args) > 2:
  let i = 2
  while i < len(all_args):
    push(script_args, all_args[i])
    i = i + 1
main(script_args)
