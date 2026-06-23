import graphics.ui as ui
import graphics.renderer as gr
import runtime.forms as forms
import runtime.events as evt

let WINDOWER_CLICK = 1
let WINDOWER_CHANGED = 2
let WINDOWER_CHECKED = 3

let _current_renderer = nil
let _rect_pipe = nil
let _rect_pl = nil

proc init_windower_pipelines(rp):
    import gpu
    let vs = gpu.load_shader("ide/shaders/ui_rect.vert.spv", gpu.STAGE_VERTEX)
    let fs = gpu.load_shader("ide/shaders/ui_rect.frag.spv", gpu.STAGE_FRAGMENT)
    if vs < 0 or fs < 0:
        return
    _rect_pl = gpu.create_pipeline_layout([], 16, gpu.STAGE_VERTEX)
    let vb = {}
    vb["binding"] = 0
    vb["stride"] = 24
    vb["rate"] = gpu.INPUT_RATE_VERTEX
    let va_pos = {}
    va_pos["location"] = 0
    va_pos["binding"] = 0
    va_pos["format"] = gpu.ATTR_VEC2
    va_pos["offset"] = 0
    let va_col = {}
    va_col["location"] = 1
    va_col["binding"] = 0
    va_col["format"] = gpu.ATTR_VEC4
    va_col["offset"] = 8
    let cfg = {}
    cfg["layout"] = _rect_pl
    cfg["render_pass"] = rp
    cfg["vertex_shader"] = vs
    cfg["fragment_shader"] = fs
    cfg["topology"] = gpu.TOPO_TRIANGLE_LIST
    cfg["cull_mode"] = gpu.CULL_NONE
    cfg["front_face"] = gpu.FRONT_CCW
    cfg["blend"] = true
    cfg["vertex_bindings"] = [vb]
    cfg["vertex_attribs"] = [va_pos, va_col]
    _rect_pipe = gpu.create_graphics_pipeline(cfg)

proc render_draw_list(cmd, draw_list, sw, sh):
    import gpu
    if _rect_pipe == nil:
        return
    let verts = []
    let i = 0
    while i < len(draw_list):
        let c = draw_list[i]
        if c["type"] == "rect":
            let x = c["x"]
            let y = c["y"]
            let w = c["w"]
            let h = c["h"]
            let col = c["color"]
            let l = x
            let r = x + w
            let t2 = y
            let b = y + h
            let c0 = col[0]
            let c1 = col[1]
            let c2 = col[2]
            let c3 = col[3]
            push(verts, l)
            push(verts, t2)
            push(verts, c0)
            push(verts, c1)
            push(verts, c2)
            push(verts, c3)
            push(verts, r)
            push(verts, t2)
            push(verts, c0)
            push(verts, c1)
            push(verts, c2)
            push(verts, c3)
            push(verts, l)
            push(verts, b)
            push(verts, c0)
            push(verts, c1)
            push(verts, c2)
            push(verts, c3)
            push(verts, r)
            push(verts, t2)
            push(verts, c0)
            push(verts, c1)
            push(verts, c2)
            push(verts, c3)
            push(verts, r)
            push(verts, b)
            push(verts, c0)
            push(verts, c1)
            push(verts, c2)
            push(verts, c3)
            push(verts, l)
            push(verts, b)
            push(verts, c0)
            push(verts, c1)
            push(verts, c2)
            push(verts, c3)
        i = i + 1
    if len(verts) > 0:
        let buf_size = len(verts) * 4
        let vbuf = gpu.create_buffer(buf_size, gpu.BUFFER_VERTEX | gpu.BUFFER_TRANSFER_DST, gpu.MEMORY_HOST_VISIBLE | gpu.MEMORY_HOST_COHERENT)
        gpu.buffer_upload(vbuf, verts)
        gpu.cmd_bind_graphics_pipeline(cmd, _rect_pipe)
        gpu.cmd_push_constants(cmd, _rect_pl, gpu.STAGE_VERTEX, [sw * 1.0, sh * 1.0, 0.0, 0.0])
        gpu.cmd_bind_vertex_buffer(cmd, vbuf)
        gpu.cmd_draw(cmd, len(verts) / 6, 1, 0, 0)
        gpu.destroy_buffer(vbuf)

proc run_form_loop(form):
    let w = form.width
    let h = form.height
    let title = form.caption
    if title == "":
        title = form.name
    let r = gr.create_renderer(w, h, title)
    if r == nil:
        return nil
    let rp = r["render_pass"]
    init_windower_pipelines(rp)
    let sw = r["width"]
    let sh = r["height"]
    let ctx = ui.ui_create()
    _current_renderer = r
    let form_should_close = false
    while not form_should_close:
        let frame = gr.begin_frame(r)
        if frame == nil:
            form_should_close = true
            break
        ui.ui_begin_frame(ctx)
        ui.ui_window(ctx, 0, 0, w, h, title)
        for ctrl in form.controls:
            render_control(ctx, ctrl, frame)
        ui.ui_end_frame(ctx)
        render_draw_list(frame["cmd"], ctx["draw_list"], sw, sh)
        gr.end_frame(r, frame)
    gr.shutdown_renderer(r)
    _current_renderer = nil
    _rect_pipe = nil
    _rect_pl = nil

proc render_control(ctx, ctrl, frame):
    let ctrl_type = type(ctrl)
    if ctrl_type != "instance":
        return
    let class_str = str(ctrl.__class__)
    let x = ctrl.left
    let y = ctrl.top
    let w = ctrl.width
    let h = ctrl.height
    if contains(class_str, "Label"):
        let text = ""
        if ctrl.caption != nil:
            text = ctrl.caption
        ui.ui_label(ctx, x, y, text)
    elif contains(class_str, "CommandButton"):
        let label = ""
        if ctrl.caption != nil:
            label = ctrl.caption
        if ui.ui_button(ctx, x, y, w, h, label):
            evt.GLOBAL_DISPATCHER.dispatch(ctrl.name, "Click", ctrl)
    elif contains(class_str, "TextBox"):
        let text = ""
        if ctrl.text != nil:
            text = ctrl.text
        let result = ui.ui_text_input(ctx, x, y, w, ctrl.name, text)
        if result != text:
            ctrl.text = result
            evt.GLOBAL_DISPATCHER.dispatch(ctrl.name, "Change", ctrl)
    elif contains(class_str, "CheckBox"):
        let label = ""
        if ctrl.caption != nil:
            label = ctrl.caption
        let checked = ctrl.value != 0
        let new_checked = ui.ui_checkbox(ctx, x, y, label, checked)
        if new_checked != checked:
            if new_checked:
                ctrl.value = 1
            else:
                ctrl.value = 0
            evt.GLOBAL_DISPATCHER.dispatch(ctrl.name, "Click", ctrl)

let _open_forms = []

proc show_form(form):
    push(_open_forms, form)
    run_form_loop(form)
