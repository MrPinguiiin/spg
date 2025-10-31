#!/bin/bash
# Script untuk obfuscate code dan commit ke repo
# Original code tetap private, obfuscated version di-commit

set -e

echo "🔒 Obfuscating source code for public repository..."
echo ""

# Function to get pyarmor command
get_pyarmor() {
    if command -v pyarmor &> /dev/null; then
        echo "pyarmor"
        return 0
    fi
    
    # Check in venv
    if [ -f "venv/bin/pyarmor" ]; then
        echo "venv/bin/pyarmor"
        return 0
    fi
    
    # Check pipx
    if command -v pipx &> /dev/null; then
        local pipx_home="${PIPX_HOME:-$HOME/.local/share/pipx}"
        if [ -f "$pipx_home/venvs/pyarmor/bin/pyarmor" ]; then
            echo "$pipx_home/venvs/pyarmor/bin/pyarmor"
            return 0
        fi
    fi
    
    return 1
}

# Check if pyarmor is installed
PYARMOR_CMD=$(get_pyarmor)
if [ -z "$PYARMOR_CMD" ]; then
    echo "Installing PyArmor..."
    
    # Try pipx first (recommended for Arch Linux)
    if command -v pipx &> /dev/null; then
        echo "Using pipx to install PyArmor..."
        pipx install pyarmor
        PYARMOR_CMD=$(get_pyarmor)
    fi
    
    # Try virtual environment
    if [ -z "$PYARMOR_CMD" ]; then
        if [ -d "venv" ]; then
            echo "Using existing virtual environment..."
        else
            echo "Creating virtual environment..."
            python3 -m venv venv
        fi
        
        echo "Installing PyArmor in virtual environment..."
        # Use venv/bin/pip directly (works with any shell)
        venv/bin/pip install pyarmor
        
        # Check if installed in venv
        if [ -f "venv/bin/pyarmor" ]; then
            PYARMOR_CMD="venv/bin/pyarmor"
        else
            PYARMOR_CMD=$(get_pyarmor)
        fi
    fi
    
    # Final check
    if [ -z "$PYARMOR_CMD" ]; then
        echo "❌ Error: Failed to install PyArmor"
        echo ""
        echo "Please install manually using one of these methods:"
        echo "  1. pipx install pyarmor  (recommended for Arch Linux)"
        echo "  2. python3 -m venv venv && source venv/bin/activate && pip install pyarmor"
        echo "  3. sudo pacman -S python-pipx  (install pipx first)"
        exit 1
    fi
    
    echo "✅ PyArmor installed successfully"
fi

# Export PYARMOR_CMD for use in script
export PYARMOR_CMD

# Backup original files ke folder src/ (dalam .gitignore)
echo "📦 Backing up original files..."
mkdir -p src

# Jika main.py ada di root (mungkin original), backup dulu
if [ -f "main.py" ]; then
    # Check apakah sudah obfuscated (cari pyarmor runtime)
    if grep -q "pyarmor_runtime" main.py 2>/dev/null; then
        echo "⚠️  main.py sudah obfuscated, skip backup"
    else
        cp main.py src/main.py.original
        echo "✅ Original main.py backed up to src/"
    fi
fi

if [ -f "config.py" ]; then
    if grep -q "pyarmor_runtime" config.py 2>/dev/null; then
        echo "⚠️  config.py sudah obfuscated, skip backup"
    else
        cp config.py src/config.py.original
        echo "✅ Original config.py backed up to src/"
    fi
fi

# Jika tidak ada original di root, gunakan yang di src/
if [ ! -f "src/main.py.original" ]; then
    echo "❌ Error: Original main.py not found in src/main.py.original"
    echo "   Please copy your original main.py to src/main.py.original first"
    exit 1
fi

if [ ! -f "src/config.py.original" ]; then
    echo "❌ Error: Original config.py not found in src/config.py.original"
    echo "   Please copy your original config.py to src/config.py.original first"
    exit 1
fi

# Obfuscate main.py - output langsung ke root
echo ""
echo "🔐 Obfuscating main.py..."
$PYARMOR_CMD gen --output dist_temp src/main.py.original

# Copy obfuscated file ke root
# PyArmor mempertahankan nama file original, jadi cari main.py.original
if [ -f "dist_temp/main.py.original" ]; then
    cp dist_temp/main.py.original main.py
    echo "✅ main.py obfuscated and copied to root"
elif [ -f "dist_temp/src/main.py.original" ]; then
    cp dist_temp/src/main.py.original main.py
    echo "✅ main.py obfuscated and copied to root"
elif [ -f "dist_temp/main.py" ]; then
    cp dist_temp/main.py main.py
    echo "✅ main.py obfuscated and copied to root"
else
    echo "❌ Error: Failed to find obfuscated main.py"
    echo "   Looking for files in dist_temp..."
    find dist_temp -type f -name "*.py" 2>/dev/null | head -10 || echo "   No Python files found"
    echo "   Full structure:"
    ls -la dist_temp/ 2>/dev/null || echo "   dist_temp not found"
    exit 1
fi

# Copy pyarmor_runtime jika ada (required untuk run obfuscated code)
if [ -d "dist_temp/pyarmor_runtime_000000" ]; then
    # Copy runtime ke root directory (dibutuhkan untuk run obfuscated code)
    cp -r dist_temp/pyarmor_runtime_000000 . 2>/dev/null || cp -r dist_temp/pyarmor_runtime_000000 pyarmor_runtime_000000
    echo "✅ PyArmor runtime copied"
elif [ -d "dist_temp/pyarmor_runtime" ]; then
    cp -r dist_temp/pyarmor_runtime . 2>/dev/null || true
    echo "✅ PyArmor runtime copied"
fi

# Obfuscate config.py - output langsung ke root
echo "🔐 Obfuscating config.py..."
$PYARMOR_CMD gen --output dist_temp src/config.py.original

if [ -f "dist_temp/config.py.original" ]; then
    cp dist_temp/config.py.original config.py
    echo "✅ config.py obfuscated and copied to root"
elif [ -f "dist_temp/src/config.py.original" ]; then
    cp dist_temp/src/config.py.original config.py
    echo "✅ config.py obfuscated and copied to root"
elif [ -f "dist_temp/config.py" ]; then
    cp dist_temp/config.py config.py
    echo "✅ config.py obfuscated and copied to root"
else
    echo "❌ Error: Failed to find obfuscated config.py"
    echo "   Looking for files in dist_temp..."
    find dist_temp -name "*.py" 2>/dev/null || echo "   No Python files found"
    exit 1
fi

# Cleanup temp directory
rm -rf dist_temp

echo ""
echo "✅ Obfuscation complete!"
echo ""
echo "📝 Files ready for commit:"
echo "   ✅ main.py (obfuscated)"
echo "   ✅ config.py (obfuscated)"
echo "   🔒 Original files saved in src/ (not committed - private)"
echo ""
echo "🧪 Testing obfuscated code (optional)..."
echo "   Run: python -c 'import main'"
echo ""
echo "🚀 Next steps:"
echo "   1. Review obfuscated files (optional)"
echo "   2. git add main.py config.py"
echo "   3. git commit -m 'Update: obfuscated source code for protection'"
echo "   4. git push"
echo ""
echo "⚠️  Remember: Original code in src/ will NOT be committed!"

