import gpu

let COLOR_BLACK = [0.0, 0.0, 0.0, 1.0]
let COLOR_WHITE = [1.0, 1.0, 1.0, 1.0]
let COLOR_RED = [1.0, 0.0, 0.0, 1.0]
let COLOR_GREEN = [0.0, 1.0, 0.0, 1.0]
let COLOR_BLUE = [0.0, 0.0, 1.0, 1.0]
let COLOR_YELLOW = [1.0, 1.0, 0.0, 1.0]
let COLOR_GRAY = [0.5, 0.5, 0.5, 1.0]
let COLOR_BUTTON_FACE = [0.83, 0.82, 0.78, 1.0]

class Graphics:
    proc init(self, ctx=nil):
        self.ctx = ctx
        self.fore_color = COLOR_BLACK
        self.back_color = COLOR_WHITE
        self.fill_style = 1
        self.draw_width = 1
        self.font_name = "Arial"
        self.font_size = 8

    proc set_ctx(self, ctx):
        self.ctx = ctx

    proc load_picture(self, path):
        return nil

    proc draw_text(self, text, x, y):
        if self.ctx == nil:
            return
        let t = self.ctx["theme"]
        let c = self.fore_color
        if x + len(text) * 8 > 0 and y + t["font_size"] > 0:
            let cmd = {}
            cmd["type"] = "text"
            cmd["x"] = x
            cmd["y"] = y
            cmd["text"] = text
            cmd["color"] = c
            cmd["font"] = nil
            push(self.ctx["draw_list"], cmd)

    proc draw_line(self, x1, y1, x2, y2):
        if self.ctx == nil:
            return
        let c = self.fore_color
        let dx = x2 - x1
        let dy = y2 - y1
        let len_v = math.sqrt(dx * dx + dy * dy)
        if len_v < 1.0:
            return
        let nx = -dy / len_v * self.draw_width / 2.0
        let ny = dx / len_v * self.draw_width / 2.0
        let cmd = {}
        cmd["type"] = "rect"
        cmd["x"] = x1 + nx
        cmd["y"] = y1 + ny
        cmd["w"] = len_v
        cmd["h"] = self.draw_width
        cmd["color"] = c
        push(self.ctx["draw_list"], cmd)

    proc draw_rect(self, x1, y1, x2, y2):
        if self.ctx == nil:
            return
        let c = self.fore_color
        let w = x2 - x1
        let h = y2 - y1
        if w < 0:
            w = -w; x1 = x2
        if h < 0:
            h = -h; y1 = y2
        self.draw_border(x1, y1, w, h, c, self.draw_width)

    proc draw_border(self, x, y, w, h, color, width_v):
        if self.ctx == nil:
            return
        let cmds = []
        let cmd1 = {}; cmd1["type"] = "rect"; cmd1["x"] = x; cmd1["y"] = y; cmd1["w"] = w; cmd1["h"] = width_v; cmd1["color"] = color; push(cmds, cmd1)
        let cmd2 = {}; cmd2["type"] = "rect"; cmd2["x"] = x; cmd2["y"] = y + h - width_v; cmd2["w"] = w; cmd2["h"] = width_v; cmd2["color"] = color; push(cmds, cmd2)
        let cmd3 = {}; cmd3["type"] = "rect"; cmd3["x"] = x; cmd3["y"] = y; cmd3["w"] = width_v; cmd3["h"] = h; cmd3["color"] = color; push(cmds, cmd3)
        let cmd4 = {}; cmd4["type"] = "rect"; cmd4["x"] = x + w - width_v; cmd4["y"] = y; cmd4["w"] = width_v; cmd4["h"] = h; cmd4["color"] = color; push(cmds, cmd4)
        let ci = 0
        while ci < len(cmds):
            push(self.ctx["draw_list"], cmds[ci])
            ci = ci + 1

    proc fill_rect(self, x1, y1, x2, y2, color_v):
        if self.ctx == nil:
            return
        let c = color_v
        if c == nil:
            c = self.fore_color
        let w = x2 - x1
        let h = y2 - y1
        if w < 0:
            w = -w; x1 = x2
        if h < 0:
            h = -h; y1 = y2
        let cmd = {}
        cmd["type"] = "rect"
        cmd["x"] = x1
        cmd["y"] = y1
        cmd["w"] = w
        cmd["h"] = h
        cmd["color"] = c
        push(self.ctx["draw_list"], cmd)

    proc draw_circle(self, cx, cy, r):
        if self.ctx == nil:
            return
        let diam = r * 2
        let cmd = {}
        cmd["type"] = "rect"
        cmd["x"] = cx - r
        cmd["y"] = cy - r
        cmd["w"] = diam
        cmd["h"] = diam
        cmd["color"] = self.fore_color
        push(self.ctx["draw_list"], cmd)

    proc draw_point(self, x, y, color_v):
        if self.ctx == nil:
            return
        let c = color_v
        if c == nil:
            c = self.fore_color
        let cmd = {}
        cmd["type"] = "rect"
        cmd["x"] = x
        cmd["y"] = y
        cmd["w"] = 1
        cmd["h"] = 1
        cmd["color"] = c
        push(self.ctx["draw_list"], cmd)
