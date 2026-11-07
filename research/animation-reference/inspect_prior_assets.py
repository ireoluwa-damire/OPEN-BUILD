from pathlib import Path
from urllib.parse import urlparse
import collections
import json

root = Path(__file__).resolve().parent
bundle_path = root.parent / 'rea-evidence-bundle.json'
bundle = json.loads(bundle_path.read_text(encoding='utf-8'))
scripts, media = {}, {}
hosts = collections.Counter()
for record in bundle['records']:
    events = record.get('normalized_result', {}).get('events', {}).get('items', [])
    for event in events:
        url = event.get('url', {})
        url = url.get('url', '') if isinstance(url, dict) else url or ''
        if not url:
            continue
        parts = urlparse(url)
        hosts[parts.hostname] += 1
        if event.get('resource_type') == 'script' or parts.path.endswith('.js'):
            scripts.setdefault(url, []).append(record['evidence_id'])
        if any(parts.path.endswith(ext) for ext in ('.riv', '.lottie', '.json', '.webm', '.mp4', '.gif')):
            media.setdefault(url, []).append(record['evidence_id'])
for group in (scripts, media):
    for key, values in group.items():
        group[key] = sorted(set(values))
report = {'bundle': str(bundle_path), 'records': len(bundle['records']), 'bundle_bytes': bundle_path.stat().st_size, 'scripts': scripts, 'media': media, 'hosts': dict(hosts)}
(root / 'prior-runtime-urls.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps({'records': report['records'], 'bundle_bytes': report['bundle_bytes'], 'script_count': len(scripts), 'scripts': list(scripts)[:25], 'media_count': len(media), 'media': media, 'hosts': hosts.most_common(10)}, indent=2))
