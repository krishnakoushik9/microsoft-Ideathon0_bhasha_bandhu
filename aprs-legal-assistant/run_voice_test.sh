#!/bin/bash

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"
TEST_AUDIO_DIR="$PROJECT_ROOT/../test_audio"
HTML_TEST_PAGE="$PROJECT_ROOT/test_voice_api.html"
NEMO_DIR="$PROJECT_ROOT/../NeMo"

echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}      APRS Legal Assistant Voice Testing Script          ${NC}"
echo -e "${BLUE}=========================================================${NC}"

# Check if required directories exist
if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}Error: Backend directory not found at $BACKEND_DIR${NC}"
    exit 1
fi

# Create test_audio directory if it doesn't exist
if [ ! -d "$TEST_AUDIO_DIR" ]; then
    echo -e "${YELLOW}Creating test_audio directory at $TEST_AUDIO_DIR${NC}"
    mkdir -p "$TEST_AUDIO_DIR"
fi

# Create NeMo/examples/asr directory if it doesn't exist
if [ ! -d "$NEMO_DIR/examples/asr" ]; then
    echo -e "${YELLOW}Creating NeMo/examples/asr directory${NC}"
    mkdir -p "$NEMO_DIR/examples/asr"
fi

# Check if HTML test page exists
if [ ! -f "$HTML_TEST_PAGE" ]; then
    echo -e "${RED}Error: HTML test page not found at $HTML_TEST_PAGE${NC}"
    echo -e "${YELLOW}Make sure you've created the test_voice_api.html file${NC}"
    exit 1
fi

# Check for required Python packages
echo -e "${BLUE}Checking for required Python packages...${NC}"
python3 -c "import fastapi" 2>/dev/null || { echo -e "${RED}FastAPI not found. Installing...${NC}"; pip install fastapi uvicorn; }
python3 -c "import librosa" 2>/dev/null || { echo -e "${RED}Librosa not found. Installing...${NC}"; pip install librosa; }
python3 -c "import soundfile" 2>/dev/null || { echo -e "${RED}SoundFile not found. Installing...${NC}"; pip install soundfile; }
python3 -c "import dotenv" 2>/dev/null || { echo -e "${RED}python-dotenv not found. Installing...${NC}"; pip install python-dotenv; }

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Function to kill processes using specific ports
kill_port_process() {
    local port=$1
    if check_port $port; then
        echo -e "${YELLOW}Port $port is in use. Killing existing process...${NC}"
        pid=$(lsof -Pi :$port -sTCP:LISTEN -t)
        if [ ! -z "$pid" ]; then
            kill -9 $pid 2>/dev/null
            sleep 1
        fi
    fi
}

# Function to kill background processes on script exit
cleanup() {
    echo -e "\n${YELLOW}Stopping servers...${NC}"
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null
    fi
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null
    fi
    echo -e "${GREEN}Cleanup complete.${NC}"
    exit 0
}

# Set trap for cleanup on script termination
trap cleanup SIGINT SIGTERM EXIT

# Kill any existing processes on ports 8000 and 1177
kill_port_process 8000
kill_port_process 1177

# Start the backend server
echo -e "\n${BLUE}Starting FastAPI backend server on port 8000...${NC}"
cd "$PROJECT_ROOT"

# Activate the virtual environment
echo -e "${YELLOW}Activating project virtual environment...${NC}"
source "$PROJECT_ROOT/venv/bin/activate"

# Print which Python is being used to confirm venv activation
echo -e "Using Python executable: $(which python)"
python --version

# Start the backend with the virtual environment's Python
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!

# Wait for backend to start
echo -e "${YELLOW}Waiting for backend to start...${NC}"
sleep 3

# Check if backend is running
if ! ps -p $BACKEND_PID > /dev/null; then
    echo -e "${RED}Error: Backend failed to start${NC}"
    exit 1
fi

echo -e "${GREEN}Backend started successfully with PID $BACKEND_PID${NC}"

# Start a simple HTTP server for the HTML test page
echo -e "\n${BLUE}Starting HTTP server for test page on port 1177...${NC}"
cd "$PROJECT_ROOT"
python3 -m http.server 1177 &
FRONTEND_PID=$!

# Wait for frontend to start
echo -e "${YELLOW}Waiting for frontend to start...${NC}"
sleep 2

# Check if frontend is running
if ! ps -p $FRONTEND_PID > /dev/null; then
    echo -e "${RED}Error: Frontend server failed to start${NC}"
    exit 1
fi

echo -e "${GREEN}Frontend started successfully with PID $FRONTEND_PID${NC}"

# Open browser
echo -e "\n${BLUE}Opening test page in browser...${NC}"
if command -v xdg-open > /dev/null; then
    xdg-open "http://localhost:1177/test_voice_api.html"
elif command -v open > /dev/null; then
    open "http://localhost:1177/test_voice_api.html"
else
    echo -e "${YELLOW}Could not automatically open browser.${NC}"
    echo -e "${YELLOW}Please open http://localhost:1177/test_voice_api.html in your browser.${NC}"
fi

echo -e "\n${GREEN}Test environment is ready!${NC}"
echo -e "${YELLOW}Backend API is running at: ${NC}http://localhost:8000/api/voice-query"
echo -e "${YELLOW}Frontend test page is at: ${NC}http://localhost:1177/test_voice_api.html"
echo -e "${BLUE}Press Ctrl+C to stop all servers${NC}"

# Keep script running
wait
