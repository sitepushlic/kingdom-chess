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
    for acc in gltf["accessors"]:
        view = gltf["bufferViews"][acc["bufferView"]]
        byte_len = acc["count"] * COMPONENT_SIZE[acc["componentType"]] * COMPONENTS[acc["type"]]
        assert acc.get("byteOffset",0) + byte_len <= view["byteLength"], f"{path}: accessor overflow"
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
    for animation in gltf.get("animations",[]):
        assert animation.get("samplers") and animation.get("channels"), f"{path}: empty animation"
        for channel in animation["channels"]:
            assert 0 <= channel["sampler"] < len(animation["samplers"]), f"{path}: bad sampler index"
            assert 0 <= channel["target"]["node"] < node_count, f"{path}: bad animation target"
            assert channel["target"]["path"] in ("translation","rotation","scale"), f"{path}: unsupported target"
        for sampler in animation["samplers"]:
            input_acc=gltf["accessors"][sampler["input"]]
            output_acc=gltf["accessors"][sampler["output"]]
            assert input_acc["type"]=="SCALAR" and input_acc["componentType"]==5126, f"{path}: invalid animation timeline"
            assert output_acc["count"]==input_acc["count"], f"{path}: animation keyframe count mismatch"
            assert input_acc["count"]>=2, f"{path}: animation must have multiple keyframes"
            if "max" in input_acc:
                assert math.isfinite(input_acc["max"][0]) and input_acc["max"][0]>0, f"{path}: invalid duration"
    names = {a["name"] for a in gltf.get("animations",[])}
    if require_animation:
        assert CLIPS.issubset(names), f"{path}: missing clips {CLIPS - names}"
    node_names = {node.get("name") for node in gltf["nodes"]}
    if require_animation:
        assert {"Arm1","Arm-1","Leg1","Leg-1"}.issubset(node_names), f"{path}: missing independent limbs"
        for joint_name in ("Arm1","Arm-1","Leg1","Leg-1"):
            joint_index = next(i for i,node in enumerate(gltf["nodes"]) if node.get("name")==joint_name)
            joint = gltf["nodes"][joint_index]
            assert "mesh" not in joint and len(joint.get("children",[])) >= 2, f"{path}: {joint_name} must be a pivot with attached armor"
            child = gltf["nodes"][joint["children"][0]]
            assert child.get("name") == joint_name+"Mesh" and "mesh" in child, f"{path}: {joint_name} must own limb mesh"
            expected_gear = ("Gauntlet" if joint_name.startswith("Arm") else "ShinPlate") + joint_name.replace("Arm","").replace("Leg","")
            attached = [gltf["nodes"][i].get("name") for i in joint["children"]]
            assert expected_gear in attached, f"{path}: {expected_gear} must follow animated limb"
    for animation in gltf.get("animations",[]):
        channels = animation["channels"]
        assert any(channel["target"]["path"] == "translation" for channel in channels), f"{path}: missing root motion"
        assert any(channel["target"]["path"] == "rotation" and gltf["nodes"][channel["target"]["node"]]["name"]=="BodyRig" for channel in channels), f"{path}: missing full-body lean animation"
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
            assert position["count"]==24 and normal["count"]==24, f"{path}: expected 24 independent face vertices"
            assert position["type"]=="VEC3" and normal["type"]=="VEC3", f"{path}: invalid vertex attribute type"
            index=gltf["accessors"][primitive["indices"]]
            assert index["count"]==36 and index["type"]=="SCALAR", f"{path}: expected 12 cube triangles"
            triangles += index["count"] // 3
    # Verify triangle winding agrees with supplied outward normals; otherwise
    # backface culling can make entire faces disappear in Godot.
    first_primitive=gltf["meshes"][0]["primitives"][0]
    def read_accessor(index):
        accessor=gltf["accessors"][index]
        view=gltf["bufferViews"][accessor["bufferView"]]
        offset=json_end+8+view.get("byteOffset",0)+accessor.get("byteOffset",0)
        component=accessor["componentType"]
        width=COMPONENTS[accessor["type"]]
        code={5126:"f",5123:"H",5125:"I"}[component]
        values=struct.unpack_from("<"+code*(accessor["count"]*width),data,offset)
        return [values[i:i+width] for i in range(0,len(values),width)]
    verts=read_accessor(first_primitive["attributes"]["POSITION"])
    normals=read_accessor(first_primitive["attributes"]["NORMAL"])
    indices=[value[0] for value in read_accessor(first_primitive["indices"])]
    for i in range(0,len(indices),3):
        a,b,c=(verts[indices[i+j]] for j in range(3))
        u=[b[j]-a[j] for j in range(3)]
        v=[c[j]-a[j] for j in range(3)]
        cross=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])
        normal=normals[indices[i]]
        assert sum(cross[j]*normal[j] for j in range(3))>0.1, f"{path}: triangle winding opposes face normal"
    # Each mesh is instanced by nodes; estimate actual rendered triangle load.
    estimated_triangles=sum(sum(gltf["accessors"][p["indices"]]["count"]//3 for p in gltf["meshes"][node["mesh"]]["primitives"]) for node in gltf["nodes"] if "mesh" in node)
    assert estimated_triangles <= 2000, f"{path}: excessive mobile triangle count {estimated_triangles}"
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
