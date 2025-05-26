import os
import json
import logging
from datetime import datetime
from typing import List, Dict, Any, Optional
import uuid
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from reportlab.lib.units import cm, mm, inch
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT, TA_RIGHT
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import re
import google.generativeai as genai
from dotenv import load_dotenv
import requests

# Load environment variables
load_dotenv()

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("pdf_generator.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("pdf_generator")

class LegalPDFGenerator:
    def __init__(self, base_dir: str = None):
        """
        Initialize the legal PDF generator.
        
        Args:
            base_dir: Base directory to store generated PDFs
        """
        if base_dir is None:
            base_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
        
        self.base_dir = base_dir
        self.pdf_dir = os.path.join(self.base_dir, "pdf_exports")
        os.makedirs(self.pdf_dir, exist_ok=True)
        
        # Use Google Gemini API for summarization
        self.gemini_api_key = os.getenv("GEMINI_API_KEY")
        self.model_initialized = bool(self.gemini_api_key)
        if self.model_initialized:
            logger.info("Using Google Gemini API for summarization")
            # Configure Gemini API
            genai.configure(api_key=self.gemini_api_key)
            self.gemini_model = genai.GenerativeModel('models/gemini-1.5-pro')
        else:
            logger.error("GEMINI_API_KEY not found. Summarization will not work.")
        
        # Setup PDF styles
        self._setup_styles()
    
    def _setup_styles(self):
        """Set up PDF styles."""
        # Register fonts
        try:
            # Try to register an elegant, old-style serif font if available
            serif_font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf"
            serif_bold_font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
            if os.path.exists(serif_font_path) and os.path.exists(serif_bold_font_path):
                pdfmetrics.registerFont(TTFont('DejaVuSerif', serif_font_path))
                pdfmetrics.registerFont(TTFont('DejaVuSerif-Bold', serif_bold_font_path))
                self.font_name = 'DejaVuSerif'
                self.font_bold = 'DejaVuSerif-Bold'
            else:
                # Fallback to Roboto if DejaVu not found
                pdfmetrics.registerFont(TTFont('Roboto', os.path.join(os.path.dirname(__file__), 'assets', 'Roboto-Regular.ttf')))
                pdfmetrics.registerFont(TTFont('Roboto-Bold', os.path.join(os.path.dirname(__file__), 'assets', 'Roboto-Bold.ttf')))
                self.font_name = 'Roboto'
                self.font_bold = 'Roboto-Bold'
        except:
            # Fall back to default fonts
            self.font_name = 'Helvetica'
            self.font_bold = 'Helvetica-Bold'
        
        # Get the default styles
        self.styles = getSampleStyleSheet()
        
        # Create custom styles
        self.styles.add(ParagraphStyle(
            name='LegalTitle',  # Changed from 'Title' to avoid conflict
            fontName=self.font_bold,
            fontSize=16,
            alignment=TA_CENTER,
            spaceAfter=12
        ))
        
        self.styles.add(ParagraphStyle(
            name='LegalHeading1',  # Changed from 'Heading1' to avoid conflict
            fontName=self.font_bold,
            fontSize=14,
            alignment=TA_LEFT,
            spaceAfter=10,
            spaceBefore=10
        ))
        
        self.styles.add(ParagraphStyle(
            name='LegalHeading2',
            fontName=self.font_bold,
            fontSize=12,
            alignment=TA_LEFT,
            spaceAfter=8,
            spaceBefore=8
        ))
        
        self.styles.add(ParagraphStyle(
            name='LegalNormal',
            fontName=self.font_name,
            fontSize=11,
            alignment=TA_JUSTIFY,
            spaceAfter=6
        ))
        
        self.styles.add(ParagraphStyle(
            name='Disclaimer',
            fontName=self.font_name,
            fontSize=9,
            alignment=TA_CENTER,
            textColor=colors.gray
        ))
    
    async def generate_legal_summary(self, conversation: List[Dict[str, Any]], client_info: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        Generate a structured legal summary from a conversation using Google Gemini API.
        
        Args:
            conversation: List of conversation messages
            client_info: Optional client information
            
        Returns:
            Dictionary with structured legal summary
        """
        if not self.model_initialized:
            logger.error("Gemini model not initialized")
            return {"error": "Gemini model not initialized"}
        try:
            # Format conversation for summarization
            formatted_conversation = self._format_conversation(conversation)
            # Generate summary prompt
            prompt = f"""
            You are a legal assistant tasked with creating a formal legal summary document.
            Analyze the following conversation between a user and a legal assistant, and extract key information to create a structured legal summary.
            
            CONVERSATION:
            {formatted_conversation}
            
            Please provide a structured legal summary with the following sections:
            1. SUMMARY OF ISSUE: A concise summary of the legal issue(s) discussed.
            2. RELEVANT LAWS: Identify any Indian Penal Code sections, laws, acts, or rules mentioned or relevant to the issue.
            3. LEGAL ANALYSIS: Provide a brief analysis of the legal situation based on the conversation.
            4. POSSIBLE OUTCOMES: Outline potential legal outcomes or consequences.
            5. RECOMMENDED NEXT STEPS: Suggest practical next steps the client should take.
            
            Format each section with a clear heading and detailed content. Be formal, precise, and comprehensive.
            """
            
            # Call Google Gemini API
            try:
                response = self.gemini_model.generate_content(prompt)
                summary_text = response.text.strip()
            except Exception as gemini_error:
                logger.error(f"Google Gemini API error: {str(gemini_error)}")
                return {"error": f"Google Gemini API error: {str(gemini_error)}"}
                
            # Parse the summary into structured sections
            structured_summary = self._parse_summary(summary_text)
            # Add client information if provided
            if client_info:
                structured_summary["client_info"] = client_info
            # Add timestamp
            structured_summary["timestamp"] = datetime.now().isoformat()
            return structured_summary
        except Exception as e:
            logger.error(f"Error generating legal summary: {e}")
            return {"error": str(e)}
    
    def _format_conversation(self, conversation: List[Dict[str, Any]]) -> str:
        """
        Format conversation for summarization.
        
        Args:
            conversation: List of conversation messages
            
        Returns:
            Formatted conversation text
        """
        formatted_text = ""
        
        for message in conversation:
            role = message.get("role", "unknown").upper()
            content = message.get("content", "")
            
            formatted_text += f"{role}: {content}\n\n"
        
        return formatted_text
    
    def _parse_summary(self, summary_text: str) -> Dict[str, Any]:
        """
        Parse the generated summary into structured sections.
        
        Args:
            summary_text: Generated summary text
            
        Returns:
            Dictionary with structured sections
        """
        # Define section patterns
        section_patterns = {
            "summary_of_issue": r"(?:SUMMARY OF ISSUE:?|ISSUE SUMMARY:?)(.*?)(?=RELEVANT LAWS:?|LEGAL PROVISIONS:?|$)",
            "relevant_laws": r"(?:RELEVANT LAWS:?|LEGAL PROVISIONS:?)(.*?)(?=LEGAL ANALYSIS:?|ANALYSIS:?|$)",
            "legal_analysis": r"(?:LEGAL ANALYSIS:?|ANALYSIS:?)(.*?)(?=POSSIBLE OUTCOMES:?|POTENTIAL OUTCOMES:?|$)",
            "possible_outcomes": r"(?:POSSIBLE OUTCOMES:?|POTENTIAL OUTCOMES:?)(.*?)(?=RECOMMENDED NEXT STEPS:?|NEXT STEPS:?|$)",
            "recommended_next_steps": r"(?:RECOMMENDED NEXT STEPS:?|NEXT STEPS:?)(.*?)(?=$)"
        }
        
        # Extract sections
        structured_summary = {}
        
        for key, pattern in section_patterns.items():
            match = re.search(pattern, summary_text, re.DOTALL | re.IGNORECASE)
            if match:
                content = match.group(1).strip()
                structured_summary[key] = content
            else:
                structured_summary[key] = ""
        
        return structured_summary
    
    async def generate_pdf(self, summary: Dict[str, Any], filename: Optional[str] = None) -> str:
        """
        Generate a PDF from a structured legal summary.
        
        Args:
            summary: Structured legal summary
            filename: Optional filename
            
        Returns:
            Path to the generated PDF
        """
        try:
            # Generate filename if not provided
            if not filename:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                client_name = summary.get("client_info", {}).get("name", "client")
                client_name = client_name.replace(" ", "_").lower()
                filename = f"legal_summary_{client_name}_{timestamp}.pdf"
            
            # Ensure .pdf extension
            if not filename.lower().endswith(".pdf"):
                filename += ".pdf"
            
            # Set the output path
            output_path = os.path.join(self.pdf_dir, filename)
            
            # Create PDF document
            doc = SimpleDocTemplate(
                output_path,
                pagesize=A4,
                rightMargin=72,
                leftMargin=72,
                topMargin=72,
                bottomMargin=72
            )
            
            # Build content
            content = []
            
            # Add title
            title = Paragraph("Case Summary Document – APRS Legal Assistant", self.styles["LegalTitle"])
            content.append(title)
            content.append(Spacer(1, 12))
            
            # Add date
            timestamp = datetime.fromisoformat(summary.get("timestamp", datetime.now().isoformat()))
            date_str = timestamp.strftime("%d %B, %Y")
            date = Paragraph(f"Date: {date_str}", self.styles["Normal"])
            content.append(date)
            content.append(Spacer(1, 12))
            
            # Add client information if available
            if "client_info" in summary:
                client_info = summary["client_info"]
                # Accept both modern and legacy keys
                client_name = client_info.get("name") or client_info.get("party_details") or ""
                client_location = client_info.get("location") or client_info.get("background_info") or ""
                motion = client_info.get("motion") or ""
                roles_responsibilities = client_info.get("roles_responsibilities") or ""
                breaches_contingencies = client_info.get("breaches_contingencies") or ""
                dates_signatures = client_info.get("dates_signatures") or ""

                if client_name:
                    client = Paragraph(f"Client: {client_name}", self.styles["Normal"])
                    content.append(client)
                if client_location:
                    location = Paragraph(f"Location: {client_location}", self.styles["Normal"])
                    content.append(location)
                if motion:
                    motion_par = Paragraph(f"Motion: {motion}", self.styles["Normal"])
                    content.append(motion_par)
                if roles_responsibilities:
                    rr_par = Paragraph(f"Roles & Responsibilities: {roles_responsibilities}", self.styles["Normal"])
                    content.append(rr_par)
                if breaches_contingencies:
                    bc_par = Paragraph(f"Breaches/Contingencies: {breaches_contingencies}", self.styles["Normal"])
                    content.append(bc_par)
                if dates_signatures:
                    ds_par = Paragraph(f"Dates & Signatures: {dates_signatures}", self.styles["Normal"])
                    content.append(ds_par)
                content.append(Spacer(1, 12))
            
            # Add summary of issue
            if "summary_of_issue" in summary and summary["summary_of_issue"]:
                heading = Paragraph("SUMMARY OF ISSUE", self.styles["Heading1"])
                content.append(heading)
                
                text = Paragraph(summary["summary_of_issue"], self.styles["Normal"])
                content.append(text)
                content.append(Spacer(1, 12))
            
            # Add relevant laws
            if "relevant_laws" in summary and summary["relevant_laws"]:
                heading = Paragraph("RELEVANT LAWS", self.styles["Heading1"])
                content.append(heading)
                
                text = Paragraph(summary["relevant_laws"], self.styles["Normal"])
                content.append(text)
                content.append(Spacer(1, 12))
            
            # Add legal analysis
            if "legal_analysis" in summary and summary["legal_analysis"]:
                heading = Paragraph("LEGAL ANALYSIS", self.styles["Heading1"])
                content.append(heading)
                
                text = Paragraph(summary["legal_analysis"], self.styles["Normal"])
                content.append(text)
                content.append(Spacer(1, 12))
            
            # Add possible outcomes
            if "possible_outcomes" in summary and summary["possible_outcomes"]:
                heading = Paragraph("POSSIBLE OUTCOMES", self.styles["Heading1"])
                content.append(heading)
                
                text = Paragraph(summary["possible_outcomes"], self.styles["Normal"])
                content.append(text)
                content.append(Spacer(1, 12))
            
            # Add recommended next steps
            if "recommended_next_steps" in summary and summary["recommended_next_steps"]:
                heading = Paragraph("RECOMMENDED NEXT STEPS", self.styles["Heading1"])
                content.append(heading)
                
                text = Paragraph(summary["recommended_next_steps"], self.styles["Normal"])
                content.append(text)
                content.append(Spacer(1, 24))
            
            # Add disclaimer
            disclaimer_text = """
            DISCLAIMER: This document is an AI-generated summary for reference purposes only. 
            The information provided does not constitute legal advice. 
            Please consult a qualified legal professional for advice specific to your situation.
            """
            disclaimer = Paragraph(disclaimer_text, self.styles["Disclaimer"])
            content.append(disclaimer)
            
            # Build PDF
            doc.build(content)
            
            logger.info(f"PDF generated successfully: {output_path}")
            
            return output_path
        
        except Exception as e:
            logger.error(f"Error generating PDF: {e}")
            return ""

# Command-line interface
if __name__ == "__main__":
    import argparse
    import asyncio
    
    parser = argparse.ArgumentParser(description="Generate legal PDF summaries")
    parser.add_argument("--conversation", help="Path to conversation JSON file")
    parser.add_argument("--client-name", help="Client name")
    parser.add_argument("--client-location", help="Client location")
    args = parser.parse_args()
    
    async def main():
        generator = LegalPDFGenerator()
        
        if args.conversation:
            # Load conversation from file
            with open(args.conversation, "r", encoding="utf-8") as f:
                conversation = json.load(f)
            
            # Prepare client info
            client_info = {}
            if args.client_name:
                client_info["name"] = args.client_name
            if args.client_location:
                client_info["location"] = args.client_location
            
            # Generate summary
            summary = await generator.generate_legal_summary(conversation, client_info)
            
            # Generate PDF
            pdf_path = await generator.generate_pdf(summary)
            
            if pdf_path:
                print(f"PDF generated successfully: {pdf_path}")
            else:
                print("Failed to generate PDF")
        else:
            print("Please provide a conversation JSON file")
    
    asyncio.run(main())
