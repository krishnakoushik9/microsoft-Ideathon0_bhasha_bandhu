#!/bin/bash
# Close port 8000 (restore firewall)
sudo ufw delete allow 8000/tcp
sudo ufw reload
echo "Port 8000 is now closed to all networks."
