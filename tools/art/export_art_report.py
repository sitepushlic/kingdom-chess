#!/usr/bin/env python3
"""Produce a machine-readable manifest of every generated 3D asset.

Intended for CI/art review: hashes, mesh complexity, animation names, materials
and geometry signatures are computed from the actual GLB bytes, not estimates.
"""
import hashlib
import json
import struct
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"build"
OUT.mkdir(parents=True,exist_ok=True)
entries=[]
for folder in ("characters","equipment"):
    for path in sorted((ROOT/"assets"/folder).glob("*.glb")):
        data=path.read_bytes()
        json_size=struct.unpack_from("<I",data,12)[0]
        gltf=json.loads(data[20:20+json_size])
        meshes=gltf.get("meshes",[])
        nodes=gltf.get("nodes",[])
        triangles=0
        for node in nodes:
            if "mesh" not in node:
                continue
            mesh=meshes[node["mesh"]]
            triangles+=sum(gltf["accessors"][p["indices"]]["count"]//3 for p in mesh["primitives"])
        entries.append({
            "asset":str(path.relative_to(ROOT)),
            "sha256":hashlib.sha256(data).hexdigest(),
            "bytes":len(data),
            "nodes":len(nodes),
            "triangles":triangles,
            "materials":[m.get("name","") for m in gltf.get("materials",[])],
            "animations":[a.get("name","") for a in gltf.get("animations",[])],
            "geometry_signature":[node.get("name","") for node in nodes if "mesh" in node],
        })
assert len(entries)==93, f"Expected 93 GLBs, found {len(entries)}"
report={
    "format":"kingdom-chess-art-report-v1",
    "asset_count":len(entries),
    "total_bytes":sum(e["bytes"] for e in entries),
    "total_triangles":sum(e["triangles"] for e in entries),
    "max_asset_triangles":max(e["triangles"] for e in entries),
    "assets":entries,
}
(OUT/"art_manifest.json").write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n")
print(f"ART MANIFEST: {report['asset_count']} GLBs, {report['total_bytes']} bytes, {report['total_triangles']} aggregate triangles")
