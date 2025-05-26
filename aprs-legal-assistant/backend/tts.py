import os
import tempfile
import uuid
from typing import Optional
from fastapi import UploadFile
import asyncio

# For offline TTS
try:
    import torch
    from TTS.api import TTS
except ImportError:
    print("Warning: TTS package not installed. Text-to-speech functionality will be limited.")

# For offline STT
try:
    from vosk import Model, KaldiRecognizer
    import wave
    import json
except ImportError:
    print("Warning: Vosk package not installed. Speech-to-text functionality will be limited.")

class TextToSpeech:
    def __init__(self):
        """Initialize the TTS system using Coqui TTS."""
        self.data_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
        self.audio_dir = os.path.join(self.data_dir, "audio")
        os.makedirs(self.audio_dir, exist_ok=True)
        
        # Initialize TTS model
        self.tts_initialized = False
        try:
            # Use Coqui TTS
            self.tts = TTS("tts_models/en/ljspeech/tacotron2-DDC")
            self.tts_initialized = True
            print("TTS system initialized successfully")
        except Exception as e:
            print(f"Error initializing TTS: {e}")
    
    async def generate_speech(self, text: str, language: str = "english") -> str:
        """
        Generate speech from text.
        
        Args:
            text: Text to convert to speech
            language: Language of the text
            
        Returns:
            Path to the generated audio file
        """
        if not self.tts_initialized:
            raise Exception("TTS system not initialized")
        
        # Generate a unique filename
        filename = f"{uuid.uuid4()}.wav"
        output_path = os.path.join(self.audio_dir, filename)
        
        # Run TTS in a separate thread to avoid blocking
        await asyncio.to_thread(self._generate_speech_sync, text, output_path, language)
        
        return output_path
    
    def _generate_speech_sync(self, text: str, output_path: str, language: str):
        """
        Synchronous version of generate_speech.
        
        Args:
            text: Text to convert to speech
            output_path: Path to save the audio file
            language: Language of the text
        """
        try:
            # Currently, our TTS model only supports English
            # For other languages, we would need to load different models
            if language.lower() != "english":
                print(f"Warning: Using English TTS model for {language} text")
            
            # Generate speech
            self.tts.tts_to_file(text=text, file_path=output_path)
        except Exception as e:
            print(f"Error generating speech: {e}")
            raise

class SpeechToText:
    def __init__(self):
        """Initialize the STT system using Vosk."""
        self.data_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
        self.models_dir = os.path.join(self.data_dir, "models")
        os.makedirs(self.models_dir, exist_ok=True)
        
        # Initialize STT model
        self.stt_initialized = False
        self.models = {}
        
        try:
            # Check if English model exists, if not print instructions
            model_path = os.path.join(self.models_dir, "vosk-model-small-en-us-0.15")
            if os.path.exists(model_path):
                self.models["english"] = Model(model_path)
                self.stt_initialized = True
                print("STT system initialized successfully")
            else:
                print("Vosk model not found. Please download it from https://alphacephei.com/vosk/models")
                print(f"Extract the model to {model_path}")
        except Exception as e:
            print(f"Error initializing STT: {e}")
    
    async def transcribe(self, audio: UploadFile, language: str = "english") -> str:
        """
        Transcribe speech to text.
        
        Args:
            audio: Audio file to transcribe
            language: Language of the audio
            
        Returns:
            Transcribed text
        """
        if not self.stt_initialized:
            raise Exception("STT system not initialized. Please download the Vosk model.")
        
        # Check if we have a model for the requested language
        if language.lower() not in self.models:
            raise Exception(f"No STT model available for {language}")
        
        # Save the uploaded file to a temporary location
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as temp_file:
            temp_path = temp_file.name
            content = await audio.read()
            temp_file.write(content)
        
        try:
            # Process the audio file
            transcription = await asyncio.to_thread(self._transcribe_sync, temp_path, language)
            return transcription
        finally:
            # Clean up the temporary file
            os.unlink(temp_path)
    
    def _transcribe_sync(self, audio_path: str, language: str) -> str:
        """
        Synchronous version of transcribe.
        
        Args:
            audio_path: Path to the audio file
            language: Language of the audio
            
        Returns:
            Transcribed text
        """
        try:
            # Open the audio file
            wf = wave.open(audio_path, "rb")
            
            # Check if it's a valid WAV file
            if wf.getnchannels() != 1 or wf.getsampwidth() != 2 or wf.getcomptype() != "NONE":
                raise Exception("Audio file must be WAV format mono PCM")
            
            # Create recognizer
            model = self.models[language.lower()]
            rec = KaldiRecognizer(model, wf.getframerate())
            rec.SetWords(True)
            
            # Process audio
            results = []
            while True:
                data = wf.readframes(4000)
                if len(data) == 0:
                    break
                
                if rec.AcceptWaveform(data):
                    result = json.loads(rec.Result())
                    results.append(result.get("text", ""))
            
            # Get final result
            final_result = json.loads(rec.FinalResult())
            results.append(final_result.get("text", ""))
            
            # Combine all results
            return " ".join(filter(None, results))
        
        except Exception as e:
            print(f"Error transcribing audio: {e}")
            raise
