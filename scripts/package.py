"""Package only release binaries, instructions and license notices."""
from pathlib import Path
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "downloads"
OUT.mkdir(exist_ok=True)
records = []
for platform, executable in [("windows", "AZTEC3.exe"), ("linux", "AZTEC3.x86_64")]:
    source = ROOT / "build" / platform / executable
    if not source.is_file() or source.stat().st_size < 10_000_000:
        raise SystemExit(f"Missing or incomplete executable: {source}")
    bundle = OUT / f"AZTEC3-{platform}.zip"
    files = [(source, executable), (ROOT / "README.md", "README.md")]
    files += [(p, "licenses/" + p.name) for p in sorted((ROOT / "licenses").glob("*.txt"))]
    with zipfile.ZipFile(bundle, "w", zipfile.ZIP_DEFLATED, compresslevel=7) as archive:
        for path, name in files:
            info = zipfile.ZipInfo(f"AZTEC3-{platform}/{name}", (2026, 9, 8, 0, 0, 0))
            info.create_system = 3
            info.external_attr = (0o100755 if path == source else 0o100644) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=7)
    with zipfile.ZipFile(bundle) as archive:
        if archive.testzip() is not None:
            raise SystemExit("Archive CRC verification failed")
    records.append({"file": bundle.name, "bytes": bundle.stat().st_size, "sha256": hashlib.sha256(bundle.read_bytes()).hexdigest(), "executable_sha256": hashlib.sha256(source.read_bytes()).hexdigest()})
(OUT / "manifest.json").write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
print(json.dumps(records, indent=2))
