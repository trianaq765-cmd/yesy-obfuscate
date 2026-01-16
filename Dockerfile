FROM python:3.9-slim

RUN apt-get update && apt-get install -y \
    lua5.1 \
    liblua5.1-0-dev \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN mkdir -p engine

# Download Parser saja
RUN wget -O engine/parser.lua https://raw.githubusercontent.com/stravant/LuaMinify/master/ParseLua.lua

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy semua file termasuk engine/strict.lua buatan kita
COPY . .

ENV LUA_PATH="/app/engine/?.lua;./engine/?.lua;;"

EXPOSE 8080
CMD ["python", "bot.py"]
