from backend.pdf_generator import LegalPDFGenerator
import os

if __name__ == "__main__":
    print(f"Using model: {os.getenv('HF_MODEL')}")
    generator = LegalPDFGenerator()
    if not generator.model_initialized:
        print("Model failed to initialize. Check logs for details.")
    else:
        try:
            # Try a simple prompt
            result = generator.llm("Hello, world!")
            print("Model output:", result)
        except Exception as e:
            print("Error running model:", e)
