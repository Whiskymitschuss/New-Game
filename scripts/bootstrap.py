#!/usr/bin/env python3
"""Reproducible Linux build prerequisites. No root access or release keys needed."""
import hashlib, os, shlex, shutil, subprocess, urllib.request, zipfile
from pathlib import Path
VERSION='4.6.3'
TOOLS=Path(os.environ.get('DEADWAVE_TOOLS','/workspace/tools')).resolve()
DOWNLOADS=TOOLS/'downloads'
DATA=TOOLS/'godot-data'
CONFIG=TOOLS/'godot-config'
SDK=TOOLS/'android'
for p in (DOWNLOADS,DATA/'godot',CONFIG/'godot',TOOLS/'android-home'):
    p.mkdir(parents=True,exist_ok=True)
BASE=f'https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable/'
def fetch(url,dest):
    if dest.exists(): return
    print('Download',url,flush=True)
    temporary=dest.with_suffix(dest.suffix+'.part')
    subprocess.run(['curl','--fail','--location','--retry','2',url,'--output',str(temporary)],check=True)
    temporary.rename(dest)
def digest(path,algorithm):
    with path.open('rb') as f:return hashlib.file_digest(f,algorithm).hexdigest()
checks=DOWNLOADS/f'godot-{VERSION}-SHA512-SUMS.txt'
fetch(BASE+'SHA512-SUMS.txt',checks)
sums={line.split()[1]:line.split()[0] for line in checks.read_text().splitlines() if len(line.split())==2}
def godot_download(name,dest):
    fetch(BASE+name,dest)
    if digest(dest,'sha512')!=sums[name]:raise RuntimeError('Official SHA-512 mismatch: '+name)
godot=shutil.which('godot') or shutil.which('godot4')
if not godot or not subprocess.check_output([godot,'--version'],text=True).startswith(VERSION+'.'):
    name=f'Godot_v{VERSION}-stable_linux.x86_64.zip'
    archive=DOWNLOADS/name
    godot_download(name,archive)
    with zipfile.ZipFile(archive) as z:z.extractall(TOOLS/'bin')
    godot=str(TOOLS/'bin'/f'Godot_v{VERSION}-stable_linux.x86_64')
    Path(godot).chmod(0o755)
templates=DATA/'godot/export_templates'/f'{VERSION}.stable'
required=['android_debug.apk','android_release.apk','windows_debug_x86_64.exe','windows_release_x86_64.exe','version.txt']
if not all((templates/n).exists() for n in required):
    archive=DOWNLOADS/'templates.tpz'
    godot_download(f'Godot_v{VERSION}-stable_export_templates.tpz',archive)
    templates.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(archive) as z:
        for n in required:(templates/n).write_bytes(z.read('templates/'+n))
manager=SDK/'cmdline-tools/latest/bin/sdkmanager'
if not manager.exists():
    archive=DOWNLOADS/'android-tools.zip'
    fetch('https://dl.google.com/android/repository/commandlinetools-linux-16111833_latest.zip',archive)
    # Official Google repository XML archive checksum (repository2-1.xml).
    if digest(archive,'sha1')!='e025545c62a8e64c7559119566a569fb1dec5f60':
        raise RuntimeError('Google command-line-tools SHA-1 mismatch')
    temporary=TOOLS/'android-extract'
    with zipfile.ZipFile(archive) as z:z.extractall(temporary)
    manager.parent.parent.parent.mkdir(parents=True,exist_ok=True)
    shutil.move(str(temporary/'cmdline-tools'),str(manager.parent.parent))
    for p in manager.parent.iterdir():p.chmod(0o755)
java=Path(shutil.which('java') or '/missing/java').resolve().parent.parent
if not (java/'bin/keytool').exists():raise RuntimeError('Install a JDK (17 or 21) before bootstrap')
env=os.environ.copy()
env.update({'ANDROID_HOME':str(SDK),'ANDROID_USER_HOME':str(TOOLS/'android-home'),'ANDROID_SDK_HOME':str(TOOLS/'android-home'),'JAVA_HOME':str(java),'XDG_DATA_HOME':str(DATA),'XDG_CONFIG_HOME':str(CONFIG),'XDG_CACHE_HOME':str(TOOLS/'cache')})
if not (SDK/'build-tools/35.0.1/apksigner').exists() or not (SDK/'platform-tools/adb').exists() or not (SDK/'platforms/android-35/android.jar').exists():
    subprocess.run([str(manager),'--sdk_root='+str(SDK),'--licenses'],input='y\n'*100,text=True,env=env,check=True)
    subprocess.run([str(manager),'--sdk_root='+str(SDK),'platform-tools','build-tools;35.0.1','platforms;android-35'],env=env,check=True)
keystore=TOOLS/'debug.keystore'
if not keystore.exists():
    subprocess.run([str(java/'bin/keytool'),'-genkeypair','-keystore',str(keystore),'-storepass','android','-alias','androiddebugkey','-keypass','android','-dname','CN=Android Debug,O=RF Worlds,C=DE','-keyalg','RSA','-keysize','2048','-validity','10000'],env=env,check=True)
settings='[gd_resource type="EditorSettings" format=3]\n[resource]\n'
for k,v in {'android_sdk_path':str(SDK),'java_sdk_path':str(java),'debug_keystore':str(keystore),'debug_keystore_user':'androiddebugkey','debug_keystore_pass':'android'}.items():
    settings+=f'export/android/{k} = "{v}"\n'
(CONFIG/'godot/editor_settings-4.6.tres').write_text(settings)
exports={k:env[k] for k in ['ANDROID_HOME','ANDROID_USER_HOME','ANDROID_SDK_HOME','JAVA_HOME','XDG_DATA_HOME','XDG_CONFIG_HOME','XDG_CACHE_HOME']}
exports['GODOT_BIN']=godot
exports['DEADWAVE_TOOLS']=str(TOOLS)
(TOOLS/'env.sh').write_text(''.join('export '+k+'='+shlex.quote(v)+'\n' for k,v in exports.items()))
repo=Path(__file__).resolve().parents[1]
subprocess.run([godot,'--headless','--path',str(repo),'--editor','--import','--quit'],env=env,check=True)
print('Ready. Source '+str(TOOLS/'env.sh')+' before development/build commands.',flush=True)
