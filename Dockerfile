FROM python:3.9-slim

# TRIK: Ubah angka ini setiap kali deploy untuk paksa rebuild
ENV CACHE_BUST=2

RUN apt-get update && apt-get install -y \
    lua5.1 \
    liblua5.1-0-dev \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy SEMUA file DULU (termasuk strict.lua)
COPY . .

# Download parser SETELAH copy (akan menimpa jika ada)
RUN wget -O engine/parser.lua https://raw.githubusercontent.com/stravant/LuaMinify/master/ParseLua.lua

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Set Lua path
ENV LUA_PATH="/app/engine/?.lua;./engine/?.lua;?.lua;;"

# Debug: List isi folder engine untuk verifikasi
RUN echo "=== ISI FOLDER ENGINE ===" && ls -la engine/

EXPOSE 8080
CMD ["python", "bot.py"]
