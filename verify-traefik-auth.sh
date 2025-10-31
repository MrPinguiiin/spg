#!/bin/bash
# Script untuk verifikasi dan troubleshooting Traefik Dashboard Auth

echo "=== Traefik Dashboard Auth Verifier ==="
echo ""

# Cek apakah .env file ada
if [ ! -f ".env" ]; then
    echo "❌ Error: File .env tidak ditemukan!"
    exit 1
fi

# Baca TRAEFIK_AUTH_USERS dari .env
AUTH_USERS=$(grep "^TRAEFIK_AUTH_USERS=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")

if [ -z "$AUTH_USERS" ]; then
    echo "❌ Error: TRAEFIK_AUTH_USERS tidak ditemukan di .env!"
    exit 1
fi

echo "✅ TRAEFIK_AUTH_USERS ditemukan di .env"
echo ""

# Cek format (harus ada double $$)
if echo "$AUTH_USERS" | grep -q '\$\$'; then
    echo "✅ Format password hash benar (menggunakan \$\$ untuk escape)"
else
    echo "⚠️  Warning: Format password hash mungkin salah"
    echo "   Seharusnya menggunakan \$\$ untuk setiap \$ dalam hash"
    echo "   Contoh: admin:\$\$apr1\$\$hash\$\$rest"
fi

# Parse username dan hash
USERNAME=$(echo "$AUTH_USERS" | cut -d':' -f1)
HASH_PART=$(echo "$AUTH_USERS" | cut -d':' -f2-)

echo ""
echo "Username yang terdeteksi: $USERNAME"
echo "Hash (disingkat): ${HASH_PART:0:20}..."
echo ""

# Cek apakah hash valid (format apr1 atau bcrypt)
if echo "$HASH_PART" | grep -qE '^\$\$apr1\$\$|\$\$2y\$|\$\$2a\$|\$\$2b\$'; then
    echo "✅ Format hash valid (apr1 atau bcrypt)"
else
    echo "⚠️  Warning: Format hash mungkin tidak valid"
    echo "   Harus dimulai dengan: \$\$apr1\$\$ atau \$\$2y\$\$ atau \$\$2a\$\$"
fi

echo ""
echo "=========================================="
echo "Cara Test Login:"
echo "=========================================="
echo "1. Akses: https://traefik.beanbill.online"
echo "2. Masukkan username: $USERNAME"
echo "3. Masukkan password yang Anda set sebelumnya"
echo ""
echo "Jika masih tidak bisa login:"
echo "1. Cek apakah container Traefik sudah restart:"
echo "   docker-compose restart traefik"
echo ""
echo "2. Cek logs Traefik:"
echo "   docker-compose logs traefik | grep -i auth"
echo ""
echo "3. Regenerate password jika perlu:"
echo "   ./generate-traefik-password.sh"
echo "   (Pastikan tidak ada quotes di .env)"
echo ""
echo "4. Verifikasi format di .env:"
echo "   TRAEFIK_AUTH_USERS harus tanpa quotes"
echo "   Harus menggunakan double \$\$ untuk setiap \$"
echo "   Contoh: TRAEFIK_AUTH_USERS=admin:\$\$apr1\$\$hash\$\$rest"
echo ""

