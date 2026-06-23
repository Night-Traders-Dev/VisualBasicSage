import gpu
import runtime.forms as forms
import runtime.controls as ctrl

let PUSH_SIZE = 16
let _rect_pipe = nil
let _rect_pl = nil
let _text_pipe = nil
let _text_pl = nil
let _text_desc = nil
let _font = nil
let _gr = nil

proc init_rect_pipeline(rp):
    let vs = gpu.load_shader("ide/shaders/ui_rect.vert.spv", gpu.STAGE_VERTEX)
    let fs = gpu.load_shader("ide/shaders/ui_rect.frag.spv", gpu.STAGE_FRAGMENT)
    if vs < 0 or fs < 0:
        print "Failed to load rect shaders"
        return
    _rect_pl = gpu.create_pipeline_layout([], PUSH_SIZE, gpu.STAGE_VERTEX)
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

proc init_text_pipeline(rp):
    if _font == nil:
        return
    let vs = gpu.load_shader("ide/shaders/ui_text.vert.spv", gpu.STAGE_VERTEX)
    let fs = gpu.load_shader("ide/shaders/ui_text.frag.spv", gpu.STAGE_FRAGMENT)
    if vs < 0 or fs < 0:
        print "Failed to load text shaders"
        return
    let desc_layout = gpu.create_descriptor_layout([
        {"binding": 0, "type": gpu.DESC_COMBINED_SAMPLER, "stage": gpu.STAGE_FRAGMENT, "count": 1}
    ])
    _text_pl = gpu.create_pipeline_layout([desc_layout], PUSH_SIZE, gpu.STAGE_VERTEX)
    let vb_pos = {}
    vb_pos["binding"] = 0
    vb_pos["stride"] = 32
    vb_pos["rate"] = gpu.INPUT_RATE_VERTEX
    let va_pos = {}
    va_pos["location"] = 0
    va_pos["binding"] = 0
    va_pos["format"] = gpu.ATTR_VEC2
    va_pos["offset"] = 0
    let va_uv = {}
    va_uv["location"] = 1
    va_uv["binding"] = 0
    va_uv["format"] = gpu.ATTR_VEC2
    va_uv["offset"] = 8
    let cfg = {}
    cfg["layout"] = _text_pl
    cfg["render_pass"] = rp
    cfg["vertex_shader"] = vs
    cfg["fragment_shader"] = fs
    cfg["topology"] = gpu.TOPO_TRIANGLE_LIST
    cfg["cull_mode"] = gpu.CULL_NONE
    cfg["front_face"] = gpu.FRONT_CCW
    cfg["blend"] = true
    cfg["vertex_bindings"] = [vb_pos]
    cfg["vertex_attribs"] = [va_pos, va_uv]
    _text_pipe = gpu.create_graphics_pipeline(cfg)
    let atlas_img = gpu.font_atlas(_font)
    let sampler = gpu.create_sampler(gpu.FILTER_LINEAR, gpu.FILTER_LINEAR, gpu.ADDRESS_CLAMP_EDGE)
    let pool = gpu.create_descriptor_pool(1, [{"type": gpu.DESC_COMBINED_SAMPLER, "count": 1}])
    _text_desc = gpu.allocate_descriptor_set(pool, desc_layout)
    gpu.update_descriptor_image(_text_desc, 0, gpu.DESC_COMBINED_SAMPLER, atlas_img, sampler)

proc build_rect_vertices(draw_list, sw, sh):
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
            let t = y
            let b = y + h
            let c0 = col[0]
            let c1 = col[1]
            let c2 = col[2]
            let c3 = col[3]
            push(verts, l)
            push(verts, t)
            push(verts, c0)
            push(verts, c1)
            push(verts, c2)
            push(verts, c3)
            push(verts, r)
            push(verts, t)
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
            push(verts, t)
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
    return verts

proc load_font():
    let font_paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/TTF/DejaVuSans.ttf",
        "/usr/share/fonts/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"
    ]
    let fp = 0
    while fp < len(font_paths):
        let path = font_paths[fp]
        let f = gpu.load_font(path, 16)
        if f != nil:
            _font = f
            return f
        fp = fp + 1
    return nil

proc setup_ide_renderer(width, height):
    import graphics.renderer as gr
    let r = gr.create_renderer(width, height, "VisualBasicSage IDE")
    if r == nil:
        return nil
    _gr = r
    let rp = r["render_pass"]
    init_rect_pipeline(rp)
    load_font()
    init_text_pipeline(rp)
    let renderer = {}
    renderer["gr"] = r
    renderer["rect_pipe"] = _rect_pipe
    renderer["rect_pl"] = _rect_pl
    renderer["text_pipe"] = _text_pipe
    renderer["text_pl"] = _text_pl
    renderer["text_desc"] = _text_desc
    renderer["font"] = _font
    renderer["width"] = width
    renderer["height"] = height
    return renderer

proc shutdown_ide_renderer():
    if _gr == nil:
        return
    import graphics.renderer as gr
    gr.shutdown_renderer(_gr)
    _gr = nil

proc get_renderer():
    if _gr == nil:
        return nil
    let renderer = {}
    renderer["gr"] = _gr
    renderer["rect_pipe"] = _rect_pipe
    renderer["rect_pl"] = _rect_pl
    renderer["text_pipe"] = _text_pipe
    renderer["text_pl"] = _text_pl
    renderer["text_desc"] = _text_desc
    renderer["font"] = _font
    return renderer
