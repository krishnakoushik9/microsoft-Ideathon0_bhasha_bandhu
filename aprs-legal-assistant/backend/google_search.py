import os
import requests
from googlesearch import search as google_search_fallback

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY", "AIzaSyAPaQjD53ITSG-T448F0fSgQ-Sf0Nt7Odw")
GOOGLE_CSE_ID = os.getenv("GOOGLE_CSE_ID", "")  # Set your CSE ID here or in .env


def google_custom_search(query, num_results=3):
    """
    Use Google Custom Search API to fetch top results.
    Returns a list of dicts: [{title, link, snippet}]
    """
    if not GOOGLE_API_KEY or not GOOGLE_CSE_ID:
        return None
    url = "https://www.googleapis.com/customsearch/v1"
    params = {
        "key": GOOGLE_API_KEY,
        "cx": GOOGLE_CSE_ID,
        "q": query,
        "num": num_results,
    }
    try:
        resp = requests.get(url, params=params, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        results = []
        for item in data.get("items", [])[:num_results]:
            results.append({
                "title": item.get("title"),
                "link": item.get("link"),
                "snippet": item.get("snippet"),
            })
        return results
    except Exception as e:
        print(f"[Google API] Error: {e}")
        return None

def google_fallback_search(query, num_results=3):
    """
    Use googlesearch-python as a fallback. Returns a list of dicts: [{title, link, snippet=None}]
    """
    try:
        links = list(google_search_fallback(query, num=num_results, stop=num_results, pause=2))
        return [{"title": None, "link": link, "snippet": None} for link in links]
    except Exception as e:
        print(f"[Google Fallback] Error: {e}")
        return None

def get_top_google_results(query, num_results=3):
    """
    Try Google Custom Search API, fallback to googlesearch-python if needed.
    """
    results = google_custom_search(query, num_results)
    if results:
        return results
    return google_fallback_search(query, num_results)
