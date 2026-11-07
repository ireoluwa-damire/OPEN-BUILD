"""Extract selected REA screenshots, verify local deliverables, and package the pack."""
from pathlib import Path
import base64
import hashlib
import json
import re
import zipfile

ROOT = Path(__file__).resolve().parent
bundle = json.loads((ROOT / "rea-evidence-bundle.json").read_text(encoding="utf-8"))
records = {row["evidence_id"]: row for row in bundle["records"]}
selected = [
    ("01-landing", "ev_4dc26b6753f6f22df4bd2a307826ff269663773387963359cd12fa1f110ecf60", "landing-ready"),
    ("02-subjects", "ev_ddfa510a04087119ff3c2160d3638a82007b9a68620b1e8e4ecd1ce24bc5be46", "onboarding-ready"),
    ("03-welcome", "ev_2c7cd0d394193077bdabbdebad526ed9b4c08e70fa9277772588b5229ad47cd5", "wait-welcome"),
    ("04-referral", "ev_2c7cd0d394193077bdabbdebad526ed9b4c08e70fa9277772588b5229ad47cd5", "intro-complete"),
    ("05-motivation", "ev_f4da35ecf26f2113811b4d2bde91b5f891091d24328f065789b1b323189a7fda", "goal-screen"),
    ("06-proficiency", "ev_44b0b491749070a2d9ded69f6deccd4b7be703ebbec6bb0a6ac3ed8258c16ec4", "level-screen"),
    ("07-outcomes", "ev_89adc3d9deddb72f436117e9254a8fcbe4cd26ba60f83a670ce652274a367c6a", "new-screen"),
    ("08-daily-goal", "ev_28e5b369c89d03a54b20eb54e7382114160de578dfbe41eff35e7a1bd583c1e1", "daily-goal-screen"),
    ("09-starting-route", "ev_8fd936d83eef2dec72804c03c1200d95e4f0fdba3bdc23a25f788b6dea5d652e", "commitment-screen"),
    ("10-first-exercise", "ev_2926e216ffbd849c4b58b158667dd4468c6307f9e2d2ee44e0ddfc6f28416a44", "next-view"),
    ("11-correct-feedback", "ev_6bc5fb8c8e58990892e4988b43a6a2a6a4b03e22a7d204332b28c1149bdeb8af", "feedback-ready"),
]
captures = ROOT / "captures"
captures.mkdir(exist_ok=True)
index = []
for name, evidence_id, step_id in selected:
    record = records[evidence_id]
    step = next(row for row in record["normalized_result"]["steps"] if row["step_id"] == step_id)
    assert step["status"] == "completed", name
    artifacts = step["artifacts"]
    screen = artifacts["screenshot"]
    assert screen["state"] == "captured", name
    raw = base64.b64decode(screen["value"]["data_base64"], validate=True)
    digest = hashlib.sha256(raw).hexdigest()
    assert digest == screen["value"]["sha256"], name
    assert len(raw) == screen["value"]["bytes"], name
    png = captures / f"{name}.png"
    png.write_bytes(raw)
    text = artifacts["accessibility"]["value"]["text"]
    assert hashlib.sha256(text.encode("utf-8")).hexdigest() == artifacts["accessibility"]["value"]["sha256"]
    (captures / f"{name}.txt").write_text(text, encoding="utf-8")
    index.append({
        "name": name,
        "evidence_id": evidence_id,
        "step_id": step_id,
        "url": step["after_url"]["url"],
        "screenshot": png.name,
        "accessibility_text": f"{name}.txt",
        "screenshot_sha256": digest,
        "capture_completeness": step["completeness"],
    })
(captures / "index.json").write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8")

tokens = json.loads((ROOT / "design-tokens.json").read_text(encoding="utf-8"))
def luminance(value):
    rgb = [int(value[i:i+2], 16) / 255 for i in (1, 3, 5)]
    linear = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb]
    return sum(a*b for a,b in zip(linear, (.2126, .7152, .0722)))

color = tokens["color"]
pairs = [
    ("textPrimary", "background"), ("textPrimary", "surface"),
    ("textSecondary", "background"), ("textSecondary", "surface"),
    ("onPrimary", "primary"), ("textPrimary", "selectedBackground"),
    ("successText", "successBackground"), ("retryText", "retryBackground"),
]
contrast = []
for foreground, background in pairs:
    a, b = sorted((luminance(color[foreground]), luminance(color[background])))
    ratio = (b + .05) / (a + .05)
    assert ratio >= 4.5, (foreground, background, ratio)
    contrast.append({"foreground": foreground, "background": background, "ratio": round(ratio, 2)})

md_files = [ROOT / f for f in ("README.md", "duolingo-teardown.md", "mvp-blueprint.md", "sources-and-materials.md")]
md_files += [ROOT / "mascots" / "mascot-directions.md"]
local_links = []
for doc in md_files:
    text = doc.read_text(encoding="utf-8")
    assert "\ufffd" not in text
    for target in re.findall(r"\]\(([^)]+)\)", text):
        if not re.match(r"https?://", target):
            assert (doc.parent / target).exists(), (doc.name, target)
            local_links.append({"document": doc.name, "target": target})
    for evidence_id in set(re.findall(r"ev_[0-9a-f]{64}", text)):
        assert evidence_id in records, evidence_id

upstream = ROOT / "reusable" / "halflife-regression"
manifest = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(upstream.iterdir()) if p.is_file() and p.name != "checksums.json"}
(upstream / "checksums.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
validation = {
    "prepared_client_date": "2026-10-27",
    "selected_screenshots_verified": len(index),
    "retained_rea_records": len(records),
    "local_markdown_links_verified": len(local_links),
    "text_contrast_checks": contrast,
    "scope": "Research-artifact validation only; no app or model benchmark was run.",
    "upstream_code_status": "Archived and inspected; not executed or modernized.",
}
(ROOT / "validation.json").write_text(json.dumps(validation, indent=2) + "\n", encoding="utf-8")

excluded = {"brief-3.png", "brief-4.png", "brief-5.png", "duolingo-landing-dom.txt", "duolingo-landing-mobile.png", "duolingo-landing-accessibility.txt"}
archive = ROOT.parent / "OPEN-BUILD-reference-pack.zip"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as z:
    for file in sorted(ROOT.rglob("*")):
        if file.is_file() and file.name not in excluded:
            z.write(file, Path("research") / file.relative_to(ROOT))
with zipfile.ZipFile(archive, "r") as z:
    assert z.testzip() is None
print(json.dumps({"screenshots": len(index), "records": len(records), "contrast": contrast, "zip": str(archive), "zip_bytes": archive.stat().st_size}, indent=2))
