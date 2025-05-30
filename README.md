<div align="center">

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&pause=1000&color=36BCF7&width=435&lines=APRS+Legal+Assistant+%F0%9F%94%96;Multilingual+AI+for+Law+%F0%9F%93%84%F0%9F%8E%93%F0%9F%9A%80" alt="Typing SVG" />

<img src="https://media.giphy.com/media/3o7aD2saalBwwftBIY/giphy.gif" width="120" alt="Animated Book" />

---

![GitHub repo stars](https://img.shields.io/github/stars/krishnakoushik9/microsoft-Ideathon0_bhasha_bandhu?style=flat-square)
![GitHub forks](https://img.shields.io/github/forks/krishnakoushik9/microsoft-Ideathon0_bhasha_bandhu?style=flat-square)
![GitHub issues](https://img.shields.io/github/issues/krishnakoushik9/microsoft-Ideathon0_bhasha_bandhu?style=flat-square)
![GitHub license](https://img.shields.io/github/license/krishnakoushik9/microsoft-Ideathon0_bhasha_bandhu?style=flat-square)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)
![Visitor Badge](https://komarev.com/ghpvc/?username=krishnakoushik9&label=VISITORS&style=flat-square)

---

<img src="https://skillicons.dev/icons?i=python,fastapi,flutter,dart,nodejs,electron,js,html,css,github,git,linux&perline=8" alt="Tech Stack" />



> ⚠️ **License & Usage Policy:**  
> If you wish to copy, reuse, or adapt any part of this project, please email the repository owner first at [23h51a66h2@cmrcet.ac.in]. Use is only allowed after explicit approval.

</div>

<details>
<summary><strong>✨ <ins>Why APRS Legal Assistant?</ins></strong> (click to expand)</summary>

> <img src="https://media.giphy.com/media/26ufnwz3wDUli7GU0/giphy.gif" width="32"> <b>APRS Legal Assistant</b> brings together multilingual AI, document management, voice, and web crawling into a single, beautiful desktop app for legal professionals, students, and researchers. It’s built for speed, security, and extensibility!

</details>

---

## 🚀 Key Features

| Feature | Description |
|---------|-------------|
| 🌐 **Multilingual** | English, Hindi, Telugu, Marathi support |
| 🧠 **RAG AI** | Context-aware Q&A using Hugging Face LLMs + Pinecone |
| 📄 **Document System** | Upload, preview, manage PDFs/images/text |
| 🗣️ **Voice Pipeline** | ASR → Translate → TTS (Bhashini models) |
| 🕸️ **Web Crawler** | Scrapes legal sites for latest data |
| 💻 **Desktop App** | Electron + Flutter for Windows/Linux |
| 🔒 **Secure Secrets** | .env config, push protection |
| 🛠️ **Offline/Online** | Works with local or cloud models |

---

## 🏗️ Architecture & Tech Stack

### Backend (Python/FastAPI)
- **FastAPI**: REST API for chat, document, and voice endpoints
- **RAG System**: Integrates Hugging Face LLMs (Mixtral, Falcon, etc.) with Pinecone for vector search
- **Document System**: Handles upload, preview, metadata, and secure storage
- **Voice Pipeline**: Bhashini ASR, translation, and TTS models (see below)
- **Web Crawling**: Selenium-based legal web scraper
- **PDF & Text Processing**: PDF parsing, text extraction, and chunking
- **Security**: .env config, secret scanning, and protected endpoints

### Frontend (Flutter Web)
- **Flutter**: Modern, responsive UI for chat, document management, and voice features
- **Document Preview**: PDF viewer, image/text preview, and metadata popups
- **Voice UI**: Record, transcribe, and playback audio queries
- **Model Selection**: Toggle between LLMs, voice models, and modes
- **Electron Integration**: Desktop-native experience

### Electron (Node.js)
- **Electron**: Wraps Flutter web frontend for cross-platform desktop deployment
- **IPC**: Secure communication between Node.js backend and Flutter frontend

### AI & Vector Search
- **Hugging Face Transformers**: Mixtral, Falcon, and others for LLM Q&A
- **Bhashini Voice Models**:
  - ASR (Telugu): `66e41f28e2f5842563c988d9`
  - Translation (Te-En): `67b871747d193a1beb4b847e`
  - TTS (English): `6576a17e00d64169e2f8f43d`
- **Pinecone**: Scalable vector DB for document and legal retrieval

### Document Management
- **Upload**: Secure file upload to `/documents` backend folder
- **Preview**: PDF, image, text, and metadata popup
- **Metadata**: File type, size, upload date, etc.
- **Actions**: Download, delete, share

---

## 📁 Directory Structure

```
aprs-legal-assistant/
├── backend/                 # Python FastAPI backend
│   ├── main.py              # API entrypoint
│   ├── rag.py               # RAG logic
│   ├── crawler.py           # Web crawler
│   ├── tts.py, bhashini_voice.py # Voice pipeline
│   ├── document_processor.py # Document handling
│   ├── legal_scraper.py     # Targeted scraping
│   ├── utils/               # Helpers
│   └── assets/              # Model/data assets
├── frontend/                # Flutter web app
│   ├── flutter_app/         # Main Dart code
│   ├── index.html           # Entry point
│   └── assets/              # Images, icons, etc.
├── electron/                # Electron desktop code
│   ├── main.js              # Electron main
│   └── preload.js           # Preload script
├── data/, downloads/, test_audio/ # Data & test files
├── requirements.txt         # Python deps
├── package.json             # Node/Electron deps
├── .env.example             # Example env vars
├── pinecone_setup.py        # Pinecone DB setup
├── run_app.sh               # Unified startup
├── stop.sh                  # Shutdown script
└── README.md                # This file
```

---

## ⚙️ Installation & Setup

### 1. Clone the repository
```bash
git clone <repository-url>
cd aprs-legal-assistant
```

### 2. Python Backend Setup
```bash
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate (Windows)
pip install -r requirements.txt
```

### 3. Node/Electron Setup
```bash
npm install  # Installs Electron and Node deps
```

### 4. Flutter Frontend Setup
- Install Flutter: https://docs.flutter.dev/get-started/install
- Run:
```bash
cd frontend/flutter_app
flutter pub get
flutter build web
```

### 5. Configure Environment Variables
- Copy `.env.example` to `.env` and fill in:
  - `HF_API_KEY` (Hugging Face, required)
  - `PINECONE_API_KEY` (Pinecone, required)
  - Any other service keys (Gemini, Google, etc.)

### 6. Pinecone Vector DB Setup
```bash
python pinecone_setup.py
```

---

## 🏃 Running the Application

### Start Backend (FastAPI)
```bash
cd backend
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Start Frontend (Flutter Web)
```bash
cd frontend/flutter_app
flutter run -d web-server --web-port 8080
```

### Start Electron Desktop App
```bash
npm start
```

---

## 🧠 AI and Voice Pipeline Details

- **RAG**: Uses Pinecone for embedding and retrieval, then LLM (Mixtral, Falcon, etc.) for answer generation
- **Voice**: Bhashini ASR (Telugu), translation (Te-En), and TTS (English) for full voice query pipeline
- **Document Management**: Secure upload, preview (PDF/image/text), metadata, and management actions
- **Web Crawler**: Scrapes legal sites for current data, feeds into vector DB

---

## 🔒 Security & Best Practices
- **Secrets**: Never commit real API keys to public repos. Use `.env` and `.gitignore`
- **Push Protection**: GitHub will block pushes with secrets unless explicitly allowed
- **Environment Variables**: Store all secrets and config in `.env` (never in code)
- **Rotate Keys**: If a key is leaked, rotate it immediately

---

## 🤝 Contributing
- Fork the repo and create a feature branch
- Submit pull requests with clear descriptions
- Follow existing code style for Python, Dart, and JS
- Add tests for new features if possible

---

## 📜 License
MIT License. See `LICENSE` file for details.

---

## 🙏 Credits
- Hugging Face, Pinecone, Bhashini, OpenAI, Google, and all open-source contributors

---

## 💬 Contact
For questions, suggestions, or support, open an issue or contact the maintainer at [GitHub Issues](https://github.com/krishnakoushik9/microsoft-Ideathon0_bhasha_bandhu/issues).


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
