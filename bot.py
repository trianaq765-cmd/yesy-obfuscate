import discord
import os
import subprocess
from flask import Flask
from threading import Thread

# --- BAGIAN 1: WEBSITE MINI (Agar Render Tidak Tidur) ---
app = Flask(__name__)

@app.route('/')
def home():
    return "Bot is Alive! 🤖"

def run_web_server():
    # Port 8080 adalah port default yang dicari Render
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
    print(f'Bot sudah online sebagai {client.user}')

@client.event
async def on_message(message):
    if message.author == client.user:
        return

    if message.attachments:
        attachment = message.attachments[0]
        if attachment.filename.endswith(('.lua', '.txt')):
            await message.channel.send(f"⏳ Sedang memproses: `{attachment.filename}`...")
            
            input_filename = "temp_input.lua"
            await attachment.save(input_filename)
            
            try:
                # Menjalankan Lua Engine
                process = subprocess.run(
                    ['lua5.1', 'engine/main.lua', input_filename],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                output_filename = "obfuscated.lua"
                # Jika output kosong, isi dengan pesan error atau default
                hasil_akhir = process.stdout if process.stdout else "-- Tidak ada output / Error"

                with open(output_filename, "w") as f:
                    f.write(hasil_akhir)
                        
                await message.channel.send(
                    content=f"✅ Selesai! (Exit Code: {process.returncode})",
                    file=discord.File(output_filename)
                )

            except Exception as e:
                await message.channel.send(f"❌ System Error: {str(e)}")
        else:
            await message.channel.send("❌ Mohon kirim file .lua")

# --- BAGIAN 3: EKSEKUSI ---
if __name__ == '__main__':
    # 1. Nyalakan Website Palsu dulu
    keep_alive()
    
    # 2. Nyalakan Bot Discord
    token = os.environ.get('DISCORD_TOKEN')
    if not token:
        print("Error: DISCORD_TOKEN belum di-set di Environment Variable!")
    else:
        client.run(token)
