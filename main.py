from fastapi import FastAPI, Request, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import httpx
import asyncio
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
import os
from dotenv import load_dotenv
from loguru import logger
import json
from typing import Dict, Any, Optional
from config import *

class QRISRequest(BaseModel):
    amount: int
    first_name: str
    email: str

app = FastAPI(
    title="Saweria Payment Gateway API",
    description="Payment Gateway API to proxy requests to Saweria and avoid Cloudflare rate limits",
    version="1.0.0"
)

# Rate limiter setup
limiter = Limiter(key_func=get_remote_address, default_limits=["100/minute"])
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Semaphore for limiting concurrent requests
request_semaphore = asyncio.Semaphore(MAX_CONCURRENT_REQUESTS)

# HTTP client with connection pooling
client = httpx.AsyncClient(
    timeout=httpx.Timeout(REQUEST_TIMEOUT),
    follow_redirects=True,
    limits=httpx.Limits(max_keepalive_connections=20, max_connections=100)
)

async def make_saweria_request(method: str, url: str, headers: Dict[str, str] = None, json_data: Dict[str, Any] = None) -> Dict[str, Any]:
    """Make a request to Saweria API with rate limiting and error handling."""
    async with request_semaphore:
        try:
            # Add delay to avoid rate limiting
            await asyncio.sleep(0.5)

            logger.info(f"Making {method} request to: {url}")

            if headers is None:
                headers = {}

            # Set default headers that mimic browser requests
            default_headers = {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                "Accept": "application/json, text/plain, */*",
                "Accept-Language": "en-US,en;q=0.9",
                "DNT": "1",
                "Connection": "keep-alive",
                "Upgrade-Insecure-Requests": "1",
            }

            # For GET requests (like payment status), don't request compression to avoid decoding issues
            if method.upper() == "GET":
                default_headers["Accept-Encoding"] = "identity"
            else:
                default_headers["Accept-Encoding"] = "gzip, deflate, br"

            headers.update(default_headers)

            if method.upper() == "POST":
                response = await client.post(url, headers=headers, json=json_data)
            elif method.upper() == "GET":
                response = await client.get(url, headers=headers)
            else:
                raise HTTPException(status_code=405, detail="Method not allowed")

            logger.info(f"Response status: {response.status_code}")

            if response.status_code == 429:
                logger.warning("Rate limit hit, retrying after delay...")
                await asyncio.sleep(5)
                return await make_saweria_request(method, url, headers, json_data)

            response.raise_for_status()

            try:
                return response.json()
            except json.JSONDecodeError:
                try:
                    # Try to get text content
                    text_content = response.text
                    return {"data": text_content}
                except UnicodeDecodeError:
                    # If it's not valid UTF-8, return info about binary content
                    content_length = len(response.content)
                    content_type = response.headers.get('content-type', 'unknown')
                    return {
                        "error": "Binary or non-UTF-8 response",
                        "content_type": content_type,
                        "content_length": content_length,
                        "status_code": response.status_code
                    }

        except httpx.TimeoutException:
            logger.error(f"Timeout error for {url}")
            raise HTTPException(status_code=504, detail="Request timeout")
        except httpx.HTTPStatusError as e:
            try:
                error_text = e.response.text
            except UnicodeDecodeError:
                error_text = f"Binary response ({len(e.response.content)} bytes)"
            logger.error(f"HTTP error {e.response.status_code} for {url}: {error_text}")
            raise HTTPException(status_code=e.response.status_code, detail=f"Saweria API error: {error_text}")
        except Exception as e:
            logger.error(f"Unexpected error for {url}: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.get("/")
async def root():
    """Health check endpoint."""
    return {"status": "ok", "message": "Saweria Payment Gateway API is running"}

@app.post("/calculate_fee")
@limiter.limit(RATE_LIMIT_CALCULATE_FEE)
async def calculate_fee(request: Request):
    """Calculate payment fee by proxying to Saweria API."""
    try:
        request_data = await request.json()
        logger.info("Calculate fee request received")

        url = f"{SAWERIA_BASE_URL}/donations/{USERNAME_SAWERIA}/calculate_pg_amount"

        # Prepare headers
        headers = {
            "Content-Type": "application/json",
            "Referer": "https://saweria.co/",
            "Origin": "https://saweria.co",
        }

        # Forward custom headers if provided
        if "X-Custom-Referer" in request.headers:
            headers["Referer"] = request.headers["X-Custom-Referer"]
        if "X-Custom-Origin" in request.headers:
            headers["Origin"] = request.headers["X-Custom-Origin"]

        response_data = await make_saweria_request("POST", url, headers, request_data)
        return response_data

    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON in request body")
    except Exception as e:
        logger.error(f"Error in calculate_fee: {str(e)}")
        raise

@app.post("/qris_generator")
@limiter.limit(RATE_LIMIT_QRIS_GENERATOR)
async def qris_generator(
    qris_data: QRISRequest,
    donation_id: str = "",
    request: Request = None
):
    """Generate QRIS payment by proxying to Saweria API.

    Required parameters:
    - amount: Payment amount in IDR
    - first_name: Customer first name
    - email: Customer email address
    """
    try:
        logger.info(f"QRIS generator request received for {qris_data.first_name} ({qris_data.email}) - Amount: {qris_data.amount}")

        # Build the complete request payload with default values
        request_data = {
            "agree": True,
            "amount": qris_data.amount,
            "currency": "IDR",
            "customer_info": {
                "first_name": qris_data.first_name,
                "email": qris_data.email,
                "phone": ""
            },
            "email": qris_data.email,
            "first_name": qris_data.first_name,
            "phone": "",
            "message": "Uji Coba Snap API",
            "notUnderage": True,
            "payment_type": "qris",
            "vote": ""
        }

        # Use environment variable if donation_id is not provided
        final_donation_id = donation_id if donation_id else DONATION_ID
        url = f"{SAWERIA_BASE_URL}/donations/snap/{final_donation_id}"

        # Prepare headers
        headers = {
            "Content-Type": "application/json",
            "Referer": "https://saweria.co/",
            "Origin": "https://saweria.co",
        }

        # Forward custom headers if provided
        if request and "X-Custom-Referer" in request.headers:
            headers["Referer"] = request.headers["X-Custom-Referer"]
        if request and "X-Custom-Origin" in request.headers:
            headers["Origin"] = request.headers["X-Custom-Origin"]

        response_data = await make_saweria_request("POST", url, headers, request_data)
        return response_data

    except Exception as e:
        logger.error(f"Error in qris_generator: {str(e)}")
        raise

@app.get("/payment_status/{payment_id}")
@limiter.limit(RATE_LIMIT_PAYMENT_STATUS)
async def payment_status(payment_id: str, request: Request = None):
    """Check payment status by proxying to Saweria API."""
    try:
        logger.info(f"Payment status request for ID: {payment_id}")

        url = f"{SAWERIA_BASE_URL}/donations/qris/snap/{payment_id}"

        # Prepare headers
        headers = {
            "Referer": "https://saweria.co/",
            "Origin": "https://saweria.co",
            "Accept": "application/json",
        }

        # Forward custom headers if provided
        if request and "X-Custom-Referer" in request.headers:
            headers["Referer"] = request.headers["X-Custom-Referer"]
        if request and "X-Custom-Origin" in request.headers:
            headers["Origin"] = request.headers["X-Custom-Origin"]

        response_data = await make_saweria_request("GET", url, headers)
        return response_data

    except Exception as e:
        logger.error(f"Error in payment_status: {str(e)}")
        raise

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown."""
    await client.aclose()
    logger.info("Application shutdown complete")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=HOST,
        port=PORT,
        reload=DEBUG,
        log_level=LOG_LEVEL.lower()
    )
