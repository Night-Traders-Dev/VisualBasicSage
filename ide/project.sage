# Project Explorer - manages project files and references

class ProjectExplorer:
  proc init(self):
    self.root = nil
    self.selected = nil
    self.expanded = {}

  proc load_project(self, project):
    self.root = project

  proc get_selected_item(self):
    return self.selected

  proc set_selected(self, item):
    self.selected = item

class Project:
  proc init(self, path=""):
    self.path = path
    self.name = ""
    self.forms = []
    self.modules = []
    self.classes = []
    self.references = []
    self.startup_object = ""
    self.title = ""
    self.icon = nil

  proc add_form(self, form_path):
    self.forms = push(self.forms, form_path)

  proc add_module(self, module_path):
    self.modules = push(self.modules, module_path)

  proc add_class(self, class_path):
    self.classes = push(self.classes, class_path)

  proc add_reference(self, ref):
    self.references = push(self.references, ref)
