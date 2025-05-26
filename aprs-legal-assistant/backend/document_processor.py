import os
# Universal Hugging Face API variables for this project:
#   HF_API_KEY from .env
#   HF_MODEL from .env
import json
import asyncio
import logging
from typing import List, Dict, Any, Optional, Tuple
from pathlib import Path
try:
    import fitz  # PyMuPDF
except ImportError:
    fitz = None
    logger = logging.getLogger("document_processor")
    logger.warning("PyMuPDF not installed. PDF extraction will be disabled.")
import docx
import uuid
from langchain.text_splitter import RecursiveCharacterTextSplitter
from sentence_transformers import SentenceTransformer

from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("document_processor.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("document_processor")

class DocumentProcessor:
    def __init__(self, base_dir: str = None):
        """
        Initialize the document processor.
        
        Args:
            base_dir: Base directory where documents are stored
        """
        if base_dir is None:
            base_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
        
        self.base_dir = base_dir
        self.documents_dir = os.path.join(self.base_dir, "legal_documents")
        self.processed_dir = os.path.join(self.base_dir, "processed_documents")
        self.chunks_dir = os.path.join(self.base_dir, "document_chunks")
        
        # Create directories
        os.makedirs(self.processed_dir, exist_ok=True)
        os.makedirs(self.chunks_dir, exist_ok=True)
        
        # Initialize text splitter
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200,
            length_function=len,
        )
        
        # Initialize embedding model
        self.embedding_model_name = os.getenv("EMBEDDING_MODEL", "sentence-transformers/all-MiniLM-L6-v2")
        self.embedding_model = SentenceTransformer(self.embedding_model_name)
    async def process_all_documents(self):
        """Process all documents in the documents directory."""
        # Get all document directories
        document_dirs = [
            d for d in os.listdir(self.documents_dir) 
            if os.path.isdir(os.path.join(self.documents_dir, d)) and d != "metadata"
        ]
        
        for dir_name in document_dirs:
            dir_path = os.path.join(self.documents_dir, dir_name)
            logger.info(f"Processing documents in {dir_path}")
            
            # Process all files in the directory
            for filename in os.listdir(dir_path):
                file_path = os.path.join(dir_path, filename)
                
                if os.path.isfile(file_path):
                    await self.process_document(file_path, document_type=dir_name)
    
    async def process_document(self, file_path: str, document_type: str = None):
        """
        Process a single document.
        
        Args:
            file_path: Path to the document
            document_type: Type of document (optional)
        """
        try:
            logger.info(f"Processing document: {file_path}")
            
            # Extract text from the document
            text, metadata = await self._extract_text(file_path)
            
            if not text:
                logger.warning(f"No text extracted from {file_path}")
                return
            
            # Add document type to metadata if provided
            if document_type:
                metadata["document_type"] = document_type
            
            # Save the processed text
            processed_path = self._save_processed_text(text, file_path, metadata)
            
            # Chunk the text
            chunks = self.text_splitter.split_text(text)
            logger.info(f"Split document into {len(chunks)} chunks")
            
            # Save chunks
            chunks_path = self._save_chunks(chunks, file_path, metadata)
            
            # Embed and store chunks
            await self._embed_and_store(chunks, metadata)
            
            return processed_path, chunks_path
        
        except Exception as e:
            logger.error(f"Error processing document {file_path}: {e}")
            return None, None
    
    async def _extract_text(self, file_path: str) -> Tuple[str, Dict[str, Any]]:
        """
        Extract text from a document.
        
        Args:
            file_path: Path to the document
            
        Returns:
            Tuple of (extracted text, metadata)
        """
        file_ext = os.path.splitext(file_path)[1].lower()
        metadata = {
            "source_file": file_path,
            "file_type": file_ext[1:] if file_ext.startswith('.') else file_ext
        }
        
        # Try to load metadata if it exists
        metadata_path = os.path.join(
            self.documents_dir, 
            "metadata", 
            f"{Path(file_path).stem}.json"
        )
        
        if os.path.exists(metadata_path):
            try:
                with open(metadata_path, "r", encoding="utf-8") as f:
                    file_metadata = json.load(f)
                    metadata.update(file_metadata)
            except Exception as e:
                logger.warning(f"Error loading metadata from {metadata_path}: {e}")
        
        # Extract text based on file type
        if file_ext == ".pdf":
            return await self._extract_text_from_pdf(file_path), metadata
        elif file_ext == ".docx":
            return await self._extract_text_from_docx(file_path), metadata
        elif file_ext in [".txt", ".text"]:
            return await self._extract_text_from_txt(file_path), metadata
        else:
            logger.warning(f"Unsupported file type: {file_ext}")
            return "", metadata
    
    async def _extract_text_from_pdf(self, file_path: str) -> str:
        """
        Extract text from a PDF document.
        
        Args:
            file_path: Path to the PDF document
            
        Returns:
            Extracted text
        """
        try:
            if fitz is None:
                logger.warning("PyMuPDF not installed. PDF extraction will be disabled.")
                return ""
            
            text = ""
            
            # Open the PDF
            with fitz.open(file_path) as pdf:
                # Extract text from each page
                for page in pdf:
                    text += page.get_text()
            
            return text
        
        except Exception as e:
            logger.error(f"Error extracting text from PDF {file_path}: {e}")
            return ""
    
    async def _extract_text_from_docx(self, file_path: str) -> str:
        """
        Extract text from a DOCX document.
        
        Args:
            file_path: Path to the DOCX document
            
        Returns:
            Extracted text
        """
        try:
            text = ""
            
            # Open the DOCX
            doc = docx.Document(file_path)
            
            # Extract text from paragraphs
            for para in doc.paragraphs:
                text += para.text + "\n"
            
            return text
        
        except Exception as e:
            logger.error(f"Error extracting text from DOCX {file_path}: {e}")
            return ""
    
    async def _extract_text_from_txt(self, file_path: str) -> str:
        """
        Extract text from a TXT document.
        
        Args:
            file_path: Path to the TXT document
            
        Returns:
            Extracted text
        """
        try:
            # Open the TXT file
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                text = f.read()
            
            return text
        
        except Exception as e:
            logger.error(f"Error extracting text from TXT {file_path}: {e}")
            return ""
    
    def _save_processed_text(self, text: str, original_path: str, metadata: Dict[str, Any]) -> str:
        """
        Save processed text to a file.
        
        Args:
            text: Extracted text
            original_path: Path to the original document
            metadata: Document metadata
            
        Returns:
            Path to the saved processed text
        """
        try:
            # Generate filename
            filename = f"{Path(original_path).stem}_processed.txt"
            
            # Set the save path
            save_path = os.path.join(self.processed_dir, filename)
            
            # Save content
            with open(save_path, "w", encoding="utf-8") as f:
                f.write(text)
            
            # Update metadata with processed file path
            metadata["processed_file"] = save_path
            
            # Save updated metadata
            metadata_path = os.path.join(self.processed_dir, f"{Path(original_path).stem}_metadata.json")
            with open(metadata_path, "w", encoding="utf-8") as f:
                json.dump(metadata, f, ensure_ascii=False, indent=2)
            
            logger.info(f"Processed text saved: {save_path}")
            
            return save_path
        
        except Exception as e:
            logger.error(f"Error saving processed text: {e}")
            return None
    
    def _save_chunks(self, chunks: List[str], original_path: str, metadata: Dict[str, Any]) -> str:
        """
        Save text chunks to a file.
        
        Args:
            chunks: Text chunks
            original_path: Path to the original document
            metadata: Document metadata
            
        Returns:
            Path to the saved chunks
        """
        try:
            # Generate filename
            filename = f"{Path(original_path).stem}_chunks.json"
            
            # Set the save path
            save_path = os.path.join(self.chunks_dir, filename)
            
            # Prepare chunks with IDs
            chunks_with_ids = [
                {"id": str(uuid.uuid4()), "text": chunk, "metadata": metadata}
                for chunk in chunks
            ]
            
            # Save chunks
            with open(save_path, "w", encoding="utf-8") as f:
                json.dump(chunks_with_ids, f, ensure_ascii=False, indent=2)
            
            logger.info(f"Chunks saved: {save_path}")
            
            return save_path
        
        except Exception as e:
            logger.error(f"Error saving chunks: {e}")
            return None
    
    async def _embed_and_store(self, chunks: List[str], metadata: Dict[str, Any]):
        """

        
        Args:
            chunks: Text chunks
            metadata: Document metadata
        """
        try:
            logger.info(f"Embedding and storing {len(chunks)} chunks")
            
            # Generate IDs for chunks
            ids = [str(uuid.uuid4()) for _ in range(len(chunks))]
            
            # Embed chunks
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
                # self.index.upsert(vectors=batch)
            
            return ids
        
        except Exception as e:
            logger.error(f"Error embedding and storing chunks: {e}")
            return None

# Command-line interface
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Process legal documents for RAG")
    parser.add_argument("--file", help="Process a specific file")
    parser.add_argument("--all", action="store_true", help="Process all documents")
    args = parser.parse_args()
    
    # Run the processor
    processor = DocumentProcessor()
    
    if args.file:
        asyncio.run(processor.process_document(args.file))
    elif args.all:
        asyncio.run(processor.process_all_documents())
    else:
        print("Please specify --file or --all")
