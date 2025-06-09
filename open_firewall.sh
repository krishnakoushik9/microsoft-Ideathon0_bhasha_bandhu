#!/bin/bash
# Open port 8000 for all networks (for FastAPI backend)
sudo ufw allow 8000/tcp
sudo ufw reload
echo "Port 8000 is now open to all networks."
