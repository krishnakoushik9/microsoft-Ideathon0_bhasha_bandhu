import os
import json
import time
import asyncio
from typing import List, Optional, Dict, Any
from selenium import webdriver
from selenium.webdriver.edge.service import Service
from selenium.webdriver.edge.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.microsoft import EdgeChromiumDriverManager
from bs4 import BeautifulSoup
import requests
import uuid

# Import RAG system for vectorizing
from backend.rag import RAGSystem

class LegalCrawler:
    def __init__(self):
        """Initialize the legal crawler with Selenium and Chrome."""
        self.data_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
        self.raw_data_dir = os.path.join(self.data_dir, "raw")
        os.makedirs(self.raw_data_dir, exist_ok=True)
        
        # Initialize RAG system for vectorizing
        self.rag_system = RAGSystem()
        
        # Legal websites to crawl
        self.legal_websites = {
            "indiankanoon": {
                "base_url": "https://indiankanoon.org",
                "search_url": "https://indiankanoon.org/search/?formInput={}",
                "parser": self._parse_indiankanoon
            },
            "legislative": {
                "base_url": "https://legislative.gov.in",
                "search_url": "https://legislative.gov.in/en/search/node/{}",
                "parser": self._parse_legislative
            },
            "barandbench": {
                "base_url": "https://www.barandbench.com",
                "search_url": "https://www.barandbench.com/search?q={}",
                "parser": self._parse_barandbench
            },
            "latestlaws": {
                "base_url": "https://www.latestlaws.com",
                "search_url": "https://www.latestlaws.com/search?q={}",
                "parser": self._parse_latestlaws
            }
        }

    
    # Cache the Edge driver path to prevent repeated downloads
    _edge_driver_path = None

    def _human_like_mouse_move_and_click(self, driver, element):
        """
        Move the mouse in a human-like jittery way to the element and click using ActionChains.
        Jitter is added to simulate natural hand movement. The final click lands at the center of the element.
        """
        import random
        import time
        from selenium.webdriver import ActionChains
        driver.execute_script("arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});", element)
        actions = ActionChains(driver)
        size = element.size
        # Get the center of the element for the final click
        center_x = size['width'] // 2
        center_y = size['height'] // 2
        # Simulate jittery movement: move in small steps with random jitter
        steps = random.randint(12, 22)
        for i in range(steps):
            # Progressively move closer to the center with jitter
            frac = (i + 1) / steps
            jitter = lambda mag: random.randint(-mag, mag)
            offset_x = int(center_x * frac + jitter(max(2, size['width']//10)))
            offset_y = int(center_y * frac + jitter(max(2, size['height']//10)))
            actions.move_to_element_with_offset(element, offset_x, offset_y)
            actions.pause(random.uniform(0.04, 0.18))
        # Land at the center for the click
        actions.move_to_element_with_offset(element, center_x, center_y)
        actions.pause(random.uniform(0.10, 0.25))
        actions.click().perform()
        print(f"[HumanMouse] Simulated jittery mouse movement and clicked at center ({center_x}, {center_y}) of element.")

    def _get_google_results(self, query: str, num_results: int = 3):
        """
        Use Google Custom Search API (with fallback) to get top results for the query.
        Returns a list of dicts: [{title, link, snippet}]
        """
        from backend.google_search import get_top_google_results
        return get_top_google_results(query, num_results)

    def _setup_driver(self):
        """Set up Edge driver (visible window for debugging, random user-agent). Cache driver binary to avoid repeated downloads."""
        import random
        edge_options = Options()
        # REMOVE headless for visible browser
        # edge_options.add_argument("--headless")
        edge_options.add_argument("--no-sandbox")
        edge_options.add_argument("--disable-dev-shm-usage")
        # Randomize user-agent to mimic real users
        user_agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/117.0"
        ]
        user_agent = random.choice(user_agents)
        edge_options.add_argument(f"--user-agent={user_agent}")
        if LegalCrawler._edge_driver_path is None:
            LegalCrawler._edge_driver_path = EdgeChromiumDriverManager().install()
        service = Service(LegalCrawler._edge_driver_path)
        driver = webdriver.Edge(service=service, options=edge_options)
        return driver
    
    async def crawl(self, urls: Optional[List[str]] = None, query: Optional[str] = None):
        """
        Crawl legal websites for content.
        
        Args:
            urls: List of specific URLs to crawl
            query: Search query to use for finding legal content
        """
        driver = self._setup_driver()
        
        try:
            if urls:
                # Crawl specific URLs
                for url in urls:
                    await self._crawl_url(driver, url)
            
            if query:
                # Search and crawl results from legal websites
                await self._search_and_crawl(driver, query)
        
        finally:
            driver.quit()
    
    async def _crawl_url(self, driver, url: str):
        """
        Crawl a specific URL and extract legal content.
        
        Args:
            driver: Selenium WebDriver
            url: URL to crawl
        """
        try:
            print(f"Crawling URL: {url}")
            driver.get(url)
            
            # Wait for page to load
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.TAG_NAME, "body"))
            )
            
            # Extract domain to determine which parser to use
            domain = self._extract_domain(url)
            
            # Parse content based on domain
            if domain in self.legal_websites:
                content = self.legal_websites[domain]["parser"](driver)
            else:
                # Use generic parser
                content = self._parse_generic(driver)
            
            if content:
                # Save content to file
                file_id = str(uuid.uuid4())
                file_path = os.path.join(self.raw_data_dir, f"{file_id}.json")
                
                with open(file_path, "w", encoding="utf-8") as f:
                    json.dump({
                        "url": url,
                        "domain": domain,
                        "content": content,
                        "crawled_at": time.time()
                    }, f, ensure_ascii=False, indent=2)
                
                # Vectorize content
                metadata = {
                    "url": url,
                    "domain": domain,
                    "file_id": file_id
                }
                await self.rag_system.vectorize_text(content, metadata)
                
                print(f"Successfully crawled and vectorized content from {url}")
                return True
            
            print(f"No content extracted from {url}")
            return False
        
        except Exception as e:
            print(f"Error crawling {url}: {e}")
            return False
    
    async def _search_and_crawl(self, driver, query: str):
        """
        Search legal websites and crawl results.
        
        Args:
            driver: Selenium WebDriver
            query: Search query
        """
        for site_name, site_info in self.legal_websites.items():
            try:
                search_url = site_info["search_url"].format(query.replace(" ", "+"))
                print(f"Searching {site_name} with query: {query}")
                
                driver.get(search_url)
                
                # Wait for search results
                WebDriverWait(driver, 10).until(
                    EC.presence_of_element_located((By.TAG_NAME, "body"))
                )
                
                # Extract result links
                result_links = self._extract_search_results(driver, site_name)
                
                print(f"Found {len(result_links)} results on {site_name}")
                
                # Crawl top results (limit to 5 per site to avoid overloading)
                for i, link in enumerate(result_links[:5]):
                    if not link.startswith("http"):
                        if link.startswith("/"):
                            link = site_info["base_url"] + link
                        else:
                            link = site_info["base_url"] + "/" + link
                    
                    await self._crawl_url(driver, link)
                    
                    # Add a small delay between requests
                    await asyncio.sleep(2)

                # Wait a random 7-10 seconds before moving to the next site (mimic real user)
                import random
                wait_time = random.uniform(7, 10)
                print(f"Waiting {wait_time:.1f} seconds before moving to next site...")
                await asyncio.sleep(wait_time)
        
            except Exception as e:
                print(f"Error searching {site_name}: {e}")
    
    def _extract_search_results(self, driver, site_name: str) -> List[str]:
        """
        Extract search result links from a search page.
        
        Args:
            driver: Selenium WebDriver
            site_name: Name of the legal website
            
        Returns:
            List of URLs from search results
        """
        links = []
        
        try:
            if site_name == "indiankanoon":
                # Extract links from Indian Kanoon search results
                elements = driver.find_elements(By.CSS_SELECTOR, "a.result_title")
                links = [elem.get_attribute("href") for elem in elements]
            
            elif site_name == "legislative":
                # Extract links from Legislative.gov.in search results
                elements = driver.find_elements(By.CSS_SELECTOR, "h3.title a")
                links = [elem.get_attribute("href") for elem in elements]
            
            elif site_name == "barandbench":
                # Extract links from Bar and Bench search results
                elements = driver.find_elements(By.CSS_SELECTOR, "h2.entry-title a")
                links = [elem.get_attribute("href") for elem in elements]
            
            elif site_name == "latestlaws":
                # Extract links from Latest Laws search results
                elements = driver.find_elements(By.CSS_SELECTOR, "h3.entry-title a")
                links = [elem.get_attribute("href") for elem in elements]
            
            else:
                # Generic extraction of links
                elements = driver.find_elements(By.TAG_NAME, "a")
                links = [elem.get_attribute("href") for elem in elements if elem.get_attribute("href")]
        
        except Exception as e:
            print(f"Error extracting search results from {site_name}: {e}")
        
        return [link for link in links if link]  # Filter out None values
    
    def _extract_domain(self, url: str) -> str:
        """
        Extract domain from URL.
        
        Args:
            url: URL to extract domain from
            
        Returns:
            Domain name
        """
        for site_name, site_info in self.legal_websites.items():
            if site_info["base_url"] in url:
                return site_name
        
        return "generic"
    
    def _parse_indiankanoon(self, driver) -> str:
        """
        Parse content from Indian Kanoon.
        
        Args:
            driver: Selenium WebDriver
            
        Returns:
            Extracted text content
        """
        try:
            # Wait for content to load
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.ID, "doc_content"))
            )
            
            # Extract document content
            doc_content = driver.find_element(By.ID, "doc_content")
            
            # Extract title
            title_elem = driver.find_elements(By.CSS_SELECTOR, "div.docTitle")
            title = title_elem[0].text if title_elem else "Untitled Document"
            
            # Extract metadata
            metadata_elem = driver.find_elements(By.CSS_SELECTOR, "div.docsource_main")
            metadata = metadata_elem[0].text if metadata_elem else ""
            
            # Combine content
            content = f"Title: {title}\n\nMetadata: {metadata}\n\nContent:\n{doc_content.text}"
            
            return content
        
        except Exception as e:
            print(f"Error parsing Indian Kanoon content: {e}")
            
            # Fallback to generic parser
            return self._parse_generic(driver)
    
    def _parse_legislative(self, driver) -> str:
        """
        Parse content from Legislative.gov.in.
        
        Args:
            driver: Selenium WebDriver
            
        Returns:
            Extracted text content
        """
        try:
            # Wait for content to load
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.ID, "main-content"))
            )
            
            # Extract main content
            main_content = driver.find_element(By.ID, "main-content")
            
            # Extract title
            title_elem = driver.find_elements(By.CSS_SELECTOR, "h1.page-title")
            title = title_elem[0].text if title_elem else "Untitled Document"
            
            # Combine content
            content = f"Title: {title}\n\nContent:\n{main_content.text}"
            
            return content
        
        except Exception as e:
            print(f"Error parsing Legislative.gov.in content: {e}")
            
            # Fallback to generic parser
            return self._parse_generic(driver)
    
    def _parse_barandbench(self, driver) -> str:
        """
        Parse content from Bar and Bench.
        
        Args:
            driver: Selenium WebDriver
            
        Returns:
            Extracted text content
        """
        try:
            # Wait for content to load
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.CLASS_NAME, "entry-content"))
            )
            
            # Extract article content
            article_content = driver.find_element(By.CLASS_NAME, "entry-content")
            
            # Extract title
            title_elem = driver.find_elements(By.CSS_SELECTOR, "h1.entry-title")
            title = title_elem[0].text if title_elem else "Untitled Article"
            
            # Extract date
            date_elem = driver.find_elements(By.CSS_SELECTOR, "time.entry-date")
            date = date_elem[0].text if date_elem else ""
            
            # Combine content
            content = f"Title: {title}\n\nDate: {date}\n\nContent:\n{article_content.text}"
            
            return content
        
        except Exception as e:
            print(f"Error parsing Bar and Bench content: {e}")
            
            # Fallback to generic parser
            return self._parse_generic(driver)
    
    def _parse_latestlaws(self, driver) -> str:
        """
        Parse content from Latest Laws.
        
        Args:
            driver: Selenium WebDriver
            
        Returns:
            Extracted text content
        """
        try:
            # Wait for content to load
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.CLASS_NAME, "entry-content"))
            )
            
            # Extract article content
            article_content = driver.find_element(By.CLASS_NAME, "entry-content")
            
            # Extract title
            title_elem = driver.find_elements(By.CSS_SELECTOR, "h1.entry-title")
            title = title_elem[0].text if title_elem else "Untitled Document"
            
            # Combine content
            content = f"Title: {title}\n\nContent:\n{article_content.text}"
            
            return content
        
        except Exception as e:
            print(f"Error parsing Latest Laws content: {e}")
            
            # Fallback to generic parser
            return self._parse_generic(driver)
    
    def _parse_generic(self, driver) -> str:
        """
        Generic parser for any website.
        
        Args:
            driver: Selenium WebDriver
            
        Returns:
            Extracted text content
        """
        try:
            # Extract title
            title_elem = driver.find_elements(By.TAG_NAME, "h1")
            title = title_elem[0].text if title_elem else "Untitled Document"
            
            # Extract main content
            # Try common content selectors
            content_selectors = [
                "article", "main", ".content", "#content", 
                ".main-content", "#main-content", ".article-content"
            ]
            
            content_text = ""
            for selector in content_selectors:
                try:
                    elements = driver.find_elements(By.CSS_SELECTOR, selector)
                    if elements:
                        content_text = elements[0].text
                        break
                except:
                    continue
            
            # If no content found with selectors, extract body text
            if not content_text:
                body = driver.find_element(By.TAG_NAME, "body")
                
                # Use BeautifulSoup to clean up the HTML and extract text
                soup = BeautifulSoup(driver.page_source, "html.parser")
                
                # Remove script and style elements
                for script in soup(["script", "style", "nav", "footer", "header"]):
                    script.extract()
                
                # Get text
                content_text = soup.get_text(separator="\n")
            
            # Combine content
            content = f"Title: {title}\n\nContent:\n{content_text}"
            
            return content
        
        except Exception as e:
            print(f"Error in generic parser: {e}")
            return ""
