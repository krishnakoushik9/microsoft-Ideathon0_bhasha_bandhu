import os
import requests

# TTS endpoint, update the default if needed
TTS_URL = os.getenv("TTS_URL", "http://localhost:5000/tts")

import base64
import logging
import asyncio
import time
import json
import dotenv
from fastapi import APIRouter, HTTPException, Request, UploadFile, File, Form
from fastapi.responses import JSONResponse
from backend.realtime_log_ws import broadcast_log

# Set up logging
logger = logging.getLogger(__name__)

# Add a handler to log all errors to mail.log (for Bhashini, NeMo, API, etc.)
from logging.handlers import RotatingFileHandler
# Set up a dedicated error handler for Bhashini/voice errors
mail_errors_log_path = os.path.join(os.path.dirname(__file__), 'mail_errors.log')
mail_errors_handler = RotatingFileHandler(mail_errors_log_path, maxBytes=2*1024*1024, backupCount=3)
mail_errors_handler.setLevel(logging.ERROR)
mail_errors_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
if not any(isinstance(h, RotatingFileHandler) and h.baseFilename == mail_errors_log_path for h in logger.handlers):
    logger.addHandler(mail_errors_handler)

# Helper to copy mail_errors.log to main_these_errors.txt after logging an error
def copy_mail_errors():
    import shutil
    src = mail_errors_log_path
    dst = os.path.join(os.path.dirname(__file__), 'main_these_errors.txt')
    try:
        shutil.copyfile(src, dst)
    except Exception as e:
        pass  # Avoid recursive logging in case of copy error


router = APIRouter()

# Load environment variables
def load_env():
    """Load environment variables from .env file"""
    dotenv_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
    if os.path.exists(dotenv_path):
        dotenv.load_dotenv(dotenv_path)
        logger.info(f"Loaded environment variables from {dotenv_path}")
        return True
    else:
        logger.warning(f"No .env file found at {dotenv_path}")
        return False

# Environment variables for security
load_env()  # Load env variables first
UDYAT_API_KEY = os.getenv("UDYAT_API_KEY")
UDYAT_USER_ID = os.getenv("UDYAT_USER_ID")
UDYAT_APP_NAME = os.getenv("UDYAT_APP_NAME")

# Log API key status (without revealing the actual keys)
if UDYAT_API_KEY:
    logger.info("UDYAT_API_KEY is set")
else:
    logger.warning("UDYAT_API_KEY is not set - API calls may fail")
    
if UDYAT_USER_ID:
    logger.info("UDYAT_USER_ID is set")
else:
    logger.warning("UDYAT_USER_ID is not set - API calls may fail")

# Bhashini API URLs
BHASHINI_API_URL = os.getenv("BHASHINI_API_URL", "https://dhruva-api.bhashini.gov.in/services/inference/pipeline")

# Define flush_log_handlers function early
def flush_log_handlers():
    for handler in logger.handlers:
        handler.flush()


# Direct service endpoints (provided by user)
# Bhashini Telugu→English Voice Pipeline Model IDs (from memory)
# Use these for full ASR (Telugu) → Translation (Telugu-English) → TTS (English)
ASR_TELUGU_MODEL_ID = "66e41f28e2f5842563c988d9"
TRANSLATION_TE_EN_MODEL_ID = "67b871747d193a1beb4b847e"
TRANSLATION_EN_TE_MODEL_ID = "67b871747d193a1beb4b847e"  # Using the same model ID for both directions
TTS_ENGLISH_MODEL_ID = "6576a17e00d64169e2f8f43d"

# Log model IDs for debugging
logger.info(f"Using ASR Telugu model ID: {ASR_TELUGU_MODEL_ID}")
logger.info(f"Using Translation TE→EN model ID: {TRANSLATION_TE_EN_MODEL_ID}")
logger.info(f"Using Translation EN→TE model ID: {TRANSLATION_EN_TE_MODEL_ID}")
logger.info(f"Using TTS English model ID: {TTS_ENGLISH_MODEL_ID}")
flush_log_handlers()

# Default Bhashini URLs
BHASHINI_MEITY_AUTH_URL = "https://meity-auth.ulcacontrib.org/ulca/apis/v0/model/getModelsPipeline"
BHASHINI_INFERENCE_URL = "https://dhruva-api.bhashini.gov.in/services/inference"
BHASHINI_ASR_URL = "https://dhruva-api.bhashini.gov.in/services/inference/asr"
BHASHINI_TRANSLATION_URL = "https://dhruva-api.bhashini.gov.in/services/inference/translation"
BHASHINI_TTS_URL = "https://dhruva-api.bhashini.gov.in/services/inference/tts"
BHASHINI_PIPELINE_URL = "https://dhruva-api.bhashini.gov.in/services/inference/pipeline"

# Bhashini pipeline service IDs (explicit for pipeline use)
ASR_TE_SERVICE_ID = os.getenv("ASR_TE_SERVICE_ID", ASR_TELUGU_MODEL_ID)
TRANSLATION_TE_EN_SERVICE_ID = os.getenv("TRANSLATION_TE_EN_SERVICE_ID", TRANSLATION_TE_EN_MODEL_ID)
TRANSLATION_EN_TE_SERVICE_ID = os.getenv("TRANSLATION_EN_TE_SERVICE_ID", TRANSLATION_EN_TE_MODEL_ID)
TTS_EN_SERVICE_ID = os.getenv("TTS_EN_SERVICE_ID", TTS_ENGLISH_MODEL_ID)

# Define the URL for English to Telugu translation (same as the regular translation URL)
TRANSLATION_EN_TE_URL = BHASHINI_TRANSLATION_URL

# Set up logging (persistent + console)
from logging.handlers import RotatingFileHandler
log_formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
log_file = os.path.join(os.path.dirname(__file__), 'bhashini_voice.log')
file_handler = RotatingFileHandler(log_file, maxBytes=2*1024*1024, backupCount=3)
file_handler.setFormatter(log_formatter)
file_handler.setLevel(logging.INFO)
console_handler = logging.StreamHandler()
console_handler.setFormatter(log_formatter)
console_handler.setLevel(logging.INFO)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
# Remove all handlers first (avoid duplicate logs)
for handler in logger.handlers[:]:
    logger.removeHandler(handler)
logger.addHandler(file_handler)
logger.addHandler(console_handler)
# Helper: flush logs after every log call - already defined above
# def flush_log_handlers():
#     for handler in logger.handlers:
#         handler.flush()

async def call_gemini_ai(text):
    """Call the Gemini AI model with the text and get a response"""
    logger.info(f"Calling AI model with text: {text}")
    flush_log_handlers()
    await broadcast_log(f"[Backend] Calling AI model with text: {text}")
    
    try:
        import google.generativeai as genai
        GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
        if not GOOGLE_API_KEY:
            logger.error("No Google API Key found in environment variables")
            flush_log_handlers()
            await broadcast_log("[Backend] No Google API Key found in environment variables")
            return "I'm sorry, I cannot process your request as no Google API key is configured."

        genai.configure(api_key=GOOGLE_API_KEY)
        model = genai.GenerativeModel('gemini-1.5-pro')
        import time
        ai_start = time.time()
        response = model.generate_content(
            f"You are a legal assistant. Answer the following question or request: {text}"
        )
        ai_elapsed = time.time() - ai_start
        ai_text = response.text
        logger.info(f"Gemini response ({ai_elapsed:.2f}s): {ai_text[:100]}...")
        flush_log_handlers()
        await broadcast_log(f"[Backend] Gemini response ({ai_elapsed:.2f}s): {ai_text[:100]}...")
        return ai_text
    except Exception as e:
        logger.error(f"Gemini API error: {e}")
        flush_log_handlers()
        copy_mail_errors()
        await broadcast_log(f"[Backend] Gemini API error: {e}")
        return f"I'm sorry, I encountered an error processing your request. Error: {str(e)}"

async def process_with_nemo_fallback(audio_bytes, save_to_test_folder=True):
    """Process audio with NeMo ASR as a fallback when Bhashini API fails"""
    import os
    import tempfile
    import subprocess
    import time
    from pathlib import Path
    
    # Try importing necessary packages - handle missing dependencies gracefully
    try:
        import librosa
        import soundfile as sf
    except ImportError as e:
        logger.error(f"Missing dependencies for audio processing: {e}")
        flush_log_handlers()
        copy_mail_errors()
        await broadcast_log(f"[Backend] Missing audio processing dependencies: {e}")
        raise Exception(f"Cannot process audio: {e}")
    
    logger.info("Processing with NeMo fallback...")
    flush_log_handlers()
    await broadcast_log("[Backend] Processing with NeMo fallback...")
    
    # Create test_audio directory if it doesn't exist
    test_audio_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "test_audio")
    os.makedirs(test_audio_dir, exist_ok=True)
    
    # Generate a unique filename based on timestamp
    timestamp = int(time.time())
    temp_wav_path = os.path.join(test_audio_dir, f"recording_{timestamp}.wav")
    processed_wav_path = os.path.join(test_audio_dir, f"recording_{timestamp}_processed.wav")
    
    try:
        # Save the original audio
        with open(temp_wav_path, 'wb') as f:
            f.write(audio_bytes)
        
        logger.info(f"Saved original audio to {temp_wav_path}")
        flush_log_handlers()
        await broadcast_log(f"[Backend] Saved original audio to {temp_wav_path}")
        
        # Process with librosa fix_short method
        y, sr = librosa.load(temp_wav_path, sr=16000, mono=True)
        sf.write(processed_wav_path, y, sr, subtype='PCM_16')
        
        logger.info(f"Processed audio with librosa and saved to {processed_wav_path}")
        flush_log_handlers()
        await broadcast_log(f"[Backend] Processed audio with librosa and saved to {processed_wav_path}")
        
        # Try using the local NeMo Telugu ASR model
        try:
            # Check if NeMo is available
            try:
                import nemo
                from backend.local_telugu_asr import LocalTeluguASR
                logger.info("Using local NeMo Telugu ASR model for transcription...")
                flush_log_handlers()
                await broadcast_log("[Backend] Using local NeMo Telugu ASR model for transcription...")
                
                # Initialize the model if not already done
                local_asr = LocalTeluguASR()
                
                # Read the processed audio file
                with open(processed_wav_path, 'rb') as f:
                    processed_audio_bytes = f.read()
                
                # Transcribe using the NeMo model
                asr_text = await asyncio.to_thread(local_asr.transcribe, processed_audio_bytes)
            except ImportError as e:
                logger.error(f"NeMo is not available: {e}")
                flush_log_handlers()
                copy_mail_errors()
                await broadcast_log(f"[Backend] NeMo is not available: {e}")
                raise Exception(f"NeMo is not available: {e}")
            
            # Save the Telugu transcription to NeMo/examples/asr/output_te.txt
            nemo_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "NeMo", "examples", "asr")
            os.makedirs(nemo_dir, exist_ok=True)
            
            output_te_path = os.path.join(nemo_dir, "output_te.txt")
            with open(output_te_path, 'w', encoding='utf-8') as f:
                f.write(f'{{"pred_text": "{asr_text}"}}\n')
            
            logger.info(f"Saved Telugu transcription to {output_te_path}")
            flush_log_handlers()
            await broadcast_log(f"[Backend] Saved Telugu transcription to {output_te_path}")
            
            # Run the clean_output.py script to generate cleaned output
            clean_script_path = os.path.join(nemo_dir, "clean_output.py")
            output_clean_path = os.path.join(nemo_dir, "output_clean.txt")
            
            # Check if clean_output.py exists, if not create it
            if not os.path.exists(clean_script_path):
                with open(clean_script_path, 'w', encoding='utf-8') as f:
                    f.write('''import json

input_file = 'output_te.txt'
output_file = 'output_clean.txt'

with open(input_file, 'r', encoding='utf-8') as fin, open(output_file, 'w', encoding='utf-8') as fout:
    for line in fin:
        line = line.strip()
        if not line:
            continue
        try:
            data = json.loads(line)
            pred = data.get('pred_text', '').strip()
            fout.write(pred + '\\n')
        except json.JSONDecodeError:
            fout.write(line + '\\n')

print(f'Wrote decoded predictions to {output_file}')
''')
            
            # Run the clean script
            subprocess.run(['python', clean_script_path], cwd=nemo_dir)
            
            # Read the cleaned output
            if os.path.exists(output_clean_path):
                with open(output_clean_path, 'r', encoding='utf-8') as f:
                    cleaned_text = f.read().strip()
                
                logger.info(f"NeMo ASR result (cleaned): {cleaned_text}")
                flush_log_handlers()
                await broadcast_log(f"[Backend] NeMo ASR result (cleaned): {cleaned_text}")
                
                return cleaned_text
            else:
                logger.warning(f"Cleaned output file not found at {output_clean_path}")
                flush_log_handlers()
                await broadcast_log(f"[Backend] Cleaned output file not found at {output_clean_path}")
                return asr_text
                
        except Exception as e:
            logger.error(f"Error using NeMo ASR: {e}")
            flush_log_handlers()
            copy_mail_errors()
            await broadcast_log(f"[Backend] Error using NeMo ASR: {e}")
            raise e
            
    except Exception as e:
        logger.error(f"Error in NeMo fallback processing: {e}")
        flush_log_handlers()
        copy_mail_errors()
        await broadcast_log(f"[Backend] Error in NeMo fallback processing: {e}")
        raise e

def check_dependencies():
    missing_deps = []
    try:
        import librosa
    except ImportError:
        missing_deps.append("librosa")
    
    try:
        import soundfile
    except ImportError:
        missing_deps.append("soundfile")
    
    if missing_deps:
        logger.warning(f"Missing dependencies: {', '.join(missing_deps)}. Some features may not work.")
        logger.warning("To install missing dependencies, run: pip install librosa soundfile")

# Check dependencies at module load time
check_dependencies()

@router.post("/api/voice-query")
async def voice_query(audio: UploadFile = File(None), text: str = Form(None), audio_base64: str = Form(None)):
    try:
        logger.info("Received voice query request")
        flush_log_handlers()
        await broadcast_log("[Backend] Received voice query request")
        audio_bytes = None
        audio_filename = None
        
        # Handle file upload from Postman or regular form submission
        if audio:
            # Create a unique filename based on timestamp
            timestamp = int(time.time())
            audio_filename = f"recording_{timestamp}.webm"
            audio_path = os.path.join(os.path.dirname(__file__), 'uploads', 'audio', audio_filename)
            
            # Ensure directory exists
            os.makedirs(os.path.dirname(audio_path), exist_ok=True)
            
            # Read and save the audio file
            audio_bytes = await audio.read()
            with open(audio_path, 'wb') as f:
                f.write(audio_bytes)
            
            logger.info(f"Saved uploaded audio file to {audio_path}")
            flush_log_handlers()
            await broadcast_log(f"[Backend] Saved uploaded audio file to {audio_path}")
        
        # Handle base64 audio data from web client
        elif audio_base64:
            try:
                # Create a unique filename based on timestamp
                timestamp = int(time.time())
                audio_filename = f"recording_{timestamp}.webm"
                audio_path = os.path.join(os.path.dirname(__file__), 'uploads', 'audio', audio_filename)
                
                # Ensure directory exists
                os.makedirs(os.path.dirname(audio_path), exist_ok=True)
                
                # Decode and save the base64 audio
                if ',' in audio_base64:
                    # Handle data URLs (e.g., data:audio/webm;base64,<data>)
                    audio_base64 = audio_base64.split(',', 1)[1]
                
                audio_bytes = base64.b64decode(audio_base64)
                with open(audio_path, 'wb') as f:
                    f.write(audio_bytes)
                
                logger.info(f"Saved base64 audio to {audio_path}")
                flush_log_handlers()
                await broadcast_log(f"[Backend] Saved base64 audio to {audio_path}")
            except Exception as e:
                error_msg = f"Error processing base64 audio: {str(e)}"
                logger.error(error_msg)
                flush_log_handlers()
                copy_mail_errors()
                await broadcast_log(f"[Backend] {error_msg}")
                raise HTTPException(status_code=400, detail=error_msg)
        asr_text = None
        translated_text = None
        tts_audio = None
        used_fallback = False

        # Step 1: ASR (Telugu)
        if text:
            asr_text = text
            logger.info(f"Received text from browser STT: {asr_text}")
            flush_log_handlers()
            await broadcast_log(f"[Backend] Received text from browser STT: {asr_text}")
        elif audio_bytes:
            # Try Bhashini API first
            try:
                logger.info("Trying Bhashini API for Telugu ASR and translation...")
                flush_log_handlers()
                await broadcast_log("[Backend] Trying Bhashini API for Telugu ASR and translation...")
                
                # Use Bhashini Pipeline API (ASR -> Translation)
                import base64
                # time is now imported globally
                audio_base64 = base64.b64encode(audio_bytes).decode('utf-8')
                
                # Create pipeline configuration with our specific model IDs
                # Following exact format from documentation
                pipeline_payload = {
                    "pipelineTasks": [
                        {
                            "taskType": "asr",
                            "config": {
                                "language": {
                                    "sourceLanguage": "te"
                                },
                                "serviceId": ASR_TE_SERVICE_ID
                            }
                        },
                        {
                            "taskType": "translation",
                            "config": {
                                "language": {
                                    "sourceLanguage": "te",
                                    "targetLanguage": "en"
                                },
                                "serviceId": TRANSLATION_TE_EN_SERVICE_ID
                            }
                        }
                    ],
                    "inputData": {
                        "input": [
                            {
                                "source": ""
                            }
                        ],
                        "audio": [
                            {
                                "audioContent": audio_base64
                            }
                        ]
                    }
                }
                
                # Start timing
                api_start = time.time()
                
                try:
                    # Prepare headers
                    api_headers = {
                        "Content-Type": "application/json",
                    }
                    if UDYAT_API_KEY:
                        api_headers["Authorization"] = f"Bearer {UDYAT_API_KEY}"
                    if UDYAT_USER_ID:
                        api_headers["userID"] = UDYAT_USER_ID
                        
                    # Make the pipeline API call
                    logger.info(f"Making pipeline request to Bhashini API using models: ASR={ASR_TE_SERVICE_ID}, Translation={TRANSLATION_TE_EN_SERVICE_ID}")
                    flush_log_handlers()
                    await broadcast_log(f"[Backend] Making Bhashini API pipeline request...")
                    
                    # Add computed URL with serviceId parameters for better compatibility
                    pipeline_url = f"{BHASHINI_PIPELINE_URL}?asr={ASR_TE_SERVICE_ID}&translation={TRANSLATION_TE_EN_SERVICE_ID}"
                    logger.info(f"Pipeline URL: {pipeline_url}")
                    
                    pipeline_resp = requests.post(
                        pipeline_url, 
                        json=pipeline_payload, 
                        headers=api_headers, 
                        timeout=90,  # Longer timeout for pipeline
                        verify=False
                    )
                    api_elapsed = time.time() - api_start
                    
                    # Check response
                    if pipeline_resp.status_code != 200:
                        logger.error(f"Pipeline API error: {pipeline_resp.text}")
                        flush_log_handlers()
                        await broadcast_log(f"[Backend] Pipeline API error: {pipeline_resp.text}")
                        raise Exception(f"Pipeline API error: {pipeline_resp.text}")
                    
                    # Parse results
                    pipeline_result = pipeline_resp.json()
                    logger.debug(f"Pipeline API response: {json.dumps(pipeline_result)}")
                    
                    # Add detailed logging of the full response for debugging
                    logger.info(f"Full Bhashini API response: {pipeline_result}")
                    
                    # Extract ASR and translation results from the pipeline
                    # The format might be an array of task results
                    if isinstance(pipeline_result, list):
                        for task in pipeline_result:
                            if task.get('taskType') == 'asr':
                                asr_text = task.get('output', [{}])[0].get('source', '')
                            elif task.get('taskType') == 'translation':
                                translated_text = task.get('output', [{}])[0].get('target', '')
                    # Or it might be a single object with pipeline output
                    elif isinstance(pipeline_result, dict):
                        if 'pipelineResponse' in pipeline_result:
                            for task in pipeline_result.get('pipelineResponse', []):
                                if task.get('taskType') == 'asr':
                                    asr_text = task.get('output', [{}])[0].get('source', '')
                                elif task.get('taskType') == 'translation':
                                    translated_text = task.get('output', [{}])[0].get('target', '')
                        # Check for ASR and translation directly in the response
                        if not asr_text and 'asr' in pipeline_result:
                            asr_data = pipeline_result.get('asr', {})
                            if isinstance(asr_data, dict) and 'output' in asr_data:
                                asr_text = asr_data.get('output', [{}])[0].get('source', '')
                        if not translated_text and 'translation' in pipeline_result:
                            translation_data = pipeline_result.get('translation', {})
                            if isinstance(translation_data, dict) and 'output' in translation_data:
                                translated_text = translation_data.get('output', [{}])[0].get('target', '')
                    
                    logger.info(f"ASR result: {asr_text}")
                    logger.info(f"Translation result: {translated_text}")
                    flush_log_handlers()
                    await broadcast_log(f"[Backend] Pipeline API success ({api_elapsed:.2f}s)")
                    await broadcast_log(f"[Backend] ASR result: {asr_text}")
                    await broadcast_log(f"[Backend] Translation result: {translated_text}")
                    
                except Exception as e:
                    logger.error(f"Pipeline API connection failed: {e}")
                    await broadcast_log(f"[Backend] Pipeline API connection failed: {e}")
                    # Raise to trigger the fallback
                    raise Exception(f"Pipeline API connection failed: {e}")
            except Exception as bhashini_exc:
                logger.warning(f"Bhashini ASR failed: {bhashini_exc}")
                flush_log_handlers()
                await broadcast_log(f"[Backend] Bhashini ASR failed: {bhashini_exc}. Falling back to NeMo ASR...")
                
                # Fallback to NeMo ASR
                try:
                    asr_text = await process_with_nemo_fallback(audio_bytes)
                    used_fallback = True
                except Exception as nemo_exc:
                    logger.error(f"NeMo ASR fallback also failed: {nemo_exc}")
                    flush_log_handlers()
                    await broadcast_log(f"[Backend] NeMo ASR fallback also failed: {nemo_exc}")
                    raise HTTPException(status_code=500, detail=f"Both Bhashini and NeMo ASR failed: {nemo_exc}")
        else:
            await broadcast_log("[Backend] No audio or text provided")
            raise HTTPException(status_code=400, detail="No audio or text provided")

        if not asr_text:
            logger.error("No ASR text returned")
            flush_log_handlers()
            await broadcast_log("[Backend] No ASR text returned")
            raise HTTPException(status_code=400, detail="No ASR text returned from ASR API")

        # Step 2: Translation Telugu -> English (if not already done in pipeline)
        ai_response_en = None  # Ensure variable is always defined
        if translated_text is None:
            if used_fallback:
                # For fallback, we'll use a simple translation service or just pass through
                # In a real implementation, you might want to use another translation service
                translated_text = asr_text  # Placeholder: in real implementation, translate properly
                logger.info(f"Using fallback translation: {translated_text}")
                flush_log_handlers()
                await broadcast_log(f"[Backend] Using fallback translation: {translated_text}")
            else:
                logger.info("Connecting to Translation API (Telugu->English)...")
                flush_log_handlers()
                await broadcast_log("[Backend] Connecting to Translation API (Telugu->English)...")
                translation_payload = {
                    "config": {
                        "language": {
                            "sourceLanguage": "te",
                            "targetLanguage": "en"
                        },
                        "serviceId": TRANSLATION_TE_EN_SERVICE_ID
                    },
                    "input": [{"source": asr_text}]
                }
                
                # Add appName to payload config if available
                if UDYAT_APP_NAME:
                    translation_payload["config"]["appName"] = UDYAT_APP_NAME
                    
                # time is now imported globally
                translation_start = time.time()
                
                # Set up headers for translation API
                translation_headers = {
                    "Content-Type": "application/json",
                }
                if UDYAT_API_KEY:
                    translation_headers["Authorization"] = f"Bearer {UDYAT_API_KEY}"
                if UDYAT_USER_ID:
                    translation_headers["userID"] = UDYAT_USER_ID
                if UDYAT_APP_NAME:
                    translation_headers["appName"] = UDYAT_APP_NAME
                    
                # Log the request payload for debugging
                logger.info(f"Translation API request payload: {translation_payload}")
                logger.info(f"Translation API headers: {translation_headers}")
                flush_log_handlers()
                copy_mail_errors()
                
                # Implement retry mechanism
                max_retries = 3
                retry_count = 0
                success = False
                last_error = None
                
                while retry_count < max_retries and not success:
                        
                        # Try with SSL verification first
                        try:
                                logger.info(f"Translation API attempt {retry_count+1}/{max_retries}")
                                flush_log_handlers()
                                
                                # Make the API call with SSL verification
                                translation_resp = requests.post(
                                    BHASHINI_TRANSLATION_URL, 
                                    json=translation_payload, 
                                    headers=translation_headers, 
                                    timeout=60, 
                                    verify=True  # Try with verification first
                                )
                                success = True
                        except requests.exceptions.SSLError as ssl_err:
                            logger.warning(f"SSL verification failed: {str(ssl_err)}, retrying without verification")
                            translation_headers["Authorization"] = f"Bearer {UDYAT_API_KEY}"
                            if UDYAT_USER_ID:
                                translation_headers["userID"] = UDYAT_USER_ID
                                
                            # Log the request payload for debugging
            logger.info(f"Translation API request payload: {translation_payload}")
            logger.info(f"Translation API headers: {translation_headers}")
            flush_log_handlers()
            copy_mail_errors()
            
            # Implement retry mechanism
            max_retries = 3
            retry_count = 0
            success = False
            last_error = None
            
            while retry_count < max_retries and not success:
                try:
                    # Try with SSL verification first
                    try:
                        logger.info(f"Translation API attempt {retry_count+1}/{max_retries}")
                        flush_log_handlers()
                        
                        # Make the API call with SSL verification
                        translation_resp = requests.post(
                            BHASHINI_TRANSLATION_URL, 
                            json=translation_payload, 
                            headers=translation_headers, 
                            timeout=60, 
                            verify=True  # Try with verification first
                        )
                        success = True
                    except requests.exceptions.SSLError as ssl_err:
                        logger.warning(f"SSL verification failed: {str(ssl_err)}, retrying without verification")
                        flush_log_handlers()
                        copy_mail_errors()
                        
                        # If SSL fails, try without verification
                        translation_resp = requests.post(
                            BHASHINI_TRANSLATION_URL, 
                            json=translation_payload, 
                            headers=translation_headers, 
                            timeout=60, 
                            verify=False
                        )
                        success = True
                except (requests.exceptions.ConnectionError, requests.exceptions.Timeout) as e:
                    retry_count += 1
                    last_error = e
                    # Exponential backoff with a cap to prevent excessive wait times
                    wait_time = min(2 ** retry_count, 10)  # Cap at 10 seconds
                    logger.warning(f"API connection error: {str(e)}. Retrying in {wait_time} seconds...")
                    flush_log_handlers()
                    copy_mail_errors()
                    time.sleep(wait_time)
            
            if not success:
                raise Exception(f"Failed to connect to Translation API after {max_retries} attempts: {str(last_error)}")
            
            
            translation_elapsed = time.time() - translation_start

            # Log the response for debugging
            logger.info(f"Translation API response status: {translation_resp.status_code}")
            logger.info(f"Translation API response: {translation_resp.text[:500]}")
            flush_log_handlers()
            copy_mail_errors()
            
            if translation_resp.status_code != 200:
                error_msg = f"Translation error: {translation_resp.text}"
                logger.error(error_msg)
                flush_log_handlers()
                copy_mail_errors()
                await broadcast_log(f"[Backend] Translation API error: {translation_resp.text}")
                # Fall back to using English response
                ai_response_te = ai_response_en
                logger.info("Falling back to English response due to translation error")
                flush_log_handlers()
                # Don't raise exception, continue with fallback
            else:
                # Try to parse the JSON response
                try:
                    translation_json = translation_resp.json()
                    logger.info(f"Successfully parsed translation response JSON")
                    flush_log_handlers()
                    
                    # Process the translation result
                    translation_result = translation_json
                    ai_response_te = translation_result.get("output", [{}])[0].get("target", "")
                    logger.info(f"Translation result (to Telugu): {ai_response_te}")
                    flush_log_handlers()
                    await broadcast_log(f"[Backend] Translation API success ({translation_elapsed:.2f}s). Telugu Result: {ai_response_te}")
                except Exception as e:
                    error_msg = f"Failed to parse translation response as JSON: {str(e)}. Raw response: {translation_resp.text[:200]}"
                    logger.error(error_msg)
                    flush_log_handlers()
                    copy_mail_errors()
                    await broadcast_log(f"[Backend] {error_msg}")
                    # Fall back to using English response
                    ai_response_te = ai_response_en
                    logger.info("Falling back to English response due to connection error")
                    flush_log_handlers()
                    # Don't raise exception, continue with fallback

        else:
            logger.error("No English->Telugu translation endpoint available. Cannot proceed.")
            flush_log_handlers()
            await broadcast_log("[Backend] No English->Telugu translation endpoint available. Cannot proceed.")
            raise HTTPException(status_code=501, detail="English->Telugu translation endpoint is unavailable. Please try again later.")

        if not ai_response_te:
            logger.error("No Telugu translation of AI response returned")
            flush_log_handlers()
            await broadcast_log("[Backend] No Telugu translation of AI response returned")
            raise HTTPException(status_code=400, detail="No Telugu translation of AI response returned from Translation API")

        # Step 4: Call AI model with English translation to get AI response in English
        if translated_text:
            try:
                ai_response_en = await asyncio.get_event_loop().run_in_executor(None, call_gemini_ai, translated_text)
                logger.info(f"AI English response: {ai_response_en}")
                flush_log_handlers()
                await broadcast_log(f"[Backend] AI English response: {ai_response_en}")
            except Exception as ai_exc:
                logger.error(f"AI model call failed: {ai_exc}")
                flush_log_handlers()
                ai_response_en = "[AI Error]"
        else:
            ai_response_en = "[No English translation available]"

        # Step 5: Skipping TTS step: No TTS server configured. Only text response will be returned.
        tts_audio = ""

        # Return final result
        return JSONResponse({
            "asr_text": asr_text,
            "translated_text": translated_text,
            "ai_response_en": ai_response_en,
            "ai_response_te": ai_response_te,
            "audio": tts_audio,
            "used_fallback": used_fallback
        })
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        flush_log_handlers()
        raise HTTPException(status_code=500, detail=str(e))