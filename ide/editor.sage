# Code Editor - syntax highlighting text editor for VB4 code

class CodeEditor:
  proc init(self):
    self.lines = [""]
    self.cursor_line = 0
    self.cursor_col = 0
    self.selection_start = nil
    self.selection_end = nil
    self.modified = false
    self.file_path = ""

  proc load_file(self, path):
    self.lines = io.readfile(path).split("\n")
    self.file_path = path
    self.modified = false

  proc save_file(self, path=nil):
    if path == nil:
      path = self.file_path
    let content = join(self.lines, "\n")
    io.writefile(path, content)
    self.modified = false

  proc get_line(self, line_num):
    if line_num >= 0 and line_num < len(self.lines):
      return self.lines[line_num]
    return ""

  proc set_line(self, line_num, text):
    self.lines[line_num] = text
    self.modified = true

  proc insert_text(self, text):
    let line = self.lines[self.cursor_line]
    let before = line[:self.cursor_col]
    let after = line[self.cursor_col:]
    self.lines[self.cursor_line] = before + text + after
    self.cursor_col = self.cursor_col + len(text)
    self.modified = true

  proc delete_char(self):
    let line = self.lines[self.cursor_line]
    if self.cursor_col < len(line):
      self.lines[self.cursor_line] = line[:self.cursor_col] + line[self.cursor_col + 1:]
      self.modified = true

  proc new_line(self):
    let line = self.lines[self.cursor_line]
    let before = line[:self.cursor_col]
    let after = line[self.cursor_col:]
    self.lines[self.cursor_line] = before
    # Insert new line after current
    let new_lines = []
    for i in range(len(self.lines)):
      new_lines = push(new_lines, self.lines[i])
      if i == self.cursor_line:
        new_lines = push(new_lines, after)
    self.lines = new_lines
    self.cursor_line = self.cursor_line + 1
    self.cursor_col = 0
    self.modified = true
