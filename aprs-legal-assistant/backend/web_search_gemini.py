import os
import requests
import json
import google.generativeai as genai
from bs4 import BeautifulSoup
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel
from typing import List, Optional
import logging
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Create a file handler for detailed logging
file_handler = logging.FileHandler('/home/krsna/Desktop/ideathon/aprs-legal-assistant/web_search_debug.log')
file_handler.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)

logger.debug("Web Search Gemini module loaded and configured")

# FastAPI router for modular integration
router = APIRouter()

# Models for request and response
class SearchRequest(BaseModel):
    query: str
    num_results: Optional[int] = 5

class SearchResult(BaseModel):
    title: str
    url: str
    snippet: str

class SearchResponse(BaseModel):
    results: List[SearchResult]
    gemini_answer: str

# Environment variables
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
SERPAPI_KEY = os.environ.get("SERPAPI_KEY")

# Initialize Gemini

def initialize_gemini():
    if not GEMINI_API_KEY:
        logger.error("GEMINI_API_KEY not found in environment variables")
        raise ValueError("GEMINI_API_KEY not found")
    genai.configure(api_key=GEMINI_API_KEY)
    return genai.GenerativeModel('models/gemini-2.0-flash')

# Web search function using SerpAPI
def search_web(query: str, num_results: int = 5):
    if not SERPAPI_KEY:
        logger.error("SERPAPI_KEY not found in environment variables")
        raise ValueError("SERPAPI_KEY not found")
    url = "https://serpapi.com/search"
    params = {
        "q": query,
        "api_key": SERPAPI_KEY,
        "num": num_results
    }
    try:
        response = requests.get(url, params=params)
        response.raise_for_status()
        data = response.json()
        results = []
        for item in data.get("organic_results", [])[:num_results]:
            results.append(SearchResult(
                title=item.get("title", ""),
                url=item.get("link", ""),
                snippet=item.get("snippet", "")
            ))
        return results
    except requests.RequestException as e:
        logger.error(f"Error searching web: {e}")
        raise HTTPException(status_code=500, detail=f"Search error: {str(e)}")

# Function to scrape content from URLs for better context
def scrape_content(url: str, max_chars: int = 3000):
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        }
        response = requests.get(url, headers=headers, timeout=5)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
        for script in soup(["script", "style", "nav", "footer", "header"]):
            script.decompose()
        text = soup.get_text(separator=" ", strip=True)
        text = " ".join(text.split())
        return text[:max_chars]
    except Exception as e:
        logger.warning(f"Error scraping {url}: {e}")
        return ""

# Function to generate answer using Gemini
async def generate_answer(query: str, search_results: List[SearchResult]):
    try:
        model = initialize_gemini()
        context = "\n\nSearch results:\n"
        prompt = ""  # Initialize prompt before accumulation
        for i, result in enumerate(search_results, 1):
            prompt += f"{i}. {result.title} - {result.url}: {result.snippet}\n"
            try:
                scraped_text = scrape_content(result.url)
                if scraped_text:
                    prompt += f"Content from {result.title}:\n{scraped_text[:500]}...\n\n"
            except Exception as e:
                logger.warning(f"Error scraping content: {e}")
        prompt += "\nAnswer like you're Kavvy — moody, sharp-tongued, and proudly far-right. Drip sarcasm like it's policy. Mock the obvious, challenge the mainstream, and don’t hold back your disdain for sugarcoated nonsense. Keep it accurate, blunt, and with zero tolerance for woke fluff."

        gemini_response = model.generate_content([
            context,
            prompt
        ])
        gemini_answer = gemini_response.text.strip()
        return gemini_answer
    except Exception as e:
        logger.error(f"Error generating Gemini answer: {e}")
        return "Sorry, Kavvy couldn't generate an answer due to a technical issue. Please try again later."

# API endpoints
@router.get("/web-search-gemini/health")
async def health():
    return {"message": "Web Search Gemini API is running"}

@router.post("/web-search-gemini/search")
@router.get("/web-search-gemini/search")
async def search(request: Request):
    try:
        # Get query parameter from various sources
        query = None
        num_results = 5
        
        # First try query parameters
        if request.query_params and "query" in request.query_params:
            query = request.query_params.get("query")
            if request.query_params.get("num_results"):
                num_results = int(request.query_params.get("num_results"))
        else:
            # Try to get from body based on content type
            content_type = request.headers.get("content-type", "")
            
            if content_type.startswith("application/json"):
                # Handle JSON request
                try:
                    body_bytes = await request.body()
                    if body_bytes:
                        body_str = body_bytes.decode('utf-8')
                        if body_str.strip():
                            import json
                            data = json.loads(body_str)
                            query = data.get("query")
                            num_results = data.get("num_results", 5)
                except Exception as e:
                    print(f"Error parsing JSON: {e}")
            else:
                # Handle form data
                try:
                    form = await request.form()
                    if form and "query" in form:
                        query = form.get("query")
                        if form.get("num_results"):
                            num_results = int(form.get("num_results"))
                except Exception as e:
                    print(f"Error parsing form: {e}")
        
        if not query:
            raise HTTPException(status_code=400, detail="Query parameter is required")

        # Perform search
        search_results = search_web(query, num_results)
        gemini_answer = await generate_answer(query, search_results)
        
        # Return response as dict (not using model to avoid validation issues)
        return {
            "results": [result.dict() for result in search_results],
            "gemini_answer": gemini_answer
        }
    except Exception as e:
        logger.error(f"Error processing search request: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
