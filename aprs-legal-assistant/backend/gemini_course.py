import os
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel
import requests
from typing import Optional

router = APIRouter()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key="

class GeminiPrompt(BaseModel):
    prompt: str

@router.post("/gemini_course")
async def gemini_course(prompt: GeminiPrompt):
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=400, detail="Missing Gemini API key.")
    # Build detailed course prompt with subtle right-wing perspective
    course_title = prompt.prompt
    prompt_text = f"""
You are an expert legal educator creating a comprehensive certification course titled "{course_title}".
Produce a professional, highly detailed curriculum with numbered modules, learning objectives, content summaries, case studies, discussion questions, and assessments.
Maintain a subtle right-wing perspective by emphasizing individual responsibility, free-market principles, respect for tradition, and the rule of law, but avoid sarcasm, dismissive language, or negative commentary.
Use clear headings for each module (e.g., Module 1: Introduction to {course_title}), and under each include:
1. Overview
2. Content Topics
3. Practical Examples or Case Studies
4. Key Takeaways
5. Recommended Resources
At the end, provide a formal certification statement and guidance on earning completion credit.
"""
    payload = {
        "contents": [{"parts": [{"text": prompt_text}]}],
        "generationConfig": {
            "temperature": 0.6,
            "maxOutputTokens": 2000
        }
    }
    resp = requests.post(
        GEMINI_API_URL + GEMINI_API_KEY,
        json=payload,
        timeout=60
    )
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail="Gemini API error")
    result = resp.json()
    # Extract generated text
    try:
        content = result["candidates"][0]["content"]["parts"][0]["text"]
    except Exception:
        raise HTTPException(status_code=500, detail="Malformed Gemini response")
    return {"content": content}
