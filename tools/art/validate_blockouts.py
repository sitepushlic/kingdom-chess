#!/usr/bin/env python3
"""Validate all generated GLB files without third-party dependencies."""
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "assets" / "characters"
EXPECTED = [f"hero_{n:02d}.glb" for n in range(1,31)] + [f"boss_region_{n}.glb" for n in range(6)]
CLIPS = {"idle","move","attack","hit","death","cast"}
COMPONENT_SIZE = {5120:1,5121:1,5122:2,5123:2,5125:4,5126:4}
COMPONENTS = {"SCALAR":1,"VEC2":2,"VEC3":3,"VEC4":4,"MAT4":16}

def validate(path):
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
    assert CLIPS.issubset(names), f"{path}: missing clips {CLIPS - names}"
    assert len(gltf["nodes"]) >= 12, f"{path}: no geometry nodes"
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
    assert len(counts) == 36
    assert len(set(counts[:30])) > 1, "all heroes have identical node counts"
    print(f"KINGDOM CHESS: 36 GLB FILES VALIDATED, {len(set(counts[:30]))} HERO MESH COUNTS")

if __name__ == "__main__":
    main()
