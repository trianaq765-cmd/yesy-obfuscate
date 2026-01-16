import discord
import os
import subprocess

# Setup Bot
intents = discord.Intents.default()
intents.message_content = True # Wajib aktif
client = discord.Client(intents=intents)

@client.event
async def on_ready():
    print(f'Bot sudah online sebagai {client.user}')

@client.event
async def on_message(message):
    # Abaikan pesan dari bot sendiri
    if message.author == client.user:
        return

    # Cek apakah user mengirim file attachment
    if message.attachments:
        attachment = message.attachments[0]
        
        # Cek apakah file berakhiran .lua atau .txt
        if attachment.filename.endswith(('.lua', '.txt')):
            await message.channel.send(f"⏳ Sedang memproses: `{attachment.filename}`...")
            
            # 1. Simpan file user sementara
            input_filename = "temp_input.lua"
            await attachment.save(input_filename)
            
            # 2. Panggil ENGINE LUA lewat Terminal (Subprocess)
            # Perintah: lua5.1 engine/main.lua temp_input.lua
            try:
                process = subprocess.run(
                    ['lua5.1', 'engine/main.lua', input_filename],
                    capture_output=True, # Tangkap output print() dari Lua
                    text=True,
                    timeout=10 # Batas waktu 10 detik agar bot tidak hang
                )
                
                # 3. Ambil hasil output dari Lua
                lua_output = process.stdout
                
                if process.returncode == 0:
                    # Kirim hasil balik ke Discord sebagai file
                    # Kita simpan output ke file baru
                    output_filename = "obfuscated.lua"
                    with open(output_filename, "w") as f:
                        f.write(lua_output)
                        
                    await message.channel.send(
                        content=f"✅ Selesai! (Exit Code: {process.returncode})",
                        file=discord.File(output_filename)
                    )
                else:
                    # Jika Lua Error
                    await message.channel.send(f"❌ Terjadi Error di Engine Lua:\n```{process.stdout}```")

            except Exception as e:
                await message.channel.send(f"❌ System Error: {str(e)}")
            
        else:
            await message.channel.send("❌ Mohon kirim file format .lua")

# Jalankan Bot (Token diambil dari Environment Variable agar aman)
# Nanti kita set TOKEN lewat Docker
client.run(os.environ.get('DISCORD_TOKEN'))
