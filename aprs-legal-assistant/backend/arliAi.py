import requests
import json

ARLI_API_URL = "https://api.arli.ai/api/v1/generate"
ARLI_API_KEY = "d52c2c3d-81be-424e-b69c-82bcbf06285f"

# Minimal working prompt for testing
prompt = "You are a helpful AI. User: What is the capital of India? Assistant:"

arli_payload = {
    "apiKeyName": "legal-app",
    "temperature": 0.8,
    "model": "Mistral-Nemo-12B-ArliAI-RPMax-v1.1",
    "dry_multiplier": 0,
    "dry_base": 1.75,
    "dry_allowed_length": 2,
    "dry_sequence_breakers": [],
    "dry_range": 0,
    "prompt": prompt
}

arli_headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {ARLI_API_KEY}"
}

def test_arli_ai():
    print("[TEST] Sending payload to ArliAI:", json.dumps(arli_payload, indent=2))
    try:
        resp = requests.post(ARLI_API_URL, headers=arli_headers, json=arli_payload, timeout=60)
        print("[TEST] Status Code:", resp.status_code)
        print("[TEST] Response Text:", resp.text)
        if resp.status_code == 200:
            data = resp.json()
            print("[TEST] Parsed Response:", json.dumps(data, indent=2))
        else:
            print("[TEST] Error: Non-200 status code")
    except Exception as e:
        print(f"[TEST] Exception occurred: {e}")

if __name__ == "__main__":
    test_arli_ai()
