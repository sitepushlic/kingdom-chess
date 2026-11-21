#!/usr/bin/env python3
"""Validate all generated GLB files without third-party dependencies."""
import json
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
        assert view.get("byteOffset",0) + view["byteLength"] <= bin_size, f"{path}: buffer view overflow"
    for acc in gltf["accessors"]:
        view = gltf["bufferViews"][acc["bufferView"]]
        byte_len = acc["count"] * COMPONENT_SIZE[acc["componentType"]] * COMPONENTS[acc["type"]]
        assert acc.get("byteOffset",0) + byte_len <= view["byteLength"], f"{path}: accessor overflow"
    names = {a["name"] for a in gltf.get("animations",[])}
    if require_animation:
        assert CLIPS.issubset(names), f"{path}: missing clips {CLIPS - names}"
    node_names = {node.get("name") for node in gltf["nodes"]}
    if require_animation:
        assert {"Arm1","Arm-1","Leg1","Leg-1"}.issubset(node_names), f"{path}: missing independent limbs"
        for joint_name in ("Arm1","Arm-1","Leg1","Leg-1"):
            joint_index = next(i for i,node in enumerate(gltf["nodes"]) if node.get("name")==joint_name)
            joint = gltf["nodes"][joint_index]
            assert "mesh" not in joint and len(joint.get("children",[])) == 1, f"{path}: {joint_name} must be a pivot"
            child = gltf["nodes"][joint["children"][0]]
            assert child.get("name") == joint_name+"Mesh" and "mesh" in child, f"{path}: {joint_name} must own limb mesh"
    for animation in gltf.get("animations",[]):
        channels = animation["channels"]
        assert any(channel["target"]["path"] == "translation" for channel in channels), f"{path}: missing root motion"
        assert any(channel["target"]["path"] == "rotation" and gltf["nodes"][channel["target"]["node"]]["name"].startswith("Arm") for channel in channels), f"{path}: missing arm animation in {animation['name']}"
        if animation["name"] in ("move","death"):
            assert any(channel["target"]["path"] == "rotation" and gltf["nodes"][channel["target"]["node"]]["name"].startswith("Leg") for channel in channels), f"{path}: missing leg animation in {animation['name']}"
    assert len(gltf["nodes"]) >= (12 if require_animation else 3), f"{path}: no geometry nodes"
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
            assert names not in shapes, f"{path}: duplicate equipment geometry"
            shapes.add(names)
    print("KINGDOM CHESS: 21 EQUIPMENT GLB FILES VALIDATED")
    assert len(set(counts[:30])) > 1, "all heroes have identical node counts"
    print(f"KINGDOM CHESS: 72 GLB FILES VALIDATED, {len(set(counts[:30]))} HERO MESH COUNTS")

if __name__ == "__main__":
    main()
