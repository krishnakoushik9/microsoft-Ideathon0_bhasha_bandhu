import os
import numpy as np
import torch
import soundfile as sf
from nemo.collections.asr.models import EncDecRNNTBPEModel

MODEL_PATH = os.path.join(os.path.dirname(__file__), "indicconformer_stt_te_hybrid_rnnt_large.nemo")

class LocalTeluguASR:
    def __init__(self):
        self.model = None
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        if os.path.exists(MODEL_PATH):
            try:
                self.model = EncDecRNNTBPEModel.restore_from(MODEL_PATH, map_location=self.device)
                self.model.eval()
            except Exception as e:
                print(f"Failed to load NeMo Telugu ASR model: {e}")
                self.model = None
        else:
            print(f"Telugu ASR model not found at {MODEL_PATH}")
            self.model = None

    def transcribe(self, wav_bytes: bytes) -> str:
        if self.model is None:
            raise RuntimeError("Local Telugu ASR model not loaded.")
        # Write bytes to temp file
        import tempfile
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            tmp.write(wav_bytes)
            tmp_path = tmp.name
        try:
            # Read audio
            audio, sr = sf.read(tmp_path)
            # NeMo expects 16kHz mono
            if sr != 16000:
                import librosa
                audio = librosa.resample(audio, orig_sr=sr, target_sr=16000)
            if len(audio.shape) > 1:
                audio = np.mean(audio, axis=1)  # Convert to mono
            # Run inference
            transcript = self.model.transcribe([audio])[0]
            return transcript.strip()
        finally:
            os.unlink(tmp_path)
