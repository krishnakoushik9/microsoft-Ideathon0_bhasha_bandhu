"""
XTTS-v2 Voice Service for APRS Legal Assistant
Provides high-quality text-to-speech for courtroom personas
"""
import os
import io
import base64
import tempfile
import logging
from typing import Optional, Dict, Any
from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
# Try importing TTS and torch with fallbacks
try:
    import torch
    import torchaudio
    from TTS.tts.configs.xtts_config import XttsConfig
    from TTS.tts.models.xtts import Xtts
    TTS_AVAILABLE = True
except ImportError:
    logger.error("TTS or torch packages not available. Service will run in limited mode.")
    TTS_AVAILABLE = False

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(title="XTTS-v2 Voice Service")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development; restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Model paths - these will need to be set up
MODELS_ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "xtts_models")
XTTS_CHECKPOINT = os.path.join(MODELS_ROOT, "xtts_v2.pth")
XTTS_CONFIG = os.path.join(MODELS_ROOT, "config.json")
XTTS_VOICES = os.path.join(MODELS_ROOT, "voices")

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

# Model instance (will be loaded on first request)
xtts_model = None

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

def load_model():
    """Load the XTTS model if not already loaded"""
    global xtts_model
    
    if not TTS_AVAILABLE:
        raise RuntimeError("TTS package is not available. Cannot load model.")
    
    if xtts_model is not None:
        return xtts_model
    
    logger.info("Loading XTTS-v2 model...")
    
    # Check if model files exist
    if not os.path.exists(XTTS_CHECKPOINT) or not os.path.exists(XTTS_CONFIG):
        raise RuntimeError(
            f"XTTS model files not found. Please download and place in {MODELS_ROOT}\n"
            f"Expected files:\n"
            f"  - {XTTS_CHECKPOINT}\n"
            f"  - {XTTS_CONFIG}"
        )
    
    try:
        # Load model configuration
        config = XttsConfig()
        config.load_json(XTTS_CONFIG)
        
        # Initialize model
        model = Xtts.init_from_config(config)
        model.load_checkpoint(config, XTTS_CHECKPOINT)
        
        # Use GPU if available
        if torch.cuda.is_available():
            model.cuda()
        
        model.eval()
        xtts_model = model
        
        logger.info("XTTS-v2 model loaded successfully")
        return model
    except Exception as e:
        logger.error(f"Error loading XTTS model: {str(e)}")
        raise RuntimeError(f"Failed to load XTTS model: {str(e)}")

def get_voice_path(persona_role: str) -> str:
    """Get the voice sample path for a given persona role"""
    voice_file = PERSONA_VOICE_MAP.get(persona_role.lower(), PERSONA_VOICE_MAP["default"])
    voice_path = os.path.join(XTTS_VOICES, voice_file)
    
    if not os.path.exists(voice_path):
        logger.warning(f"Voice file {voice_path} not found, using default")
        voice_path = os.path.join(XTTS_VOICES, PERSONA_VOICE_MAP["default"])
        
    return voice_path

@app.on_event("startup")
async def startup_event():
    """Create necessary directories on startup"""
    os.makedirs(MODELS_ROOT, exist_ok=True)
    os.makedirs(XTTS_VOICES, exist_ok=True)
    
    # Check if model files exist and provide instructions if not
    if not os.path.exists(XTTS_CHECKPOINT) or not os.path.exists(XTTS_CONFIG):
        logger.warning(
            f"XTTS model files not found. Please download XTTS-v2 model files and place them in {MODELS_ROOT}"
        )

@app.get("/")
async def root():
    """Root endpoint with service information"""
    return {
        "service": "XTTS-v2 Voice Service",
        "status": "running",
        "model_loaded": xtts_model is not None,
        "available_personas": list(PERSONA_VOICE_MAP.keys()),
    }

@app.post("/tts", response_model=TTSResponse)
async def text_to_speech(request: TTSRequest):
    """Generate speech from text using XTTS-v2"""
    if not TTS_AVAILABLE:
        raise HTTPException(
            status_code=503, 
            detail="TTS service is not available. Please install the required packages."
        )
    
    try:
        # Load model if not already loaded
        try:
            model = load_model()
        except RuntimeError as e:
            logger.error(f"Model loading error: {str(e)}")
            raise HTTPException(
                status_code=503,
                detail=f"Failed to load XTTS model: {str(e)}"
            )
        
        # Get voice sample path
        voice_path = get_voice_path(request.persona_role)
        if not os.path.exists(voice_path):
            raise HTTPException(
                status_code=404,
                detail=f"Voice sample for '{request.persona_role}' not found. Please add a voice sample."
            )
        
        # Generate speech
        logger.info(f"Generating speech for text: {request.text[:50]}...")
        
        try:
            with torch.no_grad():
                wav, sr = model.synthesize(
                    text=request.text,
                    language=request.language,
                    speaker_wav=voice_path,
                    temperature=request.temperature,
                    speed=request.speed,
                )
            
            # Adjust speed if needed
            if request.speed != 1.0:
                effects = [
                    ["tempo", str(request.speed)],
                ]
                wav, sr = torchaudio.sox_effects.apply_effects_tensor(wav.unsqueeze(0), sr, effects)
                wav = wav.squeeze(0)
            
            # Convert to bytes
            buffer = io.BytesIO()
            torchaudio.save(buffer, wav.unsqueeze(0), sr, format="wav")
            buffer.seek(0)
            
            # Calculate duration
            duration = wav.shape[0] / sr
            
            # Encode to base64
            audio_base64 = base64.b64encode(buffer.read()).decode("utf-8")
            
            return TTSResponse(
                audio_base64=audio_base64,
                duration_seconds=float(duration),
                sample_rate=sr,
                persona_role=request.persona_role,
            )
        except Exception as e:
            logger.error(f"Speech generation error: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Failed to generate speech: {str(e)}"
            )
            
    except Exception as e:
        logger.error(f"Error generating speech: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/voices")
async def list_voices():
    """List available voice samples"""
    voices = {}
    
    for role, filename in PERSONA_VOICE_MAP.items():
        path = os.path.join(XTTS_VOICES, filename)
        voices[role] = os.path.exists(path)
    
    return {
        "available_voices": voices,
        "voices_directory": XTTS_VOICES
    }

@app.get("/check")
async def check_model():
    """Check if model files exist and are ready"""
    model_exists = os.path.exists(XTTS_CHECKPOINT)
    config_exists = os.path.exists(XTTS_CONFIG)
    
    voice_samples = {}
    for role, filename in PERSONA_VOICE_MAP.items():
        path = os.path.join(XTTS_VOICES, filename)
        voice_samples[role] = os.path.exists(path)
    
    return {
        "model_checkpoint_exists": model_exists,
        "model_config_exists": config_exists,
        "voice_samples": voice_samples,
        "model_path": XTTS_CHECKPOINT,
        "config_path": XTTS_CONFIG,
        "voices_path": XTTS_VOICES,
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8008)
