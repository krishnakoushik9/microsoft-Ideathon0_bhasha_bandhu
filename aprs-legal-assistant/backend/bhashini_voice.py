"""
bhashini_voice.py

FastAPI router for Telugu conversational AI using Bhashini pipeline and Gemini.

Removes all Azure logic. Uses Bhashini pipeline for translation + TTS, and Google Gemini for AI.
"""
import os
import requests
import base64
import logging
from dotenv import load_dotenv
from pathlib import Path
from fastapi import APIRouter, Form, HTTPException
from fastapi.responses import JSONResponse
import google.generativeai as genai
from typing import Tuple

# Load environment variables from project .env
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

# Initialize router and logger
router = APIRouter()
logger = logging.getLogger(__name__)

# Bhashini pipeline endpoint and auth
BHASHINI_API_URL = os.getenv(
    "BHASHINI_API_URL",
    "https://dhruva-api.bhashini.gov.in/services/inference/pipeline"
)
BHASHINI_API_KEY = os.getenv(
    "BHASHINI_API_KEY",
    "ULCndVHFuQrOY6zFecDIx7sA2YlfujzTjeO0xIViNV8Pia_6TyunIVzfITYQvhyx"
)
HEADERS = {
    "Authorization": BHASHINI_API_KEY,
    "Content-Type": "application/json"
}

# Gemini API key
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    logger.warning("GEMINI_API_KEY not set; Gemini AI calls may fail.")
else:
    genai.configure(api_key=GEMINI_API_KEY)

# Optional ASR config (Telugu)
BHASHINI_ASR_MODEL_ID = os.getenv("BHASHINI_ASR_MODEL_ID", "6411748db1463435d2fbaec5")
BHASHINI_ASR_SERVICE_ID = os.getenv("BHASHINI_ASR_SERVICE_ID", "ai4bharat/conformer-multilingual-dravidian-gpu--t4")
if not (BHASHINI_ASR_MODEL_ID and BHASHINI_ASR_SERVICE_ID):
    logger.warning("BHASHINI_ASR_MODEL_ID or BHASHINI_ASR_SERVICE_ID not set; audio pipeline may fail.")

# Optional ASR config (English)
BHASHINI_ASR_EN_MODEL_ID = os.getenv("BHASHINI_ASR_EN_MODEL_ID", "641c0be440abd176d64c3f92")
BHASHINI_ASR_EN_SERVICE_ID = os.getenv("BHASHINI_ASR_EN_SERVICE_ID", "ai4bharat/whisper-medium-en--gpu--t4")

# Optional TTS config (Telugu)
# Using coqui-dravidian model per spec
BHASHINI_TTS_MODEL_ID = os.getenv("BHASHINI_TTS_MODEL_ID", "6348db37fb796d5e100d4ffe")
BHASHINI_TTS_SERVICE_ID = os.getenv("BHASHINI_TTS_SERVICE_ID", "ai4bharat/indic-tts-coqui-dravidian-gpu--t4")

# Task: Telugu→English translation via Bhashini pipeline
def translate_telugu_to_english(telugu_text: str) -> str:
    payload = {
        "pipelineTasks": [
            {
                "taskType": "translation",
                "config": {
                    "language": {
                        "sourceLanguage": "te",
                        "sourceScriptCode": "Telu",
                        "targetLanguage": "en",
                        "targetScriptCode": "Latn"
                    },
                    "modelId": "641d1ca98ecee6735a1b3707",
                    "serviceId": "ai4bharat/indictrans-v2-all-gpu--t4"
                }
            }
        ],
        "inputData": {"input": [{"source": telugu_text}], "audio": []}
    }
    resp = requests.post(BHASHINI_API_URL, headers=HEADERS, json=payload)
    resp.raise_for_status()
    data = resp.json()
    pipeline = data.get("pipelineResponse", [])
    if pipeline and pipeline[0].get("output"):
        out = pipeline[0]["output"]
        if out and out[0].get("target"):
            return out[0]["target"]
    logger.error("Translation pipeline returned no output: %s", data)
    raise HTTPException(status_code=502, detail="Translation pipeline error")

# Task: call Gemini AI via chat-bison-001
def call_gemini_api(english_text: str) -> str:
    if not GEMINI_API_KEY:
        raise RuntimeError("GEMINI_API_KEY not configured")
    try:
        # Create a chat completion using free-tier model
        resp = genai.chat.completions.create(
            model="chat-bison-001",
            temperature=0.2,
            candidate_count=1,
            messages=[{"author": "user", "content": english_text}]
        )
        # Extract assistant reply
        choice = resp.choices[0]
        return choice.message.content.strip()
    except Exception as e:
        logger.error("Chat completion failed: %s", e)
        raise HTTPException(status_code=502, detail="AI service error")

# Task: English→Telugu translation + TTS
def translate_english_to_telugu_tts(english_text: str) -> Tuple[str, bytes]:
    payload = {
        "pipelineTasks": [
            {
                "taskType": "translation",
                "config": {
                    "language": {
                        "sourceLanguage": "en",
                        "sourceScriptCode": "Latn",
                        "targetLanguage": "te",
                        "targetScriptCode": "Telu"
                    },
                    "modelId": "641d1cab8ecee6735a1b370b",
                    "serviceId": "ai4bharat/indictrans-v2-all-gpu--t4"
                }
            },
            {
                "taskType": "tts",
                "config": {
                    "language": {"sourceLanguage": "te", "sourceScriptCode": "Telu"},
                    "voice": "default",
                    "modelId": BHASHINI_TTS_MODEL_ID,
                    "serviceId": BHASHINI_TTS_SERVICE_ID
                }
            }
        ],
        "inputData": {"input": [{"source": english_text}]}
    }
    resp = requests.post(BHASHINI_API_URL, headers=HEADERS, json=payload)
    resp.raise_for_status()
    data = resp.json()
    telugu_text = data["outputs"][0]["output"]
    audio_b64 = data["outputs"][1]["output"]["audio"]
    return telugu_text, base64.b64decode(audio_b64)

# Task: Speech-to-text + Telugu→English translation
def speech_to_text_translate_telugu_to_english(audio_b64: str) -> Tuple[str, str]:
    payload = {
        "pipelineTasks": [
            {
                "taskType": "asr",
                "config": {
                    "serviceId": BHASHINI_ASR_SERVICE_ID,
                    "modelId": BHASHINI_ASR_MODEL_ID,
                    "language": {
                        "sourceLanguage": "te",
                        "sourceScriptCode": "Telu"
                    },
                    "domain": ["general"]
                }
            },
            {
                "taskType": "translation",
                "config": {
                    "language": {
                        "sourceLanguage": "te",
                        "sourceScriptCode": "Telu",
                        "targetLanguage": "en",
                        "targetScriptCode": "Latn"
                    },
                    "modelId": "641d1ca98ecee6735a1b3707",
                    "serviceId": "ai4bharat/indictrans-v2-all-gpu--t4"
                }
            }
        ],
        "inputData": {
            "input": [],
            "audio": [audio_b64]
        }
    }
    resp = requests.post(BHASHINI_API_URL, headers=HEADERS, json=payload)
    resp.raise_for_status()
    data = resp.json()
    asr_text = data["outputs"][0]["output"]
    en_text = data["outputs"][1]["output"]
    return asr_text, en_text

# Task: Speech-to-text for English input
def speech_to_text_translate_english(audio_b64: str) -> Tuple[str, str]:
    payload = {
        "pipelineTasks": [
            {
                "taskType": "asr",
                "config": {
                    "serviceId": BHASHINI_ASR_EN_SERVICE_ID,
                    "modelId": BHASHINI_ASR_EN_MODEL_ID,
                    "language": {"sourceLanguage": "en", "sourceScriptCode": "Latn"},
                    "domain": ["general"]
                }
            }
        ],
        "inputData": {"input": [], "audio": [audio_b64]}
    }
    resp = requests.post(BHASHINI_API_URL, headers=HEADERS, json=payload)
    resp.raise_for_status()
    data = resp.json()
    asr_text = data["outputs"][0]["output"]
    return asr_text, asr_text

# Endpoint: receive Telugu text or audio, return translated response & audio
@router.post("/voice-query")
def voice_query(
    audio_base64: str = Form(None, description="Base64-encoded audio data (multipart/form-data field 'audio_base64')"),
    language: str = Form("te", description="Language code: 'te' or 'en'"),
    telugu_text: str = Form(None, description="Raw Telugu text input if audio not provided"),
):
    try:
        # Determine input mode
        if audio_base64:
            if language == "te":
                asr_text, en = speech_to_text_translate_telugu_to_english(audio_base64)
            elif language == "en":
                asr_text, en = speech_to_text_translate_english(audio_base64)
            else:
                raise HTTPException(
                    status_code=400,
                    detail="Unsupported language: {}".format(language)
                )
        elif telugu_text:
            asr_text = telugu_text
            en = translate_telugu_to_english(telugu_text)
        else:
            raise HTTPException(
                status_code=400,
                detail="No input provided: expected form field 'audio_base64' or 'telugu_text'",
            )
        logger.info(f"ASR/Original Telugu text: {asr_text}")
        # Return ASR and translation only (Gemini AI removed)
        return JSONResponse({
            "asr_text": asr_text,
            "translated_text": en
        })
    except Exception:
        logger.exception("Error in voice_query")
        raise HTTPException(status_code=500, detail="Internal server error in voice_query")