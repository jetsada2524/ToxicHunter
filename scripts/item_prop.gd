extends Node3D
## One inspectable item in the room. A placeholder shape stands in until a
## Blender .glb or an AI sprite billboard is dropped in - swapping the visual
## later means replacing _build_mesh, nothing else.
##
## Hover raises a soft rim highlight (never revealing whether it's toxic), and a
## pick floats the item up to spin 360 degrees while the reveal card explains it.

signal picked(prop)

var entry: Dictionary          ## {id, toxic, room}
var data: Dictionary           ## the THItems record
var inspected := false

var _mesh_root: Node3D
var _mat: StandardMaterial3D
var _base_y := 0.0
var _hovering := false


func _init(e: Dictionary, d: Dictionary) -> void:
    entry = e
    data = d


func _ready() -> void:
    _base_y = position.y
    _build_mesh()

    # click + hover target
    var area := Area3D.new()
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(0.55, 0.9, 0.55)
    shape.shape = box
    shape.position = Vector3(0, 0.35, 0)
    area.add_child(shape)
    area.input_ray_pickable = true
    area.input_event.connect(_on_input)
    area.mouse_entered.connect(func(): _set_hover(true))
    area.mouse_exited.connect(func(): _set_hover(false))
    add_child(area)


func _build_mesh() -> void:
    _mesh_root = Node3D.new()
    add_child(_mesh_root)

    _mat = StandardMaterial3D.new()
    _mat.albedo_color = data.get("color", Color("B0B0B0"))
    _mat.roughness = 0.35
    _mat.metallic = 0.0

    # 1) sprite billboard - the AI painting with its real Thai label and GHS
    # symbols, which is the whole point of "read the label" gameplay. Chosen when
    # the config asks for it and the image exists.
    if Game.config().ITEM_MODE == "sprite" and _build_sprite():
        return

    # 2) the tinted Blender model. One neutral model serves every liquid.
    var glb := "res://assets/models/%s.glb" % data.get("shape", "bottle")
    if ResourceLoader.exists(glb, "PackedScene"):
        var inst: Node3D = load(glb).instantiate()
        _tint(inst)
        _mesh_root.add_child(inst)
        return

    # 3) primitive fallback (below) so the game always shows something.

    var cap_mat := StandardMaterial3D.new()
    cap_mat.albedo_color = data.get("color", Color.GRAY).darkened(0.4)
    cap_mat.roughness = 0.5

    match data.get("shape", "bottle"):
        "bottle":
            _cyl(0.20, 0.62, 0.0, _mat)
            _cyl(0.09, 0.16, 0.62, cap_mat)
        "spray":
            _cyl(0.17, 0.60, 0.0, _mat)
            _cyl(0.10, 0.14, 0.60, cap_mat)
            _box(Vector3(0.16, 0.10, 0.20), Vector3(0.02, 0.74, 0.06), cap_mat)
        "jug":
            _box(Vector3(0.42, 0.55, 0.34), Vector3(0, 0.30, 0), _mat)
            _cyl(0.10, 0.14, 0.60, cap_mat)
        "box":
            _box(Vector3(0.40, 0.52, 0.26), Vector3(0, 0.28, 0), _mat)
        "can":
            _cyl(0.22, 0.5, 0.0, _mat)
            _cyl(0.22, 0.04, 0.5, cap_mat)
        "bag":
            _box(Vector3(0.44, 0.58, 0.20), Vector3(0, 0.30, 0), _mat)
        _:
            _cyl(0.20, 0.6, 0.0, _mat)


var _sprite: Sprite3D


## Build the item as an upright billboard sprite. Kept ~1 unit tall so it sits
## on the shelf like the 3D props. Hover glow drives the sprite's modulate.
func _build_sprite() -> bool:
    var path := "res://assets/ui/item_%s.png" % entry.get("id", "")
    var tex: Texture2D = null
    if ResourceLoader.exists(path, "Texture2D"):
        tex = load(path)
    elif FileAccess.file_exists(path):
        var img := Image.new()
        if img.load(path) == OK:
            tex = ImageTexture.create_from_image(img)
    if tex == null:
        return false

    _sprite = Sprite3D.new()
    _sprite.texture = tex
    _sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    _sprite.shaded = true
    _sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
    # scale so the sprite is about 0.9 units tall regardless of source size
    var tall := maxf(1.0, float(tex.get_height()))
    _sprite.pixel_size = 0.9 / tall
    _sprite.position = Vector3(0, 0.45, 0)
    _mesh_root.add_child(_sprite)
    return true


## Recolour a loaded .glb: the body material (slot "Body") takes the item tint,
## caps stay their darker neutral. Override materials so the shared model isn't
## permanently changed for other instances.
func _tint(node: Node) -> void:
    for c in node.get_children():
        _tint(c)
    if node is MeshInstance3D:
        var mesh: MeshInstance3D = node
        for i in mesh.get_surface_override_material_count():
            var src := mesh.mesh.surface_get_material(i)
            var mname := src.resource_name if src else ""
            var m := StandardMaterial3D.new()
            if mname == "Body" or mname == "":
                m.albedo_color = data.get("color", Color("B0B0B0"))
                m.roughness = 0.32
                _mat = m       # hover glow drives this one
            elif mname == "Cap":
                m.albedo_color = data.get("color", Color.GRAY).darkened(0.45)
                m.roughness = 0.5
            else:
                m.albedo_color = Color(0.28, 0.28, 0.30)
                m.roughness = 0.5
            mesh.set_surface_override_material(i, m)


func _cyl(radius: float, height: float, y: float, mat: Material) -> void:
    var m := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    m.mesh = mesh
    m.material_override = mat
    m.position = Vector3(0, y + height * 0.5, 0)
    _mesh_root.add_child(m)


func _box(size: Vector3, pos: Vector3, mat: Material) -> void:
    var m := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    m.mesh = mesh
    m.material_override = mat
    m.position = pos
    _mesh_root.add_child(m)


func _set_hover(on: bool) -> void:
    if inspected:
        return
    _hovering = on
    if _sprite:
        # a soft brighten + slight lift, never hinting at toxicity
        _sprite.modulate = Color(1.25, 1.25, 1.25) if on else Color.WHITE
    elif _mat:
        _mat.emission_enabled = on
        _mat.emission = Color(1, 1, 1)
        _mat.emission_energy_multiplier = 0.35 if on else 0.0
    if on:
        Sfx.play(&"hover", 1.0, -12.0)


func _on_input(_cam: Node, event: InputEvent, _pos: Vector3, _n: Vector3, _i: int) -> void:
    if event is InputEventMouseButton and event.pressed \
            and event.button_index == MOUSE_BUTTON_LEFT and not inspected:
        picked.emit(self)


## Float up toward the camera and spin, so the child gets a clear look while the
## reveal card is open, then settle back and dim to show it's been handled.
func play_float_spin() -> void:
    _set_hover(false)
    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(_mesh_root, "position:y", 0.6, 0.5).set_trans(Tween.TRANS_BACK)
    if _sprite:
        # a billboard can't spin (it always faces the camera), so give it a
        # lively wobble + pop instead of a 360 turn
        tw.tween_property(_mesh_root, "scale", Vector3.ONE * 1.2, 0.5) \
            .set_trans(Tween.TRANS_BACK)
        tw.tween_property(_mesh_root, "rotation:z", 0.12, 0.25).from(-0.12) \
            .set_trans(Tween.TRANS_SINE)
    else:
        tw.tween_property(_mesh_root, "rotation:y", TAU, 1.0).from(0.0)
    tw.chain().tween_property(_mesh_root, "position:y", 0.0, 0.4)
    tw.parallel().tween_property(_mesh_root, "scale", Vector3.ONE * 0.85, 0.4)
    tw.parallel().tween_property(_mesh_root, "rotation:z", 0.0, 0.4)
    # dim afterwards to show it's been handled
    tw.chain().tween_callback(func():
        if _sprite:
            _sprite.modulate = Color(0.6, 0.6, 0.6)
        elif _mat:
            _mat.albedo_color = _mat.albedo_color.lerp(Color(0.5, 0.5, 0.5), 0.5)
    )
