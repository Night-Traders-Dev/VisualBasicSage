# VBP Parser - parses Visual Basic Project (.vbp) files

import strings

## Parse a .vbp project file into a project structure
proc parse_vbp(path):
  let content = io.readfile(path)
  let lines = strings.split(content, "\n")
  let project = {
    "type": "Standard EXE",
    "name": "",
    "startup": "",
    "help_file": "",
    "title": "",
    "exe_name": "",
    "icon_form": "",
    "forms": [],
    "modules": [],
    "classes": [],
    "references": []
  }

  for line in lines:
    let trimmed = strings.strip(line)
    if trimmed == "" or strings.startswith(trimmed, "'"):
      continue

    if strings.startswith(trimmed, "Type="):
      project["type"] = trimmed[5:]
    elif strings.startswith(trimmed, "Name="):
      project["name"] = trimmed[5:]
    elif strings.startswith(trimmed, "Startup="):
      project["startup"] = trimmed[8:]
    elif strings.startswith(trimmed, "Form="):
      let parts = strings.split(trimmed[5:], ";")
      push(project["forms"], parts[0])
    elif strings.startswith(trimmed, "Module="):
      let parts = strings.split(trimmed[7:], ";")
      push(project["modules"], parts[0])
    elif strings.startswith(trimmed, "Class="):
      let parts = strings.split(trimmed[6:], ";")
      push(project["classes"], parts[0])
    elif strings.startswith(trimmed, "Reference="):
      push(project["references"], trimmed[10:])
    elif strings.startswith(trimmed, "Title="):
      project["title"] = trimmed[6:]
    elif strings.startswith(trimmed, "ExeName32="):
      project["exe_name"] = trimmed[10:]

  return project

## Write a project structure to .vbp format
proc write_vbp(project, path):
  let lines = []
  push(lines, "Type=" + project["type"])
  push(lines, "Name=" + project["name"])
  if project["startup"] != "":
    push(lines, "Startup=" + project["startup"])
  for f in project["forms"]:
    push(lines, "Form=" + f)
  for m in project["modules"]:
    push(lines, "Module=" + m)
  for c in project["classes"]:
    push(lines, "Class=" + c)
  for r in project["references"]:
    push(lines, "Reference=" + r)
  if project["title"] != "":
    push(lines, "Title=" + project["title"])
  if project["exe_name"] != "":
    push(lines, "ExeName32=" + project["exe_name"])
  io.writefile(path, strings.join(lines, "\n"))
