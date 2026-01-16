FROM python:3.9-slim

# Install Lua
RUN apt-get update && apt-get install -y \
    lua5.1 \
    liblua5.1-0-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy semua file project (termasuk engine/parser.lua yang sudah full)
COPY . .

# Install Python Libs
RUN pip install --no-cache-dir -r requirements.txt

# Environment Variable
ENV LUA_PATH="/app/engine/?.lua;./engine/?.lua;?.lua;;"

EXPOSE 8080
CMD ["python", "bot.py"]
