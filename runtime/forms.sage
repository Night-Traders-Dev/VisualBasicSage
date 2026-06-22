# Forms runtime - form creation, lifecycle, and rendering

class Form:
  proc init(self, name, caption=""):
    self.name = name
    self.caption = caption
    self.controls = []
    self.width = 480
    self.height = 360
    self.left = 100
    self.top = 100
    self.visible = false
    self.events = {}

  proc add_control(self, control):
    push(self.controls, control)

  proc show(self):
    self.visible = true
    # TODO: render window via graphics backend

  proc hide(self):
    self.visible = false

  proc on_event(self, event_name, handler):
    self.events[event_name] = handler

  proc dispatch(self, event_name, args=[]):
    let handler = self.events[event_name]
    if handler != nil:
      handler(self, args)
