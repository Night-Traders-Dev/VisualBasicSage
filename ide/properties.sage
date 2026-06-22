# Property Window - displays and edits selected object properties

class PropertyWindow:
  proc init(self):
    self.selected_object = nil
    self.properties = []
    self.categorized = true
    self.search_text = ""

  proc select_object(self, obj):
    self.selected_object = obj

  proc get_properties(self):
    if self.selected_object == nil:
      return []
    let props = []
    for key in dict_keys(self.selected_object):
      let val = self.selected_object[key]
      push(props, {"name": key, "value": val, "type": type(val)})
    return props

  proc set_property(self, name, value):
    if self.selected_object != nil:
      self.selected_object[name] = value
