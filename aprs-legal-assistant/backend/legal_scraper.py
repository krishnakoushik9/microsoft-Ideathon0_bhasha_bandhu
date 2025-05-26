import os
import json
import time
import asyncio
import requests
import urllib.parse
from datetime import datetime
from typing import List, Dict, Any, Optional, Tuple
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from bs4 import BeautifulSoup
import uuid
import logging
from pathlib import Path

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("scraper.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("legal_scraper")

class LegalDocumentScraper:
    def __init__(self, base_dir: str = None):
        """
        Initialize the legal document scraper.
        
        Args:
            base_dir: Base directory to store scraped documents
        """
        if base_dir is None:
            base_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
        
        self.base_dir = base_dir
        self.documents_dir = os.path.join(self.base_dir, "legal_documents")
        
        # Create directories for different document types
        self.dirs = {
            "bare_acts": os.path.join(self.documents_dir, "bare_acts"),
            "judgments": os.path.join(self.documents_dir, "judgments"),
            "amendments": os.path.join(self.documents_dir, "amendments"),
            "notifications": os.path.join(self.documents_dir, "notifications"),
            "bills": os.path.join(self.documents_dir, "bills"),
            "commentaries": os.path.join(self.documents_dir, "commentaries"),
            "other": os.path.join(self.documents_dir, "other")
        }
        
        # Create all directories
        for dir_path in self.dirs.values():
            os.makedirs(dir_path, exist_ok=True)
        
        # Create metadata directory
        self.metadata_dir = os.path.join(self.documents_dir, "metadata")
        os.makedirs(self.metadata_dir, exist_ok=True)
        
        # Sources configuration
        self.sources = {
            "indiankanoon": {
                "base_url": "https://indiankanoon.org",
                "search_url": "https://indiankanoon.org/search/?formInput={}",
                "document_types": ["judgments", "commentaries"],
                "selectors": {
                    "search_results": "a.result_title",
                    "document_content": "#doc_content",
                    "document_title": "div.docTitle",
                    "document_meta": "div.docsource_main"
                }
            },
            "legislative": {
                "base_url": "https://legislative.gov.in",
                "search_url": "https://legislative.gov.in/search/site/{}",
                "document_types": ["bare_acts", "bills", "amendments"],
                "selectors": {
                    "search_results": "h3.title a",
                    "document_content": "#main-content",
                    "document_title": "h1.page-title",
                    "pdf_links": "a[href$='.pdf']"
                }
            },
            "latestlaws": {
                "base_url": "https://www.latestlaws.com",
                "search_url": "https://www.latestlaws.com/search?q={}",
                "document_types": ["bare_acts", "amendments", "notifications"],
                "selectors": {
                    "search_results": "h3.entry-title a",
                    "document_content": ".entry-content",
                    "document_title": "h1.entry-title",
                    "pdf_links": "a[href$='.pdf']"
                }
            }
        }
    
    def _setup_driver(self):
        """Set up Chrome driver with headless option."""
        chrome_options = Options()
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        
        service = Service(ChromeDriverManager().install())
        driver = webdriver.Chrome(service=service, options=chrome_options)
        return driver
    
    async def scrape_all_sources(self, keywords: List[str] = None, max_results_per_keyword: int = 10):
        """
        Scrape all configured legal sources.
        
        Args:
            keywords: List of keywords to search for
            max_results_per_keyword: Maximum number of results to scrape per keyword
        """
        if keywords is None:
            # Default keywords covering major legal areas
            keywords = [
                "constitution", "criminal", "civil", "property", "contract", 
                "family", "tax", "corporate", "intellectual property", "labor",
                "environmental", "banking", "insurance", "arbitration", "consumer",
                "supreme court", "high court", "district court"
            ]
        
        driver = self._setup_driver()
        
        try:
            for source_name, source_info in self.sources.items():
                logger.info(f"Scraping source: {source_name}")
                
                for keyword in keywords:
                    logger.info(f"Searching for keyword: {keyword}")
                    
                    # Format the search URL
                    search_url = source_info["search_url"].format(urllib.parse.quote(keyword))
                    
                    # Scrape search results
                    await self._scrape_search_results(
                        driver=driver,
                        source_name=source_name,
                        search_url=search_url,
                        max_results=max_results_per_keyword
                    )
        
        finally:
            driver.quit()
    
    async def _scrape_search_results(self, driver, source_name: str, search_url: str, max_results: int):
        """
        Scrape search results from a legal source.
        
        Args:
            driver: Selenium WebDriver
            source_name: Name of the source
            search_url: URL to search
            max_results: Maximum number of results to scrape
        """
        source_info = self.sources[source_name]
        
        try:
            # Navigate to search URL
            driver.get(search_url)
            
            # Wait for search results
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.TAG_NAME, "body"))
            )
            
            # Extract result links
            selector = source_info["selectors"]["search_results"]
            result_elements = driver.find_elements(By.CSS_SELECTOR, selector)
            
            # Limit results
            result_elements = result_elements[:max_results]
            
            # Extract URLs
            result_urls = []
            for elem in result_elements:
                url = elem.get_attribute("href")
                if url:
                    result_urls.append(url)
            
            logger.info(f"Found {len(result_urls)} results for {source_name}")
            
            # Scrape each result
            for url in result_urls:
                await self._scrape_document(driver, source_name, url)
                
                # Add a small delay between requests
                await asyncio.sleep(2)
        
        except Exception as e:
            logger.error(f"Error scraping search results from {source_name}: {e}")
    
    async def _scrape_document(self, driver, source_name: str, url: str):
        """
        Scrape a legal document.
        
        Args:
            driver: Selenium WebDriver
            source_name: Name of the source
            url: URL of the document
        """
        source_info = self.sources[source_name]
        
        try:
            logger.info(f"Scraping document: {url}")
            
            # Navigate to document URL
            driver.get(url)
            
            # Wait for page to load
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.TAG_NAME, "body"))
            )
            
            # Check for PDF links first
            if "pdf_links" in source_info["selectors"]:
                pdf_links = driver.find_elements(By.CSS_SELECTOR, source_info["selectors"]["pdf_links"])
                
                for pdf_link in pdf_links:
                    pdf_url = pdf_link.get_attribute("href")
                    if pdf_url:
                        await self._download_pdf(pdf_url, source_name)
            
            # Extract document content
            document_data = await self._extract_document_data(driver, source_name)
            
            if document_data:
                # Determine document type
                doc_type = self._determine_document_type(document_data["title"], source_name)
                
                # Save document
                await self._save_document(document_data, doc_type, source_name)
        
        except Exception as e:
            logger.error(f"Error scraping document {url}: {e}")
    
    async def _extract_document_data(self, driver, source_name: str) -> Dict[str, Any]:
        """
        Extract data from a legal document.
        
        Args:
            driver: Selenium WebDriver
            source_name: Name of the source
            
        Returns:
            Dictionary with document data
        """
        source_info = self.sources[source_name]
        
        try:
            # Extract title
            title = "Untitled Document"
            if "document_title" in source_info["selectors"]:
                title_elements = driver.find_elements(By.CSS_SELECTOR, source_info["selectors"]["document_title"])
                if title_elements:
                    title = title_elements[0].text.strip()
            
            # Extract content
            content = ""
            if "document_content" in source_info["selectors"]:
                content_elements = driver.find_elements(By.CSS_SELECTOR, source_info["selectors"]["document_content"])
                if content_elements:
                    content = content_elements[0].text.strip()
            
            # Extract metadata
            metadata = {}
            if "document_meta" in source_info["selectors"]:
                meta_elements = driver.find_elements(By.CSS_SELECTOR, source_info["selectors"]["document_meta"])
                if meta_elements:
                    metadata["source_metadata"] = meta_elements[0].text.strip()
            
            # Add common metadata
            metadata.update({
                "source": source_name,
                "url": driver.current_url,
                "scraped_at": datetime.now().isoformat()
            })
            
            return {
                "id": str(uuid.uuid4()),
                "title": title,
                "content": content,
                "metadata": metadata
            }
        
        except Exception as e:
            logger.error(f"Error extracting document data: {e}")
            return None
    
    async def _download_pdf(self, pdf_url: str, source_name: str):
        """
        Download a PDF document.
        
        Args:
            pdf_url: URL of the PDF
            source_name: Name of the source
        """
        try:
            logger.info(f"Downloading PDF: {pdf_url}")
            
            # Generate a unique filename
            filename = f"{source_name}_{str(uuid.uuid4())}.pdf"
            
            # Determine document type from URL
            doc_type = self._determine_document_type_from_url(pdf_url, source_name)
            
            # Set the save path
            save_path = os.path.join(self.dirs[doc_type], filename)
            
            # Download the PDF
            response = requests.get(pdf_url, stream=True)
            response.raise_for_status()
            
            with open(save_path, "wb") as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            
            # Save metadata
            metadata = {
                "id": str(uuid.uuid4()),
                "title": self._extract_title_from_url(pdf_url),
                "source": source_name,
                "url": pdf_url,
                "file_path": save_path,
                "document_type": doc_type,
                "scraped_at": datetime.now().isoformat()
            }
            
            metadata_path = os.path.join(self.metadata_dir, f"{Path(save_path).stem}.json")
            with open(metadata_path, "w", encoding="utf-8") as f:
                json.dump(metadata, f, ensure_ascii=False, indent=2)
            
            logger.info(f"PDF downloaded: {save_path}")
            
            return save_path, metadata
        
        except Exception as e:
            logger.error(f"Error downloading PDF {pdf_url}: {e}")
            return None, None
    
    def _determine_document_type(self, title: str, source_name: str) -> str:
        """
        Determine the type of legal document based on its title.
        
        Args:
            title: Document title
            source_name: Name of the source
            
        Returns:
            Document type
        """
        title_lower = title.lower()
        
        # Check for specific document types
        if any(term in title_lower for term in ["act", "code", "law", "statute"]):
            return "bare_acts"
        elif any(term in title_lower for term in ["judgment", "order", "decision", "vs", "versus"]):
            return "judgments"
        elif any(term in title_lower for term in ["amendment", "amend"]):
            return "amendments"
        elif any(term in title_lower for term in ["notification", "notice", "circular"]):
            return "notifications"
        elif any(term in title_lower for term in ["bill"]):
            return "bills"
        elif any(term in title_lower for term in ["commentary", "analysis", "review"]):
            return "commentaries"
        
        # Default to the first document type for the source
        return self.sources[source_name]["document_types"][0]
    
    def _determine_document_type_from_url(self, url: str, source_name: str) -> str:
        """
        Determine the type of legal document based on its URL.
        
        Args:
            url: Document URL
            source_name: Name of the source
            
        Returns:
            Document type
        """
        url_lower = url.lower()
        
        # Check for specific document types in URL
        if any(term in url_lower for term in ["act", "code", "law", "statute"]):
            return "bare_acts"
        elif any(term in url_lower for term in ["judgment", "order", "decision", "case"]):
            return "judgments"
        elif any(term in url_lower for term in ["amendment", "amend"]):
            return "amendments"
        elif any(term in url_lower for term in ["notification", "notice", "circular"]):
            return "notifications"
        elif any(term in url_lower for term in ["bill"]):
            return "bills"
        elif any(term in url_lower for term in ["commentary", "analysis", "review"]):
            return "commentaries"
        
        # Default to "other"
        return "other"
    
    def _extract_title_from_url(self, url: str) -> str:
        """
        Extract a title from a URL.
        
        Args:
            url: Document URL
            
        Returns:
            Extracted title
        """
        # Try to extract the filename
        parsed_url = urllib.parse.urlparse(url)
        path = parsed_url.path
        
        # Get the filename
        filename = os.path.basename(path)
        
        # Remove extension and replace underscores/hyphens with spaces
        title = os.path.splitext(filename)[0].replace("_", " ").replace("-", " ")
        
        # Capitalize words
        title = " ".join(word.capitalize() for word in title.split())
        
        return title if title else "Untitled Document"
    
    async def _save_document(self, document_data: Dict[str, Any], doc_type: str, source_name: str):
        """
        Save a document to the appropriate directory.
        
        Args:
            document_data: Document data
            doc_type: Document type
            source_name: Name of the source
        """
        try:
            # Generate filename
            filename = f"{source_name}_{document_data['id']}.txt"
            
            # Set the save path
            save_path = os.path.join(self.dirs[doc_type], filename)
            
            # Save content
            with open(save_path, "w", encoding="utf-8") as f:
                f.write(f"Title: {document_data['title']}\n\n")
                f.write(document_data['content'])
            
            # Update metadata with file path and document type
            document_data["metadata"]["file_path"] = save_path
            document_data["metadata"]["document_type"] = doc_type
            
            # Save metadata
            metadata_path = os.path.join(self.metadata_dir, f"{document_data['id']}.json")
            with open(metadata_path, "w", encoding="utf-8") as f:
                json.dump(document_data["metadata"], f, ensure_ascii=False, indent=2)
            
            logger.info(f"Document saved: {save_path}")
            
            return save_path
        
        except Exception as e:
            logger.error(f"Error saving document: {e}")
            return None

# Command-line interface
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Scrape legal documents from Indian legal websites")
    parser.add_argument("--keywords", nargs="+", help="Keywords to search for")
    parser.add_argument("--max-results", type=int, default=10, help="Maximum results per keyword")
    args = parser.parse_args()
    
    # Run the scraper
    scraper = LegalDocumentScraper()
    asyncio.run(scraper.scrape_all_sources(
        keywords=args.keywords,
        max_results_per_keyword=args.max_results
    ))
