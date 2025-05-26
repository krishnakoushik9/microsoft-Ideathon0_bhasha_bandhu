#!/bin/bash

# APRS Legal Assistant Stop Script

echo "[INFO] Stopping APRS Legal Assistant services..."

# Try to kill backend (uvicorn), frontend (http.server), and other services by port
BACKEND_PORT=8000
FRONTEND_PORT=8080

# Try to kill by port
if command -v fuser &> /dev/null; then
    fuser -k ${BACKEND_PORT}/tcp 2>/dev/null
    fuser -k ${FRONTEND_PORT}/tcp 2>/dev/null
fi

# Try to kill by process name and specific patterns
for PROC in uvicorn http.server; do
    pkill -f "$PROC" 2>/dev/null
done

# Kill the backend.main process specifically
pkill -f "python -m backend.main" 2>/dev/null

# Kill any Python processes related to our application, but be more selective
pkill -f "python.*aprs-legal-assistant" 2>/dev/null

# Fallback: kill any process still bound to ports via lsof
if command -v lsof &> /dev/null; then
    lsof -ti tcp:$BACKEND_PORT | xargs -r kill
    lsof -ti tcp:$FRONTEND_PORT | xargs -r kill
fi

# Also kill any lingering run scripts
for SCRIPT in run_back.sh run_front.sh; do
    pkill -f "$SCRIPT" 2>/dev/null
done

# Show a Linux popup window confirming services stopped
STOP_MSG="APRS Legal Assistant services have been stopped successfully.\n\nThe following services were terminated:\n- Backend API (port 8000)\n- Frontend UI (port 8080)\n- Web Search API (/kavvy-search)\n- Chat API (/chat)"
if command -v zenity &> /dev/null; then
    zenity --info --width=500 --height=200 --title="APRS Legal Assistant" --text="$STOP_MSG"
elif command -v notify-send &> /dev/null; then
    notify-send "APRS Legal Assistant" "$STOP_MSG"
else
    echo "$STOP_MSG"
fi
