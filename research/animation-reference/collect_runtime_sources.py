"""Bounded public guest-web bundle acquisition, never executes downloaded code."""
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.parse import urlparse
import hashlib
import gzip
import io
import json
import re

root = Path(__file__).resolve().parent
work = root / 'runtime'
source_dir = work / 'sources'
source_dir.mkdir(parents=True, exist_ok=True)
prior = json.loads((root / 'prior-runtime-urls.json').read_text(encoding='utf-8'))
names = ['manifest-9f2aff54.js', 'features-91ec4487.js', 'app-c4519c5a.js']
urls = [url for url in prior['scripts'] if urlparse(url).hostname == 'd35aaqx5ub95lt.cloudfront.net' and Path(urlparse(url).path).name in names]
records = []
for url in urls:
    record = {'url': url, 'prior_evidence_ids': prior['scripts'][url], 'date': '2026-10-27'}
    path = source_dir / Path(urlparse(url).path).name
    try:
        if path.exists():
            data = path.read_bytes()
        else:
            with urlopen(Request(url, headers={'User-Agent':'Sumi public guest-web animation-reference research'}), timeout=45) as response:
                if int(response.headers.get('Content-Length') or 0) > 24*1024*1024:
                    raise ValueError('Source above 24MiB acquisition bound')
                data = response.read(24*1024*1024+1)
                if len(data) > 24*1024*1024:
                    raise ValueError('Source above 24MiB acquisition bound')
                path.write_bytes(data)
        if data.startswith(b'\x1f\x8b'):
            wire = data
            with gzip.GzipFile(fileobj=io.BytesIO(wire)) as stream:
                data = stream.read(48*1024*1024+1)
            if len(data) > 48*1024*1024:
                raise ValueError('Decoded source above 48MiB bound')
            raw_path = path.with_suffix('.js.gz')
            raw_path.write_bytes(wire)
            path.write_bytes(data)
            record.update(acquired_encoding='gzip-by-magic', encoded_file=str(raw_path.relative_to(root)).replace('\\','/'), encoded_bytes=len(wire), encoded_sha256=hashlib.sha256(wire).hexdigest())
        text = data.decode('utf-8')
        patterns = {
            'rive_asset': r'[^\s"\'`<>]{0,200}\.riv(?:\?[^\s"\'`<>]*)?',
            'lottie_asset': r'[^\s"\'`<>]{0,200}\.lottie(?:\?[^\s"\'`<>]*)?',
            'animation_json_candidate': r'[^\s"\'`<>]{0,150}(?:animat|lottie)[^\s"\'`<>]{0,150}\.json',
        }
        matches=[]
        for kind, pattern in patterns.items():
            for match in re.finditer(pattern,text,re.IGNORECASE):
                matches.append({'kind':kind,'text':match.group(),'character_start':match.start(),'character_end':match.end(),'context':text[max(0,match.start()-140):match.end()+140]})
        record.update(status='acquired',file=str(path.relative_to(root)).replace('\\','/'),bytes=len(data),sha256=hashlib.sha256(data).hexdigest(),matches=matches,keyword_counts={word:len(re.findall(word,text,re.IGNORECASE)) for word in ['lottie','rive','animation','stateMachine']})
        print(f"{path.name}: {len(data)} bytes; {len(matches)} asset candidates; {record['keyword_counts']}",flush=True)
    except Exception as e:
        record.update(status='unavailable',reason=str(e))
        print(f'{url}: {e}',flush=True)
    records.append(record)
(work / 'source-manifest.json').write_text(json.dumps({'scope':'Three exact first-party guest-web bundles observed by earlier REA capture; no downloaded code executed','sources':records},indent=2),encoding='utf-8')
