from pathlib import Path
from urllib.parse import urlparse
import collections
import hashlib
import json
import re

root = Path(__file__).resolve().parent / 'runtime'
path = root / 'sources/app-c4519c5a.js'
text = path.read_text(encoding='utf-8')
sha = hashlib.sha256(path.read_bytes()).hexdigest()
manifest = (root / 'sources/manifest-9f2aff54.js').read_text(encoding='utf-8')
cdn = re.findall(r'\w\.p="(https://[^"\s]+/)"', manifest)
print('Public asset prefix:', cdn)
assets = []
for match in re.finditer(r'"((?:rive|lottie)/[^"\s]+\.(?:riv|json|lottie))"', text):
    rel = match.group(1)
    assets.append({'relative_url':rel,'character_start':match.start(1),'character_end':match.end(1),'source_sha256':sha})
seen = set()
assets = [a for a in assets if not(a['relative_url'] in seen or seen.add(a['relative_url']))]
first = next(a['character_start'] for a in assets if a['relative_url'].startswith('rive/makerInLesson/'))
end = text.find(',H=e=>',first)
block = text[first-20:end]
aliases = dict(re.findall(r'([A-Za-z_$][\w$]*)=a\.p\+"(rive/makerInLesson/[^\"]+)"',block))
characters=[]
for match in re.finditer(r'(\w+):\{scale:([\d.]+),url:([A-Za-z_$][\w$]*),xOffset:(-?\d+),yOffset:(-?\d+)\}',block):
    character,scale,alias,x,y=match.groups()
    if alias in aliases:
        characters.append({'character':character,'relative_url':aliases[alias],'scale':float(scale),'x_offset':int(x),'y_offset':int(y),'association':'literal object and in-scope constant in acquired source; not observed playback'})
state_start = block.find('M={artBoardName:')
state_end = block.find('},U=',state_start)
states = dict(re.findall(r'(\w+):"([^"]+)"',block[state_start:state_end]))
upper = sorted(set(re.findall(r'\b(?:DUO|LILY|ZARI|JUNIOR|EDDY|BEA|LIN|LUCY|OSCAR|VIKRAM|FALSTAFF)_[A-Z0-9_]+\b',text)))
paths=[]
for match in re.finditer(r'([A-Z][A-Z0-9_]+):\{([^{}]+)\}',text):
    body=match.group(2)
    animation=re.search(r'animation:a\.p\+"([^"]+)"',body)
    if animation and animation.group(1).startswith(('lottie/','rive/')):
        paths.append({'symbolic_name':match.group(1),'relative_url':animation.group(1),'source_character_range':[match.start(),match.end()],'association':'direct literal property in object registry, not observed playback'})
    elif 'animation:a(' in body:
        module=re.search(r'animation:a\((\d+)\)',body)
        if module:
            node={'symbolic_name':match.group(1),'bundled_module_candidate':module.group(1),'source_character_range':[match.start(),match.end()],'association':'bundled module reference; unresolved unless exact literal factory is found'}
            factory=re.search(r'\b'+module.group(1)+r':\([^)]*\)=>\{([^{}]*)\}',text)
            if factory:
                literal=re.search(r'\.exports=\w\.p\+"((?:lottie|rive)/[^\"]+)"',factory.group(1))
                if literal:
                    node.update(relative_url=literal.group(1),factory_character_range=[factory.start(),factory.end()],association='literal object to exact bundled module factory exporting a public-path asset; not observed playback')
            paths.append(node)
report = {'date':'2026-10-27','source_file':'sources/app-c4519c5a.js','source_sha256':sha,'public_path_prefix_candidates':cdn,'assets':assets,'path_registry':paths,'in_lesson_registry':{'character_associations':characters,'state_and_artboard_names':states,'source_character_range':[first-20,end]},'symbolic_action_names':upper,'coverage':'Literal registries in one acquired guest-web application bundle. Names imply design intent; no execution/reachability, full file parsing or current native coverage established.'}
(root / 'registry.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps({'counts':dict(collections.Counter(a['relative_url'].split('/')[0] for a in assets)),'characters':characters,'state_names':states,'symbolic_action_names':upper},indent=2))
first_lottie = next(a for a in assets if a['relative_url'].startswith('lottie/pathCharacters/'))
i=first_lottie['character_start']
print('Lottie registry excerpt:',text[i-200:i+1800])
