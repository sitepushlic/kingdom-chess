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
    print("Validator regression tests: pristine GLB accepted; 3 corrupt GLBs rejected")

if __name__=="__main__":
    main()
