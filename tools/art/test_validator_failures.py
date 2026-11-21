#!/usr/bin/env python3
"""Regression tests: GLB validation must reject realistic corrupt assets."""
import json
import struct
import tempfile
from pathlib import Path

from validate_blockouts import validate

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/"assets"/"characters"/"hero_01.glb"

def read_glb(raw):
    json_size=struct.unpack_from("<I",raw,12)[0]
    doc=json.loads(raw[20:20+json_size])
    binary=raw[20+json_size+8:]
    return doc,binary

def pack_glb(doc,binary):
    js=json.dumps(doc,separators=(",",":"),ensure_ascii=False).encode("utf-8")
    js+=b" "*((-len(js))%4)
    binary+=b"\x00"*((-len(binary))%4)
    size=12+8+len(js)+8+len(binary)
    return (struct.pack("<4sII",b"glTF",2,size)
            +struct.pack("<I4s",len(js),b"JSON")+js
            +struct.pack("<I4s",len(binary),b"BIN\x00")+binary)

def must_reject(raw,description):
    with tempfile.TemporaryDirectory() as directory:
        path=Path(directory)/"hero_01.glb"
        path.write_bytes(raw)
        try:
            validate(path)
        except (AssertionError,ValueError,struct.error,IndexError,KeyError):
            return
    raise AssertionError(f"Validator accepted corrupt asset: {description}")

def main():
    original=SOURCE.read_bytes()
    doc,binary=read_glb(original)
    with tempfile.TemporaryDirectory() as directory:
        path=Path(directory)/"hero_01.glb"
        path.write_bytes(original)
        validate(path)
    # Corrupt the first weighted vertex without changing any GLB metadata.
    doc,binary=read_glb(original)
    node=next(node for node in doc["nodes"] if node.get("name")=="SkinnedTorso")
    primitive=doc["meshes"][node["mesh"]]["primitives"][0]
    accessor=doc["accessors"][primitive["attributes"]["WEIGHTS_0"]]
    view=doc["bufferViews"][accessor["bufferView"]]
    binary=bytearray(binary)
    start=view.get("byteOffset",0)+accessor.get("byteOffset",0)
    struct.pack_into("<4f",binary,start,0.0,0.0,0.0,0.0)
    must_reject(pack_glb(doc,bytes(binary)),"unnormalized torso skin weights")
    # Duplicate a node/path animation channel, a common export mistake.
    doc,binary=read_glb(original)
    doc["animations"][0]["channels"].append(dict(doc["animations"][0]["channels"][0]))
    must_reject(pack_glb(doc,binary),"duplicate animation target")
    # Shift a joint's inverse bind matrix without updating its rest pose.
    doc,binary=read_glb(original)
    acc=doc["accessors"][doc["skins"][0]["inverseBindMatrices"]]
    view=doc["bufferViews"][acc["bufferView"]]
    binary=bytearray(binary)
    start=view.get("byteOffset",0)+acc.get("byteOffset",0)+12*4
    struct.pack_into("<f",binary,start,3.0)
    must_reject(pack_glb(doc,bytes(binary)),"invalid inverse bind matrix")
    # Animation input/output counts must match exactly.
    doc,binary=read_glb(original)
    sampler=doc["animations"][0]["samplers"][0]
    doc["accessors"][sampler["output"]]["count"]-=1
    must_reject(pack_glb(doc,binary),"mismatched animation key count")
    # Reject animation timelines with repeated or descending key times.
    doc,binary=read_glb(original)
    acc=doc["accessors"][doc["animations"][0]["samplers"][0]["input"]]
    view=doc["bufferViews"][acc["bufferView"]]
    binary=bytearray(binary)
    start=view.get("byteOffset",0)+acc.get("byteOffset",0)
    struct.pack_into("<f",binary,start+4,0.0)
    must_reject(pack_glb(doc,bytes(binary)),"duplicate animation key timestamp")
    # Reject unaligned binary buffer views even if payload is otherwise valid.
    doc,binary=read_glb(original)
    doc["bufferViews"][0]["byteOffset"]+=1
    must_reject(pack_glb(doc,binary),"misaligned glTF buffer view")
    # Reject a NaN in the weighted torso position stream.
    doc,binary=read_glb(original)
    node=next(node for node in doc["nodes"] if node.get("name")=="SkinnedTorso")
    primitive=doc["meshes"][node["mesh"]]["primitives"][0]
    acc=doc["accessors"][primitive["attributes"]["POSITION"]]
    view=doc["bufferViews"][acc["bufferView"]]
    binary=bytearray(binary)
    struct.pack_into("<f",binary,view.get("byteOffset",0)+acc.get("byteOffset",0),float("nan"))
    must_reject(pack_glb(doc,bytes(binary)),"nonfinite skinned vertex position")
    # Reject an out-of-range bone index in the torso's joint palette.
    doc,binary=read_glb(original)
    node=next(node for node in doc["nodes"] if node.get("name")=="SkinnedTorso")
    primitive=doc["meshes"][node["mesh"]]["primitives"][0]
    acc=doc["accessors"][primitive["attributes"]["JOINTS_0"]]
    view=doc["bufferViews"][acc["bufferView"]]
    binary=bytearray(binary)
    binary[view.get("byteOffset",0)+acc.get("byteOffset",0)]=7
    must_reject(pack_glb(doc,bytes(binary)),"out-of-range torso joint index")
    # A NaN in a root translation animation must be rejected before import.
    doc,binary=read_glb(original)
    clip=doc["animations"][0]
    channel=next(c for c in clip["channels"] if c["target"]["path"]=="translation")
    acc=doc["accessors"][clip["samplers"][channel["sampler"]]["output"]]
    view=doc["bufferViews"][acc["bufferView"]]
    binary=bytearray(binary)
    struct.pack_into("<f",binary,view.get("byteOffset",0)+acc.get("byteOffset",0),float("nan"))
    must_reject(pack_glb(doc,bytes(binary)),"nonfinite animated translation")
    # Translation output must not be silently accepted as integer data.
    doc,binary=read_glb(original)
    clip=doc["animations"][0]
    channel=next(c for c in clip["channels"] if c["target"]["path"]=="translation")
    doc["accessors"][clip["samplers"][channel["sampler"]]["output"]]["componentType"]=5125
    must_reject(pack_glb(doc,binary),"integer animation translation")
    # Detaching the grip from the wrist must fail structural validation.
    doc,binary=read_glb(original)
    wrist=next(node for node in doc["nodes"] if node.get("name")=="Arm1Lower")
    grip=next(i for i,node in enumerate(doc["nodes"]) if node.get("name")=="WeaponGrip")
    wrist["children"].remove(grip)
    doc["nodes"][1]["children"].append(grip)
    must_reject(pack_glb(doc,binary),"weapon grip left on stationary BodyRig")
    # Facial parts left behind during head rotation are also invalid.
    doc,binary=read_glb(original)
    head=next(node for node in doc["nodes"] if node.get("name")=="Head")
    nose=next(i for i,node in enumerate(doc["nodes"]) if node.get("name")=="NoseBridge")
    head["children"].remove(nose)
    doc["nodes"][1]["children"].append(nose)
    must_reject(pack_glb(doc,binary),"nose bridge detached from animated Head")
    # Signature headgear must follow the neck, not the static body.
    doc,binary=read_glb(original)
    head=next(node for node in doc["nodes"] if node.get("name")=="Head")
    crown=next(i for i,node in enumerate(doc["nodes"]) if node.get("name")=="Crown")
    head["children"].remove(crown)
    doc["nodes"][1]["children"].append(crown)
    must_reject(pack_glb(doc,binary),"signature crown detached from animated Head")
    # Royal shoulder plate must follow its upper-arm pivot.
    doc,binary=read_glb(original)
    pauldron=next(i for i,node in enumerate(doc["nodes"]) if node.get("name")=="RoyalShoulder1")
    arm=next(node for node in doc["nodes"] if node.get("name")=="Arm1")
    arm["children"].remove(pauldron)
    doc["nodes"][1]["children"].append(pauldron)
    must_reject(pack_glb(doc,binary),"royal shoulder plate detached from animated arm")
    # Forge archetype has additional articulated knee plates. Use the
    # fourth hero (family index 3), not the royal hero_01 fixture.
    forge_raw=(ROOT/"assets"/"characters"/"hero_04.glb").read_bytes()
    doc,binary=read_glb(forge_raw)
    knee=next(i for i,node in enumerate(doc["nodes"]) if node.get("name")=="ForgeKnee1")
    shin=next(node for node in doc["nodes"] if node.get("name")=="Leg1Lower")
    shin["children"].remove(knee)
    doc["nodes"][1]["children"].append(knee)
    must_reject(pack_glb(doc,binary),"forge knee plate detached from shin")
    print("Validator regression tests: pristine GLB accepted; 15 corrupt GLBs rejected")

if __name__=="__main__":
    main()
