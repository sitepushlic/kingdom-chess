#!/usr/bin/env python3
"""Deterministic original low-poly glTF 2.0 character generator.

Produces 30 heroes, 36 regional enemies and 6 bosses with six named clips
and six small two-joint GPU skins (cape, torso, arms, legs) per character.
These are procedural blockouts, not polished production models. Run before
Godot imports the project; the generated assets are not stored in Git.
"""
import json
import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "characters"
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
CUBE_VERTS = [vertex for normal,face in FACE_CORNERS for vertex in face]
CUBE_NORMALS = [normal for normal,face in FACE_CORNERS for _ in face]
CUBE_TRI = [base+offset for base in range(0,24,4) for offset in (0,1,2,0,2,3)]

def make_character(identifier, boss=False):
    num = int(identifier.split("_")[-1])
    family = (num-1) % 5
    signature = (num-1)//5
    if identifier.startswith("enemy_"):
        # Six class profiles per biome, plus a biome-specific crest treatment.
        signature = (num - 31) % 6
        family = ((num - 31) % 6 + (num - 31)//6) % 5
    if boss:
        family = num % 5
        signature = num
    palette = [
        [0.15,0.47,0.65,1], [0.67,0.24,0.25,1],
        [0.24,0.58,0.34,1], [0.58,0.37,0.70,1],
        [0.78,0.55,0.19,1], [0.36,0.67,0.70,1],
    ]
    accent = palette[(num-1)%len(palette)]
    if identifier.startswith("enemy_"):
        region = (num - 31)//6
        biome_tint = [
            [0.83,0.36,0.24,1], [0.39,0.73,0.95,1],
            [0.25,0.70,0.43,1], [0.67,0.42,0.91,1],
            [0.40,0.57,0.95,1], [0.82,0.20,0.38,1],
        ][region]
        accent = [round(accent[i]*.35 + biome_tint[i]*.65,4) for i in range(3)]+[1]
    if boss: accent = [0.72,0.16+num*0.04,0.27+num*0.03,1]
    mats = [
        {"name":"Armor","doubleSided":False,"pbrMetallicRoughness":{"baseColorFactor":accent,"metallicFactor":0.65,"roughnessFactor":0.38}},
        {"name":"Steel","doubleSided":False,"pbrMetallicRoughness":{"baseColorFactor":[0.61,0.67,0.72,1],"metallicFactor":0.82,"roughnessFactor":0.31}},
        {"name":"Skin","doubleSided":False,"pbrMetallicRoughness":{"baseColorFactor":[0.72,0.50,0.37,1],"metallicFactor":0.0,"roughnessFactor":0.8}},
        {"name":"Gold","doubleSided":False,"pbrMetallicRoughness":{"baseColorFactor":[0.88,0.67,0.29,1],"metallicFactor":0.85,"roughnessFactor":0.28}},
        {"name":"ArcaneGlow","doubleSided":False,"pbrMetallicRoughness":{"baseColorFactor":[accent[0],accent[1],accent[2],1],"metallicFactor":0.1,"roughnessFactor":0.25},"emissiveFactor":[min(1,accent[0]*.85),min(1,accent[1]*.85),min(1,accent[2]*.85)]},
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
    pos=accessor(positions,"72f",24,5126,"VEC3",34962,([-1,-1,-1],[1,1,1]))
    normals=accessor([v for normal in CUBE_NORMALS for v in normal],"72f",24,5126,"VEC3",34962)
    indices=accessor(CUBE_TRI,"36H",36,5123,"SCALAR",34963)
    # Beveled hard-surface geometry for every rigid armor/weapon part.
    # The deforming torso/limbs keep the original cube topology and skin
    # attributes. A single shared beveled mesh is instanced by all rigid
    # pieces, so 72 characters do not duplicate vertex data per plate.
    bevel_positions=[]
    bevel_normals=[]
    bevel_uvs=[]
    bevel_indices=[]
    bevel=.16
    def add_flat_face(vertices):
        # Fix winding from the face centroid, so both mirrored sides face out.
        v0,v1,v2=vertices[:3]
        u=[v1[i]-v0[i] for i in range(3)]
        v=[v2[i]-v0[i] for i in range(3)]
        cross=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
        center=[sum(vertex[i] for vertex in vertices)/len(vertices) for i in range(3)]
        if sum(cross[i]*center[i] for i in range(3)) < 0:
            vertices=list(reversed(vertices))
            cross=[-n for n in cross]
        magnitude=math.sqrt(sum(n*n for n in cross))
        assert magnitude>1e-8, "Degenerate bevel polygon"
        start=len(bevel_positions)//3
        # Per-face planar UV charts on already split flat-shaded vertices.
        dominant=max(range(3),key=lambda axis:abs(cross[axis]))
        uv_axes=[axis for axis in range(3) if axis!=dominant]
        for vertex in vertices:
            bevel_positions.extend(vertex)
            bevel_normals.extend(n/magnitude for n in cross)
            bevel_uvs.extend(((vertex[uv_axes[0]]+1.0)*0.5,
                              (vertex[uv_axes[1]]+1.0)*0.5))
        for k in range(1,len(vertices)-1):
            bevel_indices.extend((start,start+k,start+k+1))
    for axis in range(3):
        others=[i for i in range(3) if i!=axis]
        for sign in (-1,1):
            quad=[]
            for x,y in ((-1,-1),(1,-1),(1,1),(-1,1)):
                point=[0.0]*3
                point[axis]=float(sign)
                point[others[0]]=x*(1-bevel)
                point[others[1]]=y*(1-bevel)
                quad.append(point)
            add_flat_face(quad)
    # Twelve chamfer strips bridge adjacent inset faces.
    for axis in range(3):
        others=[i for i in range(3) if i!=axis]
        for sign_a in (-1,1):
            for sign_b in (-1,1):
                strip=[]
                for extent,first in ((-1,True),(1,True),(1,False),(-1,False)):
                    point=[0.0]*3
                    point[axis]=extent*(1-bevel)
                    point[others[0]]=sign_a*(1 if first else 1-bevel)
                    point[others[1]]=sign_b*(1-bevel if first else 1)
                    strip.append(point)
                add_flat_face(strip)
    # Eight triangular bevel corners close the mesh without cracks.
    for sx in (-1,1):
        for sy in (-1,1):
            for sz in (-1,1):
                add_flat_face([[sx*(1-bevel),sy,sz*(1-bevel)],
                               [sx,sy*(1-bevel),sz*(1-bevel)],
                               [sx*(1-bevel),sy*(1-bevel),sz]])
    assert len(bevel_positions)//3<65536
    bevel_pos=accessor(bevel_positions,str(len(bevel_positions))+"f",
                       len(bevel_positions)//3,5126,"VEC3",34962,
                       ([-1,-1,-1],[1,1,1]))
    bevel_normal=accessor(bevel_normals,str(len(bevel_normals))+"f",
                          len(bevel_normals)//3,5126,"VEC3",34962)
    bevel_uv=accessor(bevel_uvs,str(len(bevel_uvs))+"f",
                      len(bevel_positions)//3,5126,"VEC2",34962,
                      ([0,0],[1,1]))
    bevel_index=accessor(bevel_indices,str(len(bevel_indices))+"H",
                         len(bevel_indices),5123,"SCALAR",34963)
    for m in range(5):
        meshes.append({"name":["BeveledArmor","BeveledSteel","BeveledSkin",
                               "BeveledGold","BeveledArcaneGlow"][m],
                       "primitives":[{"attributes":{"POSITION":bevel_pos,
                                                    "NORMAL":bevel_normal,
                                                    "TEXCOORD_0":bevel_uv},
                                      "indices":bevel_index,"material":m}]})
    def box(name, center, size, material=0, angle=0):
        # Put articulated limbs under an actual shoulder/hip pivot so
        # rotation tracks swing around joints rather than around box centers.
        if name == "Head":
            joint = (0,1.17,0)
        elif name.startswith("Arm") and name[3:] in ("1","-1"):
            joint = (center[0], 1.06, center[2])
        elif name.startswith("Leg") and name[3:] in ("1","-1"):
            joint = (center[0], .53, center[2])
        else:
            joint = None
        if joint is not None:
            pivot_index=len(nodes)
            nodes.append({"name":name,"translation":list(joint),"children":[pivot_index+1]})
            nodes.append({"name":name+"Mesh","mesh":material,
                          "translation":[center[i]-joint[i] for i in range(3)],
                          "scale":[v/2 for v in size]})
            nodes[1]["children"].append(pivot_index)
            return
        idx=len(nodes)
        nodes.append({"name":name,"mesh":material,"translation":list(center),"scale":[v/2 for v in size],
                      "rotation":[0,0,math.sin(angle/2),math.cos(angle/2)]})
        head_parts=("Face","BossVisor","Eye","CheekGuard","BrowRidge","NoseBridge","NoseTip",
                    "Mouth","Pupil","Ear","LowerCheek","KingCrown","QueenDiadem",
                    "BishopMitre","KnightWing","RangerHood","EmberHorn",
                    "GlacierSpire","AstralCrown","CrimsonFang",
                    "Crown","Antler","HighHelm","Crest","Halo","Mask")
        if name.startswith(head_parts):
            head_pivot=next((n for n in nodes if n.get("name")=="Head"),None)
            if head_pivot is not None:
                nodes[idx]["translation"]=[center[i]-head_pivot["translation"][i] for i in range(3)]
                head_pivot["children"].append(idx)
                return
        # Shoulder pauldrons follow the upper-arm swing rather than
        # hovering beside the torso. Preserve world-space rest positions.
        if name.startswith("RoyalShoulder") or name=="RaiderShoulder":
            side=(name[len("RoyalShoulder"):] if name.startswith("RoyalShoulder") else "-1")
            pivot=next((n for n in nodes if n.get("name")=="Arm"+side),None)
            if pivot is not None:
                nodes[idx]["translation"]=[center[i]-pivot["translation"][i] for i in range(3)]
                pivot["children"].append(idx)
                return
        # Forged knee plates are rigid armor and must follow knee flex,
        # just like shin guards; keep their bind-space center unchanged.
        if name.startswith("ForgeKnee"):
            side=name[len("ForgeKnee"):]
            pivot=next((n for n in nodes if n.get("name")=="Leg"+side),None)
            if pivot is not None:
                nodes[idx]["translation"]=[center[i]-pivot["translation"][i] for i in range(3)]
                pivot["children"].append(idx)
                return
        if name.startswith("Gauntlet") or name.startswith("HeroWristBand") or name.startswith("ShinPlate") or name.startswith("Boot") or name.startswith("HeroBootToe"):
            side=name.split("Gauntlet")[-1] if name.startswith("Gauntlet") else (name.split("HeroWristBand")[-1] if name.startswith("HeroWristBand") else (name.split("ShinPlate")[-1] if name.startswith("ShinPlate") else (name.split("HeroBootToe")[-1] if name.startswith("HeroBootToe") else name.split("Boot")[-1])))
            pivot_name=("Arm" if name.startswith("Gauntlet") or name.startswith("HeroWristBand") else "Leg")+side
            pivot=next((n for n in nodes if n.get("name")==pivot_name),None)
            if pivot is not None:
                node=nodes[idx]
                node["translation"]=[center[i]-pivot["translation"][i] for i in range(3)]
                pivot["children"].append(idx)
                return
        nodes[1]["children"].append(idx)
    # Pivot at feet; rig node animation moves all geometry.
    # Torso is generated below as a weighted, two-joint deformable mesh.
    box("Waist",(0,.56,0),(.34,.17,.28),1)
    box("Head",(0,1.31,0),(.29,.30,.27),2)
    # Readable face and layered armor details at mobile portrait scale.
    for side in (-1,1):
        box("Eye"+str(side),(side*.075,1.34,-.144),(.053,.047,.016),4 if boss else 1)
        box("CheekGuard"+str(side),(side*.142,1.25,-.09),(.045,.14,.11),1)
    box("BrowRidge",(0,1.405,-.14),(.25,.047,.04),1)
    # Facial landmarks give each character a readable head at portrait
    # camera distance. They are children of Head and inherit neck motion.
    box("NoseBridge",(0,1.315,-.148),(.065,.125,.065),2)
    box("NoseTip",(0,1.265,-.181),(.085,.052,.060),2)
    box("Mouth",(0,1.204,-.145),(.105,.018,.023),0)
    for side in (-1,1):
        box("Pupil"+str(side),(side*.075,1.34,-.158),(.020,.024,.009),0)
        box("Ear"+str(side),(side*.160,1.30,0),(.050,.115,.065),2)
        box("LowerCheek"+str(side),(side*.100,1.226,-.124),(.095,.040,.034),2)
    box("BeltBuckle",(0,.57,-.153),(.12,.10,.055),3)
    box("ChestInsignia",(0,.92,-.143),(.16,.19,.045),3)
    # Secondary heraldry creates a readable front-facing identity at phone scale.
    # Geometry is static and inexpensive; avoid changing the articulated rig.
    for side in (-1, 1):
        box("HeraldicChestRivet"+str(side),(side*.18,.99,-.164),(.042,.042,.025),3)
        box("HeraldicBeltStud"+str(side),(side*.20,.57,-.15),(.052,.045,.032),3)
    if boss:
        # Boss chest cores glow in their biome palette, distinct from soldiers.
        box("BossHeartCore",(0,.93,-.198),(.13,.18,.065),4)
        box("BossHeartFrameTop",(0,1.06,-.20),(.25,.038,.05),3)
        box("BossHeartFrameBottom",(0,.80,-.20),(.25,.038,.05),3)
    elif identifier.startswith("hero_"):
        # A three-piece rank chevron distinguishes player heroes from enemies.
        for i in range(3):
            box("HeroRankChevron"+str(i),((i-1)*.12,.82,-.173),(.083,.055,.04),3)
    for side in (-1,1):
        box("Leg"+str(side),(side*.12,.30,0),(.13,.45,.15),1)
        box("Arm"+str(side),(side*.30,.84,0),(.13,.48,.17),1)
        box("Gauntlet"+str(side),(side*.30,.66,-.03),(.15,.14,.19),1)
        box("ShinPlate"+str(side),(side*.12,.30,-.095),(.145,.25,.06),1)
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
    # Layered armor and region identity. Distinct silhouettes remain legible
    # in a small Android viewport; all parts reuse five shared materials.
    if identifier.startswith("hero_"):
        for side in (-1, 1):
            box("HeroBootToe"+str(side),(side*.12,.085,-.155),(.19,.085,.19),1)
            box("HeroWristBand"+str(side),(side*.30,.69,-.055),(.18,.075,.20),3)
        if family == 0:
            box("RoyalGorget",(0,1.095,-.135),(.34,.13,.15),3)
            box("RoyalTabard",(0,.62,-.205),(.25,.40,.065),0)
        elif family == 1:
            for side in (-1, 1):
                box("RaiderFang"+str(side),(side*.25,1.11,-.09),(.09,.25,.10),3,side*.22)
            box("RaiderChestScar",(0,.94,-.184),(.075,.27,.05),4,-.35)
        elif family == 2:
            for side in (-1, 1):
                box("RangerCloakTrim"+str(side),(side*.20,.78,.265),(.06,.59,.055),3)
            box("RangerHoodBrow",(0,1.465,-.155),(.36,.075,.095),1)
        elif family == 3:
            for side in (-1, 1):
                box("ForgeBracer"+str(side),(side*.30,.73,-.125),(.19,.20,.10),3)
            box("ForgeChestVent",(0,.90,-.242),(.18,.12,.055),4)
        else:
            for side in (-1, 1):
                box("MageRobeHem"+str(side),(side*.18,.34,-.14),(.14,.10,.22),3)
            box("MageFocusChain",(0,1.00,-.182),(.06,.21,.045),3)
    elif identifier.startswith("enemy_"):
        region = (num - 31)//6
        # Region-specific chest silhouettes communicate increasing danger
        # without relying solely on palette differences.
        if region == 0:
            for side in (-1, 1):
                box("AshFurnaceSpike"+str(side),(side*.24,1.12,.08),(.12,.30,.14),0,side*.20)
        elif region == 1:
            for side in (-1, 1):
                box("IceCollar"+str(side),(side*.20,1.15,-.05),(.15,.25,.15),4,side*.15)
        elif region == 2:
            box("DeepSeaChestPearl",(0,.93,-.21),(.16,.17,.10),4)
            box("DeepSeaKelpMantle",(0,.87,.24),(.55,.58,.08),0)
        elif region == 3:
            for side in (-1, 1):
                box("ObsidianRidge"+str(side),(side*.21,1.01,-.15),(.10,.35,.11),1,side*.17)
        elif region == 4:
            box("SkyStormBeacon",(0,1.64,.04),(.18,.24,.16),4)
            for side in (-1, 1):
                box("SkyStormFin"+str(side),(side*.36,1.11,.16),(.12,.34,.12),3,side*.32)
        else:
            box("NightThroneSeal",(0,.97,-.21),(.22,.22,.075),4)
            for side in (-1, 1):
                box("NightThroneFang"+str(side),(side*.24,1.59,.05),(.10,.40,.12),0,side*.25)
    # Face-readable details at tactical camera distance. Heroes receive
    # expressive gold brows and clear eye highlights; enemy eyes are
    # emissive and bosses use a single ominous visor. All reuse existing
    # shared chamfered meshes and do not require additional materials.
    if boss:
        box("BossVisor",(0,1.39,-.183),(.30,.075,.065),4)
        box("BossVisorBridge",(0,1.43,-.189),(.055,.13,.05),3)
    else:
        for side in (-1,1):
            box("FaceEye"+str(side),(side*.105,1.39,-.184),(.075,.055,.044),
                3 if identifier.startswith("hero_") else 4)
        box("FaceBrow",(0,1.475,-.183),(.28,.045,.050),
            3 if identifier.startswith("hero_") else 1)
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
    # Chess-role heraldry is visible on each hero's silhouette, not just
    # in the selection UI. Roster mapping matches scripts/hero_roster.gd.
    if identifier.startswith("hero_"):
        # Explicit 30-ID mapping avoids silently changing the roster order.
        role_by_id = {
            1:"K",2:"N",3:"B",4:"R",5:"P",6:"Q",7:"N",8:"R",9:"B",10:"K",
            11:"N",12:"R",13:"Q",14:"B",15:"N",16:"R",17:"Q",18:"B",19:"B",20:"N",
            21:"K",22:"Q",23:"Q",24:"K",25:"N",26:"B",27:"Q",28:"N",29:"R",30:"K",
        }
        role = role_by_id[num]
        if role=="K":
            for side in (-1,1):
                box("KingCrownProng"+str(side),(side*.18,1.70,0),(.09,.26,.11),3)
            box("KingBreastSigil",(0,.97,-.19),(.20,.23,.06),3)
        elif role=="Q":
            for i in range(5):
                angle=(i-2)*.28
                box("QueenDiadem"+str(i),((i-2)*.11,1.65-abs(i-2)*.035,0),(.07,.22,.09),4,angle)
        elif role=="R":
            for side in (-1,1):
                box("RookBattlement"+str(side),(side*.28,1.12,0),(.20,.24,.33),1)
            box("RookChestPlate",(0,.89,-.21),(.34,.32,.10),1)
        elif role=="B":
            box("BishopMitre",(0,1.70,0),(.19,.32,.20),3)
            box("BishopStaffGem",(-.41,1.54,-.10),(.15,.20,.12),4)
        elif role=="N":
            for side in (-1,1):
                box("KnightWing"+str(side),(side*.26,1.48,.08),(.13,.31,.17),1,side*.28)
            box("KnightGorget",(0,1.08,-.14),(.37,.12,.23),1)
        else:
            box("PawnBanner",(0,1.60,.20),(.25,.38,.07),0)
            box("PawnBannerSigil",(0,1.62,.155),(.11,.14,.04),3)
    box("WeaponGrip",(.43,.75,0),(.09,.61,.09),3)
    if boss:
        # Bosses carry monumental, region-distinct relic weapons.
        box("BossRelicBlade",(.43,1.22,0),(.19+num*.03,.58+num*.07,.12),1)
        for i in range(num):
            box("BossRelicProng"+str(i),(.30+i*.09,1.57+num*.03,0),(.08,.20,.10),4)
    elif identifier.startswith("enemy_"):
        box("EnemyBasicBlade",(.43,1.18,0),(.12,.47,.10),1)
    else:
        # Five hero fighting styles: each receives an original weapon
        # silhouette in addition to the six distinct head signatures.
        if family == 0:
            box("RoyalLongsword",(.43,1.22,0),(.13,.59,.10),1)
            box("RoyalCrossguard",(.43,.93,0),(.40,.075,.10),3)
        elif family == 1:
            box("RaiderAxeHaft",(.43,1.11,0),(.08,.62,.09),1)
            box("RaiderAxeHead",(.59,1.42,0),(.38,.27,.12),1)
        elif family == 2:
            box("RangerBowStave",(.43,1.17,0),(.07,.77,.08),1)
            for side in (-1,1):
                box("RangerBowTip"+str(side),(.34,1.17+side*.36,0),(.24,.09,.08),3)
        elif family == 3:
            box("ForgeHammerHaft",(.43,1.12,0),(.08,.62,.08),1)
            box("ForgeHammerHead",(.43,1.46,0),(.49,.20,.22),1)
        else:
            box("MageStaff",(.43,1.15,0),(.08,.75,.08),1)
            box("MageCrystal",(.43,1.58,0),(.25,.28,.23),4)
        for i in range(signature):
            box("WeaponRune"+str(i),(.43,1.02+i*.07,-.09),(.055,.055,.045),4)
    if identifier.startswith("enemy_"):
        region = (num - 31)//6
        enemy_class = (num - 31)%6
        # Each enemy chess class gets a different weapon or shield profile.
        if enemy_class == 0:
            box("PawnBuckler",(-.43,.88,-.12),(.34,.38,.10),1)
        elif enemy_class == 1:
            box("RookTowerShield",(-.46,.87,-.11),(.42,.64,.12),1)
        elif enemy_class == 2:
            box("KnightLance",(.43,1.26,0),(.09,1.12,.09),1)
        elif enemy_class == 3:
            box("BishopFocus",(-.44,1.45,-.07),(.22,.24,.18),4)
        elif enemy_class == 4:
            for side in (-1,1):
                box("QueenTwinBlade"+str(side),(side*.46,1.16,-.10),(.11,.66,.10),1)
        else:
            box("KingGreatblade",(.43,1.20,0),(.26,.78,.11),3)
        for i in range(region + 1):
            box("RegionMark"+str(i),(-.24 + i*.085,1.02,-.19),(.06,.11,.07),3)
        if region >= 3:
            box("RegionBackplate",(0,.85,.21),(.43,.53,.10),1)
    if boss:
        for i in range(4):
            angle=i*math.pi/2
            box("BossSpine"+str(i),(math.cos(angle)*.32,1.62,math.sin(angle)*.30),(.10,.54,.12),3,math.cos(angle)*.28)
        box("BossChest",(0,.93,-.18),(.64,.44,.17),3)
        # Six region bosses have distinct, readable body landmarks, not
        # merely different color and oversized generic spines.
        if num == 1:
            for side in (-1,1):
                box("EmberHorn"+str(side),(side*.29,1.76,0),(.15,.61,.15),4,side*.35)
            box("LavaHeart",(0,.92,-.28),(.22,.28,.09),4)
        elif num == 2:
            for i in range(5):
                box("GlacierSpire"+str(i),(-.40+i*.20,1.67+(i%2)*.14,.18),(.12,.48+(i%2)*.18,.14),4,(i-2)*.15)
        elif num == 3:
            for side in (-1,1):
                box("ThornBranch"+str(side),(side*.41,1.42,.10),(.12,.78,.16),0,side*.45)
                box("ThornLeaf"+str(side),(side*.63,1.72,.12),(.23,.27,.12),4,side*.24)
        elif num == 4:
            box("RunicTablet",(0,1.0,.26),(.62,.70,.13),1)
            for i in range(4):
                box("RuneSeal"+str(i),(-.19+i*.13,1.10,.34),(.07,.22,.04),4)
        elif num == 5:
            for side in (-1,1):
                box("AstralWing"+str(side),(side*.54,1.15,.20),(.24,.91,.11),4,side*.33)
            box("AstralCrown",(0,1.96,0),(.45,.11,.30),4)
        else:
            for side in (-1,1):
                box("CrimsonWing"+str(side),(side*.62,1.11,.22),(.39,.85,.12),0,side*.43)
                box("CrimsonFang"+str(side),(side*.20,1.65,-.15),(.11,.39,.13),4,side*.18)
            box("CrimsonCore",(0,.93,-.27),(.30,.33,.10),4)
    # First actual GPU-skinned component: a two-bone cloth mantle. The
    # 24-vertex cape is bound to shoulder and hem joints with blended weights.
    # Unlike the articulated rigid boxes above, this uses glTF skinning
    # (JOINTS_0, WEIGHTS_0, inverseBindMatrices) and deforms between bones.
    cape_root_index=len(nodes)
    nodes.append({"name":"CapeShoulder","translation":[0,1.11,.17],"children":[cape_root_index+1]})
    nodes.append({"name":"CapeHem","translation":[0,-.58,0]})
    nodes[1]["children"].append(cape_root_index)
    cape_mesh_index=len(nodes)
    nodes.append({"name":"SkinnedCape","mesh":len(meshes),"skin":0})
    nodes[1]["children"].append(cape_mesh_index)
    # Metallic shoulder clasps stay rigid, while the weighted cloth below
    # deforms. These remain cheap shared-cube mesh instances.
    box("CapeClaspLeft",(-.21,1.10,.19),(.11,.10,.11),3)
    box("CapeClaspRight",(.21,1.10,.19),(.11,.10,.11),3)
    cape_positions=[]
    cape_weights=[]
    cape_joints=[]
    for xyz in CUBE_VERTS:
        x,y,z=xyz
        # Tapered shoulder-to-hem silhouette instead of a rectangular slab.
        # The lower corners spread as the two-bone skin bends.
        cape_width=.26 if y>0 else .43
        cape_positions.extend((x*cape_width, .74+y*.38, .20+z*.035))
        hem_weight=.72 if y<0 else .08
        cape_weights.extend((1.0-hem_weight,hem_weight,0.0,0.0))
        cape_joints.extend((0,1,0,0))
    cape_pos=accessor(cape_positions,"72f",24,5126,"VEC3",34962,
                      ([-.43,.36,.165],[.43,1.12,.235]))
    # The tapered cloth's side faces are slanted; reusing box normals
    # produces visibly incorrect lighting. Derive face normals from the
    # actual deformed rest-pose geometry, preserving flat shaded edges.
    cape_normals=[]
    for face_start in range(0,24,4):
        verts=[cape_positions[(face_start+j)*3:(face_start+j+1)*3] for j in range(4)]
        u=[verts[1][j]-verts[0][j] for j in range(3)]
        v=[verts[2][j]-verts[0][j] for j in range(3)]
        cross=(u[1]*v[2]-u[2]*v[1],
               u[2]*v[0]-u[0]*v[2],
               u[0]*v[1]-u[1]*v[0])
        magnitude=math.sqrt(sum(value*value for value in cross))
        assert magnitude>1e-8, "Degenerate tapered cape face"
        cape_normals.extend([component/magnitude for component in cross]*4)
    cape_normal=accessor(cape_normals,"72f",24,5126,"VEC3",34962)
    cape_joint=accessor(cape_joints,"96B",24,5121,"VEC4",34962)
    cape_weight=accessor(cape_weights,"96f",24,5126,"VEC4",34962)
    meshes.append({"name":"DeformingMantle","primitives":[{
        "attributes":{"POSITION":cape_pos,"NORMAL":cape_normal,
                      "JOINTS_0":cape_joint,"WEIGHTS_0":cape_weight},
        "indices":indices,"material":0}]})
    # Column-major 4x4 matrices: inverse world bind transforms for
    # CapeShoulder (y=1.11,z=.17) and CapeHem (y=.53,z=.17).
    inverse_bind=[]
    for y,z in ((1.11,.17),(.53,.17)):
        inverse_bind.extend((1,0,0,0, 0,1,0,0, 0,0,1,0, 0,-y,-z,1))
    ibm=accessor(inverse_bind,"32f",2,5126,"MAT4")
    skins=[{"name":"MantleSkin","joints":[cape_root_index,cape_root_index+1],
            "skeleton":cape_root_index,"inverseBindMatrices":ibm}]
    # Actual two-bone skinned torso, replacing the former rigid Torso box.
    # Hip and chest bones share weighted vertices; the chest can bend
    # independently during attacks and spellcasting.
    hip_index=len(nodes)
    nodes.append({"name":"SpineHip","translation":[0,.70,0],
                  "children":[hip_index+1]})
    nodes.append({"name":"SpineChest","translation":[0,.33,0]})
    nodes[1]["children"].append(hip_index)
    torso_mesh_node=len(nodes)
    nodes.append({"name":"SkinnedTorso","mesh":len(meshes),"skin":1})
    nodes[1]["children"].append(torso_mesh_node)
    # A three-ring chest shell provides a real waist/upper-torso profile
    # and a 50/50 deformation band at the spine joint.
    torso_positions=[]
    torso_normals=[]
    torso_uvs=[]
    torso_weights=[]
    torso_joints=[]
    torso_indices=[]
    for normal,face in FACE_CORNERS:
        if normal[1]==0:
            # Split each side into two outward-wound four-corner panels.
            # The shared center ring follows both SpineHip and SpineChest.
            panels=[]
            for upper in (False,True):
                polygon=[]
                for edge in range(4):
                    v=face[edge]
                    w=face[(edge+1)%4]
                    inside_v=v[1]>=0 if upper else v[1]<=0
                    inside_w=w[1]>=0 if upper else w[1]<=0
                    if inside_v: polygon.append(v)
                    if inside_v!=inside_w:
                        t=-v[1]/(w[1]-v[1])
                        polygon.append(tuple(v[k]+t*(w[k]-v[k]) for k in range(3)))
                assert len(polygon)==4
                panels.append(polygon)
        else:
            panels=[face]
        for panel in panels:
            base=len(torso_positions)//3
            panel_positions=[]
            for x,y,z in panel:
                # Wider shoulders and a tapered waist. The waist-to-chest
                # transition is continuous across the central ring.
                width={-1:.165,0:.190,1:.225}[y]
                depth={-1:.115,0:.125,1:.145}[y]
                point=(x*width,.88+y*.27,z*depth)
                panel_positions.append(point)
                torso_positions.extend(point)
                influence={-1:.18,0:.50,1:.82}[y]
                torso_weights.extend((1-influence,influence,0,0))
                torso_joints.extend((0,1,0,0))
            u=[panel_positions[1][j]-panel_positions[0][j] for j in range(3)]
            v=[panel_positions[2][j]-panel_positions[0][j] for j in range(3)]
            cross=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])
            magnitude=math.sqrt(sum(component*component for component in cross))
            assert magnitude>1e-8, "Degenerate torso panel"
            torso_normals.extend([component/magnitude for component in cross]*4)
            # Continuous vertical UVs across the waist/chest seam.
            for px,py,pz in panel_positions:
                horizontal=(px/.225+1)*.5 if abs(cross[2])>=abs(cross[0]) else (pz/.145+1)*.5
                torso_uvs.extend((max(0,min(1,horizontal)),(py-.61)/.54))
            torso_indices.extend(base+index for index in (0,1,2,0,2,3))
    torso_count=len(torso_positions)//3
    assert torso_count==40
    torso_pos=accessor(torso_positions,str(torso_count*3)+"f",torso_count,5126,"VEC3",34962,
                       ([-.225,.61,-.145],[.225,1.15,.145]))
    torso_normal=accessor(torso_normals,str(torso_count*3)+"f",torso_count,5126,"VEC3",34962)
    torso_uv=accessor(torso_uvs,str(torso_count*2)+"f",torso_count,5126,"VEC2",34962,([0,0],[1,1]))
    torso_joint=accessor(torso_joints,str(torso_count*4)+"B",torso_count,5121,"VEC4",34962)
    torso_weight=accessor(torso_weights,str(torso_count*4)+"f",torso_count,5126,"VEC4",34962)
    torso_index=accessor(torso_indices,str(len(torso_indices))+"H",len(torso_indices),5123,"SCALAR",34963)
    meshes.append({"name":"DeformingTorso","primitives":[{
        "attributes":{"POSITION":torso_pos,"NORMAL":torso_normal,
                      "TEXCOORD_0":torso_uv,"JOINTS_0":torso_joint,"WEIGHTS_0":torso_weight},
        "indices":torso_index,"material":0}]})
    torso_inverse=[]
    for y in (.70,1.03):
        torso_inverse.extend((1,0,0,0, 0,1,0,0, 0,0,1,0, 0,-y,0,1))
    torso_ibm=accessor(torso_inverse,"32f",2,5126,"MAT4")
    skins.append({"name":"TorsoSkin","joints":[hip_index,hip_index+1],
                  "skeleton":hip_index,"inverseBindMatrices":torso_ibm})
    # Weighted limb surfaces: shoulder/hip pivots remain named Arm±1 and
    # Leg±1 for gameplay equipment sockets. Each surface is now a genuine
    # two-joint glTF skin rather than an undeformed rigid cube.
    limb_skin_bones={}
    for limb_name in ("Arm1","Arm-1","Leg1","Leg-1"):
        pivot_index=next(i for i,node in enumerate(nodes)
                         if node.get("name")==limb_name)
        pivot=nodes[pivot_index]
        old_mesh_index=next(i for i in pivot["children"]
                            if nodes[i].get("name")==limb_name+"Mesh")
        old_mesh=nodes[old_mesh_index]
        # Reuse the original mesh node as a skinned node under BodyRig.
        # Its bind-pose geometry is authored in BodyRig-local coordinates.
        pivot["children"].remove(old_mesh_index)
        nodes[1]["children"].append(old_mesh_index)
        center=[pivot["translation"][j]+old_mesh["translation"][j]
                for j in range(3)]
        dimensions=[value*2 for value in old_mesh["scale"]]
        is_arm=limb_name.startswith("Arm")
        lower_joint_index=len(nodes)
        lower_offset=-.24 if is_arm else -.225
        nodes.append({"name":limb_name+"Lower",
                      "translation":[0,lower_offset,0]})
        pivot["children"].append(lower_joint_index)
        # Gauntlets, shin guards and boots are rigid armor plates. They
        # belong to the lower arm/shin bone, not the upper pivot; otherwise
        # they float above the bending mesh during elbow/knee flexion.
        # Preserve their world-space bind pose while changing parent.
        rigid_prefixes=("Gauntlet","HeroWristBand") if is_arm else ("ShinPlate","Boot","HeroBootToe","ForgeKnee")
        for child_index in list(pivot["children"]):
            if child_index==lower_joint_index:
                continue
            child=nodes[child_index]
            if any(child.get("name","").startswith(prefix) for prefix in rigid_prefixes):
                pivot["children"].remove(child_index)
                nodes[lower_joint_index].setdefault("children",[]).append(child_index)
                child["translation"][1]-=lower_offset
        # Authored weapons are ordinary mesh nodes and previously stayed
        # under BodyRig, so attacks animated an empty hand while the
        # blade/staff floated in place. Bind right-hand weapon geometry to
        # the distal arm bone and offhand shields/foci to the left arm.
        # Their existing BodyRig-local translation is converted to
        # lower-bone-local coordinates without moving the rest pose.
        if is_arm:
            weapon_prefixes=(
                ("WeaponGrip","BossRelic","EnemyBasicBlade","RoyalLongsword",
                 "RoyalCrossguard","RaiderAxe","RangerBow","ForgeHammer",
                 "MageStaff","MageCrystal","WeaponRune","KnightLance",
                 "QueenTwinBlade1","KingGreatblade")
                if limb_name=="Arm1" else
                ("PawnBuckler","RookTowerShield","BishopFocus","QueenTwinBlade-1")
            )
            lower_world=[pivot["translation"][j]+(lower_offset if j==1 else 0)
                         for j in range(3)]
            for child_index in list(nodes[1]["children"]):
                child=nodes[child_index]
                if not any(child.get("name","").startswith(prefix) for prefix in weapon_prefixes):
                    continue
                nodes[1]["children"].remove(child_index)
                nodes[lower_joint_index].setdefault("children",[]).append(child_index)
                child["translation"]=[child["translation"][j]-lower_world[j]
                                      for j in range(3)]
        old_mesh.pop("scale",None)
        old_mesh.pop("rotation",None)
        old_mesh["translation"]=[0,0,0]
        # Imported skinned meshes must not retain the original rigid cube
        # transform. All vertex positions already contain bind-space offsets.
        old_mesh["mesh"]=len(meshes)
        old_mesh["skin"]=len(skins)
        # Subdivide the four side faces at the elbow/knee level. The
        # additional middle ring prevents the entire limb from bending as
        # a single stretched cube when the lower joint rotates.
        limb_vertices=[]
        limb_normals=[]
        limb_triangles=[]
        for normal,face in FACE_CORNERS:
            if normal[1]!=0:
                quads=[face]
            else:
                upper=[]
                lower=[]
                # FACE_CORNERS are ordered around each face; clip the quad
                # against y=0 to create two independently weighted bands.
                def clip_y(vertices,keep_above):
                    result=[]
                    for edge in range(len(vertices)):
                        v=vertices[edge]
                        w=vertices[(edge+1)%len(vertices)]
                        inside_v=(v[1]>=0 if keep_above else v[1]<=0)
                        inside_w=(w[1]>=0 if keep_above else w[1]<=0)
                        if inside_v: result.append(v)
                        if inside_v != inside_w:
                            t=-v[1]/(w[1]-v[1])
                            result.append(tuple(v[k]+t*(w[k]-v[k]) for k in range(3)))
                    return result
                quads=[clip_y(face,False),clip_y(face,True)]
            for quad in quads:
                assert len(quad)==4, f"Invalid limb quad {limb_name}: {quad}"
                offset=len(limb_vertices)
                # Three radius bands make arms/legs taper toward wrists and
                # ankles while keeping the same deforming elbow/knee ring.
                # All factors <= 1 preserve the existing accessor bounds.
                profile={-1:.78,0:.90,1:1.0}
                panel=[]
                for x,y,z in quad:
                    factor=profile[y]
                    panel.append((center[0]+x*dimensions[0]*factor/2,
                                  center[1]+y*dimensions[1]/2,
                                  center[2]+z*dimensions[2]*factor/2))
                u=[panel[1][i]-panel[0][i] for i in range(3)]
                v=[panel[2][i]-panel[0][i] for i in range(3)]
                cross=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])
                magnitude=math.sqrt(sum(component*component for component in cross))
                assert magnitude>1e-8, f"Degenerate tapered limb {limb_name}"
                limb_vertices.extend(panel)
                limb_normals.extend([tuple(component/magnitude for component in cross)]*4)
                limb_triangles.extend(offset+index for index in (0,1,2,0,2,3))
        verts=[]
        uv_coords=[]
        weights=[]
        joints=[]
        for index,(x,y,z) in enumerate(limb_vertices):
            verts.extend((x,y,z))
            # Limb UVs follow the length axis and wrap around the
            # tapered perimeter. All values are normalized to [0,1].
            horizontal=(x-center[0])/dimensions[0]+.5
            vertical=(y-center[1])/dimensions[1]+.5
            uv_coords.extend((max(0,min(1,horizontal)),max(0,min(1,vertical))))
            # Original cube-ring y is reconstructed from the panel's
            # bind-space Y; exact midpoint is preserved by construction.
            ring=(y-center[1])/(dimensions[1]/2)
            distal=.12 if ring<-.5 else (.88 if ring>.5 else .50)
            weights.extend((1-distal,distal,0,0))
            joints.extend((0,1,0,0))
        mins=[center[j]-dimensions[j]/2 for j in range(3)]
        maxs=[center[j]+dimensions[j]/2 for j in range(3)]
        vertex_count=len(limb_vertices)
        pos_index=accessor(verts,str(vertex_count*3)+"f",vertex_count,5126,"VEC3",34962,
                           (mins,maxs))
        normal_index=accessor([v for n in limb_normals for v in n],
                              str(vertex_count*3)+"f",vertex_count,5126,"VEC3",34962)
        uv_index=accessor(uv_coords,str(vertex_count*2)+"f",vertex_count,5126,"VEC2",34962,([0,0],[1,1]))
        joint_index=accessor(joints,str(vertex_count*4)+"B",vertex_count,5121,"VEC4",34962)
        weight_index=accessor(weights,str(vertex_count*4)+"f",vertex_count,5126,"VEC4",34962)
        triangle_index=accessor(limb_triangles,str(len(limb_triangles))+"H",
                                len(limb_triangles),5123,"SCALAR",34963)
        meshes.append({"name":limb_name+"DeformingSurface","primitives":[{
            "attributes":{"POSITION":pos_index,"NORMAL":normal_index,
                          "TEXCOORD_0":uv_index,"JOINTS_0":joint_index,"WEIGHTS_0":weight_index},
            "indices":triangle_index,"material":1}]})
        root=pivot["translation"]
        lower=[root[0],root[1]+lower_offset,root[2]]
        inverse=[]
        for position in (root,lower):
            inverse.extend((1,0,0,0, 0,1,0,0, 0,0,1,0,
                            -position[0],-position[1],-position[2],1))
        inverse_index=accessor(inverse,"32f",2,5126,"MAT4")
        skins.append({"name":limb_name+"Skin",
                      "joints":[pivot_index,lower_joint_index],
                      "skeleton":pivot_index,
                      "inverseBindMatrices":inverse_index})
        limb_skin_bones[limb_name]=lower_joint_index
    # Six named glTF clips animate the body, rigid head pivot and all
    # six weighted glTF skins (spine, cape, elbows and knees).
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
    # Distinct combat language: heavy guardians strike slowly, duelists
    # slash, mystics channel with both arms, and bosses use wide windups.
    # All variants retain the same six clip names for the runtime.
    combat_family = family % 5
    if combat_family == 0:
        limb_poses["attack"]["Arm1"]=[0,-.80,-1.05,.75,0]
        limb_poses["cast"]["Arm-1"]=[0,-.45,-1.10,-.45,0]
    elif combat_family == 1:
        limb_poses["attack"]["Arm1"]=[0,.45,-1.45,.55,0]
        limb_poses["attack"]["Arm-1"]=[0,-.35,-.70,.25,0]
    elif combat_family == 2:
        limb_poses["attack"]["Arm1"]=[0,-.40,-1.80,.25,0]
        limb_poses["cast"]["Arm1"]=[0,-.55,-1.55,-.55,0]
    elif combat_family == 3:
        limb_poses["attack"]["Arm1"]=[0,-.95,-1.45,.85,0]
        limb_poses["attack"]["Arm-1"]=[0,-.65,-.20,.30,0]
    else:
        limb_poses["attack"]["Arm1"]=[0,-.20,-1.05,-.40,0]
        limb_poses["cast"]["Arm-1"]=[0,-.65,-1.65,-.65,0]
    if boss:
        limb_poses["attack"]["Arm1"]=[0,-.55,-1.65,-.95,.20,0]
        limb_poses["attack"]["Arm-1"]=[0,.30,-.85,-.35,.25,0]
        limb_poses["cast"]["Arm1"]=[0,-.40,-1.70,-1.40,0]
        limb_poses["cast"]["Arm-1"]=[0,-.40,-1.70,-1.40,0]
    def sample_motion(poses, target_count):
        """Sample the complete gesture curve without dropping its final pose."""
        if len(poses)==target_count:
            return list(poses)
        output=[]
        for index in range(target_count):
            phase=index*(len(poses)-1)/(target_count-1)
            left=int(phase)
            right=min(left+1,len(poses)-1)
            blend=phase-left
            output.append(poses[left]*(1-blend)+poses[right]*blend)
        return output
    node_ids = {node["name"]: idx for idx,node in enumerate(nodes)}
    animations=[]
    for name,(times,positions) in clips.items():
        t=accessor(times,str(len(times))+"f",len(times),5126,"SCALAR",None,([0],[times[-1]]))
        vals=[v for p in positions for v in p]
        v=accessor(vals,str(len(vals))+"f",len(positions),5126,"VEC3")
        samplers=[{"input":t,"output":v,"interpolation":"LINEAR"}]
        channels=[{"sampler":0,"target":{"node":1,"path":"translation"}}]
        # Body-wide squash/lean is independent from locomotion bob.
        # Animated torso rotation also carries helmets, shields and capes.
        body_lean={
            "idle":[0,.018,0], "move":[0,-.045,.045],
            "attack":[0,-.15,.20,0], "hit":[0,.13,0],
            "death":[0,.32,.55], "cast":[0,-.11,0],
        }[name]
        body_quats=[(math.sin(angle/2),0,0,math.cos(angle/2)) for angle in body_lean]
        body_values=[value for pose in body_quats for value in pose]
        body_output=accessor(body_values,str(len(body_values))+"f",len(body_quats),5126,"VEC4")
        samplers.append({"input":t,"output":body_output,"interpolation":"LINEAR"})
        channels.append({"sampler":len(samplers)-1,"target":{"node":1,"path":"rotation"}})
        # Mantle hem sways independently of the body in every animation.
        hem_angles={
            "idle":[0,.05,0], "move":[0,.22,-.16],
            "attack":[0,-.34,.27,0], "hit":[0,.30,0],
            "death":[0,.45,.70], "cast":[0,-.24,.12],
        }[name]
        hem_poses=[(math.sin(v/2),0,0,math.cos(v/2)) for v in hem_angles]
        hem_output=accessor([v for q in hem_poses for v in q],
                            str(len(hem_poses)*4)+"f",len(hem_poses),5126,"VEC4")
        samplers.append({"input":t,"output":hem_output,"interpolation":"LINEAR"})
        channels.append({"sampler":len(samplers)-1,
                         "target":{"node":cape_root_index+1,"path":"rotation"}})
        # Articulated head turns and nods; eyes, brow, helmets and crowns
        # are children of the neck pivot and therefore follow the motion.
        head_angles={
            "idle":[0,.035,0], "move":[0,-.05,.06],
            "attack":[0,-.16,.08,0], "hit":[0,.20,0],
            "death":[0,-.14,-.28], "cast":[0,-.12,.05],
        }[name]
        head_output=accessor([v for angle in head_angles
                              for v in (math.sin(angle/2),0,0,math.cos(angle/2))],
                             str(len(head_angles)*4)+"f",len(head_angles),5126,"VEC4")
        samplers.append({"input":t,"output":head_output,"interpolation":"LINEAR"})
        channels.append({"sampler":len(samplers)-1,
                         "target":{"node":node_ids["Head"],"path":"rotation"}})
        spine_angles={
            "idle":[0,.012,0], "move":[0,-.065,.055],
            "attack":[0,-.25,.20,0], "hit":[0,.24,0],
            "death":[0,.28,.46], "cast":[0,-.22,0],
        }[name]
        spine_quats=[value for angle in spine_angles
                     for value in (math.sin(angle/2),0,0,math.cos(angle/2))]
        spine_output=accessor(spine_quats,str(len(spine_quats))+"f",
                              len(spine_angles),5126,"VEC4")
        samplers.append({"input":t,"output":spine_output,"interpolation":"LINEAR"})
        channels.append({"sampler":len(samplers)-1,
                         "target":{"node":hip_index+1,"path":"rotation"}})
        # Distal joint flex makes elbows and knees deform independently
        # of the upper-arm and hip swings.
        for limb_name,lower_index in limb_skin_bones.items():
            flex={
                "idle":[0,.025,0], "move":[0,.20,-.14],
                "attack":[0,-.34,.28,0], "hit":[0,.23,0],
                "death":[0,.28,.45], "cast":[0,-.23,0],
            }[name]
            if limb_name.startswith("Leg"):
                flex=[value*.55 for value in flex]
            elif limb_name.endswith("-1"):
                flex=[-value for value in flex]
            poses=[(math.sin(v/2),0,0,math.cos(v/2)) for v in flex]
            output=accessor([v for pose in poses for v in pose],
                            str(len(poses)*4)+"f",len(poses),5126,"VEC4")
            samplers.append({"input":t,"output":output,"interpolation":"LINEAR"})
            channels.append({"sampler":len(samplers)-1,
                             "target":{"node":lower_index,"path":"rotation"}})
        for limb, angles in limb_poses[name].items():
            if limb not in node_ids:
                continue
            # The cube is scaled around its center; rotation animates its
            # orientation, giving clear readable gestures at mobile scale.
            def limb_quat(angle):
                # Forward/back locomotion uses X-axis rotation; lateral
                # knockback/death gestures use Z-axis rotation.
                half=angle/2
                if name in ("move","attack","cast","idle"):
                    return (math.sin(half),0.0,0.0,math.cos(half))
                return (0.0,0.0,math.sin(half),math.cos(half))
            # Authored five/six-pose boss and archetype gestures are resampled
            # to the clip timeline, preserving the recovery pose at the end.
            poses=[limb_quat(angle) for angle in sample_motion(angles,len(times))]
            packed=[value for pose in poses for value in pose]
            output=accessor(packed,str(len(packed))+"f",len(poses),5126,"VEC4")
            samplers.append({"input":t,"output":output,"interpolation":"LINEAR"})
            channels.append({"sampler":len(samplers)-1,"target":{"node":node_ids[limb],"path":"rotation"}})
        animations.append({"name":name,"samplers":samplers,"channels":channels})
    # Five small original deterministic PBR albedo textures. They are
    # embedded as PNG bufferViews in the GLB itself: no missing external
    # files, no third-party dependencies and no random nondeterminism.
    # UV charts are available on all rigid pieces and weighted torso/limbs.
    def material_png(material_index):
        size=32
        rows=bytearray()
        for y in range(size):
            rows.append(0)  # PNG filter: none
            for x in range(size):
                # Neutral variation multiplies existing character-specific
                # baseColorFactor without replacing hero rarity/biome colors.
                grain=((x*17+y*29+material_index*13) % 17)-8
                seam=(x%8==0 or y%8==0)
                if material_index==0: # engraved cloth / enamel armor
                    tone=236+grain-(13 if seam else 0)
                elif material_index==1: # brushed steel
                    tone=226+grain+(13 if x%6==0 else 0)
                elif material_index==2: # organic skin, restrained freckles
                    tone=240+grain-(17 if (x*3+y*7)%41==0 else 0)
                elif material_index==3: # chased gold lattice
                    tone=232+grain+(15 if (x+y)%8==0 else 0)
                else: # arcane etched circuit
                    tone=228+grain+(22 if x%8==0 or y%8==0 else 0)
                tone=max(0,min(255,tone))
                rows.extend((tone,tone,tone,255))
        def chunk(kind,data):
            return struct.pack(">I",len(data))+kind+data+struct.pack(">I",zlib.crc32(kind+data)&0xffffffff)
        return (b"\\x89PNG\\r\\n\\x1a\\n"+
                chunk(b"IHDR",struct.pack(">IIBBBBB",size,size,8,6,0,0,0))+
                chunk(b"IDAT",zlib.compress(bytes(rows),9))+
                chunk(b"IEND",b""))
    images=[]
    textures=[]
    for material_index in range(5):
        while len(blob)%4:
            blob.append(0)
        start=len(blob)
        png=material_png(material_index)
        blob.extend(png)
        views.append({"buffer":0,"byteOffset":start,"byteLength":len(png)})
        images.append({"name":mats[material_index]["name"]+"Albedo",
                       "bufferView":len(views)-1,"mimeType":"image/png"})
        textures.append({"source":material_index,"sampler":0})
        mats[material_index]["pbrMetallicRoughness"]["baseColorTexture"]={"index":material_index,"texCoord":0}
    gltf={"asset":{"version":"2.0","generator":"KingdomChess deterministic blockout generator"},
          "scene":0,"scenes":[{"nodes":[0]}],"nodes":nodes,"meshes":meshes,"materials":mats,
          "buffers":[{"byteLength":len(blob)}],"bufferViews":views,"accessors":accessors,"skins":skins,"animations":animations,\n          "images":images,"textures":textures,"samplers":[{"magFilter":9729,"minFilter":9729,"wrapS":10497,"wrapT":10497}]}
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
