# 🔒 Workflow: Obfuscate Code untuk Public Repository

Cara kerja sistem ini:
1. **Original code** disimpan di folder `src/` (tidak di-commit, ada di .gitignore)
2. **Obfuscated code** di-commit ke repository (public tapi sulit dibaca)
3. **User clone** → dapat obfuscated code → deploy → **works perfectly!**

## 📋 Workflow Lengkap

### 1. **Setup Pertama Kali**

```bash
# 1. Simpan original code ke src/ (folder baru, tidak di-commit)
mkdir -p src
cp main.py src/main.py.original
cp config.py src/config.py.original

# 2. Obfuscate code
./obfuscate-and-commit.sh

# 3. Commit obfuscated version
git add main.py config.py
git commit -m "Update: obfuscated source code for protection"
git push
```

### 2. **Update Code (Setiap Ada Perubahan)**

```bash
# 1. Edit original code di src/
nano src/main.py.original

# 2. Copy ke root untuk testing lokal (optional)
cp src/main.py.original main.py

# 3. Obfuscate dan commit
./obfuscate-and-commit.sh
git add main.py config.py
git commit -m "Update: obfuscated code"
git push
```

### 3. **User Deploy (Pihak Ketiga)**

```bash
# 1. Clone repository (dapat obfuscated code)
git clone https://github.com/MrPinguiiin/spg.git
cd spg

# 2. Setup dan deploy seperti biasa
cp env.example .env
# Edit .env

# 3. Deploy - Obfuscated code berfungsi normal!
docker-compose up --build -d
```

**Hasil:**
- ✅ User bisa deploy dengan mudah
- ✅ Code tetap obfuscated (sulit dibaca)
- ✅ Repository tetap public
- ✅ Semua berfungsi normal!

## 🔒 Keamanan

### Apa yang Dilindungi:
- ✅ Business logic di `main.py` (obfuscated)
- ✅ Configuration logic di `config.py` (obfuscated)
- ✅ API endpoints dan flow (sulit dipahami)

### Apa yang Tetap Terlihat:
- ⚠️ API endpoints (dari `/docs`)
- ⚠️ Dependencies (dari `requirements.txt`)
- ⚠️ Docker setup (dari `Dockerfile`)

### Catatan:
- **PyArmor tidak bisa di-decompile** dengan mudah (perlu reverse engineering advanced)
- **Code tetap berjalan normal** - tidak ada performance impact
- **Sensitive data** (API keys, tokens) tetap harus di `.env` file

## 🛠️ Setup Script

Script `obfuscate-and-commit.sh` akan:
1. Install PyArmor jika belum ada
2. Backup original code ke `src/`
3. Obfuscate `main.py` dan `config.py`
4. Copy obfuscated files ke root (siap di-commit)

## 📝 File Structure

```
spg/
├── main.py              # Obfuscated (DI-COMMIT, sulit dibaca)
├── config.py            # Obfuscated (DI-COMMIT, sulit dibaca)
├── src/                 # Original (TIDAK DI-COMMIT, private)
│   ├── main.py.original
│   └── config.py.original
├── Dockerfile           # Normal (tidak perlu ubah)
├── docker-compose.yml   # Normal
├── requirements.txt     # Normal
└── .gitignore          # src/ di-ignore
```

## ⚠️ Important Notes

1. **Jangan pernah commit `src/` folder** - itu original code Anda!
2. **Selalu test obfuscated code** sebelum commit
3. **Backup original code** di tempat lain juga (untuk safety)

## 🚀 Quick Commands

```bash
# Obfuscate dan siap commit
./obfuscate-and-commit.sh

# Commit obfuscated files
git add main.py config.py
git commit -m "Update: obfuscated source code"
git push

# Test obfuscated code locally (optional)
docker-compose up --build
```

---

**Result:** Public repo, bisa deploy, code sulit dibaca! 🎉

