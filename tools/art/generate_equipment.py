#!/usr/bin/env python3
"""Generate 21 modular, mobile-budget GLB equipment props (3 slots x 7 rarities).

Each prop has its own silhouette, pivot at origin, PBR materials and mesh nodes.
Coordinates are in local attachment space; the game positions the socket.
"""
import json
import math
import struct
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "assets" / "equipment"
OUT.mkdir(parents=True, exist_ok=True)
# Flat-shaded cube: 24 independent vertices (4 per face), outward-facing
# normals, consistent winding. Unlike 8 shared corners this gives hard edges.
FACE_CORNERS = [
    ((0,0,-1),[(-1,-1,-1),(-1,1,-1),(1,1,-1),(1,-1,-1)]),
    ((0,0,1),[(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]),
    ((0,-1,0),[(-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1)]),
    ((0,1,0),[(-1,1,-1),(-1,1,1),(1,1,1),(1,1,-1)]),
    ((-1,0,0),[(-1,-1,-1),(-1,-1,1),(-1,1,1),(-1,1,-1)]),
    ((1,0,0),[(1,-1,-1),(1,1,-1),(1,1,1),(1,-1,1)]),
]
VERTICES = [vertex for normal,face in FACE_CORNERS for vertex in face]
NORMALS = [normal for normal,face in FACE_CORNERS for _ in face]
TRIANGLES = [base+offset for base in range(0,24,4) for offset in (0,1,2,0,2,3)]
PALETTE = [
    (0.63,0.67,0.72,1),(0.24,0.70,0.61,1),(0.28,0.52,0.91,1),
    (0.65,0.39,0.88,1),(0.93,0.61,0.24,1),(0.93,0.31,0.47,1),
    (0.98,0.87,0.51,1),
]

def build(slot, tier):
    nodes=[{"name":"EquipmentRoot","children":[]}]
    meshes=[{"name":"Metal","primitives":[{"attributes":{"POSITION":0,"NORMAL":1},"indices":2,"material":0}]},
            {"name":"Inlay","primitives":[{"attributes":{"POSITION":0,"NORMAL":1},"indices":2,"material":1}]}]
    shapes=[]
    def box(name, center, size, mat=0, angle=0):
        index=len(nodes)
        nodes.append({"name":name,"mesh":mat,"translation":list(center),
                      "scale":[max(.002, n/2) for n in size],
                      "rotation":[0,0,math.sin(angle/2),math.cos(angle/2)]})
        nodes[0]["children"].append(index)
        shapes.append(name)
    if slot=="weapon":
        # Blade, axe, spear, fork, glaive, staff and sovereign wingblade.
        box("Grip",(0,0,0),(.075,.40,.085),1)
        if tier==0:
            box("ShortBlade",(0,.40,0),(.13,.48,.065))
        elif tier==1:
            box("AxeShaft",(0,.43,0),(.075,.70,.08))
            box("AxeHead",(.16,.71,0),(.39,.24,.09))
        elif tier==2:
            box("PikeShaft",(0,.50,0),(.07,1.02,.07))
            box("PikeTip",(0,1.09,0),(.16,.27,.08))
        elif tier==3:
            for side in (-1,1):
                box("ForkTine"+str(side),(side*.15,.72,0),(.11,.52,.08))
            box("ForkStem",(0,.39,0),(.08,.48,.08))
        elif tier==4:
            box("GlaiveShaft",(0,.47,0),(.07,.95,.08))
            box("GlaiveEdge",(.16,.87,0),(.39,.42,.08),0,.35)
        elif tier==5:
            box("RunicStaff",(0,.49,0),(.09,.99,.09))
            for i in range(4):
                a=i*math.pi/2
                box("Rune"+str(i),(math.cos(a)*.17,1.05+math.sin(a)*.17,0),(.10,.10,.10),1,a)
        else:
            box("SovereignCore",(0,.67,0),(.16,.68,.13))
            for i in range(6):
                a=i*math.pi/3
                box("Wing"+str(i),(math.cos(a)*.25,.85+math.sin(a)*.24,0),(.12,.36,.09),1,a)
    elif slot=="armor":
        box("Breastplate",(0,0,0),(.49+tier*.035,.48+tier*.018,.20))
        for side in (-1,1):
            box("Pauldron"+str(side),(side*(.33+tier*.008),.16,0),(.19+tier*.024,.20+tier*.02,.29),0,side*.14)
        for i in range(tier+1):
            box("RankPlate"+str(i),(-.22+i*.44/max(tier,1),-.12,-.13),(.055,.10,.035),1)
        if tier>=4:
            box("Collar",(0,.32,0),(.42,.12,.26),1)
        if tier>=6:
            for side in (-1,1):
                box("RoyalFin"+str(side),(side*.36,.39,0),(.13,.33,.17),1,side*.28)
    else:
        box("RelicCore",(0,0,0),(.18+tier*.022,.22+tier*.02,.14),1)
        for i in range(tier+1):
            a=i*math.tau/(tier+1)
            box("Orbit"+str(i),(math.cos(a)*.23,math.sin(a)*.23,0),(.08,.09,.07),0,a)
        if tier>=4:
            box("RelicSpire",(0,.31,0),(.09,.25,.09),1)
    blob=bytearray()
    views=[]
    accessors=[]
    def append(values, fmt, component, count, kind, target, bounds=None):
        while len(blob)%4: blob.append(0)
        offset=len(blob)
        blob.extend(struct.pack("<"+fmt,*values))
        views.append({"buffer":0,"byteOffset":offset,"byteLength":len(blob)-offset,"target":target})
        acc={"bufferView":len(views)-1,"componentType":component,"count":count,"type":kind}
        if bounds: acc["min"],acc["max"]=bounds
        accessors.append(acc)
    append([v for xyz in VERTICES for v in xyz],"72f",5126,24,"VEC3",34962,([-1,-1,-1],[1,1,1]))
    append([v for xyz in NORMALS for v in xyz],"72f",5126,24,"VEC3",34962)
    append(TRIANGLES,"36H",5123,36,"SCALAR",34963)
    while len(blob)%4: blob.append(0)
    materials=[
        {"name":"TierMetal","doubleSided":True,"pbrMetallicRoughness":{"baseColorFactor":PALETTE[tier],"metallicFactor":.75,"roughnessFactor":.34}},
        {"name":"TierInlay","doubleSided":True,"pbrMetallicRoughness":{"baseColorFactor":[.93,.79,.46,1],"metallicFactor":.8,"roughnessFactor":.25}},
    ]
    document={"asset":{"version":"2.0","generator":"Kingdom Chess modular equipment"},
              "scene":0,"scenes":[{"nodes":[0]}],"nodes":nodes,"meshes":meshes,
              "materials":materials,"buffers":[{"byteLength":len(blob)}],
              "bufferViews":views,"accessors":accessors}
    raw=json.dumps(document,separators=(",",":")).encode()
    raw+=b" "*((-len(raw))%4)
    length=12+8+len(raw)+8+len(blob)
    return struct.pack("<4sII",b"glTF",2,length)+struct.pack("<I4s",len(raw),b"JSON")+raw+struct.pack("<I4s",len(blob),b"BIN\\x00".replace(b"\\x00",b"\x00"))+blob

def main():
    for slot in ("weapon","armor","relic"):
        for tier in range(7):
            (OUT/f"{slot}_tier_{tier}.glb").write_bytes(build(slot,tier))
    print("Generated 21 modular equipment GLBs (weapon/armor/relic x 7 tiers)")

if __name__=="__main__":
    main()
