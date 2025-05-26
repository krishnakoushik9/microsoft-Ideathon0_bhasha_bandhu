import os
import json
import asyncio
import logging
import aiohttp
from typing import List, Dict, Any, Optional, Tuple

from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer
from transformers import pipeline
import requests
from urllib.parse import quote_plus
import uuid

# Import our custom modules
from backend.legal_scraper import LegalDocumentScraper
from backend.document_processor import DocumentProcessor

# Load environment variables
load_dotenv()

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("legal_rag.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("legal_rag")

class LegalRAG:
    def __init__(self):
        """Initialize the Legal RAG system."""
        # Initialize base directories
        self.base_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
        os.makedirs(self.base_dir, exist_ok=True)
        

        # Initialize models
        self._init_models()
        
        # Initialize scraper and processor
        self.scraper = LegalDocumentScraper(base_dir=self.base_dir)
        self.processor = DocumentProcessor(base_dir=self.base_dir)
        
        # Initialize Bing Search API (optional fallback)
        self.bing_search_api_key = os.getenv("BING_SEARCH_API_KEY")
        self.bing_search_endpoint = "https://api.bing.microsoft.com/v7.0/search"
    



    def _init_models(self):
        """Initialize embedding model and LLM."""
        try:
            # Initialize sentence transformer for embeddings
            self.embedding_model_name = os.getenv("EMBEDDING_MODEL", "sentence-transformers/all-MiniLM-L6-v2")
            self.embedding_model = SentenceTransformer(self.embedding_model_name)
            
            # Initialize LLM for generation
            self.llm_model_name = os.getenv("HF_MODEL", "mistralai/Mixtral-8x7B-Instruct-v0.1")
            
            # Check if we have a Hugging Face API key
            self.hf_api_key = os.getenv("HF_API_KEY")
            
            # Check if Ollama is available
            self.use_ollama = os.getenv("USE_OLLAMA", "false").lower() == "true"
            self.ollama_model = os.getenv("OLLAMA_MODEL", "gemma3:1b")
            self.ollama_url = os.getenv("OLLAMA_URL", "http://localhost:11434")
            
            if self.hf_api_key and not self.use_ollama:
                # Use Hugging Face Inference API instead of loading model locally
                logger.info("Using Hugging Face Inference API")
                self.use_hf_api = True
                self.use_local_model = False
            elif self.use_ollama:
                # Use Ollama for local inference
                logger.info(f"Using Ollama with model: {self.ollama_model}")
                self.use_hf_api = False
                self.use_local_model = False
            else:
                # Fallback to a small local model
                logger.info(f"Loading model locally: {self.llm_model_name}")
                self.use_hf_api = False
                self.use_local_model = True
                self.llm = pipeline(
                    "text-generation",
                    model=self.llm_model_name,
                    max_length=2048,
                    temperature=0.7,
                    top_p=0.95
                )
            
            self.models_initialized = True
            logger.info("Models initialized successfully")
        
        except Exception as e:
            logger.error(f"Error initializing models: {e}")
            self.models_initialized = False
    
    async def scrape_and_process(self, keywords: List[str] = None, max_results: int = 10):
        """
        Scrape legal documents and process them for RAG.
        
        Args:
            keywords: List of keywords to search for
            max_results: Maximum number of results per keyword
        """
        # Scrape documents
        await self.scraper.scrape_all_sources(keywords=keywords, max_results_per_keyword=max_results)
        
        # Process documents
        await self.processor.process_all_documents()
    
    async def search_legal_documents(self, query: str, top_k: int = 5) -> List[Dict[str, Any]]:
        """
        Search for relevant legal documents.
        
        Args:
            query: The search query
            top_k: Number of results to return
            
        Returns:
            List of document chunks with metadata
        """
        if not self.models_initialized:
            return []
        
        try:
            # Embed the query
            query_embedding = self.embedding_model.encode(query).tolist()
            

            results = self.index.query(
                vector=query_embedding,
                top_k=top_k,
                include_metadata=True
            )
            
            # Format results
            formatted_results = []
            for match in results["matches"]:
                formatted_results.append({
                    "id": match["id"],
                    "score": match["score"],
                    "text": match["metadata"].get("text", ""),
                    "metadata": {k: v for k, v in match["metadata"].items() if k != "text"}
                })
            
            return formatted_results
        
        except Exception as e:
            logger.error(f"Error searching legal documents: {e}")
            return []
    
    async def web_search_fallback(self, query: str, top_k: int = 3) -> List[Dict[str, Any]]:
        """
        Perform a web search as fallback.
        
        Args:
            query: The search query
            top_k: Number of results to return
            
        Returns:
            List of search results
        """
        if not self.bing_search_api_key:
            logger.warning("BING_SEARCH_API_KEY not found. Web search fallback will not work.")
            return []
        
        try:
            # Add legal terms to the query
            legal_query = f"{query} indian law legal"
            
            # Set up headers
            headers = {
                "Ocp-Apim-Subscription-Key": self.bing_search_api_key
            }
            
            # Set up parameters
            params = {
                "q": legal_query,
                "count": top_k,
                "offset": 0,
                "mkt": "en-IN"
            }
            
            # Make the request
            response = requests.get(self.bing_search_endpoint, headers=headers, params=params)
            response.raise_for_status()
            
            # Parse results
            search_results = response.json()
            
            # Format results
            formatted_results = []
            if "webPages" in search_results and "value" in search_results["webPages"]:
                for result in search_results["webPages"]["value"]:
                    formatted_results.append({
                        "title": result["name"],
                        "url": result["url"],
                        "snippet": result["snippet"],
                        "source": "web_search"
                    })
            
            return formatted_results
        
        except Exception as e:
            logger.error(f"Error performing web search: {e}")
            return []
    
    async def generate_legal_response(self, query: str, language: str = "english") -> str:
        """
        Generate a response to a legal query.
        
        Args:
            query: The legal query
            language: The language for the response
            
        Returns:
            Generated response
        """
        try:
            # Search for relevant documents
            legal_docs = await self.search_legal_documents(query)
            
            # If no relevant documents found, try web search fallback
            web_results = []
            if not legal_docs:
                logger.info("No relevant documents found in vector DB, trying web search fallback")
                web_results = await self.web_search_fallback(query)
            
            # Prepare context from legal documents
            legal_context = ""
            if legal_docs:
                legal_context = "LEGAL DOCUMENT CONTEXT:\n\n"
                for i, doc in enumerate(legal_docs):
                    legal_context += f"Document {i+1}:\n{doc['text']}\n\n"
                    if "source_file" in doc["metadata"]:
                        legal_context += f"Source: {doc['metadata']['source_file']}\n\n"
            
            # Prepare context from web search
            web_context = ""
            if web_results:
                web_context = "WEB SEARCH RESULTS:\n\n"
                for i, result in enumerate(web_results):
                    web_context += f"Result {i+1}: {result['title']}\n"
                    web_context += f"URL: {result['url']}\n"
                    web_context += f"Summary: {result['snippet']}\n\n"
            
            # Combine contexts
            context = legal_context + web_context
            
            # Generate response with context
            response = await self._generate_response(query, context, language)
            
            return response
        
        except Exception as e:
            logger.error(f"Error generating legal response: {e}")
            return f"I apologize, but I encountered an error while processing your query. Please try again or rephrase your question. Error details: {str(e)}"
    
    async def _generate_response(self, query: str, context: str, language: str) -> str:
        """
        Generate a response using the LLM.
        
        Args:
            query: The user's query
            context: Context from retrieved documents
            language: The language for the response
            
        Returns:
            Generated response
        """
        if not self.models_initialized:
            logger.error("Models not initialized properly")
            return "I apologize, but the language models are not initialized properly. Please try again later."
        
        # Prepare prompt
        if context:
            prompt = f"""
            You are a legal assistant specializing in Indian law. Use the following legal information to provide an accurate response.
            
            {context}
            
            USER QUERY:
            {query}
            
            Provide a clear, accurate, and helpful response based on the legal information provided above. 
            If the information doesn't fully answer the query, acknowledge the limitations and provide the best possible advice based on what's available.
            Always cite the sources of your information when possible.
            """
        else:
            prompt = f"""
            You are a legal assistant specializing in Indian law.
            
            USER QUERY:
            {query}
            
            Provide a clear, accurate, and helpful response based on your knowledge of Indian law.
            If you're unsure about specific details, acknowledge the limitations and suggest where the user might find more information.
            """
        
        # Generate response
        if hasattr(self, 'use_hf_api') and self.use_hf_api:
            # Use Hugging Face Inference API
            try:
                api_url = f"https://api-inference.huggingface.co/models/{self.llm_model_name}"
                headers = {"Authorization": f"Bearer {self.hf_api_key}"}
                payload = {"inputs": prompt, "parameters": {"max_length": 2048, "temperature": 0.7, "top_p": 0.95}}
                
                # Make async request to Hugging Face API
                async with aiohttp.ClientSession() as session:
                    async with session.post(api_url, json=payload, headers=headers) as resp:
                        if resp.status == 200:
                            result = await resp.json()
                            if isinstance(result, list) and len(result) > 0:
                                response = result[0].get('generated_text', '')
                            else:
                                response = result.get('generated_text', '')
                        else:
                            error_text = await resp.text()
                            logger.error(f"Hugging Face API error: {resp.status}, {error_text}")
                            # Fallback to a simple response
                            return "I apologize, but I'm having trouble generating a response. Please try again later."
            except Exception as e:
                logger.error(f"Error using Hugging Face API: {e}")
                return f"I apologize, but I encountered an error while generating a response. Error: {str(e)}"
        elif hasattr(self, 'use_ollama') and self.use_ollama:
            # Use Ollama for local inference
            try:
                # Ollama API endpoint for generation
                api_url = f"{self.ollama_url}/api/generate"
                
                # Prepare payload for Ollama
                payload = {
                    "model": self.ollama_model,
                    "prompt": prompt,
                    "options": {
                        "temperature": 0.7,
                        "top_p": 0.95,
                        "max_length": 2048
                    }
                }
                
                # Make async request to Ollama API
                async with aiohttp.ClientSession() as session:
                    async with session.post(api_url, json=payload) as resp:
                        if resp.status == 200:
                            result = await resp.json()
                            response = result.get('response', '')
                        else:
                            error_text = await resp.text()
                            logger.error(f"Ollama API error: {resp.status}, {error_text}")
                            # Fallback to a simple response
                            return "I apologize, but I'm having trouble generating a response. Please try again later."
            except Exception as e:
                logger.error(f"Error using Ollama: {e}")
                return f"I apologize, but I encountered an error while generating a response. Error: {str(e)}"
        elif hasattr(self, 'use_local_model') and self.use_local_model:
            # Use local Hugging Face model
            try:
                result = self.llm(prompt)
                if isinstance(result, list) and len(result) > 0:
                    response = result[0].get('generated_text', '')
                else:
                    response = result.get('generated_text', '')
            except Exception as e:
                logger.error(f"Error using local model: {e}")
                return f"I apologize, but I encountered an error while generating a response. Error: {str(e)}"
        else:
            return "I apologize, but no language model is available. Please check your configuration."
        
        # Extract the generated response (remove the prompt if present in the response)
        if prompt in response:
            response = response[response.find(prompt) + len(prompt):].strip()
        
        # If language is not English, translate the response
        if language.lower() != "english":
            # For now, we'll use a simple prompt to ask the model to translate
            # In a production app, you might want to use a dedicated translation model
            translation_prompt = f"""
            Translate the following text to {language}:
            
            {response}
            
            Translation:
            """
            
            translated_response = self.llm(translation_prompt)[0]["generated_text"]
            
            # Extract the translated response
            translated_response = translated_response[len(translation_prompt):].strip()
            
            return translated_response
        
        return response

# Command-line interface
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Legal RAG system")
    parser.add_argument("--scrape", action="store_true", help="Scrape and process legal documents")
    parser.add_argument("--keywords", nargs="+", help="Keywords to search for when scraping")
    parser.add_argument("--query", help="Legal query to process")
    parser.add_argument("--language", default="english", help="Language for the response")
    args = parser.parse_args()
    
    # Initialize the Legal RAG system
    legal_rag = LegalRAG()
    
    if args.scrape:
        # Scrape and process documents
        asyncio.run(legal_rag.scrape_and_process(keywords=args.keywords))
    
    elif args.query:
        # Generate response to query
        response = asyncio.run(legal_rag.generate_legal_response(args.query, args.language))
        print(f"\nQuery: {args.query}\n")
        print(f"Response:\n{response}")
    
    else:
        print("Please specify --scrape or --query")
