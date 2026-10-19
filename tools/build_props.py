# -*- coding: utf-8 -*-
"""Build the ToxicHunter item props as clean Pixar-ish models and export one
.glb per shape into assets/models/.

Every prop is a single mesh built from smooth primitives with a rounded bevel,
so they read as friendly household objects but stay light. Colour is left
neutral - the game tints each instance from the item database, so one bottle
model serves every liquid.

Run inside Blender:
    exec(open("<this file>").read())
"""
import bpy, bmesh, math, os

OUT = "/Users/jetsada.sri/Claude/Projects/godot_game/ToxicHunter/assets/models"
os.makedirs(OUT, exist_ok=True)


def clear():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for m in list(bpy.data.meshes):
        bpy.data.meshes.remove(m)
    for mt in list(bpy.data.materials):
        bpy.data.materials.remove(mt)


def mat(name, col, rough=0.35, metal=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*col, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    return m


def smooth(o, bevel=0.02, seg=2, ang=45):
    for p in o.data.polygons:
        p.use_smooth = True
    bm = o.modifiers.new("Bev", 'BEVEL')
    bm.width = bevel
    bm.segments = seg
    bm.limit_method = 'ANGLE'
    bm.angle_limit = math.radians(ang)
    e = o.modifiers.new("Sharp", 'EDGE_SPLIT')
    e.split_angle = math.radians(60)


def cyl(r, h, z, m, verts=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h,
                                        location=(0, 0, z + h * 0.5))
    o = bpy.context.object
    o.data.materials.append(m)
    return o


def box(sx, sy, sz, z, m):
    bpy.ops.mesh.primitive_cube_add(location=(0, 0, z + sz * 0.5))
    o = bpy.context.object
    o.scale = (sx * 0.5, sy * 0.5, sz * 0.5)
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(m)
    return o


def join(parts, name):
    for o in bpy.data.objects:
        o.select_set(False)
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    return obj


def export(name):
    for o in bpy.data.objects:
        o.select_set(o.type == 'MESH')
    path = os.path.join(OUT, name + ".glb")
    bpy.ops.export_scene.gltf(
        filepath=path, export_format='GLB', use_selection=True,
        export_apply=True, export_yup=True)
    return path


# ---------------------------------------------------------------- the props
BODY = None  # neutral so the game can tint per item
def _reset_mats():
    global BODY, CAP, TRIM
    BODY = mat("Body", (0.80, 0.80, 0.82), 0.30)
    CAP = mat("Cap", (0.45, 0.45, 0.48), 0.5)
    TRIM = mat("Trim", (0.30, 0.30, 0.32), 0.5)


def bottle():
    b = cyl(0.20, 0.62, 0.0, BODY)
    smooth(b, 0.03)
    neck = cyl(0.10, 0.10, 0.62, BODY)
    cap = cyl(0.11, 0.10, 0.70, CAP)
    smooth(cap, 0.02)
    return join([b, neck, cap], "bottle")


def spray():
    b = cyl(0.17, 0.58, 0.0, BODY)
    smooth(b, 0.03)
    neck = cyl(0.10, 0.10, 0.58, CAP)
    head = box(0.20, 0.16, 0.12, 0.66, CAP)
    smooth(head, 0.02)
    nozzle = box(0.14, 0.06, 0.05, 0.70, TRIM)
    return join([b, neck, head, nozzle], "spray")


def jug():
    b = box(0.42, 0.34, 0.55, 0.0, BODY)
    smooth(b, 0.05)
    neck = cyl(0.10, 0.10, 0.55, CAP)
    cap = cyl(0.11, 0.09, 0.63, CAP)
    smooth(cap, 0.02)
    handle = cyl(0.03, 0.34, 0.0, TRIM, 12)
    handle.rotation_euler = (math.radians(90), 0, 0)
    handle.location = (0.24, 0, 0.42)
    return join([b, neck, cap, handle], "jug")


def item_box():
    b = box(0.40, 0.26, 0.52, 0.0, BODY)
    smooth(b, 0.03)
    return join([b], "box")


def can():
    b = cyl(0.22, 0.5, 0.0, BODY)
    smooth(b, 0.03)
    lid = cyl(0.225, 0.04, 0.5, CAP)
    rim = cyl(0.10, 0.05, 0.54, TRIM)
    return join([b, lid, rim], "can")


def bag():
    b = box(0.44, 0.20, 0.58, 0.0, BODY)
    smooth(b, 0.06)
    fold = box(0.44, 0.20, 0.06, 0.58, TRIM)
    return join([b, fold], "bag")


BUILDERS = {
    "bottle": bottle, "spray": spray, "jug": jug,
    "box": item_box, "can": can, "bag": bag,
}


def run():
    made = []
    for name, fn in BUILDERS.items():
        clear()
        _reset_mats()
        fn()
        made.append(export(name))
    return made


if True:
    _made = run()
    print("exported:", _made)
