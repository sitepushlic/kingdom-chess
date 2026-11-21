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
    # Rigid pauldrons must follow upper-arm rotation.
    for side in ("1","-1"):
        name="RoyalShoulder"+side
        if name in by_name:
            assert parents[by_name[name]]==by_name["Arm"+side], f"{path}: {name} detached from shoulder"
            assert abs(world_position(by_name[name])[1]-1.04)<1e-5, f"{path}: {name} rest pose drift"
    if "RaiderShoulder" in by_name:
        assert parents[by_name["RaiderShoulder"]]==by_name["Arm-1"], f"{path}: raider pauldron detached"
        assert abs(world_position(by_name["RaiderShoulder"])[1]-1.06)<1e-5
    # Forged archetype has extra knee plates; both must inherit shin
    # rotation and keep the original authored world-space Y.
    for side in ("1","-1"):
        name="ForgeKnee"+side
        if name in by_name:
            assert parents[by_name[name]]==by_name["Leg"+side+"Lower"], f"{path}: {name} floats during knee bend"
            assert abs(world_position(by_name[name])[1]-.36)<1e-5, f"{path}: {name} rest pose drift"
    # New facial landmarks must move with the animated neck pivot.
    head_id=by_name["Head"]
    for name,rest_y in (
        ("NoseBridge",1.315),("NoseTip",1.265),("Mouth",1.204),
        ("Pupil1",1.34),("Pupil-1",1.34),
        ("Ear1",1.30),("Ear-1",1.30),
        ("LowerCheek1",1.226),("LowerCheek-1",1.226),
    ):
        assert name in by_name, f"{path}: missing facial landmark {name}"
        assert parents[by_name[name]]==head_id, f"{path}: {name} detached from animated head"
        assert abs(world_position(by_name[name])[1]-rest_y)<1e-5, f"{path}: {name} rest pose drift"
    # Six signature headgear families must follow neck rotation, too.
    signature_names=("Crown","Antler","HighHelm","Crest","Halo","Mask")
    authored=[name for name in by_name if name.startswith(signature_names)]
    assert authored, f"{path}: no authored signature headgear"
    for name in authored:
        assert parents[by_name[name]]==head_id, f"{path}: {name} is static headgear"
    # Every character's weapon must follow its actual wrist, rather
    # than staying under the stationary BodyRig during attacks.
    right=by_name["Arm1Lower"]
    left=by_name["Arm-1Lower"]
    assert parents[by_name["WeaponGrip"]]==right, f"{path}: grip detached from right wrist"
    weapon_names=("BossRelicBlade","EnemyBasicBlade","RoyalLongsword",
                  "RaiderAxeHead","RangerBowStave","ForgeHammerHead",
                  "MageCrystal","KnightLance","KingGreatblade")
    equipped=[name for name in weapon_names if name in by_name]
    assert equipped, f"{path}: missing authored weapon geometry"
    for name in equipped:
        assert parents[by_name[name]]==right, f"{path}: {name} detached from right wrist"
    for name in ("PawnBuckler","RookTowerShield","BishopFocus","QueenTwinBlade-1"):
        if name in by_name:
            assert parents[by_name[name]]==left, f"{path}: {name} detached from left wrist"
    # World-space bind centers of authored weapons are unchanged.
    assert abs(world_position(by_name["WeaponGrip"])[1]-.75)<1e-5, f"{path}: grip rest pose drift"
    return True

def main():
    assert len(FILES)==72
    for path in FILES:
        check(path)
    print("Rig attachment QA: 72 GLBs, 432 distal armor plates, hierarchy and bind positions validated")

if __name__=="__main__":
    main()
