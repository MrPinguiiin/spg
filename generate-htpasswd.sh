#!/bin/bash
# Script untuk generate .htpasswd file untuk Traefik Dashboard

echo "=== Generate .htpasswd untuk Traefik Dashboard ==="
echo ""

# Cek apakah .env ada
if [ ! -f ".env" ]; then
    echo "❌ File .env tidak ditemukan!"
    exit 1
fi

# Cek apakah TRAEFIK_AUTH_USERS ada di .env
AUTH_USERS=$(grep "^TRAEFIK_AUTH_USERS=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")

if [ -z "$AUTH_USERS" ]; then
    echo "❌ TRAEFIK_AUTH_USERS tidak ditemukan di .env!"
    echo ""
    echo "Gunakan generate-traefik-password.sh untuk generate password terlebih dahulu"
    exit 1
fi

# Parse username dan hash (dengan single $ karena docker-compose sudah unescape)
# Format di .env: admin:$$apr1$$salt$$hash
# Setelah docker-compose unescape di label: admin:$apr1$salt$hash
# Tapi untuk file, kita perlu: admin:$apr1$salt$hash (single $)

# Unescape dari format docker-compose ($$ menjadi $)
HASH_UNESCAPED=$(echo "$AUTH_USERS" | sed 's/\$\$/\$/g')

# Extract username
USERNAME=$(echo "$HASH_UNESCAPED" | cut -d':' -f1)

# Cek format hash
if echo "$HASH_UNESCAPED" | grep -qE ':\$apr1\$|:\$2[ayb]\$'; then
    echo "✅ Format hash valid"
else
    echo "⚠️  Warning: Format hash mungkin tidak valid"
    echo "   Hash yang terdeteksi: ${HASH_UNESCAPED:0:50}..."
fi

# Write to .htpasswd file
HTPASSWD_FILE="traefik/auth/.htpasswd"
mkdir -p traefik/auth
echo "$HASH_UNESCAPED" > "$HTPASSWD_FILE"

if [ $? -eq 0 ]; then
    echo "✅ File .htpasswd berhasil dibuat: $HTPASSWD_FILE"
    echo ""
    echo "Username: $USERNAME"
    echo "Format: $HASH_UNESCAPED"
    echo ""
    echo "Langkah selanjutnya:"
    echo "1. Restart Traefik: docker-compose restart traefik"
    echo "2. Test login di: https://traefik.beanbill.online"
    echo ""
    echo "⚠️  Catatan: File .htpasswd harus di-commit ke repo"
    echo "   Pastikan username/password yang digunakan aman!"
else
    echo "❌ Error: Gagal membuat file .htpasswd"
    exit 1
fi

