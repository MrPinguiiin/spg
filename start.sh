#!/bin/bash

# Saweria Payment Gateway API Startup Script

echo "🚀 Starting Saweria Payment Gateway API..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found. Please run setup first:"
    echo "   python3 -m venv venv"
    echo "   source venv/bin/activate"
    echo "   pip install -r requirements.txt"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

# Check if dependencies are installed
python -c "import fastapi, uvicorn, httpx" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "❌ Dependencies not installed. Installing..."
    pip install -r requirements.txt
fi

# Start the server
echo "✅ Starting server on http://localhost:8000"
echo "📖 API Documentation: http://localhost:8000/docs"
echo "🔄 Press Ctrl+C to stop"
echo ""

uvicorn main:app --host 0.0.0.0 --port 8000 --reload

