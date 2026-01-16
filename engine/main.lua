-- engine/main.lua
-- === LUA OBFUSCATOR ENGINE V1 (FIXED) ===
-- Fitur: Variable Renaming + String Encryption

package.path = package.path .. ";./?.lua;./engine/?.lua;/app/engine/?.lua"

local parser = require("parser")

-- ============================================
-- BAGIAN 1: UTILITAS
-- ============================================

-- Random Name Generator (Il1lI1_lI)
local function generateRandomName()
    local charset = {"I", "l", "1", "_"}
    local name = "_"
    for i = 1, math.random(8, 14) do
        name = name .. charset[math.random(1, #charset)]
    end
    return name
end

-- XOR Function (Untuk enkripsi string)
local function xorEncrypt(str, key)
    local result = {}
    for i = 1, #str do
        local byte = string.byte(str, i)
        local xored = 0
        local pow = 1
        local a, b = byte, key
        while a > 0 or b > 0 do
            local aa, bb = a % 2, b % 2
            if aa ~= bb then xored = xored + pow end
            a = math.floor(a / 2)
            b = math.floor(b / 2)
            pow = pow * 2
        end
        table.insert(result, xored)
    end
    return result
end

-- ============================================
-- BAGIAN 2: UNPARSER (AST -> CODE)
-- ============================================

local Unparser = {}

function Unparser:new()
    local obj = {
        varMap = {},
        encryptionKey = math.random(50, 200),
        output = ""
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Unparser:emit(str)
    self.output = self.output .. str
end

function Unparser:getNewVarName(oldName)
    local globals = {
        ["print"] = true, ["game"] = true, ["workspace"] = true,
        ["script"] = true, ["math"] = true, ["string"] = true,
        ["table"] = true, ["pairs"] = true, ["ipairs"] = true,
        ["tonumber"] = true, ["tostring"] = true, ["type"] = true,
        ["pcall"] = true, ["xpcall"] = true, ["error"] = true,
        ["assert"] = true, ["require"] = true, ["select"] = true,
        ["next"] = true, ["rawget"] = true, ["rawset"] = true,
        ["setmetatable"] = true, ["getmetatable"] = true,
        ["coroutine"] = true, ["debug"] = true, ["os"] = true,
        ["io"] = true, ["_G"] = true, ["_VERSION"] = true,
        ["collectgarbage"] = true, ["loadstring"] = true,
        ["unpack"] = true, ["wait"] = true, ["spawn"] = true,
        ["delay"] = true, ["tick"] = true, ["time"] = true,
        ["typeof"] = true, ["Instance"] = true, ["Vector3"] = true,
        ["CFrame"] = true, ["Color3"] = true, ["UDim2"] = true,
        ["Enum"] = true, ["task"] = true, ["true"] = true,
        ["false"] = true, ["nil"] = true, ["DEC"] = true,
        ["_XOR"] = true, ["warn"] = true, ["getfenv"] = true,
        ["setfenv"] = true, ["loadfile"] = true, ["dofile"] = true,
    }
    
    if globals[oldName] then
        return oldName
    end
    
    if not self.varMap[oldName] then
        self.varMap[oldName] = generateRandomName()
    end
    return self.varMap[oldName]
end

function Unparser:encryptString(str)
    local encrypted = xorEncrypt(str, self.encryptionKey)
    local numStr = "{"
    for i, v in ipairs(encrypted) do
        numStr = numStr .. v
        if i < #encrypted then numStr = numStr .. "," end
    end
    numStr = numStr .. "}"
    return "DEC(" .. numStr .. "," .. self.encryptionKey .. ")"
end

function Unparser:processNode(node)
    if not node then return end
    
    local t = node.AstType
    
    -- STATLIST
    if t == "Statlist" then
        for _, stmt in ipairs(node.Body) do
            self:processNode(stmt)
        end
    
    -- LOCAL STATEMENT
    elseif t == "LocalStatement" then
        self:emit("local ")
        for i, var in ipairs(node.LocalList) do
            local newName = self:getNewVarName(var.Name)
            self:emit(newName)
            if i < #node.LocalList then self:emit(",") end
        end
        if #node.InitList > 0 then
            self:emit("=")
            for i, expr in ipairs(node.InitList) do
                self:processNode(expr)
                if i < #node.InitList then self:emit(",") end
            end
        end
        self:emit("; ")
    
    -- ASSIGNMENT
    elseif t == "AssignmentStatement" then
        for i, lhs in ipairs(node.Lhs) do
            self:processNode(lhs)
            if i < #node.Lhs then self:emit(",") end
        end
        self:emit("=")
        for i, rhs in ipairs(node.Rhs) do
            self:processNode(rhs)
            if i < #node.Rhs then self:emit(",") end
        end
        self:emit("; ")
    
    -- CALL STATEMENT
    elseif t == "CallStatement" then
        self:processNode(node.Expression)
        self:emit("; ")
    
    -- CALL EXPRESSION
    elseif t == "CallExpr" then
        self:processNode(node.Base)
        self:emit("(")
        for i, arg in ipairs(node.Arguments) do
            self:processNode(arg)
            if i < #node.Arguments then self:emit(",") end
        end
        self:emit(")")
    
    -- STRING CALL
    elseif t == "StringCallExpr" then
        self:processNode(node.Base)
        self:emit("(")
        for i, arg in ipairs(node.Arguments) do
            self:processNode(arg)
            if i < #node.Arguments then self:emit(",") end
        end
        self:emit(")")
    
    -- TABLE CALL
    elseif t == "TableCallExpr" then
        self:processNode(node.Base)
        self:emit("(")
        for i, arg in ipairs(node.Arguments) do
            self:processNode(arg)
            if i < #node.Arguments then self:emit(",") end
        end
        self:emit(")")
    
    -- VARIABLE EXPRESSION
    elseif t == "VarExpr" then
        local newName = self:getNewVarName(node.Name)
        self:emit(newName)
    
    -- MEMBER EXPRESSION
    elseif t == "MemberExpr" then
        self:processNode(node.Base)
        self:emit(node.Indexer)
        self:emit(node.Ident.Data)
    
    -- INDEX EXPRESSION
    elseif t == "IndexExpr" then
        self:processNode(node.Base)
        self:emit("[")
        self:processNode(node.Index)
        self:emit("]")
    
    -- STRING EXPRESSION (ENKRIPSI!)
    elseif t == "StringExpr" then
        local rawStr = node.Value.Constant or ""
        local encrypted = self:encryptString(rawStr)
        self:emit(encrypted)
    
    -- NUMBER
    elseif t == "NumberExpr" then
        self:emit(node.Value.Data)
    
    -- BOOLEAN
    elseif t == "BooleanExpr" then
        self:emit(node.Value and "true" or "false")
    
    -- NIL
    elseif t == "NilExpr" then
        self:emit("nil")
    
    -- PARENTHESES
    elseif t == "Parentheses" then
        self:emit("(")
        self:processNode(node.Inner)
        self:emit(")")
    
    -- BINARY OPERATION
    elseif t == "BinopExpr" then
        self:processNode(node.Lhs)
        self:emit(" " .. node.Op .. " ")
        self:processNode(node.Rhs)
    
    -- UNARY OPERATION
    elseif t == "UnopExpr" then
        if node.Op == "not" then
            self:emit("not ")
        else
            self:emit(node.Op)
        end
        self:processNode(node.Rhs)
    
    -- FUNCTION DEFINITION (FIXED!)
    elseif t == "Function" then
        if node.IsLocal then
            if node.Name then
                -- local function namaFungsi(...)
                self:emit("local function ")
                if type(node.Name) == "table" and node.Name.Name then
                    local newName = self:getNewVarName(node.Name.Name)
                    self:emit(newName)
                else
                    self:processNode(node.Name)
                end
            else
                -- Anonymous function: function(...)
                self:emit("function")
            end
        else
            -- Global function: function name(...)
            self:emit("function ")
            if node.Name then
                self:processNode(node.Name)
            end
        end
        self:emit("(")
        for i, arg in ipairs(node.Arguments) do
            local newName = self:getNewVarName(arg.Name)
            self:emit(newName)
            if i < #node.Arguments then self:emit(",") end
        end
        if node.VarArg then
            if #node.Arguments > 0 then self:emit(",") end
            self:emit("...")
        end
        self:emit(") ")
        self:processNode(node.Body)
        self:emit("end ")
    
    -- IF STATEMENT
    elseif t == "IfStatement" then
        for i, clause in ipairs(node.Clauses) do
            if i == 1 then
                self:emit("if ")
                self:processNode(clause.Condition)
                self:emit(" then ")
            elseif clause.Condition then
                self:emit("elseif ")
                self:processNode(clause.Condition)
                self:emit(" then ")
            else
                self:emit("else ")
            end
            self:processNode(clause.Body)
        end
        self:emit("end ")
    
    -- WHILE LOOP
    elseif t == "WhileStatement" then
        self:emit("while ")
        self:processNode(node.Condition)
        self:emit(" do ")
        self:processNode(node.Body)
        self:emit("end ")
    
    -- NUMERIC FOR LOOP
    elseif t == "NumericForStatement" then
        self:emit("for ")
        local newVar = self:getNewVarName(node.Variable.Name)
        self:emit(newVar .. "=")
        self:processNode(node.Start)
        self:emit(",")
        self:processNode(node.End)
        if node.Step then
            self:emit(",")
            self:processNode(node.Step)
        end
        self:emit(" do ")
        self:processNode(node.Body)
        self:emit("end ")
    
    -- GENERIC FOR LOOP
    elseif t == "GenericForStatement" then
        self:emit("for ")
        for i, var in ipairs(node.VariableList) do
            local newName = self:getNewVarName(var.Name)
            self:emit(newName)
            if i < #node.VariableList then self:emit(",") end
        end
        self:emit(" in ")
        for i, gen in ipairs(node.Generators) do
            self:processNode(gen)
            if i < #node.Generators then self:emit(",") end
        end
        self:emit(" do ")
        self:processNode(node.Body)
        self:emit("end ")
    
    -- REPEAT UNTIL
    elseif t == "RepeatStatement" then
        self:emit("repeat ")
        self:processNode(node.Body)
        self:emit("until ")
        self:processNode(node.Condition)
        self:emit(" ")
    
    -- DO BLOCK
    elseif t == "DoStatement" then
        self:emit("do ")
        self:processNode(node.Body)
        self:emit("end ")
    
    -- RETURN
    elseif t == "ReturnStatement" then
        self:emit("return ")
        for i, arg in ipairs(node.Arguments) do
            self:processNode(arg)
            if i < #node.Arguments then self:emit(",") end
        end
        self:emit(" ")
    
    -- BREAK
    elseif t == "BreakStatement" then
        self:emit("break ")
    
    -- TABLE CONSTRUCTOR
    elseif t == "ConstructorExpr" then
        self:emit("{")
        for i, entry in ipairs(node.EntryList) do
            if entry.Type == "Key" then
                self:emit("[")
                self:processNode(entry.Key)
                self:emit("]=")
                self:processNode(entry.Value)
            elseif entry.Type == "KeyString" then
                self:emit(entry.Key .. "=")
                self:processNode(entry.Value)
            else
                self:processNode(entry.Value)
            end
            if i < #node.EntryList then self:emit(",") end
        end
        self:emit("}")
    
    -- DOTS
    elseif t == "DotsExpr" then
        self:emit("...")
    
    -- EOF
    elseif t == "Eof" then
        -- Nothing
    end
end

-- ============================================
-- BAGIAN 3: RUNTIME DECRYPTOR
-- ============================================

local RUNTIME_CODE = [[
-- Obfuscated by LuaObf Bot
local function _XOR(a,b)local r,m=0,1;while a>0 or b>0 do local x,y=a%2,b%2;if x~=y then r=r+m end;a,b=math.floor(a/2),math.floor(b/2);m=m*2 end;return r end
local function DEC(t,k)local r={};for i=1,#t do r[i]=string.char(_XOR(t[i],k))end;return table.concat(r)end
]]

-- ============================================
-- BAGIAN 4: MAIN EXECUTION
-- ============================================

local filename = arg[1]
if not filename then
    print("-- [ERROR] No input file")
    return
end

local f = io.open(filename, "rb")
if not f then
    print("-- [ERROR] Cannot open file")
    return
end
local code = f:read("*a")
f:close()

-- Parse
local success, ast = parser.ParseLua(code)

if not success then
    print("-- [ERROR] Parsing failed:")
    print(ast)
    return
end

-- Obfuscate
local unparser = Unparser:new()
unparser:processNode(ast)

-- Combine Runtime + Obfuscated Code
local finalCode = RUNTIME_CODE .. "\n" .. unparser.output

-- Output
print(finalCode)
