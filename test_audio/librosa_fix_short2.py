import librosa
import soundfile as sf

# Load the short segment (use absolute path to avoid issues)
input_path = '/home/krsna/Desktop/ideathon/test_audio/testing_short.wav'
output_path = '/home/krsna/Desktop/ideathon/test_audio/testing_short_librosa.wav'

# Load with librosa (force mono, 16kHz)
y, sr = librosa.load(input_path, sr=16000, mono=True)

# Save with soundfile (16-bit PCM WAV)
sf.write(output_path, y, sr, subtype='PCM_16')

print(f"Saved: {output_path} (sr={sr}, len={len(y)/sr:.2f}s)")
