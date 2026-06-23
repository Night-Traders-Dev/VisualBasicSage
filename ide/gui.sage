import gpu
import graphics.ui as ui
import graphics.renderer as gr
import runtime.forms as forms
import runtime.controls as ctrl
import runtime.events as evt
import designer.surface as ds
import designer.toolbox as tb
import ide.renderer as ider
import runtime.windower as windower

let PANEL_TOOLBOX = 0
let PANEL_PROPERTIES = 1
let PANEL_DESIGNER = 2

let _IDE_GLOBALS_designer_ctx = nil
let _IDE_GLOBALS_form_fx = 0
let _IDE_GLOBALS_form_fy = 0

proc _cb_designer_grid_line(x, y, x2, y2):
    let ctx = _IDE_GLOBALS_designer_ctx
    if ctx != nil:
        ui.ui_draw_rect(ctx, x, y, 1, 1, [0.6, 0.6, 0.6, 0.5])

proc _cb_designer_draw_control(cx, cy, cw, ch, color):
    let ctx = _IDE_GLOBALS_designer_ctx
    if ctx != nil:
        let gfx = _IDE_GLOBALS_form_fx
        let gfy = _IDE_GLOBALS_form_fy
        ui.ui_draw_rect(ctx, gfx + cx, gfy + cy, cw, ch, color)

proc _cb_designer_draw_text(tx, ty, text):
    let ctx = _IDE_GLOBALS_designer_ctx
    if ctx != nil:
        let gfx = _IDE_GLOBALS_form_fx
        let gfy = _IDE_GLOBALS_form_fy
        ui.ui_draw_text(ctx, gfx + tx, gfy + ty, text, [0.0, 0.0, 0.0, 1.0])

class IdeGui:
    proc init(self):
        self.form = nil
        self.ui_ctx = nil
        self.renderer = nil
        self.designer = ds.DesignerSurface()
        self.toolbox = tb.Toolbox()
        self.project_name = "Untitled"
        self.status_text = "Ready"
        self.selected_tool = "Pointer"
        self.menus = []
        self.panel_widths = {}
        self.panel_widths["toolbox"] = 180
        self.panel_widths["props"] = 200
        self.show_grid = true
        self.surface_x = 0
        self.surface_y = 0
        self.surface_w = 0
        self.surface_h = 0
        self._exit_requested = false
        self.init_menus()

    proc init_menus(self):
        let file_menu = {"caption": "File", "items": [
            {"label": "New Project", "action": "new"},
            {"label": "Open Project...", "action": "open"},
            {"label": "Save Project", "action": "save"},
            {"label": "---", "action": ""},
            {"label": "Exit", "action": "exit"}
        ]}
        push(self.menus, file_menu)
        let edit_menu = {"caption": "Edit", "items": [
            {"label": "Undo", "action": "undo"},
            {"label": "Redo", "action": "redo"},
            {"label": "---", "action": ""},
            {"label": "Cut", "action": "cut"},
            {"label": "Copy", "action": "copy"},
            {"label": "Paste", "action": "paste"},
            {"label": "Delete", "action": "delete"}
        ]}
        push(self.menus, edit_menu)
        let view_menu = {"caption": "View", "items": [
            {"label": "Toolbox", "action": "toggle_toolbox"},
            {"label": "Properties", "action": "toggle_properties"},
            {"label": "Grid", "action": "toggle_grid"}
        ]}
        push(self.menus, view_menu)
        let run_menu = {"caption": "Run", "items": [
            {"label": "Run Form", "action": "run"},
            {"label": "Stop", "action": "stop"}
        ]}
        push(self.menus, run_menu)

    proc new_project(self):
        self.form = forms.Form("Form1", "Form1")
        self.form.width = 480
        self.form.height = 360
        self.designer.set_form(self.form)
        self.status_text = "New project created"

    proc menu_bar_height(self):
        return 24

    proc toolbox_width(self):
        let v = self.panel_widths["toolbox"]
        if v == nil:
            return 0
        return v

    proc properties_width(self):
        let v = self.panel_widths["props"]
        if v == nil:
            return 0
        return v

    proc status_bar_height(self):
        return 22

    proc calc_designer_rect(self, win_w, win_h):
        let result = {}
        let mh = self.menu_bar_height()
        let sh = self.status_bar_height()
        let tw = self.toolbox_width()
        let pw = self.properties_width()
        result["x"] = tw
        result["y"] = mh
        result["w"] = win_w - tw - pw
        result["h"] = win_h - mh - sh
        return result

    proc render_menu_bar(self, ctx, win_w, win_h):
        let t = ctx["theme"]
        let mh = self.menu_bar_height()
        ui.ui_draw_rect(ctx, 0, 0, win_w, mh, t["panel"])
        ui.ui_draw_rect(ctx, 0, mh - 1, win_w, 1, t["border"])
        let mx = 4
        let mi = 0
        while mi < len(self.menus):
            let menu = self.menus[mi]
            let mw = len(menu["caption"]) * 9 + 12
            let items = []
            let ii = 0
            while ii < len(menu["items"]):
                push(items, menu["items"][ii]["label"])
                ii = ii + 1
            let result = ui.ui_menu_button(ctx, mx, 0, mw, mh, menu["caption"], items)
            if result >= 0:
                self.handle_action(menu["items"][result]["action"])
            mx = mx + mw + 2
            mi = mi + 1

    proc render_toolbox(self, ctx, win_w, win_h):
        let t = ctx["theme"]
        let mh = self.menu_bar_height()
        let sh = self.status_bar_height()
        let tw = self.toolbox_width()
        ui.ui_draw_rect(ctx, 0, mh, tw, win_h - mh - sh, t["panel"])
        ui.ui_draw_rect(ctx, tw - 1, mh, 1, win_h - mh - sh, t["border"])
        let title_y = mh + 4
        ui.ui_label(ctx, 8, title_y, "Toolbox")
        let item_y = title_y + 20
        let ci = 0
        while ci < len(tb.TOOLBOX_CONTROLS):
            let ctl = tb.TOOLBOX_CONTROLS[ci]
            let name = ctl["name"]
            let item_h = 22
            let hovered = ui.ui_point_in_rect(ctx, 4, item_y, tw - 8, item_h)
            let bg = t["bg"]
            if hovered:
                bg = t["bg_hover"]
            if name == self.selected_tool:
                bg = t["bg_active"]
            ui.ui_draw_rect(ctx, 4, item_y, tw - 8, item_h, bg)
            ui.ui_label(ctx, 10, item_y + 3, name)
            if hovered and ctx["mouse_clicked"]:
                self.selected_tool = name
                self.toolbox.select_tool(name)
            item_y = item_y + item_h
            ci = ci + 1

    proc render_properties(self, ctx, win_w, win_h):
        let t = ctx["theme"]
        let mh = self.menu_bar_height()
        let sh = self.status_bar_height()
        let tw = self.toolbox_width()
        let pw = self.properties_width()
        let px = win_w - pw
        ui.ui_draw_rect(ctx, px, mh, pw, win_h - mh - sh, t["panel"])
        ui.ui_draw_rect(ctx, px, mh, 1, win_h - mh - sh, t["border"])
        let title_y = mh + 4
        ui.ui_label(ctx, px + 8, title_y, "Properties")
        let prop_y = title_y + 20
        let sel = self.designer.selection
        if sel != nil:
            let props = [
                {"name": "Name", "value": sel.name},
                {"name": "Left", "value": str(sel.left)},
                {"name": "Top", "value": str(sel.top)},
                {"name": "Width", "value": str(sel.width)},
                {"name": "Height", "value": str(sel.height)}
            ]
            if sel.caption != nil:
                push(props, {"name": "Caption", "value": sel.caption})
            if sel.text != nil:
                push(props, {"name": "Text", "value": sel.text})
            let pi = 0
            while pi < len(props):
                let p = props[pi]
                ui.ui_label(ctx, px + 8, prop_y, p["name"] + ": " + p["value"])
                prop_y = prop_y + 18
                pi = pi + 1

    proc render_designer_surface(self, ctx, win_w, win_h):
        let t = ctx["theme"]
        let dr = self.calc_designer_rect(win_w, win_h)
        let dx = dr["x"]
        let dy = dr["y"]
        let dw = dr["w"]
        let dh = dr["h"]
        self.surface_x = dx
        self.surface_y = dy
        self.surface_w = dw
        self.surface_h = dh
        let form_bg = [0.95, 0.95, 0.97, 1.0]
        let surface_bg = [0.7, 0.7, 0.75, 1.0]
        ui.ui_draw_rect(ctx, dx, dy, dw, dh, surface_bg)
        if self.form != nil:
            let fw = self.form.width
            let fh = self.form.height
            let fx = dx + (dw - fw) / 2
            let fy = dy + (dh - fh) / 2
            ui.ui_draw_rect(ctx, fx, fy, fw, fh, form_bg)
            ui.ui_draw_border(ctx, fx, fy, fw, fh, [0.0, 0.0, 0.0, 0.3], 1)
            _IDE_GLOBALS_designer_ctx = ctx
            _IDE_GLOBALS_form_fx = fx
            _IDE_GLOBALS_form_fy = fy
            self.designer.render(_cb_designer_grid_line, _cb_designer_draw_control, _cb_designer_draw_text)

    proc render_status_bar(self, ctx, win_w, win_h):
        let t = ctx["theme"]
        let sh = self.status_bar_height()
        let sy = win_h - sh
        ui.ui_draw_rect(ctx, 0, sy, win_w, sh, t["panel"])
        ui.ui_draw_rect(ctx, 0, sy, win_w, 1, t["border"])
        ui.ui_label(ctx, 8, sy + 3, self.status_text)
        if self.designer.selection != nil:
            let sel = self.designer.selection
            let info = "X: " + str(sel.left) + " Y: " + str(sel.top) + " W: " + str(sel.width) + " H: " + str(sel.height)
            ui.ui_label(ctx, win_w - len(info) * 8 - 16, sy + 3, info)

    proc handle_action(self, action):
        if action == "new":
            self.new_project()
        elif action == "open":
            self.status_text = "Open project dialog"
        elif action == "save":
            self.status_text = "Project saved"
        elif action == "exit":
            self._exit_requested = true
        elif action == "run":
            self.run_form()
        elif action == "stop":
            self.status_text = "Stopped"
        elif action == "delete":
            self.designer.delete_selected()
            self.status_text = "Control deleted"
        elif action == "toggle_grid":
            self.designer.grid_enabled = not self.designer.grid_enabled
            self.show_grid = self.designer.grid_enabled
            if self.show_grid:
                self.status_text = "Grid on"
            else:
                self.status_text = "Grid off"
        elif action == "toggle_toolbox":
            let cur = self.panel_widths["toolbox"]
            if cur == nil or cur == 0:
                self.panel_widths["toolbox"] = 180
            else:
                self.panel_widths["toolbox"] = 0
        elif action == "toggle_properties":
            let cur = self.panel_widths["props"]
            if cur == nil or cur == 0:
                self.panel_widths["props"] = 200
            else:
                self.panel_widths["props"] = 0

    proc run_form(self):
        if self.form == nil:
            self.status_text = "No form to run"
            return
        self.status_text = "Running form..."
        let saved_form = self.form
        windower.show_form(saved_form)
        self.status_text = "Form closed"

    proc handle_designer_input(self):
        if self.ui_ctx == nil:
            return
        let dx = self.surface_x
        let dy = self.surface_y
        let mx = self.ui_ctx["mouse_x"]
        let my = self.ui_ctx["mouse_y"]
        let clicked = self.ui_ctx["mouse_clicked"]
        let released = self.ui_ctx["mouse_released"]
        let fmx = mx - dx
        let fmy = my - dy
        if self.form != nil:
            let fw = self.form.width
            let fh = self.form.height
            let dw = self.surface_w
            let dh = self.surface_h
            let fx = (dw - fw) / 2
            let fy = (dh - fh) / 2
            let ctrl_mx = fmx - fx
            let ctrl_my = fmy - fy
            if clicked:
                self.designer.on_mouse_down(ctrl_mx, ctrl_my)
            elif self.ui_ctx["mouse_down"]:
                self.designer.on_mouse_move(ctrl_mx, ctrl_my)
            if released:
                self.designer.on_mouse_up(ctrl_mx, ctrl_my)

    proc add_control_to_form(self, ctrl_type):
        if self.form == nil:
            self.new_project()
        if self.form != nil:
            let cx = 50
            let cy = 50
            self.designer.add_control(ctrl_type, cx, cy)
            self.status_text = "Added " + ctrl_type

    proc render(self, ctx, win_w, win_h):
        self.ui_ctx = ctx
        self.render_menu_bar(ctx, win_w, win_h)
        self.render_toolbox(ctx, win_w, win_h)
        self.render_properties(ctx, win_w, win_h)
        self.render_designer_surface(ctx, win_w, win_h)
        self.render_status_bar(ctx, win_w, win_h)
        self.handle_designer_input()

let IDE_INSTANCE = nil

proc launch_gui_ide():
    let width = 1024
    let height = 680
    let renderer = ider.setup_ide_renderer(width, height)
    if renderer == nil:
        print "Failed to create GPU renderer"
        return
    let r = renderer["gr"]
    let ctx = ui.ui_create()
    let ide = IdeGui()
    ide.renderer = renderer
    IDE_INSTANCE = ide
    ide.new_project()
    let should_exit = false
    while not should_exit:
        if gpu.window_should_close():
            should_exit = true
            break
        let frame = gr.begin_frame(r)
        if frame == nil:
            should_exit = true
            break
        let sw = r["width"]
        let sh = r["height"]
        ui.ui_begin_frame(ctx)
        ide.render(ctx, sw, sh)
        if ide._exit_requested:
            should_exit = true
        ui.ui_end_frame(ctx)
        if renderer["rect_pipe"] != nil:
            let verts = ider.build_rect_vertices(ctx["draw_list"], sw, sh)
            let cmd = frame["cmd"]
            if len(verts) > 0:
                let buf_size = len(verts) * 4
                let vbuf = gpu.create_buffer(buf_size, gpu.BUFFER_VERTEX | gpu.BUFFER_TRANSFER_DST, gpu.MEMORY_HOST_VISIBLE | gpu.MEMORY_HOST_COHERENT)
                gpu.buffer_upload(vbuf, verts)
                gpu.cmd_bind_graphics_pipeline(cmd, renderer["rect_pipe"])
                gpu.cmd_push_constants(cmd, renderer["rect_pl"], gpu.STAGE_VERTEX, [sw * 1.0, sh * 1.0, 0.0, 0.0])
                gpu.cmd_bind_vertex_buffer(cmd, vbuf)
                let vcount = len(verts) / 6
                gpu.cmd_draw(cmd, vcount, 1, 0, 0)
                gpu.destroy_buffer(vbuf)
        gr.end_frame(r, frame)
    ider.shutdown_ide_renderer()
    print "IDE closed"
