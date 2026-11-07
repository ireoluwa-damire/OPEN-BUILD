"""Evidence-based scheduling. The model can explain a route, not invent scores."""
import math
from datetime import datetime, timezone
from .catalog import QUESTIONS, RESOURCES, SKILLS, CALIBRATION

def grade_attempt(question_id, answer_index, used_hint=False, active_seconds=0):
    question = next((q for q in QUESTIONS if q["id"] == question_id), None)
    if question is None:
        raise ValueError("Unknown question.")
    if answer_index is not None and (isinstance(answer_index, bool) or answer_index not in range(len(question["options"]))):
        raise ValueError("Answer must identify a listed option.")
    correct = answer_index == question["correct"]
    return {
        "question_id": question_id, "skill": question["skill"], "answer_index": answer_index,
        "correct": correct, "correct_index": question["correct"], "used_hint": used_hint,
        "active_seconds": min(max(float(active_seconds), 0), 3600),
        "explanation": question["explanation"], "resource_id": question["resource_id"],
        "independent": correct and not used_hint,
        "recorded_at": datetime.now(timezone.utc).isoformat(),
    }

def build_plan(goal, daily_minutes, attempts, completed_skills=None, replay=False):
    if daily_minutes not in (10, 15, 20, 30):
        raise ValueError("Choose 10, 15, 20, or 30 minutes.")
    if not isinstance(goal, str) or not 3 <= len(goal.strip()) <= 300:
        raise ValueError("Describe your goal in 3 to 300 characters.")
    completed = set(completed_skills or [])
    known_ids = {skill["id"] for skill in SKILLS}
    if not completed <= known_ids:
        raise ValueError("Unknown completed capability.")
    for skill in SKILLS:
        if skill["id"] in completed and not set(skill["prerequisites"]) <= completed:
            raise ValueError("Complete the prerequisite project steps first.")
    # The first answer is baseline evidence. Repeated answers do not erase gaps.
    by_skill = {}
    for attempt in attempts:
        question = next((q for q in QUESTIONS if q["id"] == attempt.get("question_id")), None)
        if question is None:
            raise ValueError("Unknown question.")
        if question and question["skill"] not in by_skill:
            by_skill[question["skill"]] = grade_attempt(
                question["id"], attempt.get("answer_index"),
                bool(attempt.get("used_hint", False)), attempt.get("active_seconds", 0))
    independent = {key for key, value in by_skill.items() if value["independent"]}
    milestones = []
    first_open = next((s["id"] for s in SKILLS if s["id"] not in completed), None)
    for i, skill in enumerate(SKILLS):
        ready = skill["id"] in independent
        minutes = max(10, math.ceil(skill["minutes"] * (.5 if ready else 1)))
        status = "complete" if skill["id"] in completed else "current" if skill["id"] == first_open else "upcoming"
        reason = ("You showed a starting understanding. Apply it to a new example."
                  if ready else "A little focused practice will support the next part of your project.")
        milestones.append({
            **skill, "order": i+1, "status": status, "reason": reason,
            "estimated_minutes": minutes, "baseline_ready": ready,
            "evidence": "independent baseline answer" if ready else "practice recommended",
        })
    remaining = sum(m["estimated_minutes"] for m in milestones if m["status"] != "complete")
    days = max(1, math.ceil(remaining / daily_minutes))
    return {
        "goal": goal.strip(), "daily_minutes": daily_minutes, "track": "Python project foundations",
        "project": "Build a Python expense summarizer", "confidence": "Provisional",
        "summary": "Small steps, chosen from what you have shown so far. Your route will improve as you practice.",
        "milestones": milestones, "resources": RESOURCES, "calibration": CALIBRATION,
        "independent_answers": len(independent), "answered": len(by_skill), "remaining_minutes": remaining,
        "estimated_days_min": days, "estimated_days_max": math.ceil(days * 1.4),
        "completed_skills": list(s["id"] for s in SKILLS if s["id"] in completed),
        "engine": "reviewed-rules", "model": None, "model_note": "Built from reviewed content and your baseline.",
        "replay": replay,
    }
