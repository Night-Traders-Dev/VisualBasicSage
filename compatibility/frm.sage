# FRM Parser - parses Visual Basic Form (.frm) files

import strings

## Parse a .frm form file into a form structure
proc parse_frm(path):
  let content = io.readfile(path)
  let lines = strings.split(content, "\n")
  let form = {
    "name": "",
    "caption": "",
    "width": 480,
    "height": 360,
    "left": 100,
    "top": 100,
    "controls": [],
    "code": [],
    "properties": {}
  }

  let in_code = false
  let in_control = false
  let current_control = nil

  for line in lines:
    let trimmed = strings.strip(line)
    if trimmed == "":
      continue
    if strings.startswith(trimmed, "VERSION"):
      continue
    if strings.startswith(trimmed, "Begin "):
      let parts = strings.split(trimmed[6:], " ")
      if len(parts) >= 2:
        let ctrl_type = parts[0]
        let ctrl_name = parts[1]
        if ctrl_type == "Form" or ctrl_type == "VB.Form":
          form["name"] = ctrl_name
          in_control = false
        else:
          current_control = {"type": ctrl_type, "name": ctrl_name, "properties": {}}
          in_control = true
    elif strings.startswith(trimmed, "End") and in_control:
      if current_control != nil:
        push(form["controls"], current_control)
      current_control = nil
      in_control = false
    elif strings.startswith(trimmed, "Attribute"):
      in_code = true
    elif strings.startswith(trimmed, "End") and not in_control:
      in_code = true
    elif in_control and current_control != nil:
      let eq_pos = strings.indexof(trimmed, "=")
      if eq_pos >= 0:
        let prop_name = strings.strip(trimmed[:eq_pos])
        let prop_value = strings.strip(trimmed[eq_pos + 1:])
        if strings.startswith(prop_value, "\"") and strings.endswith(prop_value, "\""):
          prop_value = prop_value[1:len(prop_value) - 1]
        current_control["properties"][prop_name] = prop_value
    elif not in_control and not in_code:
      let eq_pos = strings.indexof(trimmed, "=")
      if eq_pos >= 0:
        let prop_name = strings.strip(trimmed[:eq_pos])
        let prop_value = strings.strip(trimmed[eq_pos + 1:])
        if strings.startswith(prop_value, "\"") and strings.endswith(prop_value, "\""):
          prop_value = prop_value[1:len(prop_value) - 1]
        form["properties"][prop_name] = prop_value
        if prop_name == "Name":
          form["name"] = prop_value
        elif prop_name == "Caption":
          form["caption"] = prop_value

  form["name"] = strings.strip(form["properties"]["Name"])

  return form

## Write a form structure to .frm format
proc write_frm(form, path):
  let lines = []
  push(lines, "VERSION 4.00")
  push(lines, "Begin VB.Form " + form["name"])
  push(lines, "   Caption = \"" + form["caption"] + "\"")
  push(lines, "   ClientHeight = " + str(form["height"]))
  push(lines, "   ClientWidth = " + str(form["width"]))
  push(lines, "   Left = " + str(form["left"]))
  push(lines, "   Top = " + str(form["top"]))
  for ctrl in form["controls"]:
    push(lines, "   Begin " + ctrl["type"] + " " + ctrl["name"])
    for key in dict_keys(ctrl["properties"]):
      let val = ctrl["properties"][key]
      push(lines, "      " + key + " = " + str(val))
    push(lines, "   End")
  push(lines, "End")
  push(lines, "")
  push(lines, "Sub Form_Load()")
  push(lines, "End Sub")
  io.writefile(path, strings.join(lines, "\n"))
