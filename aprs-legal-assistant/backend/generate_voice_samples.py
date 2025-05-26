#!/usr/bin/env python3
# Generate simple voice sample files for the simple_voice_service

import os
import wave
import struct
import math

def generate_sine_wave(frequency, duration, sample_rate=16000):
    """Generate a simple sine wave at the specified frequency"""
    num_samples = int(duration * sample_rate)
    samples = []
    
    for i in range(num_samples):
        sample = math.sin(2 * math.pi * frequency * i / sample_rate)
        # Scale to 16-bit range and convert to integer
        sample = int(sample * 32767)
        samples.append(sample)
    
    return samples

def save_wav(filename, samples, sample_rate=16000):
    """Save samples to a WAV file"""
    with wave.open(filename, 'w') as wav_file:
        # Set parameters
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 2 bytes per sample (16-bit)
        wav_file.setframerate(sample_rate)
        
        # Write samples
        for sample in samples:
            wav_file.writeframes(struct.pack('h', sample))

def main():
    # Create voice_samples directory if it doesn't exist
    samples_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'voice_samples')
    os.makedirs(samples_dir, exist_ok=True)
    
    # Generate different tones for each persona
    personas = {
        'judge': 440,      # A4
        'lawyer': 523.25,  # C5
        'defendant': 587.33,  # D5
        'witness': 659.25,  # E5
        'default': 392     # G4
    }
    
    # Generate and save samples
    for persona, frequency in personas.items():
        filename = os.path.join(samples_dir, f"{persona}.wav")
        samples = generate_sine_wave(frequency, duration=3)
        save_wav(filename, samples)
        print(f"Created {filename}")

if __name__ == "__main__":
    main()
