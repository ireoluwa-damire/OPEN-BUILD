from pathlib import Path
from html import escape
import csv
import json
import shutil
import zipfile

root=Path(__file__).resolve().parent
runtime=root/'runtime'
registry=json.loads((runtime/'registry.json').read_text(encoding='utf-8'))
manifest=json.loads((runtime/'asset-manifest.json').read_text(encoding='utf-8'))
aliases={}
for entry in registry['path_registry']:
    if 'relative_url' in entry:
        aliases.setdefault(entry['relative_url'],[]).append(entry['symbolic_name'])
for entry in registry['in_lesson_registry']['character_associations']:
    aliases.setdefault(entry['relative_url'],[]).append(entry['character'].upper()+' · in-lesson rig')
rows=[]
csv_rows=[]
for asset in manifest['assets']:
    names=', '.join(aliases.get(asset['relative_url'],[])) or 'No specific actor/action mapped in this pass'
    duration=f"{asset['duration_seconds']}s · {asset['frame_rate']}fps" if 'duration_seconds' in asset else 'RIVE header checked; internal timelines not parsed'
    rows.append('<tr><td><strong>'+escape(names)+'</strong><br><small>'+escape(asset['relative_url'])+'</small></td><td>'+escape(asset.get('format','unknown'))+'<br>'+escape(duration)+'</td><td>'+f"{asset.get('bytes',0):,}"+' bytes<br><code>'+escape(asset.get('sha256','')[:16])+'…</code></td><td><a download href="'+escape(asset.get('file','#'))+'">Local export</a><br><a href="'+escape(asset['url'])+'">Original CDN URL</a></td></tr>')
    csv_rows.append({'names':names,**asset})
head='<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Public guest-web animation exports</title><style>body{font:16px/1.5 system-ui;color:#20202a;background:#f8f7f3;margin:24px}main{max-width:1200px;margin:auto}table{width:100%;border-collapse:collapse;background:white}td,th{padding:14px;text-align:left;border-bottom:1px solid #ddd;vertical-align:top}small{overflow-wrap:anywhere;color:#666}a{color:#343576}input{padding:12px;border:1px solid #aaa;border-radius:8px;width:min(90%,550px);margin:16px 0}code{font-size:12px}@media(max-width:650px){td,th{padding:8px}table{font-size:12px}}</style><main><h1>Public guest-web animation exports</h1><p>75 acquired exports:59 Lottie JSON files and16 Rive binary candidates. Source registries map42 general path actions,6 Math path actions and10 in-lesson character rigs. Remaining exports retain their source directory labels. Names are static source observations; animations have not been played in this follow-up.</p><p><strong>Private reference only.</strong> Original character rights remain with Duolingo/respective owners. No reusable licence or editable authoring project was established. Do not ship these files in Sumi.</p><p><a href="../runtime-asset-inventory.md">Evidence, state names and limitations</a> · <a href="asset-manifest.json">Complete asset manifest</a> · <a href="registry.json">Source registry and character offsets</a></p><label for="filter">Filter character, action, group or format</label><br><input id="filter" type="search" placeholder="Try Duo, Lily, correct, math or splash"><table><thead><tr><th>Source association</th><th>Format and timing metadata</th><th>Size and SHA-256 prefix</th><th>Files</th></tr></thead><tbody>'
tail='</tbody></table></main><script>document.getElementById("filter").addEventListener("input",function(){const q=this.value.toLowerCase();document.querySelectorAll("tbody tr").forEach(row=>row.hidden=!row.textContent.toLowerCase().includes(q));});</script>'
(runtime/'asset-index.html').write_text(head+''.join(rows)+tail,encoding='utf-8')
fields=['names','relative_url','url','file','format','status','bytes','sha256','duration_seconds','frame_rate','width','height','rive_magic']
with (runtime/'asset-manifest.csv').open('w',newline='',encoding='utf-8-sig') as target:
    writer=csv.DictWriter(target,fieldnames=fields,extrasaction='ignore')
    writer.writeheader()
    writer.writerows(csv_rows)
(runtime/'NOTICE.txt').write_text((root/'NOTICE.txt').read_text(encoding='utf-8'),encoding='utf-8')
shutil.copyfile(root.parent/'rea-evidence-bundle.json', runtime/'prior-guest-web-evidence.json')
archive=runtime/'runtime-reference-pack.zip'
files=sorted(p for p in runtime.rglob('*') if p.is_file() and p.suffix!='.zip' and p.name!='registry-extraction.log')
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=1) as output:
    for path in files:
        output.write(path,Path('runtime')/path.relative_to(runtime))
    output.write(root/'runtime-asset-inventory.md','runtime-asset-inventory.md')
with zipfile.ZipFile(archive,'r') as check:
    bad=check.testzip()
    if bad:
        raise RuntimeError('ZIP integrity failure: '+bad)
print(json.dumps({'index_rows':len(rows),'archive':str(archive),'archive_bytes':archive.stat().st_size,'archive_files':len(files)+1,'zip_integrity':'passed'}))
