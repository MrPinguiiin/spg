import os
from dotenv import load_dotenv

load_dotenv()

# Server Configuration
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", "8000"))
DEBUG = os.getenv("DEBUG", "true").lower() == "true"

# Rate Limiting
RATE_LIMIT_CALCULATE_FEE = os.getenv("RATE_LIMIT_CALCULATE_FEE", "30/minute")
RATE_LIMIT_QRIS_GENERATOR = os.getenv("RATE_LIMIT_QRIS_GENERATOR", "20/minute")
RATE_LIMIT_PAYMENT_STATUS = os.getenv("RATE_LIMIT_PAYMENT_STATUS", "50/minute")

# Request Configuration
REQUEST_TIMEOUT = float(os.getenv("REQUEST_TIMEOUT", "30.0"))
MAX_CONCURRENT_REQUESTS = int(os.getenv("MAX_CONCURRENT_REQUESTS", "10"))
REQUEST_DELAY = float(os.getenv("REQUEST_DELAY", "0.5"))

# Logging
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
LOG_FILE = os.getenv("LOG_FILE", "logs/payment_gateway.log")

# Saweria API
SAWERIA_BASE_URL = "https://backend.saweria.co"
USERNAME_SAWERIA = os.getenv("USERNAME_SAWERIA", "")
DONATION_ID = os.getenv("DONATION_ID", "")
