#!/bin/bash
# Script untuk test dan debug Traefik Basic Auth

echo "=== Test Traefik Dashboard Login ==="
echo ""

# Get container name
CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep -i traefik | head -1)
if [ -z "$CONTAINER_NAME" ]; then
    echo "❌ Container Traefik tidak ditemukan!"
    exit 1
fi

echo "Container: $CONTAINER_NAME"
echo ""

# Step 1: Restart Traefik
echo "1. Restarting Traefik..."
docker-compose restart traefik > /dev/null 2>&1
sleep 3
echo "✅ Traefik restarted"
echo ""

# Step 2: Cek middleware
echo "2. Checking middleware..."
MIDDLEWARE_CHECK=$(docker exec "$CONTAINER_NAME" wget -qO- http://localhost:8080/api/http/middlewares 2>/dev/null | grep -o "auth-traefik" | head -1)
if [ -n "$MIDDLEWARE_CHECK" ]; then
    echo "✅ Middleware 'auth-traefik' terdeteksi"
else
    echo "❌ Middleware 'auth-traefik' TIDAK terdeteksi!"
    echo ""
    echo "Available middlewares:"
    docker exec "$CONTAINER_NAME" wget -qO- http://localhost:8080/api/http/middlewares 2>/dev/null | grep -o '"name":"[^"]*"' | head -5
fi
echo ""

# Step 3: Cek router
echo "3. Checking router..."
ROUTER_CHECK=$(docker exec "$CONTAINER_NAME" wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | grep -o "traefik-dashboard" | head -1)
if [ -n "$ROUTER_CHECK" ]; then
    echo "✅ Router 'traefik-dashboard' terdeteksi"
else
    echo "❌ Router 'traefik-dashboard' TIDAK terdeteksi!"
fi
echo ""

# Step 4: Cek basic auth users format
echo "4. Checking basic auth format..."
BASIC_AUTH=$(docker exec "$CONTAINER_NAME" wget -qO- http://localhost:8080/api/http/middlewares/auth-traefik@docker 2>/dev/null)
if [ -n "$BASIC_AUTH" ]; then
    echo "✅ Middleware detail:"
    echo "$BASIC_AUTH" | grep -o '"basicAuth":{[^}]*}' || echo "Basic auth config found"
    echo ""
    
    # Extract users value
    USERS_VALUE=$(echo "$BASIC_AUTH" | grep -o '"users":\["[^"]*"\]' | grep -o '"[^"]*"' | tr -d '"' | head -1)
    if [ -n "$USERS_VALUE" ]; then
        echo "Format users di Traefik: $USERS_VALUE"
        # Check if format correct (should be user:$apr1$... or user:$2y$...)
        if echo "$USERS_VALUE" | grep -qE '^\$apr1\$|^\$2[ayb]\$'; then
            echo "✅ Format hash valid (apr1 atau bcrypt)"
        elif echo "$USERS_VALUE" | grep -qE '\$\$\$'; then
            echo "⚠️  Warning: Ada escape ganda ($$$) - format mungkin salah!"
        else
            echo "⚠️  Format hash tidak terdeteksi sebagai apr1 atau bcrypt"
        fi
    fi
else
    echo "❌ Tidak bisa membaca middleware detail"
fi
echo ""

# Step 5: Test access
echo "5. Test access ke dashboard..."
echo "Akses: https://traefik.beanbill.online"
echo ""

# Read username and password from .env
USERNAME=$(grep "^TRAEFIK_AUTH_USERS=" .env 2>/dev/null | cut -d'=' -f2- | cut -d':' -f1)
if [ -n "$USERNAME" ]; then
    echo "Username dari .env: $USERNAME"
    echo ""
    echo "⚠️  Jika login masih gagal, coba:"
    echo "   1. Pastikan password yang dimasukkan sama dengan saat generate"
    echo "   2. Regenerate password: ./generate-traefik-password.sh"
    echo "   3. Pastikan di .env tidak ada quotes: TRAEFIK_AUTH_USERS=admin:$$apr1$$..."
    echo "   4. Restart: docker-compose restart traefik"
else
    echo "⚠️  Username tidak ditemukan di .env"
fi
echo ""

