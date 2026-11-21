#!/usr/bin/env python3
"""Validate all generated GLB files without third-party dependencies."""
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "assets" / "characters"
EXPECTED = ([f"hero_{n:02d}.glb" for n in range(1,31)] + [f"boss_region_{n}.glb" for n in range(6)] + [f"enemy_{piece}_region_{region}.glb" for region in range(6) for piece in "prnbqk"])
CLIPS = {"idle","move","attack","hit","death","cast"}
COMPONENT_SIZE = {5120:1,5121:1,5122:2,5123:2,5125:4,5126:4}
COMPONENTS = {"SCALAR":1,"VEC2":2,"VEC3":3,"VEC4":4,"MAT4":16}

def validate(path, require_animation=True):
    data = path.read_bytes()
    assert len(data) >= 28, f"{path}: too short"
    magic, version, total = struct.unpack_from("<4sII", data, 0)
    assert magic == b"glTF" and version == 2 and total == len(data), f"{path}: invalid GLB header"
    json_size, kind = struct.unpack_from("<I4s", data, 12)
    assert kind == b"JSON" and json_size % 4 == 0, f"{path}: invalid JSON chunk"
    json_end = 20 + json_size
    assert json_end + 8 <= len(data), f"{path}: missing binary chunk"
    gltf = json.loads(data[20:json_end])
    bin_size, bin_kind = struct.unpack_from("<I4s", data, json_end)
    assert bin_kind == b"BIN\x00", f"{path}: wrong BIN chunk"
    assert json_end + 8 + bin_size == len(data), f"{path}: bad BIN size"
    assert gltf["buffers"][0]["byteLength"] <= bin_size, f"{path}: buffer overrun"
    for view in gltf["bufferViews"]:
        assert view["buffer"] == 0
        assert view.get("byteOffset",0) % 4 == 0, f"{path}: glTF buffer view is not 4-byte aligned"
        assert view.get("byteOffset",0) + view["byteLength"] <= bin_size, f"{path}: buffer view overflow"
    if require_animation:
        # Rigid parts must use genuine chamfered topology, not the previous
        # flat six-face cube blockout. Skin meshes are validated separately.
        for material_index in range(5):
            rigid_mesh=gltf["meshes"][material_index]
            assert rigid_mesh["name"].startswith("Beveled"), f"{path}: missing beveled armor"
            rigid_primitive=rigid_mesh["primitives"][0]
            vertex_count=gltf["accessors"][rigid_primitive["attributes"]["POSITION"]]["count"]
            triangle_count=gltf["accessors"][rigid_primitive["indices"]]["count"]//3
            assert "TEXCOORD_0" in rigid_primitive["attributes"], f"{path}: rigid mesh missing UV charts"
            uv_acc=gltf["accessors"][rigid_primitive["attributes"]["TEXCOORD_0"]]
            assert uv_acc["type"]=="VEC2" and uv_acc["componentType"]==5126, f"{path}: invalid UV format"
            assert uv_acc["count"]==vertex_count, f"{path}: UV and vertex count mismatch"
            assert uv_acc["min"]==[0,0] and uv_acc["max"]==[1,1], f"{path}: invalid UV coordinate range"
            assert vertex_count>=96 and triangle_count>=40, f"{path}: rigid geometry still cube blockout"
    if require_animation:
        # All five PBR materials must have self-contained valid PNG images.
        assert len(gltf.get("images",[]))==10, f"{path}: missing five embedded albedo and five normal images"
        assert len(gltf.get("textures",[]))==10, f"{path}: missing PBR albedo/normal texture bindings"
        assert len(gltf.get("samplers",[]))==1, f"{path}: textures should share a sampler"
        for material_index,material in enumerate(gltf["materials"]):
            texture_ref=material["pbrMetallicRoughness"].get("baseColorTexture",{})
            assert texture_ref.get("index")==material_index and texture_ref.get("texCoord")==0, f"{path}: invalid material texture binding"
            normal_ref=material.get("normalTexture",{})
            assert normal_ref.get("index")==5+material_index and normal_ref.get("texCoord")==0, f"{path}: invalid normal map binding"
            assert 0.0 < normal_ref.get("scale",0) <= 1.0, f"{path}: unsafe normal map strength"
            normal_texture=gltf["textures"][5+material_index]
            assert normal_texture["source"]==5+material_index and normal_texture["sampler"]==0, f"{path}: normal texture source mismatch"
            texture=gltf["textures"][material_index]
            assert texture["source"]==material_index and texture["sampler"]==0, f"{path}: invalid texture source"
            img=gltf["images"][material_index]
            assert img["mimeType"]=="image/png" and "uri" not in img, f"{path}: texture must be embedded PNG"
            view=gltf["bufferViews"][img["bufferView"]]
            start=json_end+8+view["byteOffset"]
            png=data[start:start+view["byteLength"]]
            assert png.startswith(b"\x89PNG\r\n\x1a\n"), f"{path}: invalid embedded PNG header {png[:16]!r}, offset={view['byteOffset']}"
            assert len(png)>80 and png[-12:]==b"\x00\x00\x00\x00IEND\xaeB\x60\x82", f"{path}: truncated PNG"
            normal_img=gltf["images"][5+material_index]
            assert normal_img["mimeType"]=="image/png" and "uri" not in normal_img, f"{path}: normal map must be embedded"
            normal_view=gltf["bufferViews"][normal_img["bufferView"]]
            normal_start=json_end+8+normal_view["byteOffset"]
            normal_png=data[normal_start:normal_start+normal_view["byteLength"]]
            assert normal_png.startswith(b"\x89PNG\r\n\x1a\n"), f"{path}: invalid normal PNG signature"
            assert len(normal_png)>80 and normal_png[-12:]==b"\x00\x00\x00\x00IEND\xaeB\x60\x82", f"{path}: truncated normal PNG"
            assert struct.unpack_from(">IIBB",normal_png,16)==(128,128,8,6), f"{path}: normal PNG dimensions mismatch"
            width,height,depth,color=struct.unpack_from(">IIBB",png,16)
            assert (width,height,depth,color)==(128,128,8,6), f"{path}: expected 128px RGBA material atlas"
        for mesh in gltf["meshes"]:
            for primitive in mesh["primitives"]:
                attrs=primitive["attributes"]
                assert "TEXCOORD_0" in attrs, f"{path}: mesh {mesh['name']} has no UV for PBR textures"
                uv=gltf["accessors"][attrs["TEXCOORD_0"]]
                pos=gltf["accessors"][attrs["POSITION"]]
                assert uv["type"]=="VEC2" and uv["count"]==pos["count"], f"{path}: invalid UV count in {mesh['name']}"
    for acc in gltf["accessors"]:
        view = gltf["bufferViews"][acc["bufferView"]]
        byte_len = acc["count"] * COMPONENT_SIZE[acc["componentType"]] * COMPONENTS[acc["type"]]
        assert acc.get("byteOffset",0) + byte_len <= view["byteLength"], f"{path}: accessor overflow"
        component_alignment=COMPONENT_SIZE[acc["componentType"]]
        assert acc.get("byteOffset",0)%component_alignment==0, f"{path}: accessor offset misaligned"
        assert view.get("byteOffset",0)%component_alignment==0, f"{path}: accessor buffer view misaligned"
        if acc["type"]=="MAT4":
            assert acc["componentType"]==5126, f"{path}: inverse bind matrix must use float32"
        if "min" in acc or "max" in acc:
            assert "min" in acc and "max" in acc, f"{path}: incomplete accessor bounds"
            assert len(acc["min"])==len(acc["max"])==COMPONENTS[acc["type"]], f"{path}: incorrect accessor bound dimension"
            assert all(math.isfinite(x) and math.isfinite(y) and x<=y for x,y in zip(acc["min"],acc["max"])), f"{path}: invalid accessor bounds"
    # Check glTF node graph and animation sampler consistency before Godot.
    node_count=len(gltf["nodes"])
    parent_counts=[0]*node_count
    for node in gltf["nodes"]:
        for child in node.get("children",[]):
            assert isinstance(child,int) and 0 <= child < node_count, f"{path}: invalid child index"
            parent_counts[child]+=1
        for key in ("translation","rotation","scale"):
            if key in node:
                values=node[key]
                assert len(values)==(4 if key=="rotation" else 3), f"{path}: malformed {key}"
                assert all(math.isfinite(value) for value in values), f"{path}: nonfinite {key}"
        if "rotation" in node:
            assert abs(sum(value*value for value in node["rotation"])-1.0)<0.02, f"{path}: nonunit quaternion"
    assert all(count<=1 for count in parent_counts), f"{path}: glTF node with multiple parents"
    visited=set()
    active=set()
    def visit(index):
        assert index not in active, f"{path}: cyclic glTF hierarchy"
        if index in visited: return
        active.add(index)
        for child in gltf["nodes"][index].get("children",[]): visit(child)
        active.remove(index)
        visited.add(index)
    for scene in gltf.get("scenes",[]):
        for root in scene["nodes"]: visit(root)
    assert len(visited)==node_count, f"{path}: orphaned glTF nodes"
    for scene in gltf.get("scenes",[]):
        for root in scene["nodes"]:
            assert 0 <= root < node_count, f"{path}: invalid scene root"
    def unpack_accessor(index):
        acc=gltf["accessors"][index]
        view=gltf["bufferViews"][acc["bufferView"]]
        start=json_end+8+view.get("byteOffset",0)+acc.get("byteOffset",0)
        width=COMPONENTS[acc["type"]]
        fmt={5121:"B",5123:"H",5125:"I",5126:"f"}[acc["componentType"]]
        count=acc["count"]
        values=struct.unpack_from("<"+fmt*(count*width),data,start)
        return [values[i:i+width] for i in range(0,len(values),width)]
    for animation in gltf.get("animations",[]):
        assert animation.get("samplers") and animation.get("channels"), f"{path}: empty animation"
        targets=[(channel["target"]["node"],channel["target"]["path"]) for channel in animation["channels"]]
        assert len(targets)==len(set(targets)), f"{path}: duplicate animated node/property targets in {animation['name']}"
        for channel in animation["channels"]:
            assert 0 <= channel["sampler"] < len(animation["samplers"]), f"{path}: bad sampler index"
            assert 0 <= channel["target"]["node"] < node_count, f"{path}: bad animation target"
            assert channel["target"]["path"] in ("translation","rotation","scale"), f"{path}: unsupported target"
        for channel in animation["channels"]:
            sampler=animation["samplers"][channel["sampler"]]
            input_acc=gltf["accessors"][sampler["input"]]
            output_acc=gltf["accessors"][sampler["output"]]
            assert input_acc["count"]==output_acc["count"], f"{path}: animation keyframe/value count mismatch"
            target_path=channel["target"]["path"]
            assert target_path in ("translation","rotation","scale"), f"{path}: unsupported animation target {target_path}"
            expected_type="VEC4" if target_path=="rotation" else "VEC3"
            assert output_acc["type"]==expected_type, f"{path}: invalid {target_path} keyframe vector type"
            assert output_acc["componentType"]==5126, f"{path}: animation output must be float32"
            assert all(all(math.isfinite(value) for value in key) for key in unpack_accessor(sampler["output"])), f"{path}: nonfinite animated {target_path} value"
            if target_path=="scale":
                assert all(all(value>0 for value in key) for key in unpack_accessor(sampler["output"])), f"{path}: nonpositive animated scale"
            if channel["target"]["path"]=="rotation":
                sampler=animation["samplers"][channel["sampler"]]
                acc=gltf["accessors"][sampler["output"]]
                assert acc["type"]=="VEC4" and acc["componentType"]==5126, f"{path}: rotation must be float quaternion"
                quaternions=unpack_accessor(sampler["output"])
                assert all(all(math.isfinite(x) for x in q) and abs(sum(x*x for x in q)-1)<1e-4 for q in quaternions), f"{path}: nonunit animated quaternion"
        for sampler in animation["samplers"]:
            input_acc=gltf["accessors"][sampler["input"]]
            output_acc=gltf["accessors"][sampler["output"]]
            assert input_acc["type"]=="SCALAR" and input_acc["componentType"]==5126, f"{path}: invalid animation timeline"
            assert output_acc["count"]==input_acc["count"], f"{path}: animation keyframe count mismatch"
            assert input_acc["count"]>=2, f"{path}: animation must have multiple keyframes"
            timeline=[row[0] for row in unpack_accessor(sampler["input"])]
            assert all(math.isfinite(value) and value>=0 for value in timeline), f"{path}: invalid animation times"
            assert all(a<b for a,b in zip(timeline,timeline[1:])), f"{path}: non-increasing animation times"
            assert sampler.get("interpolation","LINEAR") in ("LINEAR","STEP"), f"{path}: unsupported animation interpolation"
            if "max" in input_acc:
                assert math.isfinite(input_acc["max"][0]) and input_acc["max"][0]>0, f"{path}: invalid duration"
    names = {a["name"] for a in gltf.get("animations",[])}
    if require_animation:
        assert CLIPS.issubset(names), f"{path}: missing clips {CLIPS - names}"
    node_names = {node.get("name") for node in gltf["nodes"]}
    if require_animation:
        assert len(gltf.get("skins",[]))==6, f"{path}: expected cape, torso, two arms and two legs skinned rigs"
        skin=gltf["skins"][0]
        assert len(skin["joints"])==2 and skin.get("inverseBindMatrices") is not None, f"{path}: invalid two-bone mantle"
        assert gltf["accessors"][skin["inverseBindMatrices"]]["type"]=="MAT4", f"{path}: inverse bind matrices must be MAT4"
        assert gltf["accessors"][skin["inverseBindMatrices"]]["count"]==2, f"{path}: missing bind matrices"
        for joint_index in skin["joints"]:
            assert 0<=joint_index<node_count, f"{path}: invalid skin joint"
        # A skin is only valid if each inverse-bind matrix cancels its
        # joint's world-space rest transform. This catches distorted meshes
        # that pass superficial JOINTS_0 / WEIGHTS_0 presence checks.
        parents={}
        for parent_index,node in enumerate(gltf["nodes"]):
            for child in node.get("children",[]):
                parents[child]=parent_index
        def world_rest_translation(index):
            result=[0.0,0.0,0.0]
            while True:
                node=gltf["nodes"][index]
                # Generated joints have translation-only bind transforms.
                assert "rotation" not in node or node["rotation"]==[0,0,0,1], f"{path}: nontrivial joint rest rotation needs full matrix validation"
                for axis,value in enumerate(node.get("translation",[0,0,0])):
                    result[axis]+=value
                if index not in parents: break
                index=parents[index]
            return result
        # Facial detail is real head-attached geometry, not a static
        # decoration left behind when the neck rotates.
        face_head=next(i for i,node in enumerate(gltf["nodes"]) if node.get("name")=="Head")
        face_children={gltf["nodes"][i].get("name") for i in gltf["nodes"][face_head].get("children",[])}
        assert {"NoseBridge","NoseTip","Mouth","Pupil1","Pupil-1",
                "Ear1","Ear-1","LowerCheek1","LowerCheek-1"}<=face_children, f"{path}: missing animated facial detail"
        headgear_prefixes=("Crown","Antler","HighHelm","Crest","Halo","Mask")
        authored_headgear={node.get("name") for node in gltf["nodes"]
                           if node.get("name","").startswith(headgear_prefixes)}
        assert authored_headgear, f"{path}: missing signature headgear"
        assert authored_headgear<=face_children, f"{path}: signature headgear detached from animated head"
        # Face accents must move with head animations; boss visors use
        # different geometry from regular hero/enemy eye highlights.
        if path.stem.startswith("boss_"):
            assert {"BossVisor","BossVisorBridge"} <= face_children, f"{path}: boss visor not bound to head"
        else:
            assert {"FaceEye1","FaceEye-1","FaceBrow"} <= face_children, f"{path}: facial accents not bound to head"
        # Art identity regression: every hero gets class-specific equipment,
        # and every regional enemy must have a recognizable biome silhouette.
        name=path.stem
        if name.startswith("hero_"):
            assert {"HeroBootToe1","HeroBootToe-1","HeroWristBand1","HeroWristBand-1"}<=node_names, f"{path}: missing class armor detail"
            assert any(part in node_names for part in (
                "RoyalGorget","RaiderChestScar","RangerHoodBrow",
                "ForgeChestVent","MageFocusChain"
            )), f"{path}: missing hero class silhouette"
        if name.startswith("enemy_"):
            region=int(name.rsplit("_",1)[-1])
            region_marker=("AshFurnaceSpike1","IceCollar1","DeepSeaChestPearl",
                           "ObsidianRidge1","SkyStormBeacon","NightThroneSeal")[region]
            assert region_marker in node_names, f"{path}: missing biome identity"
        if name.startswith("boss_"):
            assert "BossHeartCore" in node_names, f"{path}: missing emissive boss core"
        # Distal rigid armor must inherit the lower bone transform.
        # A plate left under the shoulder/hip floats during joint flex.
        by_name={node.get("name"):i for i,node in enumerate(gltf["nodes"])}
        for side in ("1","-1"):
            for lower_name,plates in (
                ("Arm"+side+"Lower",("Gauntlet"+side,)),
                ("Leg"+side+"Lower",("ShinPlate"+side,"Boot"+side)),
            ):
                lower_node=gltf["nodes"][by_name[lower_name]]
                child_names={gltf["nodes"][i].get("name") for i in lower_node.get("children",[])}
                assert set(plates)<=child_names, f"{path}: distal armor not attached to {lower_name}"
        # Shoulder plates must be driven by animated upper-arm pivots.
        for side in ("1","-1"):
            pauldron="RoyalShoulder"+side
            if pauldron in by_name:
                upper=gltf["nodes"][by_name["Arm"+side]]
                assert by_name[pauldron] in upper.get("children",[]), f"{path}: {pauldron} not arm-mounted"
        if "RaiderShoulder" in by_name:
            upper=gltf["nodes"][by_name["Arm-1"]]
            assert by_name["RaiderShoulder"] in upper.get("children",[]), f"{path}: raider pauldron not arm-mounted"
        # Extra forge-class knee plates must deform with their shin bones.
        for side in ("1","-1"):
            plate="ForgeKnee"+side
            if plate in by_name:
                lower=gltf["nodes"][by_name["Leg"+side+"Lower"]]
                assert by_name[plate] in lower.get("children",[]), f"{path}: {plate} not attached to lower leg"
        # The authored weapon must be parented to the animated wrist.
        right_children={gltf["nodes"][i].get("name") for i in gltf["nodes"][by_name["Arm1Lower"]].get("children",[])}
        assert "WeaponGrip" in right_children, f"{path}: weapon grip not attached to wrist"
        assert any(name in right_children for name in (
            "BossRelicBlade","EnemyBasicBlade","RoyalLongsword",
            "RaiderAxeHead","RangerBowStave","ForgeHammerHead",
            "MageCrystal","KnightLance","KingGreatblade"
        )), f"{path}: authored weapon geometry not attached to wrist"
        for skin_index,skin_data in enumerate(gltf["skins"]):
            assert len(skin_data["joints"])==2, f"{path}: skin {skin_index} must use two joints"
            ibm_accessor=gltf["accessors"][skin_data["inverseBindMatrices"]]
            assert ibm_accessor["type"]=="MAT4" and ibm_accessor["count"]==2, f"{path}: skin {skin_index} invalid inverse binds"
            ibm_view=gltf["bufferViews"][ibm_accessor["bufferView"]]
            ibm_start=json_end+8+ibm_view.get("byteOffset",0)+ibm_accessor.get("byteOffset",0)
            inverse_matrices=struct.unpack_from("<32f",data,ibm_start)
            for joint_position,joint_index in enumerate(skin_data["joints"]):
                matrix=inverse_matrices[joint_position*16:(joint_position+1)*16]
                rest=world_rest_translation(joint_index)
                assert all(abs(matrix[12+axis]+rest[axis])<1e-4 for axis in range(3)), f"{path}: skin {skin_index} inverse bind disagrees with joint rest pose"
                assert all(abs(matrix[i]-1)<1e-5 for i in (0,5,10,15)), f"{path}: skin {skin_index} invalid bind matrix diagonal"
        # glTF skinning requires compatible per-vertex attributes on every
        # primitive of every mesh referenced by a skin node.
        for node in gltf["nodes"]:
            if "skin" not in node:
                continue
            assert "mesh" in node and 0<=node["skin"]<len(gltf["skins"]), f"{path}: skinned node missing valid mesh/skin"
            for primitive in gltf["meshes"][node["mesh"]]["primitives"]:
                attrs=primitive["attributes"]
                assert {"POSITION","NORMAL","JOINTS_0","WEIGHTS_0"}.issubset(attrs), f"{path}: skinned mesh lacks vertex attributes"
                counts=[gltf["accessors"][attrs[key]]["count"] for key in ("POSITION","NORMAL","JOINTS_0","WEIGHTS_0")]
                assert len(set(counts))==1, f"{path}: skin attribute vertex count mismatch"
                assert gltf["accessors"][attrs["JOINTS_0"]]["type"]=="VEC4", f"{path}: joints must be VEC4"
                assert gltf["accessors"][attrs["WEIGHTS_0"]]["type"]=="VEC4", f"{path}: weights must be VEC4"
                positions=unpack_accessor(attrs["POSITION"])
                normals=unpack_accessor(attrs["NORMAL"])
                weights=unpack_accessor(attrs["WEIGHTS_0"])
                joints=unpack_accessor(attrs["JOINTS_0"])
                joint_count=len(gltf["skins"][node["skin"]]["joints"])
                assert all(all(math.isfinite(value) for value in vertex) for vertex in positions), f"{path}: nonfinite skinned position"
                assert all(abs(sum(value*value for value in normal)-1)<1e-3 for normal in normals), f"{path}: nonunit skinned normal"
                assert all(all(math.isfinite(value) and 0<=value<=1 for value in row) and abs(sum(row)-1)<1e-4 for row in weights), f"{path}: invalid skinned weights"
                assert all(all(0<=value<joint_count for value in row) for row in joints), f"{path}: skinned vertex references invalid bone"
        skinned=[node for node in gltf["nodes"] if "skin" in node]
        assert len(skinned)==6 and {node["skin"] for node in skinned}==set(range(6)), f"{path}: missing skinned character meshes"
        assert {node.get("name") for node in skinned}=={"SkinnedCape","SkinnedTorso","Arm1Mesh","Arm-1Mesh","Leg1Mesh","Leg-1Mesh"}, f"{path}: unexpected skinned geometry"
        torso_skin=gltf["skins"][1]
        assert len(torso_skin["joints"])==2, f"{path}: torso must use two bones"
        assert [gltf["nodes"][i].get("name") for i in torso_skin["joints"]]==["SpineHip","SpineChest"], f"{path}: missing torso skeleton bones"
        torso_ibm=gltf["accessors"][torso_skin["inverseBindMatrices"]]
        assert torso_ibm["type"]=="MAT4" and torso_ibm["count"]==2, f"{path}: invalid torso inverse bind matrices"
        torso_node=next(node for node in skinned if node["skin"]==1)
        torso_primitive=gltf["meshes"][torso_node["mesh"]]["primitives"][0]
        assert {"POSITION","NORMAL","JOINTS_0","WEIGHTS_0"}.issubset(torso_primitive["attributes"]), f"{path}: missing torso skin vertex streams"
        cape_node=next(node for node in skinned if node["skin"]==0 and node.get("name")=="SkinnedCape")
        cape=gltf["meshes"][cape_node["mesh"]]["primitives"][0]
        assert {"JOINTS_0","WEIGHTS_0","NORMAL","POSITION"}.issubset(cape["attributes"]), f"{path}: missing skinning vertex streams"
        joints_acc=gltf["accessors"][cape["attributes"]["JOINTS_0"]]
        weights_acc=gltf["accessors"][cape["attributes"]["WEIGHTS_0"]]
        assert joints_acc["type"]=="VEC4" and joints_acc["componentType"] in (5121,5123), f"{path}: invalid joint indices"
        assert weights_acc["type"]=="VEC4" and weights_acc["componentType"]==5126, f"{path}: invalid vertex weights"
        assert joints_acc["count"]==weights_acc["count"]==24, f"{path}: skinning vertex count mismatch"
        def decode_attribute(accessor_index):
            acc=gltf["accessors"][accessor_index]
            view=gltf["bufferViews"][acc["bufferView"]]
            start=json_end+8+view.get("byteOffset",0)+acc.get("byteOffset",0)
            width=COMPONENTS[acc["type"]]
            fmt={5121:"B",5123:"H",5126:"f"}[acc["componentType"]]
            values=struct.unpack_from("<"+fmt*(acc["count"]*width),data,start)
            return [values[i:i+width] for i in range(0,len(values),width)]
        skin_weights=decode_attribute(cape["attributes"]["WEIGHTS_0"])
        skin_joints=decode_attribute(cape["attributes"]["JOINTS_0"])
        assert all(abs(sum(row)-1.0)<1e-5 and all(0<=w<=1 for w in row) for row in skin_weights), f"{path}: invalid normalized skin weights"
        assert all(all(j<len(skin["joints"]) for j in row) for row in skin_joints), f"{path}: skin joint index out of range"
        assert any(.05<row[1]<.95 for row in skin_weights), f"{path}: cloth does not actually blend two bones"
        torso_weights=decode_attribute(torso_primitive["attributes"]["WEIGHTS_0"])
        torso_joints=decode_attribute(torso_primitive["attributes"]["JOINTS_0"])
        assert len(torso_weights)==len(torso_joints)==40, f"{path}: missing tapered torso middle ring"
        torso_positions=decode_attribute(torso_primitive["attributes"]["POSITION"])
        torso_normals=decode_attribute(torso_primitive["attributes"]["NORMAL"])
        torso_triangles=decode_attribute(torso_primitive["indices"])
        assert len(torso_positions)==len(torso_normals)==40 and len(torso_triangles)==60, f"{path}: incorrect tapered torso geometry"
        assert any(abs(row[1]-.5)<1e-5 for row in torso_weights), f"{path}: missing spine mid-ring blending"
        assert max(row[0] for row in torso_positions)>0.22 and min(row[0] for row in torso_positions)<-0.22, f"{path}: missing shoulder breadth"
        assert all(abs(sum(x*x for x in normal)-1)<1e-3 for normal in torso_normals), f"{path}: invalid tapered torso normals"
        assert all(abs(sum(row)-1)<1e-5 for row in torso_weights), f"{path}: torso weights are not normalized"
        assert all(all(j<2 for j in row) for row in torso_joints), f"{path}: torso joint index out of range"
        assert any(.05<row[1]<.95 for row in torso_weights), f"{path}: torso does not blend between bones"
        inverse_matrices=decode_attribute(skin["inverseBindMatrices"])
        assert all(abs(row[15]-1)<1e-6 and all(math.isfinite(v) for v in row) for row in inverse_matrices), f"{path}: invalid inverse bind matrices"
        assert "Head" in node_names, f"{path}: missing animated neck pivot"
        head_joint=next(node for node in gltf["nodes"] if node.get("name")=="Head")
        head_children=[gltf["nodes"][index].get("name","") for index in head_joint.get("children",[])]
        assert "HeadMesh" in head_children and "BrowRidge" in head_children, f"{path}: face does not follow head pivot"
        assert any(name.startswith("Eye") for name in head_children), f"{path}: eyes not attached to animated head"
        assert {"Arm1","Arm-1","Leg1","Leg-1"}.issubset(node_names), f"{path}: missing independent limbs"
        for joint_name in ("Arm1","Arm-1","Leg1","Leg-1"):
            joint_index = next(i for i,node in enumerate(gltf["nodes"]) if node.get("name")==joint_name)
            joint = gltf["nodes"][joint_index]
            assert "mesh" not in joint and len(joint.get("children",[])) >= 1, f"{path}: {joint_name} must be an articulated pivot"
            assert any(gltf["nodes"][child].get("name")==joint_name+"Lower" for child in joint["children"]), f"{path}: missing elbow/knee bone"
            limb_mesh=next(node for node in skinned if node.get("name")==joint_name+"Mesh")
            assert "mesh" in limb_mesh and limb_mesh["skin"]>=2, f"{path}: missing deformable limb surface"
            limb_skin=gltf["skins"][limb_mesh["skin"]]
            assert len(limb_skin["joints"])==2 and limb_skin["joints"][0]==joint_index, f"{path}: invalid limb skeleton"
            limb_primitive=gltf["meshes"][limb_mesh["mesh"]]["primitives"][0]
            assert {"POSITION","NORMAL","JOINTS_0","WEIGHTS_0"}.issubset(limb_primitive["attributes"]), f"{path}: missing weighted limb geometry"
            limb_weights=decode_attribute(limb_primitive["attributes"]["WEIGHTS_0"])
            limb_joints=decode_attribute(limb_primitive["attributes"]["JOINTS_0"])
            assert len(limb_weights)==len(limb_joints)==40, f"{path}: missing subdivided elbow/knee vertex ring"
            limb_positions=decode_attribute(limb_primitive["attributes"]["POSITION"])
            limb_indices=decode_attribute(limb_primitive["indices"])
            assert len(limb_positions)==40 and len(limb_indices)==60, f"{path}: expected 40 vertices / 20 triangles per deforming limb"
            ring_levels=sorted({round(vertex[1],5) for vertex in limb_positions})
            assert len(ring_levels)==3, f"{path}: missing geometric elbow/knee ring"
            ring_widths=[]
            for level in ring_levels:
                ring_vertices=[vertex for vertex in limb_positions if abs(vertex[1]-level)<1e-4]
                ring_widths.append(max(vertex[0] for vertex in ring_vertices)-min(vertex[0] for vertex in ring_vertices))
            assert ring_widths[0]<ring_widths[1]<ring_widths[2], f"{path}: untapered limb silhouette"
            assert any(abs(weights[1]-.5)<1e-5 for weights in limb_weights), f"{path}: missing balanced elbow/knee ring weights"
            assert all(abs(sum(weights)-1)<1e-5 for weights in limb_weights), f"{path}: nonnormalized limb skin weights"
            assert all(all(0<=joint<2 for joint in joints) for joints in limb_joints), f"{path}: invalid limb skin joint index"
            assert any(.05<weights[1]<.95 for weights in limb_weights), f"{path}: missing blended elbow/knee vertices"
            limb_inverse=gltf["accessors"][limb_skin["inverseBindMatrices"]]
            assert limb_inverse["type"]=="MAT4" and limb_inverse["count"]==2, f"{path}: missing limb bind matrices"
            expected_gear = ("Gauntlet" if joint_name.startswith("Arm") else "ShinPlate") + joint_name.replace("Arm","").replace("Leg","")
            lower_joint_index = limb_skin["joints"][1]
            assert lower_joint_index in joint["children"], f"{path}: lower limb bone must descend from upper pivot"
            attached = [gltf["nodes"][i].get("name") for i in gltf["nodes"][lower_joint_index].get("children", [])]
            assert expected_gear in attached, f"{path}: {expected_gear} must follow animated lower limb"
    for animation in gltf.get("animations",[]):
        channels = animation["channels"]
        assert any(channel["target"]["path"] == "translation" for channel in channels), f"{path}: missing root motion"
        assert any(channel["target"]["path"] == "rotation" and gltf["nodes"][channel["target"]["node"]]["name"]=="BodyRig" for channel in channels), f"{path}: missing full-body lean animation"
        if require_animation:
            assert any(channel["target"]["path"]=="rotation" and gltf["nodes"][channel["target"]["node"]]["name"]=="CapeHem" for channel in channels), f"{path}: missing skinned mantle sway track"
            assert any(channel["target"]["path"]=="rotation" and gltf["nodes"][channel["target"]["node"]]["name"]=="Head" for channel in channels), f"{path}: missing head animation"
            assert any(channel["target"]["path"]=="rotation" and gltf["nodes"][channel["target"]["node"]]["name"]=="SpineChest" for channel in channels), f"{path}: missing animated skinned torso chest"
            for limb_name in ("Arm1","Arm-1","Leg1","Leg-1"):
                assert any(channel["target"]["path"]=="rotation" and gltf["nodes"][channel["target"]["node"]]["name"]==limb_name+"Lower" for channel in channels), f"{path}: missing animated elbow/knee {limb_name}"
        assert any(channel["target"]["path"] == "rotation" and gltf["nodes"][channel["target"]["node"]]["name"].startswith("Arm") for channel in channels), f"{path}: missing arm animation in {animation['name']}"
        if animation["name"] in ("move","death"):
            assert any(channel["target"]["path"] == "rotation" and gltf["nodes"][channel["target"]["node"]]["name"].startswith("Leg") for channel in channels), f"{path}: missing leg animation in {animation['name']}"
    assert len(gltf["nodes"]) >= (12 if require_animation else 3), f"{path}: no geometry nodes"
    # Mobile budget: no runaway geometry, uncompressed GLB, or excessive nodes.
    assert len(data) < 250_000, f"{path}: GLB exceeds 250KB blockout budget"
    assert len(gltf["nodes"]) <= 160, f"{path}: excessive draw-call nodes"
    assert all(material.get("doubleSided",False) is False for material in gltf["materials"]), f"{path}: avoid mobile two-sided material overdraw"
    assert all("pbrMetallicRoughness" in material for material in gltf["materials"]), f"{path}: missing PBR material"
    triangles=0
    for mesh in gltf["meshes"]:
        for primitive in mesh["primitives"]:
            attrs=primitive["attributes"]
            assert "POSITION" in attrs and "NORMAL" in attrs, f"{path}: missing flat-shading normals"
            position=gltf["accessors"][attrs["POSITION"]]
            normal=gltf["accessors"][attrs["NORMAL"]]
            expected_vertices=(96 if mesh.get("name","").startswith("Beveled") else (40 if mesh.get("name","").endswith("DeformingSurface") or mesh.get("name")=="DeformingTorso" else 24))
            assert position["count"]==normal["count"]==expected_vertices, f"{path}: {mesh.get('name')} expected {expected_vertices} vertices"
            assert position["type"]=="VEC3" and normal["type"]=="VEC3", f"{path}: invalid vertex attribute type"
            index=gltf["accessors"][primitive["indices"]]
            expected_indices=132 if expected_vertices==96 else (60 if expected_vertices==40 else 36)
            assert index["count"]==expected_indices and index["type"]=="SCALAR", f"{path}: {mesh.get('name')} expected {expected_indices} indices"
            triangles += index["count"] // 3
    # Verify triangle winding agrees with supplied outward normals; otherwise
    # backface culling can make entire faces disappear in Godot.
    def read_accessor(index):
        accessor=gltf["accessors"][index]
        view=gltf["bufferViews"][accessor["bufferView"]]
        offset=json_end+8+view.get("byteOffset",0)+accessor.get("byteOffset",0)
        component=accessor["componentType"]
        width=COMPONENTS[accessor["type"]]
        code={5121:"B",5126:"f",5123:"H",5125:"I"}[component]
        values=struct.unpack_from("<"+code*(accessor["count"]*width),data,offset)
        return [values[i:i+width] for i in range(0,len(values),width)]
    # Inspect every unique geometry primitive, including the new tapered
    # skinned cloth. Tiny bevel/cloth faces have a much smaller area than
    # the unit cube, so compare orientation rather than arbitrary area.
    checked=set()
    for mesh in gltf["meshes"]:
        for primitive in mesh["primitives"]:
            key=(primitive["attributes"]["POSITION"],primitive["attributes"]["NORMAL"],primitive["indices"])
            if key in checked: continue
            checked.add(key)
            verts=read_accessor(key[0])
            normals=read_accessor(key[1])
            indices=[value[0] for value in read_accessor(key[2])]
            for i in range(0,len(indices),3):
                a,b,c=(verts[indices[i+j]] for j in range(3))
                u=[b[j]-a[j] for j in range(3)]
                v=[c[j]-a[j] for j in range(3)]
                cross=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])
                normal=normals[indices[i]]
                assert sum(cross[j]*normal[j] for j in range(3))>1e-6, f"{path}: triangle winding opposes face normal"
    # Each mesh is instanced by nodes; estimate actual rendered triangle load.
    estimated_triangles=sum(sum(gltf["accessors"][p["indices"]]["count"]//3 for p in gltf["meshes"][node["mesh"]]["primitives"]) for node in gltf["nodes"] if "mesh" in node)
    # Chamfered rigid meshes improve silhouettes. Budget is 6k triangles per
    # character including the new 30-hero/36-enemy/6-boss ornament pass.
    assert estimated_triangles <= 6000, f"{path}: excessive mobile triangle count {estimated_triangles}"
    for node in gltf["nodes"]:
        if "mesh" in node:
            assert 0 <= node["mesh"] < len(gltf["meshes"])
    return len(gltf["nodes"])

def main():
    counts=[]
    for name in EXPECTED:
        path = ART / name
        assert path.is_file(), f"missing {path}"
        counts.append(validate(path))
    assert len(counts) == 72
    # Hero IDs must retain their canonical chess-role silhouette markers.
    role_by_id = {
        1:"K",2:"N",3:"B",4:"R",5:"P",6:"Q",7:"N",8:"R",9:"B",10:"K",
        11:"N",12:"R",13:"Q",14:"B",15:"N",16:"R",17:"Q",18:"B",19:"B",20:"N",
        21:"K",22:"Q",23:"Q",24:"K",25:"N",26:"B",27:"Q",28:"N",29:"R",30:"K",
    }
    role_markers={"K":"KingCrownProng","Q":"QueenDiadem","R":"RookBattlement","B":"BishopMitre","N":"KnightWing","P":"PawnBanner"}
    for hero_id,role in role_by_id.items():
        data=(ART / f"hero_{hero_id:02d}.glb").read_bytes()
        json_size=struct.unpack_from("<I",data,12)[0]
        hero_gltf=json.loads(data[20:20+json_size])
        assert any(node.get("name","").startswith(role_markers[role]) for node in hero_gltf["nodes"]), f"hero_{hero_id:02d}: missing {role} class heraldry"
    boss_landmarks=("EmberHorn", "GlacierSpire", "ThornBranch", "RunicTablet", "AstralWing", "CrimsonWing")
    for region, landmark in enumerate(boss_landmarks):
        data=(ART / f"boss_region_{region}.glb").read_bytes()
        json_size=struct.unpack_from("<I",data,12)[0]
        boss_gltf=json.loads(data[20:20+json_size])
        assert any(node.get("name","").startswith(landmark) for node in boss_gltf["nodes"]), f"boss {region}: missing {landmark} silhouette"
    # Production readability contracts: each of the 72 rigged figures must
    # have recognizable physical geometry, not only differently tinted PBR.
    identity_signatures = set()
    for hero_id in range(1,31):
        path = ART / f"hero_{hero_id:02d}.glb"
        data = path.read_bytes()
        length = struct.unpack_from("<I",data,12)[0]
        gltf = json.loads(data[20:20+length])
        names = {node.get("name","") for node in gltf["nodes"]}
        signature_names = tuple(sorted(name for name in names if name.startswith("Identity")))
        assert any(name.startswith("IdentityBadge_") for name in signature_names), f"{path}: missing personal badge"
        assert "IdentityBeltBuckle" in names and "IdentityBackBanner" in names, f"{path}: missing layered outfit"
        assert any(name.startswith(("IdentitySun","IdentityScout","IdentityOracle","IdentityVeteran","IdentityMoon","IdentityAscendant")) for name in names), f"{path}: missing head signature"
        assert signature_names not in identity_signatures, f"{path}: duplicate hero identity geometry"
        identity_signatures.add(signature_names)
    role_markers_new = {
        "p":"EnemyPawnHood", "r":"EnemyRookTower",
        "n":"EnemyKnightLance", "b":"EnemyBishopMitre",
        "q":"EnemyQueenScepter", "k":"EnemyKingCrown"
    }
    for region in range(6):
        for role, marker in role_markers_new.items():
            path = ART / f"enemy_{role}_region_{region}.glb"
            data = path.read_bytes()
            length = struct.unpack_from("<I",data,12)[0]
            gltf = json.loads(data[20:20+length])
            assert any(node.get("name","").startswith(marker) for node in gltf["nodes"]), f"{path}: missing chess role silhouette {marker}"
        path = ART / f"boss_region_{region}.glb"
        data = path.read_bytes()
        length = struct.unpack_from("<I",data,12)[0]
        gltf = json.loads(data[20:20+length])
        names = {node.get("name","") for node in gltf["nodes"]}
        assert f"BossHeartCore_{region+1}" in names, f"{path}: missing biome boss heart core"
        assert sum(name.startswith("BossCrownShard_") for name in names) == 4+region, f"{path}: missing boss crown shards"
    print("KINGDOM CHESS: 30 UNIQUE HERO SIGNATURES, 36 ENEMY CLASS SILHOUETTES AND 6 BOSS CROWNS VALIDATED")
    equipment_dir = ROOT / "assets" / "equipment"
    for slot in ("weapon","armor","relic"):
        shapes = set()
        for tier in range(7):
            path = equipment_dir / f"{slot}_tier_{tier}.glb"
            assert path.is_file(), f"missing {path}"
            validate(path, require_animation=False)
            data=path.read_bytes()
            chunk_size=struct.unpack_from("<I",data,12)[0]
            gltf=json.loads(data[20:20+chunk_size])
            names=tuple(node["name"] for node in gltf["nodes"])
            # Verify layered geometry on all 21 equipment variants,
            # including non-enchanted early items and premium silhouettes.
            expected_base = {
                "weapon": ("WeaponPommel", "WeaponCrossguard"),
                "armor": ("ArmorGorget", "ArmorCenterSeal", "ArmorRibPlate-1", "ArmorRibPlate1"),
                "relic": ("RelicSocket", "RelicWing-1", "RelicWing1"),
            }[slot]
            assert all(part in names for part in expected_base), f"{path}: missing sculpted equipment details"
            if tier>=4:
                assert (slot.capitalize()+"PowerCrystal") in names, f"{path}: missing premium core"
            if tier==6:
                assert any("Ascendant" in name for name in names), f"{path}: final rarity missing ascendant silhouette"
            crystals=[name for name in names if "Crystal" in name]
            assert bool(crystals)==(tier>=4), f"{path}: enchanted crystal progression incorrect"
            assert len(gltf["materials"])>=3 and "emissiveFactor" in gltf["materials"][2], f"{path}: missing enchantment shader"
            assert names not in shapes, f"{path}: duplicate equipment geometry"
            shapes.add(names)
    print("KINGDOM CHESS: 21 EQUIPMENT GLB FILES VALIDATED")
    assert len(set(counts[:30])) > 1, "all heroes have identical node counts"
    print(f"KINGDOM CHESS: 72 GLB FILES VALIDATED, {len(set(counts[:30]))} HERO MESH COUNTS")

if __name__ == "__main__":
    main()
