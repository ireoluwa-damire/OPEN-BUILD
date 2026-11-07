from pathlib import Path
import json
import sys
root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root))
from backend.catalog import QUESTIONS, RESOURCES, SKILLS, CALIBRATION
destination = root / "app" / "assets" / "catalog.json"
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_text(json.dumps({"questions": QUESTIONS, "resources": RESOURCES,
    "skills": SKILLS, "calibration": CALIBRATION}, indent=2) + "\n", encoding="utf-8")
print("Client catalogue updated.")
