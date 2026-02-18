import logging
import sys
import os
from datetime import datetime
from pathlib import Path

class EndpointFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        return record.getMessage().find("/health") == -1

def setup_logging():
    """Setup logging configuration with console and file handlers"""
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
        
        # Use Path for better cross-platform compatibility
        base_dir = Path.cwd()
        log_dir = base_dir / "logs" / today
        log_dir.mkdir(parents=True, exist_ok=True)
        
        # Create log file: HH-MM-SS.log
        timestamp = datetime.now().strftime("%H-%M-%S")
        log_file = log_dir / f"{timestamp}.log"
        
        file_handler = logging.FileHandler(log_file)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
        
        logger.info(f"Logging initialized. Log file: {log_file}")
        
    except PermissionError as e:
        print(f"Permission denied when creating log file: {e}", file=sys.stderr)
        print("Continuing with console logging only", file=sys.stderr)
    except OSError as e:
        print(f"OS error when setting up file logging: {e}", file=sys.stderr)
        print("Continuing with console logging only", file=sys.stderr)
    except Exception as e:
        print(f"Unexpected error setting up file logging: {e}", file=sys.stderr)
        print("Continuing with console logging only", file=sys.stderr)
    
    # Uvicorn Access Logger adjustment (filter out health checks to reduce noise)
    logging.getLogger("uvicorn.access").addFilter(EndpointFilter())
    
    return logger

logger = setup_logging()
