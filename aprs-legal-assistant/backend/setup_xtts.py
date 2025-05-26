"""
Setup script for XTTS-v2 model and voice samples
Downloads and prepares necessary files for the XTTS voice service
"""
import os
import sys
import shutil
import argparse
import subprocess
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

# Paths
SCRIPT_DIR = Path(__file__).parent.absolute()
MODELS_DIR = SCRIPT_DIR / "xtts_models"
VOICES_DIR = MODELS_DIR / "voices"
TEMP_DIR = SCRIPT_DIR / "temp_downloads"

# Model URLs - these would need to be updated with actual download links
# For now, we'll use placeholders and provide instructions
XTTS_MODEL_URL = "https://huggingface.co/coqui/XTTS-v2/resolve/main/model.pth"
XTTS_CONFIG_URL = "https://huggingface.co/coqui/XTTS-v2/resolve/main/config.json"

def check_dependencies():
    """Check if required Python packages are installed"""
    # First install torch and torchaudio separately
    try:
        __import__("torch")
        logger.info("✓ torch is installed")
    except ImportError:
        logger.error("✗ torch is not installed")
        logger.info("Installing torch...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "torch==2.0.1", "--index-url", "https://download.pytorch.org/whl/cpu"])
        logger.info("✓ torch installed successfully")
    
    try:
        __import__("torchaudio")
        logger.info("✓ torchaudio is installed")
    except ImportError:
        logger.error("✗ torchaudio is not installed")
        logger.info("Installing torchaudio...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "torchaudio==2.0.2", "--index-url", "https://download.pytorch.org/whl/cpu"])
        logger.info("✓ torchaudio installed successfully")
    
    # Install TTS from GitHub
    try:
        __import__("TTS")
        logger.info("✓ TTS is installed")
    except ImportError:
        logger.error("✗ TTS is not installed")
        logger.info("Installing TTS from GitHub...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "git+https://github.com/coqui-ai/TTS.git@v0.21.1"])
            logger.info("✓ TTS installed successfully")
        except subprocess.CalledProcessError:
            logger.error("Failed to install TTS from GitHub. Trying alternative method...")
            try:
                subprocess.check_call([sys.executable, "-m", "pip", "install", "TTS==0.21.1", "--no-deps"])
                subprocess.check_call([sys.executable, "-m", "pip", "install", "numpy", "scipy", "librosa", "unidecode", "phonemizer", "pyyaml"])
                logger.info("✓ TTS installed with alternative method")
            except subprocess.CalledProcessError:
                logger.error("Failed to install TTS. You may need to install it manually.")
                logger.info("Manual installation instructions:")
                logger.info("1. pip install numpy scipy librosa unidecode phonemizer pyyaml")
                logger.info("2. pip install git+https://github.com/coqui-ai/TTS.git@v0.21.1")
    
    # Install FastAPI and uvicorn
    other_packages = ["fastapi", "uvicorn"]
    for package in other_packages:
        try:
            __import__(package)
            logger.info(f"✓ {package} is installed")
        except ImportError:
            logger.error(f"✗ {package} is not installed")
            logger.info(f"Installing {package}...")
            subprocess.check_call([sys.executable, "-m", "pip", "install", package])
            logger.info(f"✓ {package} installed successfully")

def create_directories():
    """Create necessary directories"""
    os.makedirs(MODELS_DIR, exist_ok=True)
    os.makedirs(VOICES_DIR, exist_ok=True)
    os.makedirs(TEMP_DIR, exist_ok=True)
    
    logger.info(f"Created directories at {MODELS_DIR}")

def download_model():
    """Download XTTS-v2 model files"""
    logger.info("Downloading XTTS-v2 model files...")
    
    # For now, we'll just provide instructions since direct download links may change
    logger.info("\n" + "-"*80)
    logger.info("MANUAL DOWNLOAD REQUIRED:")
    logger.info("Please download the XTTS-v2 model files from Hugging Face:")
    logger.info("1. Visit: https://huggingface.co/coqui/XTTS-v2")
    logger.info(f"2. Download the model.pth file and save it to: {MODELS_DIR / 'xtts_v2.pth'}")
    logger.info(f"3. Download the config.json file and save it to: {MODELS_DIR / 'config.json'}")
    logger.info("-"*80 + "\n")
    
    input("Press Enter after you've downloaded the model files...")

def prepare_voice_samples():
    """Prepare voice samples for different courtroom personas"""
    logger.info("Setting up voice samples...")
    
    # Voice sample instructions
    logger.info("\n" + "-"*80)
    logger.info("VOICE SAMPLES REQUIRED:")
    logger.info("XTTS-v2 requires voice samples for each persona. Please prepare:")
    logger.info(f"1. Record or find voice samples for each courtroom role")
    logger.info(f"2. Save them as WAV files in: {VOICES_DIR}")
    logger.info(f"3. Name them according to the role: judge.wav, prosecutor.wav, etc.")
    logger.info("Required voice samples:")
    
    persona_roles = [
        "judge", "prosecutor", "defense", "witness", 
        "defendant", "clerk", "bailiff", "expert", "default"
    ]
    
    for role in persona_roles:
        logger.info(f"  - {role}.wav")
    
    logger.info("-"*80 + "\n")
    
    # Create a default voice sample if needed
    default_voice = VOICES_DIR / "default.wav"
    if not default_voice.exists():
        logger.info("No default voice sample found. You'll need to provide at least one voice sample.")
        logger.info("You can use any clear voice recording, about 10-30 seconds long, saved as a WAV file.")

def check_installation():
    """Check if the installation is complete"""
    model_path = MODELS_DIR / "xtts_v2.pth"
    config_path = MODELS_DIR / "config.json"
    
    if not model_path.exists() or not config_path.exists():
        logger.warning("⚠️ Model files are missing!")
        return False
    
    voice_files = list(VOICES_DIR.glob("*.wav"))
    if not voice_files:
        logger.warning("⚠️ No voice samples found!")
        return False
    
    logger.info("✓ Installation check passed!")
    logger.info(f"Found model files: {model_path.exists()} {config_path.exists()}")
    logger.info(f"Found {len(voice_files)} voice samples")
    
    return True

def main():
    """Main setup function"""
    parser = argparse.ArgumentParser(description="Setup XTTS-v2 for APRS Legal Assistant")
    parser.add_argument("--skip-deps", action="store_true", help="Skip dependency check")
    parser.add_argument("--skip-model", action="store_true", help="Skip model download")
    parser.add_argument("--skip-voices", action="store_true", help="Skip voice sample setup")
    args = parser.parse_args()
    
    logger.info("Setting up XTTS-v2 for APRS Legal Assistant")
    
    create_directories()
    
    if not args.skip_deps:
        check_dependencies()
    
    if not args.skip_model:
        download_model()
    
    if not args.skip_voices:
        prepare_voice_samples()
    
    check_installation()
    
    logger.info("\n" + "-"*80)
    logger.info("SETUP COMPLETE")
    logger.info("To start the XTTS service, run:")
    logger.info("python xtts_service.py")
    logger.info("-"*80 + "\n")

if __name__ == "__main__":
    main()
