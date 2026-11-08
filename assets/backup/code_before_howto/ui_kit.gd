extends RefCounted
## Shared UI kit: detective-notebook cards, capsule buttons, GHS hazard icons,
## star ratings. One place for the look so every screen matches.
class_name THUi

const ART_DIR := "res://assets/ui/"

# palette
const PAPER := Color("FBF6E9")
const PAPER_D := Color("EDE3CB")
const INK := Color("2B3A4A")
const LINE := Color("3E6E8E")
const LINE_D := Color("2C4E66")
const GREEN := Color("46B36B")
const RED := Color("E05A4A")
const AMBER := Color("F0A83D")
const TEAL := Color("2FA6A0")

static var _cache: Dictionary = {}


static func art(file: String) -> Texture2D:
    if _cache.has(file):
        return _cache[file]
    var path := ART_DIR + file
    var tex: Texture2D = null
    if ResourceLoader.exists(path, "Texture2D"):
        tex = load(path) as Texture2D
    elif FileAccess.file_exists(path):
        var img := Image.new()
        if img.load(path) == OK:
            tex = ImageTexture.create_from_image(img)
    _cache[file] = tex
    return tex


static func font(bold: bool) -> Font:
    var itim := _ttf("res://fonts/Itim/Itim-Regular.ttf")
    if itim:
        _add_fallbacks(itim)
        if not bold:
            return itim
        var v := FontVariation.new()
        v.base_font = itim
        v.variation_embolden = 0.35
        return v
    return _ttf("res://fonts/Sarabun/Sarabun-%s.ttf" % ("Bold" if bold else "Regular"))


## The web build has no system fonts, so anything Itim lacks (dashes,
## subscripts like H₂SO₄, ★, emoji) would show as boxes. Chain the bundled
## fallbacks once: Sarabun, then CosmosSymbols / CosmosEmoji (fonts/Emoji).
static func _add_fallbacks(f: FontFile) -> void:
    if not f.fallbacks.is_empty():
        return
    var list: Array[Font] = []
    for p in ["res://fonts/Sarabun/Sarabun-Bold.ttf", "res://fonts/Emoji/CosmosSymbols.ttf",
            "res://fonts/Emoji/CosmosEmoji.ttf"]:
        var fb := _ttf(p)
        if fb:
            list.append(fb)
    f.fallbacks = list


static func _ttf(path: String) -> FontFile:
    # exported builds (web / macOS / Windows) only ship the imported font,
    # not the raw .ttf, so load it as a resource first
    if ResourceLoader.exists(path):
        var res := load(path) as FontFile
        if res:
            return res
    if not FileAccess.file_exists(path):
        return null
    var f := FontFile.new()
    f.data = FileAccess.get_file_as_bytes(path)
    return f


static func card(bg: Color = PAPER, border: Color = LINE, radius: int = 26,
        bw: int = 5) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.set_corner_radius_all(radius)
    sb.set_border_width_all(bw)
    sb.border_color = border
    sb.content_margin_left = 22
    sb.content_margin_right = 22
    sb.content_margin_top = 17
    sb.content_margin_bottom = 19
    sb.shadow_color = Color(0.05, 0.08, 0.14, 0.5)
    sb.shadow_size = 10
    sb.shadow_offset = Vector2(0, 5)
    return sb


static func capsule(bg: Color, border: Color, radius: int = 36, shadow: int = 7,
        off: int = 5) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.set_corner_radius_all(radius)
    sb.set_border_width_all(5)
    sb.border_color = border
    sb.content_margin_left = 26
    sb.content_margin_right = 26
    sb.content_margin_top = 13
    sb.content_margin_bottom = 16
    sb.shadow_color = Color(0.05, 0.08, 0.14, 0.45)
    sb.shadow_size = shadow
    sb.shadow_offset = Vector2(0, off)
    return sb


static func button(text: String, tint: Color, w := 0, h := 62, fs := 24) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(w, h)
    b.add_theme_font_size_override("font_size", fs)
    b.add_theme_font_override("font", font(true))
    b.add_theme_color_override("font_color", Color.WHITE)
    b.add_theme_color_override("font_hover_color", Color.WHITE)
    b.add_theme_color_override("font_pressed_color", Color.WHITE)
    b.add_theme_stylebox_override("normal", capsule(tint, tint.darkened(0.3)))
    b.add_theme_stylebox_override("hover", capsule(tint.lightened(0.13), tint.darkened(0.3)))
    b.add_theme_stylebox_override("pressed", capsule(tint.darkened(0.18), tint.darkened(0.35), 36, 1, 1))
    b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    return b


static func title(text: String, size: int, col: Color, bold := true) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_font_override("font", font(bold))
    l.add_theme_color_override("font_color", col)
    return l


static func stars(n: int) -> String:
    return "★".repeat(n) + "☆".repeat(5 - n)


## Draw a GHS-style hazard pictogram into a texture: red diamond, white field,
## black symbol. Recognisable at a glance and matches the labels children see
## on real products.
static func ghs_texture(kind: String, px: int = 96) -> ImageTexture:
    var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var c := px * 0.5
    var r := px * 0.46
    # rotated-square (diamond) frame
    for y in px:
        for x in px:
            var dx: float = abs(x - c)
            var dy: float = abs(y - c)
            var man := dx + dy                     # diamond distance
            if man <= r:
                var col := Color(0.90, 0.13, 0.10)  # red border
                if man <= r - px * 0.10:
                    col = Color(1, 1, 1)            # white field
                img.set_pixel(x, y, col)
    _stamp_symbol(img, kind, c, px)
    return ImageTexture.create_from_image(img)


static func _stamp_symbol(img: Image, kind: String, c: float, px: float) -> void:
    var ink := Color(0.06, 0.06, 0.08)
    var s := px * 0.22
    match kind:
        "flammable":
            # simple flame: teardrop of dots
            for i in 220:
                var t := i / 220.0
                var w := s * (1.0 - t) * 0.9
                var yy := c + s * 0.7 - t * s * 1.8
                for k in range(-int(w), int(w)):
                    _dot(img, c + k + sin(t * 6.0) * s * 0.2, yy, ink)
        "corrosive":
            # two streams dripping onto a bar
            for k in range(-int(px * 0.22), int(px * 0.22)):
                _dot(img, c + k, c + px * 0.14, ink)
            for i in 40:
                _dot(img, c - px * 0.10, c - px * 0.14 + i * px * 0.006, ink)
                _dot(img, c + px * 0.10, c - px * 0.14 + i * px * 0.006, ink)
        "toxic":
            # skull: round head + two eye gaps
            for y in range(int(c - s), int(c + s)):
                for x in range(int(c - s), int(c + s)):
                    if Vector2(x - c, y - c + px * 0.02).length() <= s:
                        img.set_pixel(x, y, ink)
            for e in [-1, 1]:
                for y in range(int(c - px * 0.06), int(c + px * 0.02)):
                    for x in range(int(c + e * px * 0.09 - px * 0.05), int(c + e * px * 0.09 + px * 0.05)):
                        if Vector2(x - (c + e * px * 0.09), y - (c - px * 0.02)).length() <= px * 0.05:
                            img.set_pixel(x, y, Color(1, 1, 1))
        "environment":
            # a leaf / fish stand-in: filled circle lower half
            for y in range(int(c), int(c + s)):
                for x in range(int(c - s), int(c + s)):
                    if Vector2(x - c, y - c).length() <= s:
                        img.set_pixel(x, y, ink)
        _:
            # harmful: exclamation
            for y in range(int(c - s), int(c + s * 0.4)):
                _dot(img, c, y, ink, px * 0.05)
            _dot(img, c, c + s * 0.7, ink, px * 0.06)


static func _dot(img: Image, x: float, y: float, col: Color, r: float = 2.0) -> void:
    var ix := int(x)
    var iy := int(y)
    var ir := int(r)
    for yy in range(iy - ir, iy + ir + 1):
        for xx in range(ix - ir, ix + ir + 1):
            if xx < 0 or yy < 0 or xx >= img.get_width() or yy >= img.get_height():
                continue
            if Vector2(xx - x, yy - y).length() <= r:
                img.set_pixel(xx, yy, col)
