#!/usr/bin/env python3
import os
import sys

# Add the parent directory to the Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Now import and run the main app
from backend.main import app
import uvicorn

if __name__ == "__main__":
    # Set up logging
    import logging
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )
    logger = logging.getLogger("backend")
    logger.info("Starting backend server...")
    
    # Run the app
    uvicorn.run(app, host="0.0.0.0", port=8000)
