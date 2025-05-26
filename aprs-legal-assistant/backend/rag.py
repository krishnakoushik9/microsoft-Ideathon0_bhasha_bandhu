import os
import json
from dotenv import load_dotenv
from typing import List, Dict, Any, Optional
from sentence_transformers import SentenceTransformer
from transformers import pipeline
from langchain.text_splitter import RecursiveCharacterTextSplitter
import asyncio
import uuid

# Load environment variables
load_dotenv()

class RAGSystem:
    def __init__(self):

        # Initialize Hugging Face models
        self.embedding_model_name = os.getenv("EMBEDDING_MODEL", "sentence-transformers/all-MiniLM-L6-v2")
        self.llm_model_name = os.getenv("HF_MODEL", "mistralai/Mixtral-8x7B-Instruct-v0.1")
        
        # Create data directory if it doesn't exist
        self.data_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
        os.makedirs(self.data_dir, exist_ok=True)
        
        # Initialize components
        self._init_models()
        self._init_text_splitter()
    
    def _init_models(self):
        """Initialize embedding model and LLM."""
        try:
            # Initialize sentence transformer for embeddings
            self.embedding_model = SentenceTransformer(self.embedding_model_name)
            
            # Initialize LLM for generation
            self.llm = pipeline(
                "text-generation",
                model=self.llm_model_name,
                max_length=1024,
                temperature=0.7,
                top_p=0.95,
                device_map="auto"  # Use GPU if available
            )
            
            self.models_initialized = True
        except Exception as e:
            print(f"Error initializing models: {e}")
            self.models_initialized = False
    
    def _init_text_splitter(self):
        """Initialize text splitter for chunking documents."""
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200,
            length_function=len,
        )
    
    async def vectorize_text(self, text: str, metadata: Optional[Dict[str, Any]] = None) -> List[str]:
        """

        
        Args:
            text: The text to vectorize
            metadata: Optional metadata to store with the vectors
            
        Returns:
            List of IDs for the stored vectors
        """

        
        # Split text into chunks
        chunks = self.text_splitter.split_text(text)
        
        # Generate IDs for chunks
        ids = [str(uuid.uuid4()) for _ in range(len(chunks))]
        
        # Create metadata if not provided
        if metadata is None:
            metadata = {}
        

        embeddings = self.embedding_model.encode(chunks)
        
        # Prepare vectors for upsert
        vectors = []
        for i, (chunk_id, embedding, chunk) in enumerate(zip(ids, embeddings, chunks)):
            # Create metadata for this chunk
            chunk_metadata = metadata.copy()
            chunk_metadata["text"] = chunk
            chunk_metadata["chunk_id"] = i
            
            vectors.append({
                "id": chunk_id,
                "values": embedding.tolist(),
                "metadata": chunk_metadata
            })
        

        batch_size = 100
        for i in range(0, len(vectors), batch_size):
            batch = vectors[i:i+batch_size]
            self.index.upsert(vectors=batch)
        
        return ids
    
    async def search(self, query: str, top_k: int = 5) -> List[Dict[str, Any]]:
        """
        Search for similar documents in Pinecone.
        
        Args:
            query: The search query
            top_k: Number of results to return
            
        Returns:
            List of document chunks with metadata
        """

        
        # Embed the query
        query_embedding = self.embedding_model.encode(query).tolist()
        
        # Search Pinecone
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
    
    async def retrieve_and_generate(self, query: str) -> str:
        """
        Retrieve relevant documents and generate a response.
        
        Args:
            query: The user's query
            
        Returns:
            Generated response based on retrieved documents
        """
        # Search for relevant documents
        results = await self.search(query)
        
        if not results:
            # If no results, generate response without context
            return await self._generate_response(query)
        
        # Extract text from results
        context = "\n\n".join([result["text"] for result in results])
        
        # Generate response with context
        return await self._generate_response(query, context)
    
    async def _generate_response(self, query: str, context: Optional[str] = None) -> str:
        """
        Generate a response using the LLM.
        
        Args:
            query: The user's query
            context: Optional context from retrieved documents
            
        Returns:
            Generated response
        """
        if not self.models_initialized:
            raise Exception("Models not initialized properly")
        
        # Prepare prompt
        if context:
            prompt = f"""
            You are a legal assistant helping with a query. Use the following legal information to provide an accurate response.
            
            LEGAL CONTEXT:
            {context}
            
            USER QUERY:
            {query}
            
            Provide a clear, accurate, and helpful response based on the legal context provided:
            """
        else:
            prompt = f"""
            You are a legal assistant helping with a query.
            
            USER QUERY:
            {query}
            
            Provide a clear, accurate, and helpful response:
            """
        
        # Generate response
        response = self.llm(prompt)[0]["generated_text"]
        
        # Extract the generated response (remove the prompt)
        response = response[len(prompt):].strip()
        
        return response
    
    async def process_query(self, query: str, language: str) -> str:
        """
        Process a query and return a response in the specified language.
        
        Args:
            query: The user's query
            language: The language for the response
            
        Returns:
            Generated response in the specified language
        """
        # First, get a response using RAG
        response = await self.retrieve_and_generate(query)
        
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
