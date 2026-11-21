"""Create editable, original head ornaments for heroes 01–06.

Run with Blender 4.3+:
    blender -b --python tools/art/create_hero_signatures_batch_01.py

The exported GLBs are rigid accessories intended to be parented to each
hero's animated Head pivot. Character bodies and their animation clips remain
in the existing character GLBs. The .blend file is the editable source.
"""
from pathlib import Path
import bpy
import math
from mathutils import Euler

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "characters" / "authored_details"
SOURCE_DIR = OUT / "blender_source"
SOURCE_DIR.mkdir(parents=True, exist_ok=True)
(SOURCE_DIR / ".gdignore").touch()
SOURCE = SOURCE_DIR / "hero_signatures_batch_01.blend"
OUT.mkdir(parents=True, exist_ok=True)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials):
    for block in list(datablocks):
        if block.users == 0:
            datablocks.remove(block)

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE_NEXT"
scene.render.resolution_x = 720
scene.render.resolution_y = 1280
scene.render.resolution_percentage = 100


def material(name, color, metallic=0.0, roughness=0.42, emission=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*color, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission
    return mat


def cube(name, loc, size, mat, bevel=0.025, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.rotation_euler = Euler(rotation, "XYZ")
    if bevel:
        mod = obj.modifiers.new("Soft forged edges", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.materials.append(mat)
    return obj


def sphere(name, loc, size, mat, segments=16, rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    return obj


def cone(name, loc, radius, depth, mat, vertices=8, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=0.0, depth=depth, location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def torus(name, loc, major, minor, mat, rotation=(0, 0, 0), segments=32):
    bpy.ops.mesh.primitive_torus_add(major_segments=segments, minor_segments=8, major_radius=major, minor_radius=minor, location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    for face in obj.data.polygons:
        face.use_smooth = True
    return obj


def leaf(name, loc, length, width, mat, rotation=(0, 0, 0)):
    # A shallow, tapered, double-sided leaf plate with a raised central vein.
    verts = [
        (-width / 2, 0, 0), (width / 2, 0, 0),
        (width * .34, length * .48, .018), (-width * .34, length * .48, .018),
        (0, length, 0.0),
    ]
    faces = [(0, 1, 2, 3), (3, 2, 4), (0, 3, 4), (1, 4, 2)]
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = loc
    obj.rotation_euler = Euler(rotation, "XYZ")
    solidify = obj.modifiers.new("Leaf thickness", "SOLIDIFY")
    solidify.thickness = .025
    bevel = obj.modifiers.new("Leaf edge", "BEVEL")
    bevel.width = .012
    bevel.segments = 2
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=solidify.name)
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    return obj


def hero_collection(hero_id):
    collection = bpy.data.collections.new(hero_id)
    scene.collection.children.link(collection)
    return collection


def move_to_collection(objects, collection):
    for obj in objects:
        for previous in list(obj.users_collection):
            previous.objects.unlink(obj)
        collection.objects.link(obj)


profiles = [
    ("hero_01", "BeaconCrown", [(.91,.78,.48),(.29,.55,.52),(.83,.60,.28)]),
    ("hero_02", "AshDuel", [(.25,.26,.28),(.52,.29,.22),(.64,.58,.48)]),
    ("hero_03", "ForestWayfinder", [(.30,.40,.25),(.72,.67,.49),(.40,.29,.20)]),
    ("hero_04", "OathForge", [(.32,.37,.40),(.20,.22,.24),(.70,.36,.20)]),
    ("hero_05", "StreetSpark", [(.22,.55,.51),(.84,.54,.20),(.35,.36,.39)]),
    ("hero_06", "RuneKeeper", [(.24,.33,.62),(.78,.74,.62),(.31,.64,.62)]),
]

for hero_id, motif, colors in profiles:
    start = set(bpy.context.scene.objects)
    metal = material(motif + "Metal", colors[0], .72, .28)
    cloth = material(motif + "Enamel", colors[1], .28, .34)
    gem = material(motif + "Glow", colors[2], .38, .22, .35)

    if hero_id == "hero_01":
        # Aelin: lighthouse lens, four rays and a sea-glass beacon.
        torus("Aelin_LighthouseHalo", (0,.24,.025), .27,.035, metal, (math.radians(72),0,0))
        for i, angle in enumerate((-55,-20,20,55)):
            rad = math.radians(angle)
            cone("Aelin_SunRay_%02d"%i,(math.sin(rad)*.28,.30+math.cos(rad)*.12,.03),.055,.29,metal,6,(0,0,-rad))
        sphere("Aelin_BeaconLens",(0,.04,-.275),(.105,.105,.045),gem)
        cube("Aelin_LensFrame",(0,.04,-.255),(.26,.23,.05),metal,.035)
        sphere("Aelin_LensFrameInset",(0,.04,-.285),(.072,.072,.018),gem)
    elif hero_id == "hero_02":
        # Bran: asymmetrical ash guard, broken blade crest and split cheek plates.
        cube("Bran_AshVisor",(0,.02,-.255),(.40,.115,.075),metal,.025,(0,0,.05))
        cube("Bran_BrokenBladeBase",(-.07,.24,.02),(.075,.27,.07),cloth,.018,(0,0,-.22))
        cone("Bran_BladeTip",(-.11,.39,.02),.055,.18,metal,5,(0,0,.18))
        for side in (-1,1):
            cube("Bran_CheekGuard_%s"%side,(side*.19,-.045,-.19),(.12,.15,.09),cloth,.025,(0,0,side*.20))
        sphere("Bran_AshGem",(.13,.10,-.26),(.045,.045,.02),gem)
    elif hero_id == "hero_03":
        # Mira: leaf hood, paired feather leaves and a trailfinder brow clasp.
        leaf("Mira_HoodCrest",(0,.20,.04),.24,.18,cloth)
        for side in (-1,1):
            leaf("Mira_Feather_%s"%side,(side*.16,.04,.08),.29,.11,metal,(side*.24,side*.12,side*-.45))
            sphere("Mira_TemplePin_%s"%side,(side*.22,.02,-.12),(.045,.055,.035),gem)
        cube("Mira_BrowClasp",(0,.10,-.258),(.20,.065,.035),metal,.025)
        sphere("Mira_PathfinderStone",(0,.10,-.285),(.05,.045,.018),gem)
    elif hero_id == "hero_04":
        # Toren: forge brow, side anvils and a compact oath-hammer crest.
        cube("Toren_ForgedBrow",(0,.14,-.255),(.38,.105,.065),metal,.025)
        for side in (-1,1):
            cube("Toren_TempleFlange_%s"%side,(side*.22,.03,-.08),(.11,.25,.16),cloth,.025,(0,0,side*.14))
            sphere("Toren_Rivet_%s"%side,(side*.18,.16,-.296),(.035,.035,.018),gem)
        cube("Toren_HammerCrestHandle",(0,.29,.02),(.055,.24,.055),cloth,.015)
        cube("Toren_HammerCrestHead",(0,.38,.02),(.22,.09,.10),metal,.02)
    elif hero_id == "hero_05":
        # Lissa: bright street-mage collar shards and a floating spark focus.
        for side in (-1,1):
            cone("Lissa_CollarSpark_%s"%side,(side*.14,-.17,-.04),.085,.26,metal,5,(side*-.18,0,side*.28))
            sphere("Lissa_EarFocus_%s"%side,(side*.245,.02,-.06),(.055,.065,.045),gem)
        torus("Lissa_StreetSigil",(0,.19,.025),.19,.018,cloth,(math.radians(82),0,0),24)
        sphere("Lissa_SparkCore",(.30,.18,-.015),(.09,.11,.08),gem)
        for i in range(3):
            cone("Lissa_SparkProng_%d"%i,(.30,.29+i*.035,-.01),.035,.10,metal,5,(0,0,(i-1)*.28))
    else:
        # Orwin: scholar's rune plate and three nested orbit rings.
        cube("Orwin_RuneBrow",(0,.12,-.26),(.32,.075,.055),metal,.025)
        for side in (-1,1):
            torus("Orwin_TempleOrbit_%s"%side,(side*.20,.03,.02),.11,.018,gem,(math.radians(78),side*.4,0),20)
        for i in range(3):
            cube("Orwin_RuneMark_%d"%i,((i-1)*.085,.13,-.294),(.035,.048,.018),cloth,.008,(0,0,(i-1)*.25))
        sphere("Orwin_TranslationStone",(0,.23,.03),(.065,.08,.055),gem)

    added = [obj for obj in bpy.context.scene.objects if obj not in start]
    coll = hero_collection(hero_id)
    move_to_collection(added, coll)
    # Export only this hero's accessory objects. Their origin stays at the
    # Head pivot; runtime parents each GLB to that animated node.
    bpy.ops.object.select_all(action="DESELECT")
    for obj in added:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = added[0]
    destination = OUT / (hero_id + "_detail.glb")
    bpy.ops.export_scene.gltf(filepath=str(destination), export_format="GLB", use_selection=True, export_animations=False, export_apply=True)
    print("EXPORTED", destination.relative_to(ROOT), destination.stat().st_size, "bytes", len(added), "objects")

bpy.ops.object.select_all(action="DESELECT")
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
print("SAVED_SOURCE", SOURCE.relative_to(ROOT), SOURCE.stat().st_size, "bytes")
