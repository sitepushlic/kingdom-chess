#!/usr/bin/env python3
"""Check deterministic regeneration of every procedural GLB using SHA-256."""
import hashlib
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[2]
paths = sorted((root / "assets" / "characters").glob("*.glb")) + sorted((root / "assets" / "equipment").glob("*.glb"))
assert len(paths) == 93, f"expected 93 assets, found {len(paths)}"
before = {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest() for path in paths}
for script in ("generate_blockouts.py", "generate_equipment.py"):
    subprocess.run([sys.executable, str(root / "tools" / "art" / script)], check=True, cwd=root)
after = {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest() for path in paths}
changed = [name for name in before if before[name] != after[name]]
assert not changed, "nondeterministic generated GLBs: " + ", ".join(changed)
print(f"KINGDOM CHESS: {len(paths)} GLB SHA-256 REPRODUCIBILITY CHECK PASSED")
