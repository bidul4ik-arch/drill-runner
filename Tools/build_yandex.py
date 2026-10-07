#!/usr/bin/env python3
"""Isolated Godot 4.3 web export; original desktop imports stay on 4.2."""
from pathlib import Path
import shutil,subprocess,re,json,zipfile,hashlib
ROOT=Path(__file__).resolve().parents[1]
STAGE=ROOT/'Builds/YandexProject';OUT=ROOT/'Builds/Yandex';TC=ROOT/'Builds/Toolchain'
GODOT=TC/'Godot.app/Contents/MacOS/Godot'
STAGE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
for name in ['Main','Script','Scenes','Config','Localization','Audio','Web']:
 shutil.copytree(ROOT/name,STAGE/name,dirs_exist_ok=True)
for name in ['Models','Textures','UI']:
 shutil.copytree(ROOT/'Art'/name,STAGE/'Art'/name,dirs_exist_ok=True)
project=(ROOT/'project.godot').read_text().replace('"Forward Plus"','"GL Compatibility"').replace('renderer/rendering_method="forward_plus"','renderer/rendering_method="gl_compatibility"')
project+='\n[gui]\ntheme/custom_font=\"res://Art/UI/Fonts/DejaVuSans-Bold.ttf\"\n'
(STAGE/'project.godot').write_text(project)
# Export only referenced resources, including dynamically loaded models/configured levels.
files=[]
for folder in ['Main','Scenes','Script']:
 files += ['res://'+p.relative_to(STAGE).as_posix() for p in (STAGE/folder).rglob('*') if p.suffix in ['.tscn','.gd']]
files += ['res://'+p.relative_to(STAGE).as_posix() for p in (STAGE/'Art/Models').glob('*.glb')]
files += ['res://'+p.relative_to(STAGE).as_posix() for p in (STAGE/'Audio').glob('*') if p.suffix in ['.wav','.ogg','.mp3']]
files += ['res://'+p.relative_to(STAGE).as_posix() for folder in ['Art/UI','Art/Textures'] for p in (STAGE/folder).rglob('*') if p.suffix in ['.png','.svg','.gdshader','.ttf','.otf','.tres']]
files += ['res://Art/UI/Lobby/splash.png','res://Art/UI/Lobby/app-icon.png']
preset='''[preset.0]
name="Yandex Games"
platform="Web"
runnable=true
export_filter="resources"
export_files=PackedStringArray(%s)
include_filter="Config/*.json,Localization/*.json"
exclude_filter=""
export_path="%s"
[preset.0.options]
custom_template/release="%s"
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=true
html/custom_html_shell="res://Web/shell.html"
html/canvas_resize_policy=0
html/focus_canvas_on_start=true
progressive_web_app/enabled=false
'''%(','.join(json.dumps(x) for x in files),(OUT/'index.html').as_posix(),(TC/'web_nothreads_release.zip').as_posix())
(STAGE/'export_presets.cfg').write_text(preset)
# Web image imports: lossless originals stay in source; mobile-sized GPU textures in this build.
for folder in ['Models','Textures']:
 for p in (STAGE/'Art'/folder).rglob('*.png.import'):
  s=p.read_text();s=s.replace('compress/mode=0','compress/mode=1')
  s=s.replace('process/size_limit=0','process/size_limit=1024')
  p.write_text(s)
for phase,args in [('import',['--editor','--import']),('export',['--export-release','Yandex Games',str(OUT/'index.html')])]:
 with open(ROOT/f'Tests/Yandex/{phase}.log','w') as log:
  result=subprocess.run([str(GODOT),'--headless','--path',str(STAGE)]+args,stdout=log,stderr=subprocess.STDOUT,timeout=600)
 print(phase,result.returncode,flush=True)
 if result.returncode:raise SystemExit(result.returncode)
for src,dst in [('Web/GODOT-LICENSE.txt','godot-license.txt'),('Web/save-store.js','save-store.js'),('Web/yandex.js','yandex.js'),('Art/UI/Lobby/splash.png','splash.png'),('Art/UI/Lobby/app-icon.png','app-icon.png'),('Art/UI/Fonts/LICENSE.txt','fonts-license.txt')]:shutil.copy(ROOT/src,OUT/dst)
archive=ROOT/'Builds/DrillDrop-Yandex.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 for p in OUT.iterdir():
  if p.is_file():z.write(p,p.name)
size=sum(p.stat().st_size for p in OUT.iterdir() if p.is_file())
print('Uncompressed bytes',size,'ZIP bytes',archive.stat().st_size,flush=True)
if any(not re.fullmatch(r'[A-Za-z0-9_.-]+',p.name) for p in OUT.iterdir() if p.is_file()):raise SystemExit('Invalid archive filename')
if size>100_000_000:raise SystemExit('Yandex 100 MB limit exceeded')
(ROOT/'Tests/Yandex/build.json').write_text(json.dumps({'uncompressed_bytes':size,'zip_bytes':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest()},indent=2)+'\n')
