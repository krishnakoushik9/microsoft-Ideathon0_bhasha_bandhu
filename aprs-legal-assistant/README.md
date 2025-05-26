# APRS Legal Assistant

A multilingual legal assistant application with RAG (Retrieval-Augmented Generation) capabilities, web crawling, and offline voice support.

## Features

- **Multilingual Support**: English, Hindi, Telugu, and Marathi
- **RAG System**: Uses Hugging Face models and Pinecone for vector storage
- **Web Crawler**: Automatically scrapes legal websites for up-to-date information
- **Voice Support**: Optional speech-to-text and text-to-speech functionality
- **Desktop Application**: Electron-based for Windows and Linux support

## System Requirements

- Python 3.8+
- Node.js 14+
- Chrome (for Selenium web crawler)

## Project Structure

```
aprs-legal-assistant/
├── backend/
│   ├── main.py                # FastAPI server entrypoint
│   ├── rag.py                 # Retrieval-Augmented Generation logic
│   ├── crawler.py             # Legal web crawler
│   ├── tts.py                 # Text-to-speech & speech-to-text (ASR, TTS)
│   ├── bhashini_voice.py      # Voice translation pipeline (ASR → Translate → TTS)
│   ├── google_search.py       # Google search integration
│   ├── document_processor.py  # PDF/document processing
│   ├── legal_scraper.py       # Targeted legal site scraping
│   ├── arliAi.py              # (Custom AI logic)
│   ├── pdf_generator.py       # PDF generation utilities
│   ├── utils/                 # Helper modules
│   └── assets/                # Model and resource files
├── frontend/
│   ├── index.html             # Main web UI
│   ├── style.css              # Styling
│   ├── renderer.js            # Main JS logic (chat, voice, error handling)
│   └── assets/                # Frontend assets (images, etc)
├── electron/
│   ├── main.js                # Electron main process
│   └── preload.js             # Electron preload script
├── data/                      # Data and scratch files
├── downloads/                 # Downloaded/generated files
├── requirements.txt           # Python dependencies
├── package.json               # Node.js/Electron dependencies
├── .env.example               # Example environment variables
├── pinecone_setup.py          # Pinecone vector DB setup
├── run_app.sh                 # Unified app startup script
├── stop.sh                    # App shutdown script
└── README.md                  # Project documentation
```

## Setup Instructions

### 1. Clone the repository

```bash
git clone <repository-url>
cd aprs-legal-assistant
```

### 2. Set up Python environment

```bash
# Create and activate virtual environment (optional but recommended)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install Python dependencies
pip install -r requirements.txt
```

### 3. Configure Environment Variables

### Hugging Face API (Universal)
- `HF_API_KEY`: Your Hugging Face API key (required for all Hugging Face API calls)
- `HF_MODEL`: The model repo ID to use (e.g., `mistralai/Mixtral-8x7B-Instruct-v0.1`)

These are used universally throughout the backend (main.py, legal_rag.py, pdf_generator.py, rag.py, etc). Ensure they are present in your `.env` file:

```
HF_API_KEY=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
HF_MODEL=mistralai/Mixtral-8x7B-Instruct-v0.1
```

```bash
# Copy the example .env file and edit it with your API keys
cp .env.example .env
```

Edit the `.env` file with your:
- Pinecone API key (sign up at https://www.pinecone.io/)
- Hugging Face API key (sign up at https://huggingface.co/)

### 4. Set up Pinecone

```bash
python pinecone_setup.py
```

### 5. Install Node.js dependencies

```bash
npm install
```

### 6. Run the application

#### Development mode (separate backend and frontend)

```bash
# Start the backend server
python backend/main.py

# In another terminal, start the Electron app
npm start
```

#### Development mode (combined)

```bash
npm run dev
```

## Building Desktop Application

### For Windows

```bash
npm run build:win
```

### For Linux

```bash
npm run build:linux
```

The built applications will be available in the `dist` directory.

## Legal Data Sources

The application is configured to scrape and process legal information from:

- [Indian Kanoon](https://indiankanoon.org)
- [Legislative.gov.in](https://legislative.gov.in)
- [Bar and Bench](https://www.barandbench.com)
- [Latest Laws](https://www.latestlaws.com)

## Adding Custom Legal Documents

You can add your own legal documents through the UI:

1. Click on "Upload Legal Documents" in the application
2. Select your document (.pdf, .doc, .docx, or .txt)
3. The document will be processed and added to the vector database

## Technologies Used

- **Backend**: Python, FastAPI, Langchain, Hugging Face Transformers
- **Vector Database**: Pinecone
- **Web Crawler**: Selenium, BeautifulSoup
- **Voice Processing**: Vosk (STT), Coqui TTS
- **Frontend**: HTML, CSS, JavaScript
- **Desktop App**: Electron

## License

MIT

## Disclaimer

This application is for educational and informational purposes only. It is not a substitute for professional legal advice.
