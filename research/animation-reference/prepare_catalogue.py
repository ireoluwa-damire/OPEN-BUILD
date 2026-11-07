from pathlib import Path
from PIL import Image, ImageDraw, ImageOps
import base64
import json

root = Path(__file__).resolve().parent
manifest = json.loads((root / 'manifest.json').read_text(encoding='utf-8'))
animated = [a for a in manifest['assets'] if a.get('animated')]
cell_width, cell_height = 240, 200
sheet = Image.new('RGB', (cell_width*3, cell_height*len(animated)), '#eeeeec')
draw = ImageDraw.Draw(sheet)
for row, item in enumerate(animated):
    with Image.open(root / item['file']) as im:
        frames = [0, im.n_frames//2, im.n_frames-1]
        for col, frame in enumerate(frames):
            im.seek(frame)
            thumb = ImageOps.contain(im.convert('RGBA'), (224, 162))
            x = col*cell_width + (cell_width-thumb.width)//2
            y = row*cell_height + 25 + (162-thumb.height)//2
            sheet.paste(thumb, (x,y), thumb)
            draw.text((col*cell_width+8,row*cell_height+6), f"{item['id']} frame {frame+1}/{im.n_frames}", fill='#20202a')
sheet.save(root / 'animated-contact-sheet.jpg', quality=90)
bundle = json.loads((root / 'rea-evidence-bundle.json').read_text(encoding='utf-8'))
record = next(r for r in bundle['records'] if r['evidence_id'] == 'ev_8707b868793d0447a1caea4bf0e83cdffa2da37c14645006cdd440bb824e680c')
artifacts = record['normalized_result']['steps'][-1]['artifacts']
(root / 'rea-streak-article.png').write_bytes(base64.b64decode(artifacts['screenshot']['value']['data_base64']))
(root / 'rea-streak-dom.html').write_text(artifacts['dom']['value']['text'], encoding='utf-8')
(root / 'rea-streak-accessibility.txt').write_text(artifacts['accessibility']['value']['text'], encoding='utf-8')
print(f"Prepared contact sheet for {len(animated)} multi-frame GIFs and extracted REA capture.")
