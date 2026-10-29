#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${GODOT_BIN:=godot}"
: "${ANDROID_HOME:?Source the generated tools/env.sh first}"
mkdir -p builds
"$GODOT_BIN" --headless --path . --editor --import --quit > builds/import.log 2>&1
if rg -q 'SCRIPT ERROR|Parse Error' builds/import.log; then cat builds/import.log; exit 1; fi
./scripts/check.sh
"$GODOT_BIN" --headless --path . --export-debug Android builds/DeadwaveHeroes-v0.2.9-debug.apk > builds/android-export.log 2>&1
"$ANDROID_HOME/build-tools/35.0.1/apksigner" verify --verbose builds/DeadwaveHeroes-v0.2.9-debug.apk > builds/apk-verification.log
"$ANDROID_HOME/build-tools/35.0.1/zipalign" -c -P 16 -v 4 builds/DeadwaveHeroes-v0.2.9-debug.apk > builds/apk-alignment.log
"$GODOT_BIN" --headless --path . --export-debug Windows builds/DeadwaveHeroes-v0.2.9-windows.exe > builds/windows-export.log 2>&1
python3 - <<'PY'
from pathlib import Path
import hashlib,json,zipfile
out=Path('builds')
with zipfile.ZipFile(out/'DeadwaveHeroes-v0.2.9-windows.zip','w',zipfile.ZIP_DEFLATED) as z:
 z.write(out/'DeadwaveHeroes-v0.2.9-windows.exe','DeadwaveHeroes.exe')
 z.write('README.md','README.md')
files=['DeadwaveHeroes-v0.2.9-debug.apk','DeadwaveHeroes-v0.2.9-windows.zip']
manifest={name:{'bytes':(out/name).stat().st_size,'sha256':hashlib.sha256((out/name).read_bytes()).hexdigest()} for name in files}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(manifest,indent=2))
PY
