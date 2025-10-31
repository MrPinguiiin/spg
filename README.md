# Saweria Payment Gateway API

A FastAPI-based payment gateway that proxies requests to Saweria's API while implementing rate limiting and other mechanisms to avoid Cloudflare rate limits.

## Features

- **Rate Limiting**: Built-in rate limiting to prevent overwhelming the Saweria API
- **Request Queuing**: Semaphore-based concurrency control
- **Error Handling**: Comprehensive error handling with proper HTTP status codes
- **Logging**: Structured logging with file rotation
- **CORS Support**: Cross-origin resource sharing enabled
- **Automatic Retries**: Automatic retry mechanism for rate-limited requests
- **Browser-like Headers**: Mimics browser requests to avoid detection

## Installation

1. **Clone or create the project directory**:
   ```bash
   cd /run/media/mrpinguiiin/DATA/PYTHON/saweria_payment_gateway
   ```

2. **Install Python pip** (if not already installed):
   ```bash
   # On Arch Linux
   sudo pacman -S python-pip

   # On Ubuntu/Debian
   sudo apt install python3-pip

   # On macOS
   brew install python3
   ```

3. **Install dependencies** (in virtual environment):
   ```bash
   source venv/bin/activate  # Activate virtual environment
   pip install -r requirements.txt
   ```

4. **Create environment file** (optional):
   ```bash
   # Create a .env file if you want to customize settings
   cp env.example .env
   ```

5. **Start the API**:
   ```bash
   # Quick start with script
   ./start.sh

   # Or manually
   source venv/bin/activate
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

## Configuration

The API can be configured through environment variables or the `config.py` file:

| Variable | Default | Description |
|----------|---------|-------------|
| `HOST` | `0.0.0.0` | Server host |
| `PORT` | `8000` | Server port |
| `DEBUG` | `true` | Enable debug mode |
| `RATE_LIMIT_CALCULATE_FEE` | `30/minute` | Rate limit for calculate_fee endpoint |
| `RATE_LIMIT_QRIS_GENERATOR` | `20/minute` | Rate limit for qris_generator endpoint |
| `RATE_LIMIT_PAYMENT_STATUS` | `50/minute` | Rate limit for payment_status endpoint |
| `REQUEST_TIMEOUT` | `30.0` | Request timeout in seconds |
| `MAX_CONCURRENT_REQUESTS` | `10` | Maximum concurrent requests |
| `REQUEST_DELAY` | `0.5` | Delay between requests in seconds |
| `LOG_LEVEL` | `INFO` | Logging level |
| `LOG_FILE` | `logs/payment_gateway.log` | Log file path |

## Running the API

### Development
```bash
python main.py
```

### Production
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

## API Endpoints

### 1. Health Check
- **GET** `/`
- Returns API status

### 2. Calculate Fee
- **POST** `/calculate_fee`
- Proxies to Saweria's fee calculation endpoint
- Rate limit: 30 requests/minute

**Request Body:**
```json
{
  "agree": true,
  "amount": 1000,
  "amountToPay": "",
  "currency": "IDR",
  "customer_info": {
    "first_name": "Testing",
    "email": "testing@example.com",
    "phone": ""
  },
  "giphy": null,
  "mediaType": null,
  "message": "Test payment",
  "notUnderage": true,
  "payment_type": "qris",
  "pgFee": "",
  "platformFee": "",
  "vote": "",
  "yt": "",
  "ytStart": 0
}
```

### 3. QRIS Generator
- **POST** `/qris_generator?donation_id={id}`
- Proxies to Saweria's QRIS generation endpoint
- Rate limit: 20 requests/minute
- **Only requires 3 fields**: amount, first_name, email

**Request Body (Simplified):**
```json
{
  "amount": 10000,
  "first_name": "John Doe",
  "email": "john@example.com"
}
```

**Note**: The API automatically fills in all other required fields with default values from the Postman collection.

### 4. Payment Status
- **GET** `/payment_status/{payment_id}`
- Proxies to Saweria's payment status endpoint
- Rate limit: 50 requests/minute

## Custom Headers

You can override default headers by sending custom headers:

- `X-Custom-Referer`: Override the Referer header
- `X-Custom-Origin`: Override the Origin header

## Rate Limiting Strategy

The API implements multiple layers of rate limiting to avoid Cloudflare detection:

1. **SlowAPI Rate Limiting**: Per-endpoint rate limits
2. **Request Semaphore**: Limits concurrent requests
3. **Request Delays**: Adds delays between requests
4. **Automatic Retries**: Retries failed requests with exponential backoff
5. **Browser-like Headers**: Mimics legitimate browser requests

## Error Handling

The API provides detailed error responses:

- `400`: Invalid JSON in request body
- `429`: Rate limit exceeded
- `504`: Request timeout
- `500`: Internal server error

## Logging

Logs are written to `logs/payment_gateway.log` with:
- Request details
- Response status codes
- Error messages
- Automatic log rotation (10MB, 1 week retention)

## Deployment

### 🚀 **Rekomendasi Platform Gratis Terbaik:**

#### **1. Render (Recommended)**
**Free Tier:** 750 jam/bulan, sleep setelah 15 menit tidak aktif
**Keuntungan:** Mudah setup, Python native, persistent apps
**Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`

#### **2. Railway**
**Free Tier:** $5 credit/bulan, auto-recharge
**Keuntungan:** Sangat mudah, Git integration, databases free
**Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`

#### **3. Fly.io**
**Free Tier:** 3 VMs kecil (256MB RAM), 160GB outbound/bulan
**Keuntungan:** Global CDN, custom domains free, persistent
**Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`

### Render Deployment (Detail)

1. **Push code ke Git repository** (GitHub/GitLab)

2. **Connect to Render**:
   - Buat Web Service baru di Render
   - Connect ke repository Git Anda
   - Pilih **Python** sebagai runtime

3. **Konfigurasi Build & Start**:
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`

4. **Environment Variables** (optional, untuk customization):
   ```
   DEBUG=false
   LOG_LEVEL=INFO
   RATE_LIMIT_CALCULATE_FEE=30/minute
   RATE_LIMIT_QRIS_GENERATOR=20/minute
   RATE_LIMIT_PAYMENT_STATUS=50/minute
   ```

5. **Deploy**: Klik **Create Web Service**

### Railway Deployment (Alternatif)

1. **Push ke GitHub**
2. **Connect ke Railway**: railway.app/new
3. **Auto-detect Python**: Railway akan auto-detect dan setup
4. **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
5. **Deploy otomatis** setiap push

### Fly.io Deployment (Advanced)

1. **Install Fly CLI**: `curl -L https://fly.io/install.sh | sh`
2. **Login**: `fly auth login`
3. **Launch**: `fly launch` (akan buat fly.toml)
4. **Deploy**: `fly deploy`

### Manual Deployment

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
uvicorn main:app --host 0.0.0.0 --port 8000

# Or using Python
python main.py
```

## Docker Support

### 🚀 **Opsi 1: Menggunakan Docker Script (Recommended)**
```bash
# Deploy lengkap (build + run)
./docker-deploy.sh deploy

# Atau command spesifik:
./docker-deploy.sh build    # Build image
./docker-deploy.sh run      # Run container
./docker-deploy.sh logs     # Lihat logs
./docker-deploy.sh status   # Cek status
./docker-deploy.sh stop     # Stop container
./docker-deploy.sh restart  # Restart container
```

### 🐳 **Opsi 2: Menggunakan Docker Compose**
```bash
# Build dan run
docker-compose up --build -d

# Lihat logs
docker-compose logs -f

# Stop
docker-compose down
```

### 🔧 **Opsi 3: Manual Docker Commands**
```bash
# Build image
docker build -t saweria-payment-gateway .

# Run container
docker run -d \
  --name saweria-gateway-app \
  --restart unless-stopped \
  -p 8000:8000 \
  -e DEBUG=false \
  saweria-payment-gateway

# View logs
docker logs saweria-gateway-app

# Stop container
docker stop saweria-gateway-app
```

### 📁 **File Docker yang Tersedia:**
- `Dockerfile` - Docker image configuration
- `docker-compose.yml` - Multi-container setup
- `docker-deploy.sh` - Automated deployment script

### 🔍 **Debugging Docker:**
```bash
# Check container status
docker ps -f name=saweria-gateway-app

# View real-time logs
docker logs -f saweria-gateway-app

# Enter container
docker exec -it saweria-gateway-app bash

# Check container health
docker inspect saweria-gateway-app
```

## Security Considerations

- **Rate Limiting**: Prevents abuse and API exhaustion
- **Input Validation**: Validates JSON payloads
- **CORS**: Configurable cross-origin policies
- **Logging**: Comprehensive request logging for monitoring
- **Timeout Protection**: Prevents hanging requests

## Monitoring

- Check `/` endpoint for health status
- Monitor log files for errors and unusual activity
- Track rate limit hits in logs

## Troubleshooting

1. **"externally-managed-environment" Error**:
   ```bash
   # Create virtual environment instead of system-wide install
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Rate Limit Errors**: Reduce request frequency or increase rate limits in config
3. **Timeout Errors**: Increase `REQUEST_TIMEOUT` in configuration
4. **Connection Errors**: Check network connectivity to Saweria API
5. **JSON Errors**: Ensure request bodies are valid JSON
6. **Rust/Cargo Errors**: Update to latest package versions (already fixed in requirements.txt)
7. **Permission Errors**: Run with proper user permissions, avoid system directories

## License

This project is provided as-is for educational and development purposes.
