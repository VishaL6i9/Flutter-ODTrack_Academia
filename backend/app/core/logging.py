import logging
import sys
import os
from datetime import datetime
from app.core.config import get_settings

settings = get_settings()

class EndpointFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        return record.getMessage().find("/health") == -1

def setup_logging():
    # Define log format
    log_format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    formatter = logging.Formatter(log_format)
    
    # Create logger
    logger = logging.getLogger("odtrack")
    logger.setLevel(logging.INFO)
    
    # Console Handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # File Handler
    try:
        # Create logs directory: backend/logs/YYYY-MM-DD
        today = datetime.now().strftime("%Y-%m-%d")
        
        # Ensure we are relative to the backend root or reliable path
        # Using CWD is typical for these apps, but let's be safe
        base_dir = os.getcwd() 
        log_dir = os.path.join(base_dir, "logs", today)
        os.makedirs(log_dir, exist_ok=True)
        
        # Create log file: HH-MM-SS.log
        timestamp = datetime.now().strftime("%H-%M-%S")
        log_file = os.path.join(log_dir, f"{timestamp}.log")
        
        file_handler = logging.FileHandler(log_file)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
        
        # Also log to file that logging started
        # We can't use logger.info yet as we are setting it up, 
        # but the handler is added so subsequent calls will work.
        
    except Exception as e:
        # Fallback to console only if file setup fails
        print(f"Failed to setup file logging: {e}")
    
    # Uvicorn Access Logger adjustment (filter out health checks to reduce noise)
    logging.getLogger("uvicorn.access").addFilter(EndpointFilter())
    
    return logger

logger = setup_logging()
