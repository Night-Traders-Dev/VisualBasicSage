# Event dispatcher - routes events between controls and event handlers

let EVENT_CLICK = "Click"
let EVENT_DBLCLICK = "DblClick"
let EVENT_KEYPRESS = "KeyPress"
let EVENT_KEYDOWN = "KeyDown"
let EVENT_KEYUP = "KeyUp"
let EVENT_MOUSEDOWN = "MouseDown"
let EVENT_MOUSEUP = "MouseUp"
let EVENT_MOUSEMOVE = "MouseMove"
let EVENT_LOAD = "Load"
let EVENT_UNLOAD = "Unload"
let EVENT_CHANGE = "Change"
let EVENT_GOTFOCUS = "GotFocus"
let EVENT_LOSTFOCUS = "LostFocus"
let EVENT_TIMER = "Timer"

class EventDispatcher:
  proc init(self):
    self.handlers = {}

  proc register(self, control_name, event_name, handler):
    let key = control_name + "." + event_name
    self.handlers[key] = handler

  proc dispatch(self, control_name, event_name, sender, args=[]):
    let key = control_name + "." + event_name
    let handler = self.handlers[key]
    if handler != nil:
      handler(sender, args)

let GLOBAL_DISPATCHER = EventDispatcher()
