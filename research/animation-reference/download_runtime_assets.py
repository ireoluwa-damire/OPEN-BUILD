from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from urllib.request import Request,urlopen
import collections
import gzip
import hashlib
import io
import json
import re

root=Path(__file__).resolve().parent/'runtime'
registry=json.loads((root/'registry.json').read_text(encoding='utf-8'))
prefix=registry['public_path_prefix_candidates'][0]
records=[]

def collect(item):
    relative=item['relative_url']
    url=prefix+relative
    path=root/'assets'/relative
    record={'relative_url':relative,'url':url,'source_sha256':registry['source_sha256'],'source_character_range':[item['character_start'],item['character_end']],'licence':'No reuse or redistribution licence established; private reference only. Do not bundle in Sumi.'}
    try:
        if path.exists():
            data=path.read_bytes()
        else:
            with urlopen(Request(url,headers={'User-Agent':'Sumi public guest-web animation reference study'}),timeout=35) as response:
                if int(response.headers.get('Content-Length') or 0)>4*1024*1024:
                    raise ValueError('Asset above 4MiB bounded acquisition limit')
                data=response.read(4*1024*1024+1)
                if len(data)>4*1024*1024:
                    raise ValueError('Asset above 4MiB acquisition limit')
                record['response_content_type']=response.headers.get_content_type()
                record['content_encoding']=response.headers.get('Content-Encoding')
            if data.startswith(b'\x1f\x8b'):
                encoded=data
                with gzip.GzipFile(fileobj=io.BytesIO(data)) as stream:
                    data=stream.read(16*1024*1024+1)
                if len(data)>16*1024*1024:
                    raise ValueError('Decoded asset above 16MiB bound')
                record.update(encoded_sha256=hashlib.sha256(encoded).hexdigest(),encoded_bytes=len(encoded))
            path.parent.mkdir(parents=True,exist_ok=True)
            path.write_bytes(data)
        record.update(status='downloaded',file=str(path.relative_to(root)).replace('\\','/'),bytes=len(data),sha256=hashlib.sha256(data).hexdigest())
        if relative.endswith('.json'):
            parsed=json.loads(data)
            if not isinstance(parsed,dict) or not all(k in parsed for k in ('v','fr','ip','op','layers')):
                raise ValueError('JSON does not match selected Lottie structural fields')
            record.update(format='Lottie JSON',version=parsed['v'],frame_rate=parsed['fr'],in_frame=parsed['ip'],out_frame=parsed['op'],width=parsed.get('w'),height=parsed.get('h'),layer_count=len(parsed['layers']),top_layer_names=[l.get('nm') for l in parsed['layers'][:8]],duration_seconds=round((parsed['op']-parsed['ip'])/parsed['fr'],3) if parsed['fr'] else None,external_image_candidates=[{'u':a.get('u'),'p':a.get('p')} for a in parsed.get('assets',[]) if a.get('p') and not str(a['p']).startswith('data:')])
        else:
            record.update(format='Rive binary candidate',header_hex=data[:12].hex(),rive_magic=data.startswith(b'RIVE'))
            strings=re.findall(rb'[\x20-\x7e]{4,100}',data)
            record['state_string_candidates']=sorted(set(s.decode('ascii') for s in strings if any(term in s.lower() for term in (b'trig',b'state',b'bool',b'idle',b'correct',b'artboard'))))[:30]
    except Exception as e:
        record.update(status='unavailable',reason=str(e))
    print(f"{record['status']} {relative} {record.get('bytes',0)}",flush=True)
    return record

with ThreadPoolExecutor(max_workers=4) as executor:
    for future in as_completed([executor.submit(collect,item) for item in registry['assets']]):
        records.append(future.result())
records.sort(key=lambda r:r['relative_url'])
out={'date':'2026-10-27','scope':'Only 75 literal Rive/Lottie URLs present in one prior-observed public guest-web bundle; no code or animations executed.','counts':{'referenced':len(records),'downloaded':sum(r['status']=='downloaded' for r in records),'bytes':sum(r.get('bytes',0) for r in records),'formats':dict(collections.Counter(r.get('format','unavailable') for r in records))},'assets':records}
(root/'asset-manifest.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out['counts']),flush=True)
