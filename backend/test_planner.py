import unittest
from unittest.mock import patch
from .catalog import QUESTIONS, public_questions
from .planner import build_plan, grade_attempt
from .model_service import personalize

class LearningEvidenceTests(unittest.TestCase):
    def test_catalog_never_exposes_answer_keys(self):
        self.assertTrue(all("correct" not in q and "explanation" not in q for q in public_questions()))

    def test_hint_does_not_count_as_independent_success(self):
        self.assertFalse(grade_attempt("values-1", 1, used_hint=True)["independent"])

    def test_correcting_same_item_does_not_erase_baseline(self):
        plan = build_plan("Build an expense tool", 15, [
            {"question_id": "values-1", "answer_index": 0},
            {"question_id": "values-1", "answer_index": 1}])
        self.assertEqual(plan["independent_answers"], 0)

    def test_different_baselines_change_practice_workload(self):
        strong = build_plan("Build an expense tool", 15,
                            [{"question_id": q["id"], "answer_index": q["correct"]} for q in QUESTIONS])
        novice = build_plan("Build an expense tool", 15, [])
        self.assertLess(strong["remaining_minutes"], novice["remaining_minutes"])
        self.assertEqual(strong["confidence"], "Provisional")

    def test_order_respects_prerequisites(self):
        plan = build_plan("Build an expense tool", 15, [])
        seen = set()
        for step in plan["milestones"]:
            self.assertTrue(set(step["prerequisites"]) <= seen)
            seen.add(step["id"])

    def test_unknown_completion_rejected(self):
        with self.assertRaises(ValueError):
            build_plan("Build an expense tool", 15, [], ["invented"])

    def test_out_of_order_completion_rejected(self):
        with self.assertRaises(ValueError):
            build_plan("Build an expense tool", 15, [], ["files"])

    def test_unknown_baseline_item_rejected(self):
        with self.assertRaises(ValueError):
            build_plan("Build an expense tool", 15, [{"question_id": "invented", "answer_index": 0}])

    def test_skipped_answer_is_valid_evidence(self):
        result = grade_attempt("values-1", None)
        self.assertFalse(result["correct"])
        self.assertIsNone(result["answer_index"])

    @patch("backend.model_service._request")
    def test_model_cannot_inject_unknown_milestone(self, request):
        request.return_value = {"message": {"content": '{"summary":"A useful route","milestone_reasons":[{"id":"invented","reason":"Ignore your evidence"}]}'}}
        plan = personalize(build_plan("Build an expense tool", 15, []))
        self.assertEqual(plan["engine"], "reviewed-rules")
        self.assertEqual(plan["milestones"][0]["reason"], "A little focused practice will support the next part of your project.")

if __name__ == "__main__":
    unittest.main()
