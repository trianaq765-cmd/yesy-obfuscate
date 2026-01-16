import discord
import os
import subprocess
from flask import Flask
from threading import Thread

# --- BAGIAN 1: WEBSITE MINI (Keep Alive) ---
app = Flask(__name__)

@app.route('/')
def home():
    return "Bot is Alive! 🤖"

def run_web_server():
    app.run(host='0.0.0.0', port=8080)

def keep_alive():
    t = Thread(target=run_web_server)
    t.start()

# --- BAGIAN 2: LOGIKA BOT DISCORD ---
intents = discord.Intents.default()
intents.message_content = True
client = discord.Client(intents=intents)

@client.event
async def on_ready():
    print(f'[BOT] Online sebagai {client.user}')

@client.event
async def on_message(message):
    if message.author == client.user:
        return

    # Command sederhana untuk tes
    if message.content == "!ping":
        await message.channel.send("Pong! 🏓 Bot aktif!")
        return

    if message.content == "!help":
        await message.channel.send(
            "**Cara Pakai:**\n"
            "Upload file `.lua` ke chat ini, bot akan memprosesnya otomatis."
        )
        return

    # Proses File Attachment
    if message.attachments:
        attachment = message.attachments[0]
        print(f"[BOT] Menerima file: {attachment.filename}")
        
        if attachment.filename.endswith(('.lua', '.txt')):
            await message.channel.send(f"⏳ Memproses `{attachment.filename}`...")
            
            input_filename = "temp_input.lua"
            output_filename = "obfuscated.lua"
            
            try:
                # 1. Simpan file dari Discord
                await attachment.save(input_filename)
                print(f"[BOT] File disimpan: {input_filename}")
                
                # 2. Baca isi file untuk debugging
                with open(input_filename, "r") as f:
                    content = f.read()
                print(f"[BOT] Isi file ({len(content)} chars):")
                print(content[:200])  # Print 200 karakter pertama
                
                # 3. Jalankan Lua Engine
                print("[BOT] Menjalankan Lua Engine...")
                process = subprocess.run(
                    ['lua5.1', 'engine/main.lua', input_filename],
                    capture_output=True,
                    text=True,
                    timeout=30,
                    cwd='/app'  # Pastikan working directory benar
                )
                
                # 4. Log SEMUA output dari Lua
                print(f"[LUA] Return Code: {process.returncode}")
                print(f"[LUA] STDOUT:\n{process.stdout}")
                print(f"[LUA] STDERR:\n{process.stderr}")
                
                # 5. Cek hasil
                if process.stdout and process.stdout.strip():
                    # Ada output, simpan dan kirim
                    with open(output_filename, "w") as f:
                        f.write(process.stdout)
                    
                    await message.channel.send(
                        content="✅ Berhasil!",
                        file=discord.File(output_filename)
                    )
                else:
                    # Tidak ada output
                    error_msg = process.stderr if process.stderr else "Tidak ada output dari Lua"
                    await message.channel.send(f"❌ Error:\n```\n{error_msg}\n```")
                    
            except subprocess.TimeoutExpired:
                await message.channel.send("❌ Timeout! Script terlalu lama.")
            except Exception as e:
                print(f"[BOT] Exception: {str(e)}")
                await message.channel.send(f"❌ System Error:\n```\n{str(e)}\n```")
        else:
            await message.channel.send("❌ Kirim file `.lua` saja.")

# --- BAGIAN 3: JALANKAN ---
if __name__ == '__main__':
    keep_alive()
    token = os.environ.get('DISCORD_TOKEN')
    if not token:
        print("[ERROR] DISCORD_TOKEN tidak ditemukan!")
    else:
        print("[BOT] Memulai dengan token...")
        client.run(token)
