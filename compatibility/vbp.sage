# VBP Parser - parses Visual Basic Project (.vbp) files

## Parse a .vbp project file into a project structure
proc parse_vbp(path):
  let content = io.readfile(path)
  let lines = content.split("\n")
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
    let trimmed = strip(line)
    if trimmed == "" or startswith(trimmed, "'"):
      continue

    if startswith(trimmed, "Type="):
      project["type"] = trimmed[5:]
    elif startswith(trimmed, "Name="):
      project["name"] = trimmed[5:]
    elif startswith(trimmed, "Startup="):
      project["startup"] = trimmed[8:]
    elif startswith(trimmed, "Form="):
      # Form=formname.frm
      let parts = trimmed[5:].split(";")
      project["forms"] = push(project["forms"], parts[0])
    elif startswith(trimmed, "Module="):
      let parts = trimmed[7:].split(";")
      project["modules"] = push(project["modules"], parts[0])
    elif startswith(trimmed, "Class="):
      let parts = trimmed[6:].split(";")
      project["classes"] = push(project["classes"], parts[0])
    elif startswith(trimmed, "Reference="):
      project["references"] = push(project["references"], trimmed[10:])
    elif startswith(trimmed, "Title="):
      project["title"] = trimmed[6:]
    elif startswith(trimmed, "ExeName32="):
      project["exe_name"] = trimmed[10:]

  return project

## Write a project structure to .vbp format
proc write_vbp(project, path):
  let lines = []
  lines = push(lines, "Type=" + project["type"])
  lines = push(lines, "Name=" + project["name"])
  if project["startup"] != "":
    lines = push(lines, "Startup=" + project["startup"])
  for f in project["forms"]:
    lines = push(lines, "Form=" + f)
  for m in project["modules"]:
    lines = push(lines, "Module=" + m)
  for c in project["classes"]:
    lines = push(lines, "Class=" + c)
  for r in project["references"]:
    lines = push(lines, "Reference=" + r)
  if project["title"] != "":
    lines = push(lines, "Title=" + project["title"])
  if project["exe_name"] != "":
    lines = push(lines, "ExeName32=" + project["exe_name"])
  io.writefile(path, join(lines, "\n"))
