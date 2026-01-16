-- engine/main.lua
-- === ENGINE OBFUSCATOR V1 (Renaming + String Encryption) ===

local parser = require("parser") -- Load library Stravant

-- 1. UTILITIES: Fungsi untuk membuat nama acak (Il1l1...)
local function generateRandomName()
    local charset = {"I", "l", "1", "_"}
    local name = "_"
    for i = 1, math.random(8, 15) do
        name = name .. charset[math.random(1, #charset)]
    end
    return name
end

-- 2. UTILITIES: String Encryption (XOR Sederhana)
local function encryptString(str, key)
    local result = {}
    for i = 1, #str do
        local b = string.byte(str, i)
        -- Logika XOR manual untuk Lua 5.1
        local xor_val = 0
        local pow = 1
        local m, n = b, key
        while m > 0 or n > 0 do
            local am, an = m % 2, n % 2
            if am ~= an then xor_val = xor_val + pow end
            m = math.floor(m / 2)
            n = math.floor(n / 2)
            pow = pow * 2
        end
        table.insert(result, "\\" .. xor_val)
    end
    return table.concat(result)
end

-- 3. THE UNPARSER (Mengubah AST kembali jadi Code)
-- Ini adalah bagian tersulit: menyusun ulang potongan puzzle
local function unparse(ast, scope)
    if not ast then return "" end
    
    -- Mapping Variabel Lama -> Variabel Baru
    scope = scope or {}
    
    local type = ast.Type
    
    if type == "StatList" then
        local code = ""
        for _, node in ipairs(ast.StatementList) do
            code = code .. unparse(node, scope) .. " "
        end
        return code

    elseif type == "CallExpression" then
        local base = unparse(ast.Base, scope)
        local args = ""
        for i, arg in ipairs(ast.Arguments) do
            args = args .. unparse(arg, scope) .. (i < #ast.Arguments and "," or "")
        end
        return base .. "(" .. args .. ")"

    elseif type == "StringLiteral" then
        -- FITUR: ENKRIPSI STRING OTOMATIS
        local content = ast.Token.Source
        -- Hapus tanda kutip awal/akhir
        content = content:sub(2, #content-1)
        
        local key = math.random(1, 100)
        local encrypted = encryptString(content, key)
        
        -- Kita ganti string jadi fungsi decrypt runtime
        -- Format: _G.DECRYPT("...angka...", key)
        return "_G.DEC(\"" .. encrypted .. "\", " .. key .. ")"

    elseif type == "NumberLiteral" then
        return ast.Token.Source

    elseif type == "Variable" then
        local name = ast.Token.Source
        -- Cek apakah variabel ini harus direname (ada di scope)
        if scope[name] then
            return scope[name]
        else
            return name -- Global variable (print, game, workspace) jangan diubah
        end
    
    elseif type == "LocalVarStat" then
        local vars = ""
        local values = ""
        
        -- Generate nama baru untuk setiap variabel lokal
        for i, varName in ipairs(ast.VarList) do
            local oldName = varName.Token.Source
            local newName = generateRandomName()
            scope[oldName] = newName -- Simpan di database scope
            
            vars = vars .. newName .. (i < #ast.VarList and "," or "")
        end
        
        for i, val in ipairs(ast.ValueList) do
            values = values .. unparse(val, scope) .. (i < #ast.ValueList and "," or "")
        end
        
        return "local " .. vars .. (values ~= "" and " = " .. values or "") .. ";"

    elseif type == "AssignmentStat" then
        local vars = ""
        local values = ""
        for i, v in ipairs(ast.Lhs) do
            vars = vars .. unparse(v, scope) .. (i < #ast.Lhs and "," or "")
        end
        for i, v in ipairs(ast.Rhs) do
            values = values .. unparse(v, scope) .. (i < #ast.Rhs and "," or "")
        end
        return vars .. " = " .. values .. ";"
        
    elseif type == "FunctionLiteral" then
        local args = ""
        -- Rename Argumen Fungsi
        local newScope = {} 
        -- Copy scope lama ke scope baru (inherit)
        for k,v in pairs(scope) do newScope[k] = v end
        
        for i, arg in ipairs(ast.ArgList) do
            local old = arg.Token.Source
            local new = generateRandomName()
            newScope[old] = new
            args = args .. new .. (i < #ast.ArgList and "," or "")
        end
        
        local body = unparse(ast.Body, newScope)
        return "function(" .. args .. ") " .. body .. " end"
    end
    
    -- Fallback sederhana (untuk tipe node yang belum ke-handle)
    -- Di versi Luraph asli, semua tipe node harus di-handle manual.
    return "" 
end


-- ==========================================
-- MAIN EXECUTION
-- ==========================================

local filename = arg[1]
if not filename then return end

local f = io.open(filename, "rb")
local code = f:read("*a")
f:close()

-- 1. Parse
local success, ast = pcall(parser.ParseLua, code)

if not success then
    print("-- ERROR: Gagal Parse Script")
    print(ast)
    return
end

-- 2. Siapkan "Runtime Decryptor"
-- Ini adalah fungsi yang wajib disertakan agar string bisa dibaca lagi
local runtime = [[
local function bxor(a,b)
  local r,m=0,1
  while a>0 or b>0 do
    local xx,yy=a%2,b%2
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
