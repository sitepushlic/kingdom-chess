#!/usr/bin/env python3
"""Validate the actual generated weighted elbow/knee topology, no Godot needed."""
import json
import math
import struct
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
ASSETS=ROOT/"assets"/"characters"

def inspect(path):
    data=path.read_bytes()
    json_size=struct.unpack_from("<I",data,12)[0]
    gltf=json.loads(data[20:20+json_size])
    binary_start=20+json_size+8
    def read(index):
        acc=gltf["accessors"][index]
        view=gltf["bufferViews"][acc["bufferView"]]
        start=binary_start+view.get("byteOffset",0)+acc.get("byteOffset",0)
        width={"SCALAR":1,"VEC3":3,"VEC4":4}[acc["type"]]
        fmt={5121:"B",5123:"H",5126:"f"}[acc["componentType"]]
        flat=struct.unpack_from("<"+fmt*(width*acc["count"]),data,start)
        return [flat[i:i+width] for i in range(0,len(flat),width)]
    for limb in ("Torso","Arm1","Arm-1","Leg1","Leg-1"):
        node_name="SkinnedTorso" if limb=="Torso" else limb+"Mesh"
        node=next(n for n in gltf["nodes"] if n.get("name")==node_name)
        primitive=gltf["meshes"][node["mesh"]]["primitives"][0]
        vertices=read(primitive["attributes"]["POSITION"])
        normals=read(primitive["attributes"]["NORMAL"])
        weights=read(primitive["attributes"]["WEIGHTS_0"])
        indices=[x[0] for x in read(primitive["indices"])]
        assert len(vertices)==len(normals)==len(weights)==40, f"{path}: {limb} missing middle ring"
        assert len(indices)==60, f"{path}: {limb} wrong triangle count"
        assert len({round(w[1],2) for w in weights})==3, f"{path}: {limb} missing blended joint band"
        if limb=="Torso":
            xs=[p[0] for p in vertices]
            assert max(xs)>.22 and min(xs)<-.22, f"{path}: missing tapered shoulders"
            waist=[abs(p[0]) for p in vertices if abs(p[1]-.61)<1e-4]
            assert waist and max(waist)<.17, f"{path}: missing tapered waist"
        for t in range(0,len(indices),3):
            a,b,c=(vertices[indices[t+i]] for i in range(3))
            u=[b[i]-a[i] for i in range(3)]
            v=[c[i]-a[i] for i in range(3)]
            cross=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])
            normal=normals[indices[t]]
            assert sum(cross[i]*normal[i] for i in range(3))>1e-8, f"{path}: {limb} inward or degenerate triangle {t//3}"
        assert all(abs(sum(w)-1)<1e-5 for w in weights), f"{path}: {limb} invalid weights"

def main():
    paths=sorted(ASSETS.glob("hero_*.glb"))+sorted(ASSETS.glob("enemy_*.glb"))+sorted(ASSETS.glob("boss_region_*.glb"))
    assert len(paths)==72, f"Expected 72 characters, found {len(paths)}"
    for path in paths:
        inspect(path)
    print(f"Validated {len(paths)*4} subdivided limbs and {len(paths)} tapered torsos: outward winding, 3 weighted rings, 20 triangles each")

if __name__=="__main__":
    main()
