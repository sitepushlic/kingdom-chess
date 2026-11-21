#!/usr/bin/env python3
"""Deterministic original GLB character mesh pipeline, no external dependencies.

Produces 30 hero models and six region boss models with six named glTF
animation clips. Models are intentionally stylized low-poly BLOCKOUTS, not
final rigged production characters. Each hero gets a different costume/head
profile, not only a material swap. Run before Godot imports the project.
"""
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "characters"
OUT.mkdir(parents=True, exist_ok=True)
CUBE_VERTS = [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]
CUBE_TRI = [0,1,2,0,2,3,4,6,5,4,7,6,0,4,5,0,5,1,3,2,6,3,6,7,1,5,6,1,6,2,0,3,7,0,7,4]

def make_character(identifier, boss=False):
    num = int(identifier.split("_")[-1])
    family = (num-1) % 5
    signature = (num-1)//5
    if boss:
        family = num % 5
        signature = num
    palette = [
        [0.15,0.47,0.65,1], [0.67,0.24,0.25,1],
        [0.24,0.58,0.34,1], [0.58,0.37,0.70,1],
        [0.78,0.55,0.19,1], [0.36,0.67,0.70,1],
    ]
    accent = palette[(num-1)%len(palette)]
    if boss: accent = [0.72,0.16+num*0.04,0.27+num*0.03,1]
    mats = [
        {"name":"Armor","pbrMetallicRoughness":{"baseColorFactor":accent,"metallicFactor":0.65,"roughnessFactor":0.38}},
        {"name":"Steel","pbrMetallicRoughness":{"baseColorFactor":[0.61,0.67,0.72,1],"metallicFactor":0.82,"roughnessFactor":0.31}},
        {"name":"Skin","pbrMetallicRoughness":{"baseColorFactor":[0.72,0.50,0.37,1],"metallicFactor":0.0,"roughnessFactor":0.8}},
        {"name":"Gold","pbrMetallicRoughness":{"baseColorFactor":[0.88,0.67,0.29,1],"metallicFactor":0.85,"roughnessFactor":0.28}},
    ]
    nodes = [{"name":"Root","children":[1]},{"name":"BodyRig","children":[]}]
    meshes = []
    blob = bytearray()
    views = []
    accessors = []
    def accessor(data, fmt, count, component, type_, target=None, minmax=None):
        while len(blob)%4: blob.append(0)
        start=len(blob)
        blob.extend(struct.pack("<"+fmt,*data) if not isinstance(data,bytes) else data)
        view={"buffer":0,"byteOffset":start,"byteLength":len(blob)-start}
        if target is not None: view["target"]=target
        views.append(view)
        a={"bufferView":len(views)-1,"componentType":component,"count":count,"type":type_}
        if minmax:
            a["min"],a["max"]=minmax
        accessors.append(a)
        return len(accessors)-1
    positions=[v for xyz in CUBE_VERTS for v in xyz]
    pos=accessor(positions,"24f",8,5126,"VEC3",34962,([-1,-1,-1],[1,1,1]))
    indices=accessor(CUBE_TRI,"36H",36,5123,"SCALAR",34963)
    for m in range(4):
        meshes.append({"name":["ArmorBox","SteelBox","SkinBox","GoldBox"][m],"primitives":[{"attributes":{"POSITION":pos},"indices":indices,"material":m}]})
    def box(name, center, size, material=0, angle=0):
        idx=len(nodes)
        nodes.append({"name":name,"mesh":material,"translation":list(center),"scale":[v/2 for v in size],
                      "rotation":[0,0,math.sin(angle/2),math.cos(angle/2)]})
        nodes[1]["children"].append(idx)
    # Pivot at feet; rig node animation moves all geometry.
    box("Torso",(0,0.88,0),(.39,.54,.26))
    box("Waist",(0,.56,0),(.34,.17,.28),1)
    box("Head",(0,1.31,0),(.29,.30,.27),2)
    for side in (-1,1):
        box("Leg"+str(side),(side*.12,.30,0),(.13,.45,.15),1)
        box("Arm"+str(side),(side*.30,.84,0),(.13,.48,.17),1)
        box("Boot"+str(side),(side*.12,.12,-.05),(.17,.15,.25),1)
    # Distinct armor silhouettes: 5 body archetypes.
    if family==0:
        box("Mantle",(0,.87,.17),(.58,.62,.11))
        for side in (-1,1): box("RoyalShoulder"+str(side),(side*.34,1.04,0),(.27,.17,.36),3,side*.2)
    elif family==1:
        box("RaiderShoulder",(-.32,1.06,0),(.35,.25,.32),1)
        for i in range(4): box("SerratedSkirt"+str(i),(-.18+i*.12,.45,-.16),(.10,.28,.08),0,(i-1.5)*.16)
    elif family==2:
        box("RangerHood",(0,1.46,.06),(.40,.21,.33),0)
        box("TravelCloak",(0,.81,.19),(.43,.68,.08))
        box("Quiver",(-.28,1.0,.20),(.15,.53,.16),1)
    elif family==3:
        box("ForgeBreast",(0,.88,-.14),(.53,.46,.15),1)
        for side in (-1,1): box("ForgeKnee"+str(side),(side*.12,.36,-.14),(.22,.21,.17),1)
    else:
        box("MageRobe",(0,.55,0),(.55,.48,.37))
        box("ArcaneCollar",(0,1.06,0),(.50,.13,.38),3)
        box("Focus",(-.43,1.12,-.08),(.15,.15,.15),3)
    # Six head geometry signatures.
    if signature==0:
        box("Crown",(0,1.52,0),(.40,.14,.31),3)
    elif signature==1:
        for side in (-1,1): box("Antler"+str(side),(side*.22,1.58,0),(.09,.45,.10),3,side*.3)
    elif signature==2:
        box("HighHelm",(0,1.57,0),(.25,.40,.26),1)
    elif signature==3:
        for i in range(3): box("Crest"+str(i),((i-1)*.14,1.56,0),(.08,.28+(i%2)*.12,.10),3)
    elif signature==4:
        box("HaloLeft",(-.23,1.52,0),(.10,.12,.12),3)
        box("HaloRight",(.23,1.52,0),(.10,.12,.12),3)
        box("HaloCenter",(0,1.62,0),(.13,.13,.13),3)
    else:
        box("Mask",(0,1.37,-.17),(.41,.15,.15),1)
        box("MaskSpike",(0,1.57,0),(.08,.33,.10),3)
    box("WeaponGrip",(.43,.75,0),(.09,.61,.09),3)
    box("WeaponBlade",(.43,1.18,0),(.12,.47,.10),1)
    if boss:
        for i in range(4):
            angle=i*math.pi/2
            box("BossSpine"+str(i),(math.cos(angle)*.32,1.62,math.sin(angle)*.30),(.10,.54,.12),3,math.cos(angle)*.28)
        box("BossChest",(0,.93,-.18),(.64,.44,.17),3)
    # Six named glTF clips animate the full character pivot. These are
    # rigid transform clips, NOT skeletal animations.
    clips = {
        "idle":([0,.5,1.0],[(0,0,0),(0,.025,0),(0,0,0)]),
        "move":([0,.18,.36],[(0,0,0),(0,.12,0),(0,0,0)]),
        "attack":([0,.12,.24,.40],[(0,0,0),(0,0,-.10),(0,0,.20),(0,0,0)]),
        "hit":([0,.10,.28],[(0,0,0),(0,-.08,.12),(0,0,0)]),
        "death":([0,.35,.70],[(0,0,0),(0,-.30,.1),(0,-.55,.1)]),
        "cast":([0,.20,.42],[(0,0,0),(0,.16,0),(0,0,0)]),
    }
    # Articulated node animation: limb meshes are separate glTF nodes.
    # This is not skinning; however, arms and legs now move independently
    # instead of the previous rigid full-body-only animation.
    limb_poses = {
        "idle":   {"Arm1":[0,-.08,0], "Arm-1":[0,.08,0]},
        "move":   {"Arm1":[0,-.55,.48], "Arm-1":[0,.55,-.48],
                   "Leg1":[0,.40,-.35], "Leg-1":[0,-.40,.35]},
        "attack": {"Arm1":[0,-1.25,.70], "Arm-1":[0,.05,0]},
        "hit":    {"Arm1":[0,-.65,0], "Arm-1":[0,-.65,0]},
        "death":  {"Arm1":[0,-1.25,-1.50], "Arm-1":[0,-1.25,1.50],
                   "Leg1":[0,.45,.25], "Leg-1":[0,-.45,-.25]},
        "cast":   {"Arm1":[0,-1.60,-.60], "Arm-1":[0,-1.60,.60]},
    }
    node_ids = {node["name"]: idx for idx,node in enumerate(nodes)}
    animations=[]
    for name,(times,positions) in clips.items():
        t=accessor(times,str(len(times))+"f",len(times),5126,"SCALAR",None,([0],[times[-1]]))
        vals=[v for p in positions for v in p]
        v=accessor(vals,str(len(vals))+"f",len(positions),5126,"VEC3")
        samplers=[{"input":t,"output":v,"interpolation":"LINEAR"}]
        channels=[{"sampler":0,"target":{"node":1,"path":"translation"}}]
        for limb, angles in limb_poses[name].items():
            if limb not in node_ids:
                continue
            # The cube is scaled around its center; rotation animates its
            # orientation, giving clear readable gestures at mobile scale.
            def quat_z(angle):
                return (0.0,0.0,math.sin(angle/2),math.cos(angle/2))
            poses=[quat_z(angle) for angle in angles]
            if len(poses)!=len(times):
                # Hold the last pose for clips with four timeline samples.
                poses = (poses + [poses[-1]]*len(times))[:len(times)]
            packed=[value for pose in poses for value in pose]
            output=accessor(packed,str(len(packed))+"f",len(poses),5126,"VEC4")
            samplers.append({"input":t,"output":output,"interpolation":"LINEAR"})
            channels.append({"sampler":len(samplers)-1,"target":{"node":node_ids[limb],"path":"rotation"}})
        animations.append({"name":name,"samplers":samplers,"channels":channels})
    gltf={"asset":{"version":"2.0","generator":"KingdomChess deterministic blockout generator"},
          "scene":0,"scenes":[{"nodes":[0]}],"nodes":nodes,"meshes":meshes,"materials":mats,
          "buffers":[{"byteLength":len(blob)}],"bufferViews":views,"accessors":accessors,"animations":animations}
    json_bytes=json.dumps(gltf,ensure_ascii=False,separators=(",",":")).encode("utf-8")
    json_bytes+=b" " * ((-len(json_bytes))%4)
    blob.extend(b"\x00"*((-len(blob))%4))
    total=12+8+len(json_bytes)+8+len(blob)
    result=struct.pack("<4sII",b"glTF",2,total)
    result+=struct.pack("<I4s",len(json_bytes),b"JSON")+json_bytes
    result+=struct.pack("<I4s",len(blob),b"BIN\x00")+blob
    return result

def main():
    for i in range(1,31):
        (OUT/("hero_%02d.glb"%i)).write_bytes(make_character("hero_%02d"%i))
    for i in range(6):
        (OUT/("boss_region_%d.glb"%i)).write_bytes(make_character("boss_%02d"%(i+1),True))
    # Six enemy chess classes per region. Distinct silhouettes are generated
    # by varying family, crest, material palette and armor details.
    for region in range(6):
        for class_index, chess_class in enumerate("PRNBQK"):
            enemy_number = 31 + region*6 + class_index
            (OUT/("enemy_%s_region_%d.glb"%(chess_class.lower(),region))).write_bytes(
                make_character("enemy_%02d"%enemy_number))
    print("Generated 30 hero, 6 boss and 36 regional enemy GLB blockouts")

if __name__=="__main__":
    main()
