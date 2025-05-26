import os
from pinecone import Pinecone, ServerlessSpec
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def setup_pinecone():
    """
    Set up Pinecone vector database.
    """
    # Get API key from environment variables
    pinecone_api_key = os.getenv("PINECONE_API_KEY")
    pinecone_region = os.getenv("PINECONE_ENVIRONMENT", "us-east-1")
    index_name = os.getenv("PINECONE_INDEX_NAME", "legal-app-microsoft")
    
    if not pinecone_api_key:
        print("Error: PINECONE_API_KEY environment variable not set.")
        print("Please set it in your .env file or environment variables.")
        return False
    
    try:
        # Initialize Pinecone client
        pc = Pinecone(api_key=pinecone_api_key)
        
        # Check if index exists
        existing_indexes = pc.list_indexes().names()
        if index_name in existing_indexes:
            print(f"Index '{index_name}' already exists.")
        else:
            # Create index
            pc.create_index(
                name=index_name,
                dimension=384,  # Dimension for all-MiniLM-L6-v2
                metric="cosine",
                spec=ServerlessSpec(
                    cloud="aws",
                    region=pinecone_region
                )
            )
            print(f"Index '{index_name}' created successfully.")
        
        return True
    
    except Exception as e:
        print(f"Error setting up Pinecone: {e}")
        return False

if __name__ == "__main__":
    print("Setting up Pinecone vector database...")
    if setup_pinecone():
        print("Pinecone setup completed successfully.")
    else:
        print("Pinecone setup failed.")
