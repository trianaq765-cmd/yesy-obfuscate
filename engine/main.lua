-- engine/main.lua (Versi Debug Sederhana)

-- Fix path untuk require
package.path = package.path .. ";./engine/?.lua;/app/engine/?.lua"

print("-- [DEBUG] Script Lua dimulai...")

-- Cek argumen
local filename = arg[1]
if not filename then
    print("-- [ERROR] Tidak ada file input")
    return
end

print("-- [DEBUG] File input: " .. filename)

-- Baca file
local f = io.open(filename, "rb")
if not f then
    print("-- [ERROR] Gagal buka file: " .. filename)
    return
end

local code = f:read("*a")
f:close()

print("-- [DEBUG] Berhasil baca file, ukuran: " .. #code .. " bytes")

-- Coba load parser
print("-- [DEBUG] Loading parser...")
local ok, parser = pcall(require, "parser")
if not ok then
    print("-- [ERROR] Gagal load parser:")
    print(parser)
    return
end

print("-- [DEBUG] Parser loaded!")

-- Coba parse
print("-- [DEBUG] Parsing code...")
local ok2, ast = pcall(function()
    return parser.ParseLua(code)
end)

if not ok2 then
    print("-- [ERROR] Gagal parse:")
    print(ast)
    return
end

print("-- [DEBUG] Parse berhasil!")
print("-- [SUCCESS] Semua berjalan lancar!")
print("")
print("-- Output sementara (kode asli):")
print(code)
