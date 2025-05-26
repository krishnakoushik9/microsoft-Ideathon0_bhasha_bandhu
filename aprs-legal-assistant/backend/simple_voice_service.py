"""
Simple Voice Service for APRS Legal Assistant
Provides voice synthesis for courtroom personas using pre-recorded audio files
"""
import os
import io
import base64
import logging
import tempfile
from typing import Optional, Dict, Any, List
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import uvicorn

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(title="Simple Voice Service")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development; restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
VOICES_DIR = os.path.join(BASE_DIR, "voice_samples")
os.makedirs(VOICES_DIR, exist_ok=True)

# Voice mapping for courtroom personas
PERSONA_VOICE_MAP = {
    "judge": "judge.wav",
    "prosecutor": "prosecutor.wav",
    "defense": "defense.wav",
    "witness": "witness.wav",
    "defendant": "defendant.wav",
    "clerk": "clerk.wav",
    "bailiff": "bailiff.wav",
    "expert": "expert.wav",
    "default": "default.wav"
}

class TTSRequest(BaseModel):
    """Request model for text-to-speech generation"""
    text: str
    persona_role: str = "default"
    language: str = "en"
    speed: float = 1.0
    temperature: float = 0.7

class TTSResponse(BaseModel):
    """Response model with audio data and metadata"""
    audio_base64: str
    duration_seconds: float
    sample_rate: int
    persona_role: str

def get_voice_path(persona_role: str) -> str:
    """Get the voice sample path for a given persona role"""
    voice_file = PERSONA_VOICE_MAP.get(persona_role.lower(), PERSONA_VOICE_MAP["default"])
    voice_path = os.path.join(VOICES_DIR, voice_file)
    
    if not os.path.exists(voice_path):
        logger.warning(f"Voice file {voice_path} not found, using default")
        voice_path = os.path.join(VOICES_DIR, PERSONA_VOICE_MAP["default"])
        
    return voice_path

@app.get("/")
async def root():
    """Root endpoint with service information"""
    return {
        "service": "Simple Voice Service",
        "status": "running",
        "available_personas": list(PERSONA_VOICE_MAP.keys()),
    }

@app.post("/tts", response_model=TTSResponse)
async def text_to_speech(request: TTSRequest):
    """Return a pre-recorded voice sample for the requested persona"""
    try:
        # Get voice sample path
        voice_path = get_voice_path(request.persona_role)
        
        if not os.path.exists(voice_path):
            # If no voice samples exist at all, return an error
            if not any(os.path.exists(os.path.join(VOICES_DIR, f)) for f in PERSONA_VOICE_MAP.values()):
                raise HTTPException(
                    status_code=404,
                    detail="No voice samples found. Please add voice samples to the voice_samples directory."
                )
            
            # Try to find any available voice sample
            available_samples = [f for f in os.listdir(VOICES_DIR) if f.endswith('.wav')]
            if available_samples:
                voice_path = os.path.join(VOICES_DIR, available_samples[0])
            else:
                raise HTTPException(
                    status_code=404, 
                    detail=f"No voice samples available. Please add voice samples to {VOICES_DIR}"
                )
        
        # Read the voice sample
        with open(voice_path, 'rb') as f:
            audio_data = f.read()
        
        # Encode to base64
        audio_base64 = base64.b64encode(audio_data).decode("utf-8")
        
        # Estimate duration (assuming 16kHz sample rate, 16-bit audio)
        file_size = os.path.getsize(voice_path)
        duration = file_size / (16000 * 2)  # Approximate duration in seconds
        
        return TTSResponse(
            audio_base64=audio_base64,
            duration_seconds=float(duration),
            sample_rate=16000,
            persona_role=request.persona_role,
        )
        
    except Exception as e:
        logger.error(f"Error generating speech: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/voices")
async def list_voices():
    """List available voice samples"""
    voices = {}
    
    for role, filename in PERSONA_VOICE_MAP.items():
        path = os.path.join(VOICES_DIR, filename)
        voices[role] = os.path.exists(path)
    
    return {
        "available_voices": voices,
        "voices_directory": VOICES_DIR
    }

@app.post("/upload_voice")
async def upload_voice(
    persona_role: str = Form(...),
    file: UploadFile = File(...)
):
    """Upload a voice sample for a specific persona role"""
    if not file.filename or not file.filename.lower().endswith('.wav'):
        raise HTTPException(status_code=400, detail="Only WAV files are supported")
    
    if persona_role not in PERSONA_VOICE_MAP:
        raise HTTPException(status_code=400, detail=f"Invalid persona role. Valid roles: {list(PERSONA_VOICE_MAP.keys())}")
    
    try:
        # Save the uploaded file
        file_path = os.path.join(VOICES_DIR, PERSONA_VOICE_MAP[persona_role])
        
        with open(file_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        return {"message": f"Voice sample for {persona_role} uploaded successfully"}
    
    except Exception as e:
        logger.error(f"Error uploading voice sample: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8008)
