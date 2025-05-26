#!/bin/bash
# run_back.sh - Starts the backend server

# Get script directory
auto_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$auto_SCRIPT_DIR"

echo "[INFO] Starting backend server..."
exec uvicorn backend.main:app --host 0.0.0.0 --port 8000 --log-level info
