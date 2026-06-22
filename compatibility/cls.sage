# CLS Parser - parses Visual Basic Class Module (.cls) files

## Parse a .cls class module file
proc parse_cls(path):
  let content = io.readfile(path)
  return {
    "name": path,
    "content": content,
    "properties": [],
    "methods": [],
    "events": []
  }
