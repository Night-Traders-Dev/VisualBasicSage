# BAS Parser - parses Visual Basic Module (.bas) files

## Parse a .bas module file
proc parse_bas(path):
  let content = io.readfile(path)
  return {
    "name": path,
    "content": content,
    "declarations": []
  }

## Write a module to .bas format
proc write_bas(module, path):
  io.writefile(path, module["content"])
