# IDE Shell - main IDE window, menus, toolbars

class IdeShell:
  proc init(self):
    self.menus = []
    self.toolbar = nil
    self.project_explorer = nil
    self.property_window = nil
    self.code_editor = nil
    self.form_designer = nil
    self.debug_console = nil
    self.current_project = nil
    self.status_text = "Ready"

  proc create_menu(self, caption):
    let menu = {"caption": caption, "items": []}
    push(self.menus, menu)
    return menu

  proc add_menu_item(self, menu, caption, shortcut="", handler=nil):
    let item = {"caption": caption, "shortcut": shortcut, "handler": handler}
    push(menu["items"], item)

  proc show_status(self, text):
    self.status_text = text
    print "Status: " + text

  proc run_project(self):
    if self.current_project == nil:
      self.show_status("No project loaded")
      return
    self.show_status("Running...")
    # TODO: invoke compiler/runtime pipeline

  proc stop_project(self):
    self.show_status("Stopped")

  proc new_project(self):
    self.show_status("New project created")
    # TODO: create blank project

  proc open_project(self, path):
    self.show_status("Opening: " + path)
    # TODO: load .vbp file
