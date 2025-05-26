#!/bin/bash

# APRS Legal Assistant Startup Script

echo "[INFO] Starting APRS Legal Assistant..."
echo "[INFO] Version: 2.0 with XTTS-v2 Voice Integration"

# Show a Linux popup window with full-screen and project description, with OK (Start) and Cancel (Stop) buttons
PROJECT_BLURB="Welcome to the APRS Legal Assistant!\n\nThis application is an advanced AI-powered legal research assistant. It leverages the latest in AI search (Perplexity.ai), web scraping, and document analysis to help you quickly find legal answers, summarize documents, and more.\n\nFeatures:\n- AI-driven legal search (Perplexity integration)\n- Natural language answers\n- PDF and DOCX document support\n- Voice input/output (if TTS/Vosk installed)\n- Modern web UI\n\nHow it works:\n1. The backend (FastAPI) runs on port 8000.\n2. The frontend is served on port 8080.\n3. The frontend connects to the backend for chat and legal search.\n\nPress 'Start Application' to launch both servers.\nPress 'Cancel' to abort startup."

if command -v zenity &> /dev/null; then
    zenity --question --width=900 --height=600 --title="APRS Legal Assistant" \
        --ok-label="Start Application" --cancel-label="Cancel" \
        --text="$PROJECT_BLURB"
    if [ $? -ne 0 ]; then
        echo "Startup cancelled by user."
        exit 0
    fi
elif command -v notify-send &> /dev/null; then
    notify-send "APRS Legal Assistant" "Starting your application...\nSee terminal for details."
else
    echo "(Install 'zenity' or 'notify-send' for popup notifications)"
    echo -e "$PROJECT_BLURB"
    read -p "Press Enter to start, or Ctrl+C to cancel..."
fi

# Check if Python is installed
echo "[INFO] Checking for Python 3..."
if ! command -v python3 &> /dev/null; then
    echo "[ERROR] Python 3 is not installed. Please install Python 3 to run this application."
    exit 1
else
    echo "[OK] Python 3 found."
fi

# Check if Node.js is installed (for frontend serving)
echo "[INFO] Checking for Node.js..."
if ! command -v node &> /dev/null; then
    echo "[WARN] Node.js is not installed. It's recommended for serving the frontend."
    echo "[INFO] We'll continue with Python's http.server as fallback."
    USE_NODE=false
else
    echo "[OK] Node.js found."
    USE_NODE=true
fi

# Set script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check for existing virtual environment in various locations
if [ -d "$SCRIPT_DIR/backend/venv" ]; then
    VENV_PATH="$SCRIPT_DIR/backend/venv"
    echo "Using existing virtual environment in backend folder..."
elif [ -d "$SCRIPT_DIR/venv" ]; then
    VENV_PATH="$SCRIPT_DIR/venv"
    echo "Using existing virtual environment in project root..."
elif [ -d "$HOME/.virtualenvs/aprs-legal" ]; then
    # For users who use virtualenvwrapper
    VENV_PATH="$HOME/.virtualenvs/aprs-legal"
    echo "Using existing virtualenvwrapper environment..."
else
    echo "No virtual environment found. Please create one before running this script."
    echo "You can create a virtual environment with: python3 -m venv $SCRIPT_DIR/venv"
    exit 1
fi

# Activate virtual environment
echo "Activating virtual environment..."
source "$VENV_PATH/bin/activate"

# Check and install required Python dependencies
echo "Checking required dependencies..."
if ! python -c "import fastapi" &>/dev/null || ! python -c "import aiohttp" &>/dev/null; then
    echo "Installing FastAPI and other required packages..."
    pip install fastapi uvicorn reportlab pymupdf python-docx python-multipart requests sentence-transformers python-dotenv pinecone-client aiohttp google-generativeai
fi

# No need for special dependencies for the simplified voice service
echo "Checking voice service dependencies..."
if ! python -c "import fastapi" &>/dev/null; then
    echo "[INFO] Installing voice service dependencies..."
    pip install fastapi uvicorn python-multipart
fi

# Check if .env file exists, if not create from example
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "Creating .env file from example..."
    if [ -f "$SCRIPT_DIR/.env.example" ]; then
        cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
        echo "Please edit the .env file with your API keys before continuing."
    else
        echo "Warning: .env.example file not found. Creating empty .env file."
        touch "$SCRIPT_DIR/.env"
        echo "PINECONE_API_KEY=your_pinecone_api_key" >> "$SCRIPT_DIR/.env"
        echo "PINECONE_ENVIRONMENT=us-east-1" >> "$SCRIPT_DIR/.env"
        echo "PINECONE_INDEX_NAME=legal-app-microsoft" >> "$SCRIPT_DIR/.env"
        echo "HUGGINGFACE_API_KEY=your_huggingface_api_key" >> "$SCRIPT_DIR/.env"
        echo "GEMINI_API_KEY=your_gemini_api_key" >> "$SCRIPT_DIR/.env"
        echo "Please edit $SCRIPT_DIR/.env with your API keys before continuing."
    fi
    exit 1
fi

# Create necessary directories
echo "Setting up directories..."
mkdir -p "$SCRIPT_DIR/data/pdf_exports"  # For storing generated PDFs
mkdir -p "$SCRIPT_DIR/data/legal_documents/metadata"
mkdir -p "$SCRIPT_DIR/backend/xtts_models/voices"

# Clean and build the Flutter web frontend before serving
FRONTEND_DIR="$SCRIPT_DIR/frontend/flutter_app"
echo "[INFO] Cleaning Flutter web build..."
if command -v flutter &> /dev/null; then
    cd "$FRONTEND_DIR"
    flutter clean
    echo "[INFO] Building Flutter web frontend..."
    flutter build web
    cd "$SCRIPT_DIR"
else
    echo "[ERROR] Flutter is not installed or not in PATH. Please install Flutter to build the frontend."
    exit 1
fi

# Start the backend server - this is critical for proper operation
echo "[INFO] Starting main backend server on port 8000..."

# Kill any existing processes on port 8000 to avoid conflicts
if command -v lsof &> /dev/null; then
    lsof -ti tcp:8000 | xargs -r kill
fi

# Start the backend directly instead of using run_back.sh for better control
cd "$SCRIPT_DIR"
python -m backend.main &
BACKEND_PID=$!

# Wait for backend to be ready
echo "Waiting for backend to be ready..."
sleep 3  # Give backend a moment to start

# VOICE SERVICE PERMANENTLY DISABLED TO AVOID PORT CONFLICTS
echo "[INFO] Voice service permanently disabled to avoid port conflicts with web search API"

# Wait for backend to start
echo "Waiting for backend to be ready..."
if command -v curl &> /dev/null; then
  until curl -s http://127.0.0.1:8000/ >/dev/null; do
    echo "Waiting for backend..."
    sleep 1
  done
else
  sleep 3
fi
echo "Backend is up."

# Start the frontend server on port 8080 to avoid conflicts with backend
echo "Starting frontend server on port 8080..."

# Kill any existing processes on port 8080 to avoid conflicts
if command -v lsof &> /dev/null; then
    lsof -ti tcp:8080 | xargs -r kill
fi

if [ "$USE_NODE" = true ] && command -v http-server &> /dev/null; then
    echo "[INFO] Serving frontend via http-server (Node.js)"
    http-server "$SCRIPT_DIR/frontend/flutter_app/build/web" -p 8080 &
    FRONTEND_PID=$!
else
    echo "[INFO] Serving frontend via Python's http.server"
    cd "$SCRIPT_DIR/frontend/flutter_app/build/web"
    python3 -m http.server 8080 &
    FRONTEND_PID=$!
fi

# Wait for frontend to start
echo "Waiting for frontend to start..."
sleep 2

# Open the application in a browser
echo "Opening application in browser..."
if command -v xdg-open &> /dev/null; then
    xdg-open http://localhost:8080
elif command -v open &> /dev/null; then
    open http://localhost:8080
else
    echo "Application is running at http://localhost:8080"
fi

echo "Backend API is running at http://localhost:8000"

# Wait for user to exit
echo "Press Ctrl+C to stop the application"
echo "[INFO] Services running:"
echo "  - Backend API: http://localhost:8000"
echo "  - Frontend UI: http://localhost:8080"
echo ""
echo "[INFO] Features:"
echo "  - Web Search API: Direct endpoint at /kavvy-search for legal search queries"
echo "  - Chat API: Simplified endpoint at /chat for legal assistance"
echo "  - Document Management: Upload and manage legal documents"
echo "  - PDF Generation: Generate legal summaries from conversations"
trap "kill $BACKEND_PID $FRONTEND_PID; echo 'Application stopped.'; exit 0" INT
wait
