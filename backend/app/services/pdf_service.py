from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from io import BytesIO
from datetime import datetime
from app.core.logging import logger

class PDFGenerationError(Exception):
    """Custom exception for PDF generation errors"""
    pass

class PDFService:
    def generate_od_report(self, od_data: list[dict]) -> bytes:
        try:
            if not od_data:
                raise PDFGenerationError("No data provided for PDF generation")
                
            buffer = BytesIO()
            c = canvas.Canvas(buffer, pagesize=letter)
            width, height = letter
            
            # Header
            c.setFont("Helvetica-Bold", 16)
            c.drawString(50, height - 50, "ODTrack Academia - OD Request Report")
            
            c.setFont("Helvetica", 10)
            c.drawString(50, height - 70, f"Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            
            # Table Header
            y = height - 100
            c.setFont("Helvetica-Bold", 10)
            c.drawString(50, y, "ID")
            c.drawString(100, y, "Student ID")
            c.drawString(200, y, "Date")
            c.drawString(350, y, "Status")
            c.line(50, y - 5, 500, y - 5)
            
            # Rows
            y -= 20
            c.setFont("Helvetica", 10)
            for item in od_data:
                if y < 50: # New page if needed (simplified)
                    c.showPage()
                    y = height - 50
                    
                c.drawString(50, y, str(item.get('id', 'N/A')))
                c.drawString(100, y, str(item.get('student_id', 'N/A')))
                c.drawString(200, y, str(item.get('date', 'N/A')))
                c.drawString(350, y, item.get('status', 'N/A'))
                y -= 15
                
            c.save()
            buffer.seek(0)
            logger.info(f"Generated PDF report for {len(od_data)} records")
            return buffer.getvalue()
        except PDFGenerationError:
            raise
        except Exception as e:
            logger.error(f"Error generating PDF report: {e}", exc_info=True)
            raise PDFGenerationError(f"Failed to generate PDF report: {str(e)}")

pdf_service = PDFService()
