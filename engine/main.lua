-- engine/main.lua

-- 1. Setup Path (Agar Lua menemukan parser di folder yang sama)
-- Kita tambah "./?.lua" dan "/app/engine/?.lua"
package.path = package.path .. ";./?.lua;./engine/?.lua;/app/engine/?.lua"

-- 2. Load Parser (Yang sudah Full Version)
local status_lib, parser = pcall(require, "parser")

if not status_lib then
    print("[FATAL ERROR] Parser tidak bisa di-load!")
    print("Error: " .. tostring(parser))
    return
end

-- 3. Baca File Input dari Python
local filename = arg[1]
if not filename then
    print("[ERROR] Tidak ada input file.")
    return
end

local f = io.open(filename, "rb")
if not f then
    print("[ERROR] Gagal membuka file.")
    return
end
local code = f:read("*a")
f:close()

print("[-] Memproses file: " .. filename)
print("[-] Ukuran kode: " .. #code .. " bytes")

-- 4. EKSEKUSI PARSING
local status, ast = pcall(function()
    return parser.ParseLua(code)
end)

if status then
    print("\n✅ [SUKSES] PARSING BERHASIL!")
    print("-------------------------------------------------")
    print("Struktur kode berhasil dibaca komputer.")
    print("Tipe AST Root: " .. tostring(ast.AstType)) -- Harusnya "Statlist"
    print("Jumlah Statement: " .. #ast.Body)
    print("-------------------------------------------------")
    
    -- Cetak ulang kode asli sebagai bukti output tidak error
    print("\n-- [OUTPUT SEMENTARA: KODE ASLI]")
    print(code)
else
    print("\n❌ [GAGAL] PARSING ERROR")
    print("Pesan Error:")
    print(ast)
end
