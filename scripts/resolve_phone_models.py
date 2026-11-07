"""Pin public model files and published SHA-256 values; does not fetch weights."""
from pathlib import Path
from urllib.request import urlopen
import json

root = Path(__file__).resolve().parents[1]
choices = [
    ('qwen3-small', 'Qwen3 0.6B', 'Qwen/Qwen3-0.6B-GGUF', 'Qwen3-0.6B-Q8_0.gguf', 'Q8_0', 'apache-2.0', 3, 'Smallest starter option. Text only; modest reasoning ability.'),
    ('qwen3-medium', 'Qwen3 1.7B', 'Qwen/Qwen3-1.7B-GGUF', 'Qwen3-1.7B-Q8_0.gguf', 'Q8_0', 'apache-2.0', 5, 'More storage and memory. Try the small model first.'),
    ('deepseek-distill', 'DeepSeek R1 Distill Qwen 1.5B', 'bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF', 'DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf', 'Q4_K_M', 'mit', 4, 'Community GGUF conversion of a distilled model. This is not DeepSeek V4.1.'),
]
models = []
for identifier, name, repo, filename, quant, license_id, ram, note in choices:
    with urlopen(f'https://huggingface.co/api/models/{repo}?blobs=true', timeout=40) as response:
        data = json.load(response)
    entry = next(s for s in data['siblings'] if s['rfilename'] == filename)
    lfs = entry['lfs']
    digest = lfs['sha256']
    assert len(digest) == 64
    models.append(dict(id=identifier, name=name, repo=repo, file=filename,
        revision=data['sha'], sha256=digest, bytes=lfs['size'], quantization=quant,
        license=license_id, suggested_ram_gb=ram, note=note))
    print(f"Pinned {name}: {lfs['size']} bytes", flush=True)
target = root / 'app/assets/model_catalog.json'
target.write_text(json.dumps({'models': models}, indent=2) + '\n', encoding='utf-8')
