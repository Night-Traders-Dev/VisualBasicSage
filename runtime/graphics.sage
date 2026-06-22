# Graphics runtime - drawing primitives and rendering

## RGB color helper
proc rgb(r, g, b):
  return r * 65536 + g * 256 + b

let COLOR_BLACK = rgb(0, 0, 0)
let COLOR_WHITE = rgb(255, 255, 255)
let COLOR_RED = rgb(255, 0, 0)
let COLOR_GREEN = rgb(0, 255, 0)
let COLOR_BLUE = rgb(0, 0, 255)
let COLOR_YELLOW = rgb(255, 255, 0)
let COLOR_GRAY = rgb(128, 128, 128)
let COLOR_BUTTON_FACE = rgb(212, 208, 200)

class Graphics:
  proc init(self):
    self.fore_color = COLOR_BLACK
    self.back_color = COLOR_WHITE
    self.fill_style = 1  # 0=Solid, 1=Transparent
    self.draw_width = 1
    self.font_name = "Arial"
    self.font_size = 8

  ## Load a bitmap (placeholder)
  proc load_picture(self, path):
    return nil

  ## Draw text
  proc draw_text(self, text, x, y):
    print text  # TODO: render to surface

  ## Draw a line
  proc draw_line(self, x1, y1, x2, y2):
    pass  # TODO: implement line drawing

  ## Draw a rectangle
  proc draw_rect(self, x1, y1, x2, y2):
    pass

  ## Fill a rectangle
  proc fill_rect(self, x1, y1, x2, y2, color):
    pass

  ## Draw a circle
  proc draw_circle(self, cx, cy, r):
    pass

  ## Draw a point
  proc draw_point(self, x, y, color):
    pass
