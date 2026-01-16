-- engine/main.lua
local parser_mod = require("parser")

-- 1. Ambil nama file dari argumen command line (dikirim oleh Python)
local filename = arg[1]

if not filename then
    print("Error: Tidak ada file input!")
    return
end

-- 2. Baca file tersebut
local f = io.open(filename, "rb")
if not f then
    print("Error: File tidak ditemukan -> " .. filename)
    return
end
local code = f:read("*a") -- Baca seluruh isi file
f:close()

print("[-] Menerima file untuk diproses...")

-- 3. Parse Kode (Menggunakan Stravant Parser)
local status, ast = pcall(function()
    return parser_mod.ParseLua(code)
end)

if status then
    -- DISINI NANTI LOGIKA OBFUSCATOR ANDA (XOR, VM, DLL)
    -- Untuk sekarang, kita hanya akan membuktikan file terbaca
    print("[+] SUKSES: File Lua valid!")
    print("[+] Ukuran File: " .. #code .. " bytes")
    
    -- Simulasi output (Nanti kita ganti jadi kode hasil obfuscate)
    print("--------------------------------")
    print("-- WATERMARK: PROCESSED BY BOT --")
    print(code) -- Print ulang kode aslinya dulu
else
    print("[!] ERROR: Script Lua User error/invalid syntax.")
    print(ast)
end
