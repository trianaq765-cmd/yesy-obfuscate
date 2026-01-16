-- engine/main.lua (Versi Debugging)

-- 1. Cek apakah Parser ada
local status_pkg, parser = pcall(require, "parser")
if not status_pkg then
    print("-- [FATAL ERROR] Library Parser tidak ditemukan!")
    print("-- Pastikan file 'parser.lua' ada di folder yang sama.")
    print("-- Error Detail: " .. tostring(parser))
    return
end

-- 2. Cek File Input
local filename = arg[1]
if not filename then
    print("-- [ERROR] Tidak ada nama file input.")
    return
end

local f = io.open(filename, "rb")
if not f then
    print("-- [ERROR] Tidak bisa membuka file: " .. filename)
    return
end
local code = f:read("*a")
f:close()

-- 3. Coba Parse
local status_parse, ast = pcall(function()
    return parser.ParseLua(code)
end)

if not status_parse then
    print("-- [ERROR] Gagal Parsing Script User.")
    print("-- Syntax Error di script asli Anda?")
    print("-- Detail: " .. tostring(ast))
    return
end

-- Jika sampai sini, berarti aman. Lanjut ke Unparser (Kode sebelumnya...)
-- Masukkan kode fungsi generateRandomName, encryptString, unparse di sini...

-- (Agar pendek, saya taruh contoh output sukses saja dulu)
print("-- [DEBUG] PARSE SUKSES!")
print("-- Kode asli panjangnya: " .. #code .. " karakter")
print("-- AST Tipe: " .. type(ast))
print("print('Halo dari Bot yang sudah diperbaiki')")     local xx,yy=a%2,b%2
    if xx~=yy then r=r+m end
    a,b=math.floor(a/2),math.floor(b/2)
    m=m*2
  end
  return r
end

_G.DEC = function(str, key)
    local res = {}
    for s in str:gmatch("\\(%d+)") do
        table.insert(res, string.char(bxor(tonumber(s), key)))
    end
    return table.concat(res)
end
]]

-- 3. Unparse & Obfuscate
-- Kita bungkus kode user dengan scope kosong
local obfuscatedBody = unparse(ast, {})

-- 4. Gabungkan Runtime + Kode Hasil
local finalResult = runtime .. "\n\n" .. obfuscatedBody

-- 5. Print Output (Ditangkap oleh Python)
print(finalResult)
