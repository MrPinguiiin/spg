#!/bin/bash
# Script untuk generate password Traefik Dashboard

echo "=== Traefik Dashboard Password Generator ==="
echo ""
echo "Masukkan username (default: admin):"
read -r USERNAME
USERNAME=${USERNAME:-admin}

echo "Masukkan password:"
read -s PASSWORD

if [ -z "$PASSWORD" ]; then
    echo "Error: Password tidak boleh kosong!"
    exit 1
fi

# Generate hash
HASH=$(htpasswd -nb "$USERNAME" "$PASSWORD" 2>/dev/null)

if [ $? -eq 0 ]; then
    # Escape $ untuk docker-compose
    HASH_ESCAPED=$(echo "$HASH" | sed 's/\$/\$\$/g')
    echo ""
    echo "=========================================="
    echo "Tambahkan ini ke file .env:"
    echo "=========================================="
    echo "TRAEFIK_AUTH_USERS=$HASH_ESCAPED"
    echo "=========================================="
    echo ""
    echo "Username: $USERNAME"
    echo "Password: (yang Anda masukkan)"
else
    echo "Error: Gagal generate password!"
    echo "Pastikan htpasswd sudah terinstall:"
    echo "  Ubuntu/Debian: sudo apt install apache2-utils"
    echo "  Arch: sudo pacman -S apache"
    exit 1
fi

