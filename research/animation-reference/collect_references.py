"""Download public editorial reference media; no branded art enters the app."""
from concurrent.futures import ThreadPoolExecutor, as_completed
from hashlib import sha256
from html import escape, unescape
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urljoin, urlparse
from urllib.request import Request, urlopen
import csv
import json
import re

ROOT = Path(__file__).resolve().parent
MEDIA = ROOT / 'media'
MEDIA.mkdir(exist_ok=True)
SOURCES = [
    ('building-character', 'https://blog.duolingo.com/building-character/'),
    ('streak-animation', 'https://blog.duolingo.com/streak-milestone-design-animation/'),
    ('zari-3d-production', 'https://blog.duolingo.com/duolingo-art-intern-animation-case-study/'),
    ('female-cast', 'https://blog.duolingo.com/duolingo-female-character-origin-stories/'),
    ('shape-language', 'https://blog.duolingo.com/shape-language-duolingos-art-style/'),
    ('learning-path', 'https://blog.duolingo.com/new-duolingo-home-screen-design/'),
    ('super-duo', 'https://blog.duolingo.com/super-duolingo-launch/'),
    ('falstaff-call', 'https://blog.duolingo.com/beginner-video-call-with-falstaff/'),
    ('lily-roleplay', 'https://blog.duolingo.com/duolingo-max/'),
    ('adventures', 'https://blog.duolingo.com/adventures/'),
    ('cast-poses', 'https://blog.duolingo.com/lgbtq-representation-in-duolingo-stories-and-characters/'),
    ('oscar-chess', 'https://blog.duolingo.com/chess-game-review/'),
]

class MediaParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.items = []
    def handle_starttag(self, tag, attributes):
        a = dict(attributes)
        if tag in ('img', 'source', 'video'):
            src = a.get('src') or a.get('data-src')
            if src:
                self.items.append({'url': src, 'alt': a.get('alt', ''), 'tag': tag})

def read_url(url, limit=20*1024*1024):
    with urlopen(Request(url, headers={'User-Agent': 'Sumi editorial animation reference research'}), timeout=45) as r:
        length = int(r.headers.get('Content-Length') or 0)
        if length > limit:
            raise ValueError(f'File above {limit} byte collection limit')
        body = r.read(limit+1)
        if len(body) > limit:
            raise ValueError(f'File above {limit} byte collection limit')
        return body, r.headers.get_content_type(), r.geturl()

pages, candidates = [], []
for slug, url in SOURCES:
    try:
        raw, mime, final_url = read_url(url, 3*1024*1024)
        html = raw.decode('utf-8')
        start = html.find('<article')
        end = html.find('</article>', start)
        if start < 0 or end < 0:
            raise ValueError('Article boundary not found')
        parser = MediaParser()
        parser.feed(html[start:end])
        page = {'id': slug, 'url': url, 'final_url': final_url, 'fetched_at': '2026-10-27', 'sha256': sha256(raw).hexdigest(), 'candidate_media': len(parser.items)}
        pages.append(page)
        for item in parser.items:
            asset_url = urljoin(final_url, unescape(item['url']))
            host = urlparse(asset_url).hostname or ''
            if host not in ('blog.duolingo.com', 'storage.ghost.io', 'images.prismic.io', 'd35aaqx5ub95lt.cloudfront.net'):
                continue
            extension = Path(urlparse(asset_url).path).suffix.lower()
            if extension not in ('.gif', '.mp4', '.webm', '.png', '.jpg', '.jpeg', '.webp', '.svg'):
                continue
            candidates.append({'source_id': slug, 'source_page': url, 'url': asset_url, 'alt': item['alt'], 'extension': extension})
    except Exception as e:
        pages.append({'id': slug, 'url': url, 'status': 'unavailable', 'error': str(e)})

unique = {}
for candidate in candidates:
    if candidate['url'] not in unique:
        unique[candidate['url']] = candidate

def collect(pair):
    index, item = pair
    entry = dict(item)
    entry['id'] = f'ref-{index:03d}'
    entry['licence'] = 'No reuse/redistribution licence established. Duolingo editorial reference only.'
    entry['app_use'] = 'Do not bundle in Sumi; create original art.'
    name = re.sub('[^A-Za-z0-9_.-]', '-', Path(urlparse(item['url']).path).name)
    path = MEDIA / f"{entry['id']}-{name}"
    try:
        if path.exists():
            body = path.read_bytes()
            mime = 'previously downloaded'
            final = item['url']
        else:
            body, mime, final = read_url(item['url'])
            path.write_bytes(body)
        entry.update(status='downloaded', file=str(path.relative_to(ROOT)).replace('\\', '/'), bytes=len(body), sha256=sha256(body).hexdigest(), content_type=mime, final_url=final)
        try:
            from PIL import Image
            with Image.open(path) as image:
                entry.update(format=image.format, width=image.width, height=image.height, frames=getattr(image, 'n_frames', 1))
                entry['animated'] = entry['frames'] > 1
                if entry['animated']:
                    duration = 0
                    for frame in range(entry['frames']):
                        image.seek(frame)
                        duration += image.info.get('duration', 0)
                    entry['duration_ms'] = duration
        except (ImportError, OSError):
            entry['animated'] = None
    except Exception as e:
        entry.update(status='not-downloaded', reason=str(e))
    return entry

entries = []
with ThreadPoolExecutor(max_workers=4) as pool:
    futures = [pool.submit(collect, pair) for pair in enumerate(unique.values(), start=1)]
    for future in as_completed(futures):
        entry = future.result()
        entries.append(entry)
        print(f"{entry['id']} {entry['status']} {entry.get('bytes', 0)} {entry.get('frames', '?')} frames", flush=True)
entries.sort(key=lambda entry: entry['id'])
manifest = {'date': '2026-10-27', 'scope': f'Media explicitly embedded in {len(SOURCES)} public first-party editorial articles. Not all app animations, all versions, or a licensed character library.', 'sources': pages, 'assets': entries, 'counts': {'discovered': len(entries), 'downloaded': sum(e['status']=='downloaded' for e in entries), 'verified_animated': sum(e.get('animated') is True for e in entries), 'downloaded_bytes': sum(e.get('bytes', 0) for e in entries)}}
(ROOT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
fields = ['id','source_id','alt','status','file','format','width','height','frames','duration_ms','bytes','sha256','url','source_page','licence']
with (ROOT / 'manifest.csv').open('w', newline='', encoding='utf-8-sig') as target:
    writer = csv.DictWriter(target, fieldnames=fields, extrasaction='ignore')
    writer.writeheader()
    writer.writerows(entries)

cards = []
for item in entries:
    media = ''
    if item['status'] == 'downloaded':
        media = f'<img loading="lazy" src="{escape(item["file"])}" alt="{escape(item["alt"])}">'
    cards.append(f'<article><h2>{escape(item["id"])} · {escape(item["source_id"])}</h2>{media}<p>{escape(item["alt"] or "No publisher alt text")}</p><p>{item.get("frames", "?")} frames · {item.get("bytes",0):,} bytes · {escape(item["status"])}</p><a href="{escape(item["source_page"])}">Publisher article</a> · <a href="{escape(item["url"])}">Original asset</a></article>')
document = '<!doctype html><meta charset="utf-8"><title>Duolingo animation reference catalogue</title><style>body{font:16px/1.5 system-ui;background:#f5f5f4;color:#20202a;margin:32px}h1{max-width:900px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(310px,1fr));gap:20px}article{background:white;padding:20px;border-radius:16px}h2{font-size:16px}img{width:100%;height:260px;object-fit:contain}a{color:#343576}</style><h1>Editorial animation references</h1><p>Private design study. Branded artwork is not licensed for reuse in Sumi. GIFs play inline. This is a bounded source collection, not every animation in Duolingo.</p><div class="grid">' + ''.join(cards) + '</div>'
(ROOT / 'catalogue.html').write_text(document, encoding='utf-8')
print(json.dumps(manifest['counts']), flush=True)
