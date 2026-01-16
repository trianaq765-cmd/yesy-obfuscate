FROM python:3.9-slim

# Install Lua & Wget
RUN apt-get update && apt-get install -y \
    lua5.1 \
    liblua5.1-0-dev \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN mkdir -p engine

# Download Parser
RUN wget -O engine/parser.lua https://raw.githubusercontent.com/stravant/LuaMinify/master/ParseLua.lua

# Copy requirements & Install Python Libs
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy sisa file
COPY . .

# Environment Variable Dummy (Nanti ditimpa saat run)
ENV DISCORD_TOKEN="ganti_token_saat_run"

# Jalankan Bot Python
CMD ["python", "bot.py"]
