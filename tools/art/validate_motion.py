#!/usr/bin/env python3
"""Check the semantic content of generated glTF motion, not just clip names."""
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "assets" / "characters"

def load(path):
    data=path.read_bytes()
    json_size=struct.unpack_from("<I",data,12)[0]
    doc=json.loads(data[20:20+json_size])
    bin_start=20+json_size+8
    return doc,data,bin_start

def values(doc,data,base,index):
    acc=doc["accessors"][index]
    view=doc["bufferViews"][acc["bufferView"]]
    count=acc["count"]
    width={"SCALAR":1,"VEC3":3,"VEC4":4,"MAT4":16}[acc["type"]]
    fmt={5126:"f",5123:"H",5121:"B"}[acc["componentType"]]
    start=base+view.get("byteOffset",0)+acc.get("byteOffset",0)
    flat=struct.unpack_from("<"+fmt*(count*width),data,start)
    return [flat[i:i+width] for i in range(0,len(flat),width)]

def animation_track(doc,data,base,clip,node_name):
    animation=next(a for a in doc["animations"] if a["name"]==clip)
    node=next(i for i,n in enumerate(doc["nodes"]) if n.get("name")==node_name)
    for channel in animation["channels"]:
        if channel["target"]["node"]==node and channel["target"]["path"]=="rotation":
            sampler=animation["samplers"][channel["sampler"]]
            return values(doc,data,base,sampler["output"])
    raise AssertionError(f"Missing {clip}/{node_name} rotation")

def main():
    signatures=set()
    for n in range(1,31):
        doc,data,base=load(ART / f"hero_{n:02d}.glb")
        arm=animation_track(doc,data,base,"attack","Arm1")
        assert len(arm)==4, f"Hero {n}: attack track must follow 4-key timeline"
        assert abs(arm[0][0])<1e-5, f"Hero {n}: attack does not start at rest"
        assert abs(arm[-1][0])<1e-5, f"Hero {n}: attack does not recover to rest"
        signatures.add(tuple(round(frame[0],3) for frame in arm))
        for clip in ("idle","move","attack","hit","death","cast"):
            for bone in ("SpineChest","CapeHem","Head","Arm1Lower","Arm-1Lower","Leg1Lower","Leg-1Lower"):
                quats=animation_track(doc,data,base,clip,bone)
                assert len(quats)>=3, f"Hero {n}: {clip}/{bone} too short"
                for q in quats:
                    assert abs(sum(x*x for x in q)-1)<1e-4, f"Hero {n}: nonunit {clip}/{bone} quaternion"
    assert len(signatures)>=5, f"Expected 5 distinct hero attack silhouettes, got {len(signatures)}"
    for n in range(1,31):
        doc,data,base=load(ART / f"hero_{n:02d}.glb")
        for limb in ("Arm1Lower","Arm-1Lower","Leg1Lower","Leg-1Lower"):
            motion=animation_track(doc,data,base,"move",limb)
            assert max(abs(pose[0]) for pose in motion)>0.02, f"Hero {n}: {limb} never flexes during locomotion"
    for n in range(6):
        doc,data,base=load(ART / f"boss_region_{n}.glb")
        arm=animation_track(doc,data,base,"attack","Arm1")
        assert abs(arm[-1][0])<1e-5, f"Boss {n}: attack does not recover to rest"
    print(f"Motion validated: 30 heroes, 6 bosses, {len(signatures)} distinct hero attack profiles")

if __name__=="__main__":
    main()
