"""
Mock NeMo ASR module for testing the fallback mechanism.
This provides a simple implementation that can be used when the real NeMo ASR is not available.
"""

import os
import logging
import soundfile as sf
import numpy as np
import random
import string

# Set up logging
logger = logging.getLogger(__name__)

# Sample Telugu phrases for mock transcription
TELUGU_PHRASES = [
    "నమస్కారం, మీరు ఎలా ఉన్నారు?",  # Hello, how are you?
    "నాకు సహాయం కావాలి",  # I need help
    "నేను నా హక్కులను తెలుసుకోవాలనుకుంటున్నాను",  # I want to know my rights
    "నాకు న్యాయ సలహా కావాలి",  # I need legal advice
    "దయచేసి నాకు సహాయం చేయండి",  # Please help me
    "నేను ఒక న్యాయవాదిని కలవాలనుకుంటున్నాను",  # I want to meet a lawyer
    "ఈ పత్రాలను అర్థం చేసుకోవడానికి నాకు సహాయం కావాలి",  # I need help understanding these documents
    "నా కేసు స్థితి ఏమిటి?",  # What is the status of my case?
    "నేను ఫిర్యాదు దాఖలు చేయాలనుకుంటున్నాను",  # I want to file a complaint
    "నా హక్కులు ఏమిటి?"  # What are my rights?
]

class MockTeluguASR:
    """Mock Telugu ASR class that mimics the behavior of the NeMo ASR model."""
    
    def __init__(self):
        """Initialize the mock ASR model."""
        logger.info("Initializing Mock Telugu ASR")
    
    def transcribe(self, wav_bytes: bytes) -> str:
        """
        Mock transcription function that returns a random Telugu phrase.
        
        Args:
            wav_bytes: Audio bytes to transcribe
            
        Returns:
            A random Telugu phrase as a mock transcription
        """
        try:
            # Save the audio to a temporary file for analysis
            tmp_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "test_audio", f"mock_asr_temp_{self._random_string(8)}.wav")
            with open(tmp_path, 'wb') as f:
                f.write(wav_bytes)
            
            # Read the audio file to get duration
            audio, sr = sf.read(tmp_path)
            duration = len(audio) / sr
            
            # Log the audio properties
            logger.info(f"Mock ASR received audio: {len(wav_bytes)} bytes, {duration:.2f} seconds")
            
            # Generate a mock transcription based on audio duration
            if duration < 1.0:
                # Very short audio, probably just noise
                transcription = "..."
            else:
                # Select a random Telugu phrase
                transcription = random.choice(TELUGU_PHRASES)
                
                # For longer audio, possibly combine phrases
                if duration > 5.0:
                    transcription += " " + random.choice(TELUGU_PHRASES)
            
            # Clean up the temporary file
            try:
                os.remove(tmp_path)
            except:
                pass
                
            # Save the transcription to the expected output file
            nemo_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "NeMo", "examples", "asr")
            os.makedirs(nemo_dir, exist_ok=True)
            
            output_te_path = os.path.join(nemo_dir, "output_te.txt")
            with open(output_te_path, 'w', encoding='utf-8') as f:
                f.write(f"Transcription: {transcription}")
            
            output_clean_path = os.path.join(nemo_dir, "output_clean.txt")
            with open(output_clean_path, 'w', encoding='utf-8') as f:
                f.write(transcription)
            
            logger.info(f"Mock ASR generated transcription: {transcription}")
            return transcription
            
        except Exception as e:
            logger.error(f"Error in mock ASR transcription: {str(e)}")
            return "మాక్ ట్రాన్స్క్రిప్షన్ విఫలమైంది"  # Mock transcription failed
    
    def _random_string(self, length=8):
        """Generate a random string for temporary filenames."""
        return ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))
