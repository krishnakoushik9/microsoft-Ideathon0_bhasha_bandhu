#!/usr/bin/env python3
"""
Test script for NeMo ASR fallback functionality.
This script simulates a failure in the Bhashini API and tests the fallback to NeMo ASR.
"""

import os
import sys
import requests
import json
import base64
import time
from pathlib import Path

# Configuration
API_ENDPOINT = "http://localhost:8000/api/voice-query"
TEST_AUDIO_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "test_audio")
SAMPLE_AUDIO = os.path.join(TEST_AUDIO_PATH, "sample_telugu.wav")  # You'll need to create this file

def create_sample_audio():
    """Create a sample audio file if it doesn't exist"""
    if not os.path.exists(SAMPLE_AUDIO):
        print(f"Sample audio file not found at {SAMPLE_AUDIO}")
        print("You need to create a sample Telugu audio file for testing.")
        print("You can use any Telugu audio file and rename it to 'sample_telugu.wav'")
        print(f"Place it in the {TEST_AUDIO_PATH} directory.")
        return False
    return True

def test_api_directly():
    """Test the API directly with a sample audio file"""
    if not create_sample_audio():
        return
    
    print(f"Testing with audio file: {SAMPLE_AUDIO}")
    
    # Read the audio file
    with open(SAMPLE_AUDIO, "rb") as f:
        audio_bytes = f.read()
    
    # Create multipart form data
    files = {
        'audio': (os.path.basename(SAMPLE_AUDIO), audio_bytes, 'audio/wav')
    }
    
    try:
        # Send the request
        print("Sending request to API...")
        response = requests.post(API_ENDPOINT, files=files)
        
        # Check the response
        if response.status_code == 200:
            data = response.json()
            print("\nAPI Response:")
            print(json.dumps(data, indent=2))
            
            # Check if fallback was used
            if data.get('used_fallback'):
                print("\n✅ Fallback to NeMo ASR was used!")
                print(f"Telugu ASR text: {data.get('asr_text', 'N/A')}")
                
                # Check if files were created
                nemo_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "NeMo", "examples", "asr")
                output_te_path = os.path.join(nemo_dir, "output_te.txt")
                output_clean_path = os.path.join(nemo_dir, "output_clean.txt")
                
                if os.path.exists(output_te_path):
                    print(f"\nContent of {output_te_path}:")
                    with open(output_te_path, 'r', encoding='utf-8') as f:
                        print(f.read())
                
                if os.path.exists(output_clean_path):
                    print(f"\nContent of {output_clean_path}:")
                    with open(output_clean_path, 'r', encoding='utf-8') as f:
                        print(f.read())
            else:
                print("\n❌ Fallback to NeMo ASR was NOT used. Bhashini API worked successfully.")
                print("To test the fallback, you need to simulate a failure in the Bhashini API.")
                print("You can do this by temporarily modifying the API endpoint URL in bhashini_voice.py")
        else:
            print(f"\n❌ API request failed with status code: {response.status_code}")
            print(f"Response: {response.text}")
    except Exception as e:
        print(f"\n❌ Error: {e}")

def simulate_bhashini_failure():
    """Simulate a failure in the Bhashini API by modifying the API endpoint temporarily"""
    bhashini_voice_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "backend", "bhashini_voice.py")
    
    if not os.path.exists(bhashini_voice_path):
        print(f"❌ Could not find bhashini_voice.py at {bhashini_voice_path}")
        return False
    
    # Read the file
    with open(bhashini_voice_path, 'r') as f:
        content = f.read()
    
    # Create a backup
    backup_path = f"{bhashini_voice_path}.bak"
    with open(backup_path, 'w') as f:
        f.write(content)
    
    # Modify the ASR_URL to an invalid URL
    modified_content = content.replace(
        'ASR_URL = f"https://dhruva-api.bhashini.gov.in/services/inference/asr?serviceId={ASR_TELUGU_MODEL_ID}"',
        'ASR_URL = f"https://invalid-url-for-testing.bhashini.gov.in/services/inference/asr?serviceId={ASR_TELUGU_MODEL_ID}"'
    )
    
    if modified_content == content:
        print("❌ Could not find the ASR_URL line to modify")
        return False
    
    # Write the modified content
    with open(bhashini_voice_path, 'w') as f:
        f.write(modified_content)
    
    print(f"✅ Modified bhashini_voice.py to simulate Bhashini API failure")
    print(f"Original file backed up to {backup_path}")
    return True

def restore_bhashini_file():
    """Restore the original bhashini_voice.py file"""
    bhashini_voice_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "backend", "bhashini_voice.py")
    backup_path = f"{bhashini_voice_path}.bak"
    
    if not os.path.exists(backup_path):
        print(f"❌ Backup file not found at {backup_path}")
        return False
    
    # Restore from backup
    with open(backup_path, 'r') as f:
        content = f.read()
    
    with open(bhashini_voice_path, 'w') as f:
        f.write(content)
    
    # Remove the backup
    os.remove(backup_path)
    
    print(f"✅ Restored original bhashini_voice.py file")
    return True

def main():
    """Main function"""
    print("=" * 80)
    print("NeMo ASR Fallback Test Script")
    print("=" * 80)
    
    # Check if test_audio directory exists
    if not os.path.exists(TEST_AUDIO_PATH):
        os.makedirs(TEST_AUDIO_PATH)
        print(f"Created directory: {TEST_AUDIO_PATH}")
    
    # Menu
    while True:
        print("\nOptions:")
        print("1. Test API directly (without modifying files)")
        print("2. Simulate Bhashini API failure (modifies bhashini_voice.py)")
        print("3. Restore original bhashini_voice.py file")
        print("4. Exit")
        
        choice = input("\nEnter your choice (1-4): ")
        
        if choice == '1':
            test_api_directly()
        elif choice == '2':
            if simulate_bhashini_failure():
                print("\nNow you can test the API to see the fallback in action.")
                test_now = input("Do you want to test the API now? (y/n): ")
                if test_now.lower() == 'y':
                    test_api_directly()
        elif choice == '3':
            restore_bhashini_file()
        elif choice == '4':
            print("Exiting...")
            break
        else:
            print("Invalid choice. Please enter a number between 1 and 4.")

if __name__ == "__main__":
    main()
