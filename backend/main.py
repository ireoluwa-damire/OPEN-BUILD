from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, ConfigDict
from typing import Literal
from .catalog import CALIBRATION, RESOURCES, SKILLS, public_questions
from .planner import build_plan, grade_attempt
from .model_service import model_status, personalize
import os

app = FastAPI(title="Sumi learning API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.environ.get("SUMI_CORS_ORIGINS", "http://localhost:5173,http://127.0.0.1:5173,http://localhost:8080,http://127.0.0.1:8080").split(","),
    allow_methods=["GET", "POST"], allow_headers=["Content-Type"],
)

class Attempt(BaseModel):
    model_config = ConfigDict(extra="forbid")
    question_id: str
    answer_index: int | None = Field(default=None, ge=0, le=3)
    used_hint: bool = False
    active_seconds: float = Field(default=0, ge=0, le=3600)

class PlanRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    goal: str = Field(min_length=3, max_length=300)
    daily_minutes: Literal[10, 15, 20, 30] = 15
    attempts: list[Attempt] = Field(default_factory=list, max_length=100)
    completed_skills: list[str] = Field(default_factory=list, max_length=6)
    use_model: bool = True

@app.get("/health")
def health():
    return {"status": "ok", "service": "sumi", "version": "0.1.0"}

@app.get("/v1/catalog")
def catalog():
    return {"questions": public_questions(), "resources": RESOURCES, "skills": SKILLS, "calibration": CALIBRATION}

@app.get("/v1/model-status")
def status():
    return model_status()

@app.post("/v1/attempts")
def attempt(request: Attempt):
    try:
        return grade_attempt(**request.model_dump())
    except ValueError as error:
        raise HTTPException(422, str(error)) from error

@app.post("/v1/plans")
def plan(request: PlanRequest):
    try:
        result = build_plan(request.goal, request.daily_minutes,
                            [a.model_dump() for a in request.attempts], request.completed_skills)
    except ValueError as error:
        raise HTTPException(422, str(error)) from error
    return personalize(result) if request.use_model else result
