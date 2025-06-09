from fastapi import FastAPI, Request, File, UploadFile, Form, HTTPException, BackgroundTasks, Body, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
import uvicorn
import os
import uuid
import logging
import requests  # for HTTP calls in chat endpoint
from dotenv import load_dotenv
from typing import List, Dict, Any, Optional
import json
from datetime import datetime
import base64
from pydantic import BaseModel

# Import routers
import sys
import os
# Add the current directory to the path so we can import local modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from lawyers import router as lawyers_router
from bhashini_voice import router as voice_router

# Setup logging
logger = logging.getLogger("aprs_legal_assistant")

# Load environment variables
load_dotenv()

app = FastAPI(title="APRS Legal Assistant API")

# --- Serve Flutter web build as static files from FastAPI ---
from fastapi.staticfiles import StaticFiles
frontend_build_dir = os.path.join(os.path.dirname(__file__), "../frontend/flutter_app/build/web")
if os.path.exists(frontend_build_dir):
    # IMPORTANT: Mount static files at /app instead of root to avoid conflicts with API routes
    app.mount(
        "/app",  # Serve at /app instead of root
        StaticFiles(directory=frontend_build_dir, html=True),
        name="frontend"
    )
# --- END static files mount ---

# Simple web search endpoint that will definitely work
@app.get("/api/search")
@app.post("/api/search")
async def api_search(request: Request):
    print(f"[DEBUG] Received search request: {request.method} {request.url.path}")
    
    try:
        # Get query from various sources
        query = None
        
        # First try query parameters
        if "query" in request.query_params:
            query = request.query_params.get("query")
            print(f"[DEBUG] Got query from URL params: {query}")
        else:
            # Try to get from body
            try:
                body_bytes = await request.body()
                if body_bytes:
                    body_text = body_bytes.decode('utf-8')
                    if body_text.strip():
                        import json
                        body_json = json.loads(body_text)
                        query = body_json.get("query")
                        print(f"[DEBUG] Got query from JSON body: {query}")
            except Exception as e:
                print(f"[ERROR] Failed to parse request body: {e}")
        
        if not query:
            return {"error": "No query parameter found"}
        
        # Simple mock response for testing
        return {
            "results": [
                {
                    "title": "Legal Rights in India - Sample Result",
                    "url": "https://example.com/legal-rights-india",
                    "snippet": "Information about legal rights in India..."
                }
            ],
            "gemini_answer": "This is a test response for query: " + query
        }
    except Exception as e:
        print(f"[ERROR] Error in search: {e}")
        return {"error": str(e)}

# Add the kavvy-search endpoint that the frontend is trying to access
@app.get("/kavvy-search")
@app.post("/kavvy-search")
async def kavvy_search(request: Request):
    print(f"[DEBUG] Received kavvy-search request: {request.method} {request.url.path}")
    
    try:
        # Get query from various sources
        query = None
        
        # First try query parameters
        if "query" in request.query_params:
            query = request.query_params.get("query")
            print(f"[DEBUG] Got query from URL params: {query}")
        else:
            # Try to get from body
            try:
                body_bytes = await request.body()
                if body_bytes:
                    body_text = body_bytes.decode('utf-8')
                    if body_text.strip():
                        import json
                        body_json = json.loads(body_text)
                        query = body_json.get("query")
                        print(f"[DEBUG] Got query from JSON body: {query}")
            except Exception as e:
                print(f"[ERROR] Failed to parse request body: {e}")
        
        if not query:
            return {"error": "No query parameter found"}
        
        # Real implementation: use search_web and generate_answer from web_search_gemini.py
        from backend.web_search_gemini import search_web, generate_answer
        num_results = 5
        try:
            # Try to get num_results from body if provided
            if body_bytes:
                body_text = body_bytes.decode('utf-8')
                if body_text.strip():
                    import json
                    body_json = json.loads(body_text)
                    if 'num_results' in body_json:
                        num_results = int(body_json['num_results'])
        except Exception:
            pass
        
        search_results = search_web(query, num_results)
        gemini_answer = await generate_answer(query, search_results)
        return {
            "results": [result.dict() for result in search_results],
            "gemini_answer": gemini_answer
        }
    except Exception as e:
        print(f"[ERROR] Error in kavvy-search: {e}")
        return {"error": str(e)}

# Include routers
app.include_router(lawyers_router)
app.include_router(voice_router, prefix="/api")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development; restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure JSON responses include utf-8 charset for emoji support in frontend
@app.middleware("http")
async def ensure_utf8_charset(request: Request, call_next):
    response = await call_next(request)
    ct = response.headers.get("content-type", "")
    if ct.startswith("application/json"):
        response.headers["content-type"] = "application/json; charset=utf-8"
    return response

# Component initialization disabled to avoid dependency issues

@app.post("/google-search")
async def google_search(query: str = Form(...)):
    """
    Search Google and return the top 3 results (title, link, snippet) for the query.
    """
    try:
        # Simple mock response for testing
        results = [
            {
                "title": "Google Search Result 1",
                "link": "https://example.com/result1",
                "snippet": "This is the first result snippet..."
            },
            {
                "title": "Google Search Result 2",
                "link": "https://example.com/result2",
                "snippet": "This is the second result snippet..."
            },
            {
                "title": "Google Search Result 3",
                "link": "https://example.com/result3",
                "snippet": "This is the third result snippet..."
            }
        ]
        return {"results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Legal RAG components disabled to avoid dependency issues

@app.get("/")
async def root():
    return {"message": "APRS Legal Assistant API is running"}

# Mount static files directory for serving processed documents
data_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
os.makedirs(data_dir, exist_ok=True)
app.mount("/data", StaticFiles(directory=data_dir), name="data")

# Setup IndicConformer model storage and audio folder
os.makedirs(os.path.join(data_dir, "models", "indic-conformer"), exist_ok=True)
audio_dir = os.path.join(data_dir, "audio")
os.makedirs(audio_dir, exist_ok=True)
app.mount("/audio", StaticFiles(directory=audio_dir), name="audio")

# Setup uploads directory for voice API
uploads_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "uploads", "audio")
os.makedirs(uploads_dir, exist_ok=True)

# Setup text output dirs
tel_text_dir = os.path.join(data_dir, "text", "telugu")
eng_text_dir = os.path.join(data_dir, "text", "english")
os.makedirs(tel_text_dir, exist_ok=True)
os.makedirs(eng_text_dir, exist_ok=True)
app.mount("/texts", StaticFiles(directory=os.path.join(data_dir, "text")), name="texts")

import logging

# Handle both GET and POST for the /chat endpoint
@app.post("/chat")
@app.get("/chat")
async def chat(request: Request):
    print(f"[DEBUG] Incoming /chat request: method={request.method}")
    
    try:
        # Parse either JSON or Form input
        content_type = request.headers.get("content-type", "")
        query = None
        language = None
        
        if content_type.startswith("application/json"):
            data = await request.json()
            query = data.get("query")
            language = data.get("language")
        else:
            form_data = await request.form()
            query = form_data.get("query")
            language = form_data.get("language")
            
        if not query or not language:
            return JSONResponse(status_code=422, content={"error": "Missing 'query' or 'language' field"})

        # Greeting patterns
        greetings = [
            'hello', 'hi', 'hey', 'namaste', 'good morning', 'good evening', 'good afternoon'
        ]
        user_query = query.strip().lower()
        is_greeting = any(user_query == g or user_query.startswith(g + ' ') for g in greetings)

        if is_greeting:
            return JSONResponse(content={"response": "Hello! 👋 I'm your APRS Legal Assistant. How can I help you with Indian law today?"})

        # For non-greeting queries, return a simple response
        response = f"This is a test response for: {query}. Please note: My responses are for informational purposes only and should not be considered legal advice."
        return JSONResponse(content={"response": response})
    except Exception as e:
        print(f"[ERROR] Error in chat endpoint: {e}")
        return JSONResponse(status_code=500, content={"error": str(e)})

    # End of chat endpoint


@app.post("/upload_audio")
async def upload_audio(request: Request, file: UploadFile = File(...)):
    """
    Uploads an audio file and returns URL and filename. No transcription.
    """
    # Generate unique filename
    ext = os.path.splitext(file.filename)[1]
    unique_filename = f"{uuid.uuid4().hex}{ext}"
    audio_path = os.path.join(audio_dir, unique_filename)
    # Save file
    with open(audio_path, "wb") as f:
        f.write(await file.read())
    # Return audio URL and filename
    return JSONResponse(content={"audioUrl": f"{request.base_url}audio/{unique_filename}", "filename": unique_filename})

@app.post("/nemo_transcribe")
async def nemo_transcribe(audio: UploadFile = File(...), language: str = Form("telugu")):
    """
    Upload audio and perform ASR transcription for Telugu or English using local models when available.
    """
    # Save uploaded file
    ext = os.path.splitext(audio.filename)[1]
    unique_filename = f"{uuid.uuid4().hex}{ext}"
    audio_path = os.path.join(audio_dir, unique_filename)
    audio_bytes = await audio.read()
    
    with open(audio_path, "wb") as f:
        f.write(audio_bytes)
    
    # Determine if we're transcribing Telugu or English
    is_telugu = language.lower() == "telugu"
    
    # Bhashini model IDs (consistent with the memory)
    asr_model_id = "66e41f28e2f5842563c988d9"  # Telugu ASR
    translation_model_id = "67b871747d193a1beb4b847e"  # Telugu-to-English
    tts_model_id = "6576a17e00d64169e2f8f43d"  # English TTS
    
    try:
        if is_telugu:
            # Use our local Telugu ASR implementation
            from backend.local_telugu_asr import LocalTeluguASR
            
            # Create an instance if not already created
            if not hasattr(nemo_transcribe, "telugu_asr"):
                nemo_transcribe.telugu_asr = LocalTeluguASR()
            
            # Transcribe using local model
            raw_text = await asyncio.to_thread(nemo_transcribe.telugu_asr.transcribe, audio_bytes)
            logger.info(f"Local Telugu ASR result: {raw_text}")
            
            # Return both the Telugu text and model IDs
            return JSONResponse(content={
                "text": raw_text,
                "filename": unique_filename,
                "language": "telugu",
                "model_ids": {
                    "asr": asr_model_id,
                    "translation": translation_model_id,
                    "tts": tts_model_id
                }
            })
        else:
            # For English, use the existing STT system
            text = await stt_system.transcribe(audio, language="english")
            return JSONResponse(content={
                "text": text,
                "filename": unique_filename,
                "language": "english"
            })
    except Exception as e:
        logger.error(f"Error in ASR transcription: {e}")
        # If local model fails, attempt to use Bhashini API for Telugu
        if is_telugu:
            try:
                # Use bhashini_voice API as fallback
                logger.info("Falling back to Bhashini API for Telugu ASR")
                try:
                    # Read the audio file
                    with open(audio_path, "rb") as f:
                        audio_content = f.read()
                    
                    # Create a multipart form with the audio file
                    form_data = aiohttp.FormData()
                    form_data.add_field('audio',
                                      audio_content,
                                      filename=os.path.basename(audio_path),
                                      content_type='audio/wav')
                    
                    # Make the request to the voice API
                    async with aiohttp.ClientSession() as session:
                        async with session.post("http://localhost:8000/api/voice-query", data=form_data) as resp:
                            if resp.status == 200:
                                result = await resp.json()
                                return JSONResponse(content={
                                    "text": result.get("asr_text", ""),  # Updated to match the correct field name
                                    "translated_text": result.get("translated_text", ""),
                                    "filename": unique_filename,
                                    "language": "telugu",
                                    "model_ids": {
                                        "asr": asr_model_id,
                                        "translation": translation_model_id,
                                        "tts": tts_model_id
                                    }
                                })
                            else:
                                error_msg = await resp.text()
                                logger.error(f"Bhashini API error: {error_msg}")
                                raise HTTPException(status_code=resp.status, detail=f"Bhashini API error: {error_msg}")
                except Exception as e:
                    logger.error(f"Error using Bhashini API fallback: {str(e)}")
                    raise HTTPException(status_code=500, detail=f"Error using Bhashini API fallback: {str(e)}")
            except Exception as fallback_err:
                logger.error(f"Fallback ASR also failed: {fallback_err}")
        
        # Return the error if all methods fail
        raise HTTPException(status_code=500, detail=f"ASR transcription failed: {str(e)}")


@app.post("/rag")
async def rag_query(query: str = Form(...)):
    """
    Use RAG to fetch and respond based on local/web legal docs.
    """
    try:
        response = await rag_system.retrieve_and_generate(query)
        return JSONResponse(content={"response": response})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/tts")
async def text_to_speech(text: str = Form(...), language: str = Form("english")):
    """
    Convert text to speech.
    """
    try:
        audio_path = await tts_system.generate_speech(text, language)
        return JSONResponse(content={"audio_path": audio_path})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/stt")
async def speech_to_text(audio: UploadFile = File(...), language: str = Form("english")):
    """
    Convert speech to text.
    """
    try:
        text = await stt_system.transcribe(audio, language)
        return JSONResponse(content={"text": text})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/crawl")
async def crawl(background_tasks: BackgroundTasks, urls: List[str] = Form(None), query: str = Form(None)):
    """
    Crawl legal websites for content.
    """
    if not urls and not query:
        raise HTTPException(status_code=400, detail="Either URLs or a search query must be provided")
    
    try:
        # Run crawling in the background
        background_tasks.add_task(legal_crawler.crawl, urls, query)
        return JSONResponse(content={"message": "Crawling started in the background"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/legal-scrape")
async def legal_scrape(background_tasks: BackgroundTasks, keywords: List[str] = Form(None), max_results: int = Form(10)):
    """
    Scrape legal documents from Indian legal websites.
    
    Args:
        keywords: Keywords to search for
        max_results: Maximum results per keyword
    """
    if not keywords:
        raise HTTPException(status_code=400, detail="Keywords must be provided")
    
    try:
        # Run legal scraping in the background
        async def scrape_and_process():
            await legal_scraper.scrape_all_sources(keywords=keywords, max_results_per_keyword=max_results)
            await document_processor.process_all_documents()
        
        background_tasks.add_task(scrape_and_process)
        return JSONResponse(content={"message": "Legal document scraping started in the background"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/vectorize")
async def vectorize(background_tasks: BackgroundTasks, file: UploadFile = File(None), text: str = Form(None)):
    """
    Embed legal content and store in Pinecone.
    """
    if not file and not text:
        raise HTTPException(status_code=400, detail="Either a file or text must be provided")
    
    try:
        if file:
            content = await file.read()
            text = content.decode("utf-8")
        
        # Vectorize in the background
        background_tasks.add_task(rag_system.vectorize_text, text)
        return JSONResponse(content={"message": "Vectorization started in the background"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/search")
async def search(query: str = Form(...), top_k: int = Form(5)):
    """
    Query Pinecone vector DB and return top N documents/snippets.
    """
    try:
        results = await rag_system.search(query, top_k)
        return JSONResponse(content={"results": results})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/legal-search")
async def legal_search(query: str = Form(...), top_k: int = Form(5)):
    """
    Search for relevant legal documents.
    
    Args:
        query: The search query
        top_k: Number of results to return
    """
    try:
        results = await legal_rag_system.search_legal_documents(query, top_k)
        return JSONResponse(content={"results": results})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/documents/{doc_type}")
async def list_documents(doc_type: str):
    """
    List available legal documents by type.
    
    Args:
        doc_type: Type of documents to list (bare_acts, judgments, amendments, etc.)
    """
    try:
        # Get the documents directory
        documents_dir = os.path.join(data_dir, "legal_documents", doc_type)
        
        if not os.path.exists(documents_dir):
            raise HTTPException(status_code=404, detail=f"Document type '{doc_type}' not found")
        
        # List files in the directory
        files = []
        for filename in os.listdir(documents_dir):
            file_path = os.path.join(documents_dir, filename)
            if os.path.isfile(file_path):
                # Try to find metadata
                metadata_path = os.path.join(data_dir, "legal_documents", "metadata", f"{os.path.splitext(filename)[0]}.json")
                metadata = {}
                
                if os.path.exists(metadata_path):
                    with open(metadata_path, "r", encoding="utf-8") as f:
                        metadata = json.load(f)
                
                files.append({
                    "filename": filename,
                    "path": f"/data/legal_documents/{doc_type}/{filename}",
                    "metadata": metadata
                })
        
        return JSONResponse(content={"files": files})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/document/{doc_id}")
async def get_document(doc_id: str):
    """
    Get a specific legal document by ID.
    
    Args:
        doc_id: Document ID
    """
    try:
        # Find the document in metadata
        metadata_dir = os.path.join(data_dir, "legal_documents", "metadata")
        
        for filename in os.listdir(metadata_dir):
            metadata_path = os.path.join(metadata_dir, filename)
            
            if os.path.isfile(metadata_path):
                with open(metadata_path, "r", encoding="utf-8") as f:
                    metadata = json.load(f)
                    
                    if metadata.get("id") == doc_id:
                        file_path = metadata.get("file_path")
                        
                        if file_path and os.path.exists(file_path):
                            return FileResponse(file_path)
        
        raise HTTPException(status_code=404, detail=f"Document with ID '{doc_id}' not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/generate-pdf")
async def generate_pdf(conversation: List[Dict[str, Any]], client_info: Optional[Dict[str, Any]] = None):
    """
    Generate a legal PDF summary from a conversation.
    
    Args:
        conversation: List of conversation messages
        client_info: Optional client information
    """
    try:
        # Generate summary
        summary = await pdf_generator.generate_legal_summary(conversation, client_info)
        
        # Generate PDF
        pdf_path = await pdf_generator.generate_pdf(summary)
        
        if not pdf_path or not os.path.exists(pdf_path):
            raise HTTPException(status_code=500, detail="Failed to generate PDF")
        
        # Return the PDF file
        return FileResponse(
            path=pdf_path,
            filename=os.path.basename(pdf_path),
            media_type="application/pdf"
        )
    except Exception as e:
        logger.error(f"Error generating PDF: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/pdf-exports")
async def list_pdf_exports():
    """
    List all generated PDF exports.
    """
    try:
        pdf_dir = os.path.join(data_dir, "pdf_exports")
        os.makedirs(pdf_dir, exist_ok=True)
        
        # List files in the directory
        files = []
        for filename in os.listdir(pdf_dir):
            file_path = os.path.join(pdf_dir, filename)
            if os.path.isfile(file_path) and filename.lower().endswith(".pdf"):
                files.append({
                    "filename": filename,
                    "path": f"/data/pdf_exports/{filename}",
                    "created_at": datetime.fromtimestamp(os.path.getctime(file_path)).isoformat()
                })
        
        return JSONResponse(content={"files": files})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Endpoint for Flutter file upload
@app.post("/upload_documents")
async def upload_documents(file: UploadFile = File(...)):
    upload_dir = os.path.join(data_dir, "uploaded_docs")
    os.makedirs(upload_dir, exist_ok=True)
    contents = await file.read()
    file_path = os.path.join(upload_dir, file.filename)
    with open(file_path, "wb") as f:
        f.write(contents)
    return JSONResponse(content={"detail": "File uploaded successfully."})

# Download summary as base64 to Flutter
@app.post("/download_summary")
async def download_summary_alias(conversation: List[Dict[str, Any]] = Body(...)):
    summary = await pdf_generator.generate_legal_summary(conversation, None)
    pdf_path = await pdf_generator.generate_pdf(summary)
    with open(pdf_path, "rb") as f:
        data = f.read()
    encoded = base64.b64encode(data).decode()
    return Response(content=encoded, media_type="text/plain")

# Generate legal document from client info and return base64 PDF
@app.post("/generate_document")
async def generate_document_alias(client_info: Dict[str, Any] = Body(...)):
    summary = await pdf_generator.generate_legal_summary([], client_info)
    pdf_path = await pdf_generator.generate_pdf(summary)
    with open(pdf_path, "rb") as f:
        data = f.read()
    encoded = base64.b64encode(data).decode()
    return Response(content=encoded, media_type="text/plain")

# Endpoint to transcribe and translate audio after user confirmation
@app.post("/transcribe_audio")
async def transcribe_audio(request: Request, filename: str = Form(...)):
    # Locate audio
    audio_path = os.path.join(audio_dir, filename)
    if not os.path.exists(audio_path):
        raise HTTPException(status_code=404, detail="Audio file not found")
    # Transcribe Telugu ASR
    from nemo.collections.asr.models import ASRModel
    model_path = os.path.join(models_dir, "indicconformer_stt_te_hybrid_rnnt_large.nemo")
    asr_model = ASRModel.restore_from(model_path)
    pred_text = asr_model.transcribe([audio_path], language_id="te")[0].strip()
    # Save Telugu text
    tel_file = f"{os.path.splitext(filename)[0]}_telugu.txt"
    tel_path = os.path.join(tel_text_dir, tel_file)
    with open(tel_path, "w", encoding="utf-8") as f:
        f.write(pred_text)
    # Translate to English
    from transformers import pipeline
    translator = pipeline("translation", model="Helsinki-NLP/opus-mt-te-en")
    eng_text = translator(pred_text, max_length=512)[0]["translation_text"].strip()
    # Save English text
    eng_file = f"{os.path.splitext(filename)[0]}_english.txt"
    eng_path = os.path.join(eng_text_dir, eng_file)
    with open(eng_path, "w", encoding="utf-8") as f:
        f.write(eng_text)
    # Return URLs and contents
    base = str(request.base_url)
    return JSONResponse({
        "audioUrl": f"{base}audio/{filename}",
        "teluguTextUrl": f"{base}texts/telugu/{tel_file}",
        "englishTextUrl": f"{base}texts/english/{eng_file}",
        "teluguText": pred_text,
        "englishText": eng_text
    })

class OCRResult(BaseModel):
    text: str
    tags: List[str]

@app.post("/ocr", response_model=OCRResult)
async def ocr_document(file: UploadFile = File(...), language: Optional[str] = Form(None)):
    # Read file bytes
    data_bytes = await file.read()
    # Call external OCR API
    ocr_url = "https://meity-dev.ulcacontrib.org/anuvaad/ocr/v0/ulca-ocr"
    files_payload = {"file": (file.filename, data_bytes, file.content_type)}
    payload = {"lang": language or "eng"}
    resp = requests.post(ocr_url, files=files_payload, data=payload, timeout=120)
    if resp.status_code != 200:
        raise HTTPException(status_code=502, detail="OCR service error")
    result = resp.json()
    # Extract text from predictions
    extracted = []
    for pred in result.get("predictions", []):
        extracted.append(pred.get("text", ""))
    full_text = " ".join(extracted).strip()
    # Simple keyword tagging
    keywords = {"contract": ["contract", "agreement"], "evidence": ["evidence", "photo", "image"], "invoice": ["invoice", "bill"]}
    tags = [tag for tag, kws in keywords.items() if any(kw in full_text.lower() for kw in kws)]
    return OCRResult(text=full_text, tags=tags)

if __name__ == "__main__":
    uvicorn.run("backend.main:app", host="0.0.0.0", port=8000, reload=False)
