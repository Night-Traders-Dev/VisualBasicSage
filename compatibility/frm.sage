# FRM Parser - parses Visual Basic Form (.frm) files

## Parse a .frm form file into a form structure
proc parse_frm(path):
  let content = io.readfile(path)
  let lines = content.split("\n")
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
    let trimmed = strip(line)
    if startswith(trimmed, "VERSION"):
      continue
    if startswith(trimmed, "Begin "):
      # Begin Form FormName or Begin ControlType ControlName
      let parts = trimmed[6:].split(" ")
      if len(parts) >= 2:
        let ctrl_type = parts[0]
        let ctrl_name = parts[1]
        if ctrl_type == "Form" or ctrl_type == "VB.Form":
          in_control = false
        else:
          current_control = {"type": ctrl_type, "name": ctrl_name, "properties": {}}
          in_control = true
    elif startswith(trimmed, "End") and in_control:
      if current_control != nil:
        form["controls"] = push(form["controls"], current_control)
      current_control = nil
      in_control = false
    elif startswith(trimmed, "Attribute"):
      in_code = true
    elif startswith(trimmed, "End") and not in_control:
      in_code = true
    elif in_control and current_control != nil:
      let eq_pos = indexof(trimmed, "=")
      if eq_pos >= 0:
        let prop_name = strip(trimmed[:eq_pos])
        let prop_value = strip(trimmed[eq_pos + 1:])
        current_control["properties"][prop_name] = prop_value
    elif not in_control and not in_code:
      let eq_pos = indexof(trimmed, "=")
      if eq_pos >= 0:
        let prop_name = strip(trimmed[:eq_pos])
        let prop_value = strip(trimmed[eq_pos + 1:])
        form["properties"][prop_name] = prop_value
        if prop_name == "Name":
          form["name"] = prop_value
        elif prop_name == "Caption":
          form["caption"] = prop_value

  form["name"] = strip(form["properties"]["Name"])

  return form

## Write a form structure to .frm format
proc write_frm(form, path):
  let lines = []
  lines = push(lines, "VERSION 4.00")
  lines = push(lines, "Begin VB.Form " + form["name"])
  lines = push(lines, "   Caption = \"" + form["caption"] + "\"")
  lines = push(lines, "   ClientHeight = " + str(form["height"]))
  lines = push(lines, "   ClientWidth = " + str(form["width"]))
  lines = push(lines, "   Left = " + str(form["left"]))
  lines = push(lines, "   Top = " + str(form["top"]))
  for ctrl in form["controls"]:
    lines = push(lines, "   Begin " + ctrl["type"] + " " + ctrl["name"])
    for key in dict_keys(ctrl["properties"]):
      let val = ctrl["properties"][key]
      lines = push(lines, "      " + key + " = " + str(val))
    lines = push(lines, "   End")
  lines = push(lines, "End")
  lines = push(lines, "")
  lines = push(lines, "Sub Form_Load()")
  lines = push(lines, "End Sub")
  io.writefile(path, join(lines, "\n"))
