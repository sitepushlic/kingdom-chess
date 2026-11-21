#!/usr/bin/env python3
"""Check rigid armor rest transforms and articulated joint inheritance in every character GLB."""
import json
import math
import struct
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/"assets"/"characters"
FILES=([ART/f"hero_{n:02d}.glb" for n in range(1,31)]
       +[ART/f"boss_region_{n}.glb" for n in range(6)]
       +[ART/f"enemy_{piece}_region_{region}.glb" for region in range(6) for piece in "prnbqk"])

def check(path):
    data=path.read_bytes()
    size=struct.unpack_from("<I",data,12)[0]
    doc=json.loads(data[20:20+size])
    nodes=doc["nodes"]
    by_name={node.get("name"):i for i,node in enumerate(nodes)}
    parents={}
    for i,node in enumerate(nodes):
        for child in node.get("children",[]):
            assert child not in parents, f"{path}: multiply parented node {child}"
            parents[child]=i
    def world_position(i):
        point=[0.0,0.0,0.0]
        seen=set()
        while True:
            assert i not in seen, f"{path}: cyclic rig"
            seen.add(i)
            node=nodes[i]
            assert "rotation" not in node or node["rotation"]==[0,0,0,1], f"{path}: rotated rest joint requires matrix evaluation"
            xyz=node.get("translation",[0,0,0])
            for k in range(3): point[k]+=xyz[k]
            if i not in parents: return point
            i=parents[i]
    for side in ("1","-1"):
        for upper,lower,plate_names in (
            ("Arm"+side,"Arm"+side+"Lower",("Gauntlet"+side,)),
            ("Leg"+side,"Leg"+side+"Lower",("ShinPlate"+side,"Boot"+side)),
        ):
            upper_id=by_name[upper]
            lower_id=by_name[lower]
            assert parents[lower_id]==upper_id, f"{path}: {lower} is not a child of {upper}"
            offset=nodes[lower_id]["translation"][1]
            expected_offset=-.24 if upper.startswith("Arm") else -.225
            assert abs(offset-expected_offset)<1e-6, f"{path}: unexpected lower joint offset"
            upper_position=world_position(upper_id)
            for name in plate_names:
                plate_id=by_name[name]
                assert parents[plate_id]==lower_id, f"{path}: {name} does not follow distal bone"
                position=world_position(plate_id)
                local=nodes[plate_id]["translation"]
                assert abs(position[1]-(upper_position[1]+local[1]+offset))<1e-5
                # Reparenting must retain the originally authored world Y:
                # local offset relative to lower bone cancels the lower shift.
                expected_center={("Gauntlet"+side):.66,("ShinPlate"+side):.30,("Boot"+side):.12}[name]
                assert abs(position[1]-expected_center)<1e-5, f"{path}: {name} rest Y drifted: {position[1]} vs {expected_center}"
                assert all(math.isfinite(x) for x in position), f"{path}: {name} nonfinite bind position"
    return True

def main():
    assert len(FILES)==72
    for path in FILES:
        check(path)
    print("Rig attachment QA: 72 GLBs, 432 distal armor plates, hierarchy and bind positions validated")

if __name__=="__main__":
    main()
