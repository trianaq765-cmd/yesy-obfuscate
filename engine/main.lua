-- engine/main.lua
-- === LUA OBFUSCATOR ENGINE V2 (ADVANCED) ===
-- Fitur: Variable Renaming + String Encryption + Number Obfuscation + Junk Code

package.path = package.path .. ";./?.lua;./engine/?.lua;/app/engine/?.lua"

local parser = require("parser")

-- ============================================
-- BAGIAN 1: UTILITAS
-- ============================================

math.randomseed(os.time())

-- Random Name Generator (Il1lI1_lI)
local usedNames = {}
local function generateRandomName()
    local charset = {"I", "l", "1", "_"}
    local name
    repeat
        name = "_"
        for i = 1, math.random(10, 18) do
            name = name .. charset[math.random(1, #charset)]
        end
    until not usedNames[name]
    usedNames[name] = true
    return name
end

-- Junk Variable Name Generator
local function generateJunkName()
    local prefixes = {"_G", "_V", "_X", "_Z", "_Q", "_W"}
    local name = prefixes[math.random(1, #prefixes)]
    for i = 1, math.random(5, 10) do
        name = name .. string.char(math.random(97, 122)) -- a-z
    end
    return name
end

-- XOR Function
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

-- Number Obfuscation
local function obfuscateNumber(num)
    local methods = {
        function(n) -- Addition
            local a = math.random(1, 1000)
            return "(" .. (n - a) .. "+" .. a .. ")"
        end,
        function(n) -- Subtraction
            local a = math.random(1, 1000)
            return "(" .. (n + a) .. "-" .. a .. ")"
        end,
        function(n) -- Multiplication + Addition
            if n > 10 then
                local a = math.random(2, 5)
                local remainder = n % a
                local base = (n - remainder) / a
                if remainder == 0 then
                    return "(" .. base .. "*" .. a .. ")"
                else
                    return "((" .. base .. "*" .. a .. ")+" .. remainder .. ")"
                end
            end
            return tostring(n)
        end,
        function(n) -- Double operation
            local a = math.random(50, 200)
            local b = math.random(50, 200)
            return "((" .. (n + a) .. "-" .. a .. ")+" .. b .. "-" .. b .. ")"
        end
    }
    
    -- Parse number
    local n = tonumber(num)
    if not n or n ~= math.floor(n) or n < 0 or n > 100000 then
        return num -- Return as-is for floats, negatives, or very large numbers
    end
    
    if n == 0 then return "(1-1)" end
    if n == 1 then return "(2-1)" end
    
    return methods[math.random(1, #methods)](n)
end

-- Generate Junk Code
local function generateJunkCode()
    local junkPatterns = {
        function()
            local v1 = generateJunkName()
            local v2 = generateJunkName()
            local n1 = math.random(1, 1000)
            local n2 = math.random(1, 1000)
            return "local " .. v1 .. "=" .. n1 .. ";local " .. v2 .. "=" .. n2 .. ";if " .. v1 .. ">" .. (n1 + 1) .. " then " .. v1 .. "=" .. v2 .. " end;"
        end,
        function()
            local v = generateJunkName()
            local n = math.random(100, 999)
            return "local " .. v .. "=(function() return " .. n .. " end)();"
        end,
        function()
            local v = generateJunkName()
            return "local " .. v .. "={};for _=" .. math.random(1,5) .. "," .. math.random(1,3) .. " do end;"
        end,
        function()
            local v = generateJunkName()
            local n1 = math.random(100, 500)
            local n2 = math.random(501, 999)
            return "local " .. v .. "=(" .. n1 .. "<" .. n2 .. ") and " .. n1 .. " or " .. n2 .. ";"
        end
    }
    return junkPatterns[math.random(1, #junkPatterns)]()
end

-- ============================================
-- BAGIAN 2: UNPARSER (AST -> CODE)
-- ============================================

local Unparser = {}

function Unparser:new()
    local obj = {
        varMap = {},
        encryptionKey = math.random(50, 200),
        encryptionKey2 = math.random(10, 50), -- Second layer key
        output = "",
        junkCounter = 0,
        junkInterval = math.random(3, 6) -- Insert junk every N statements
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Unparser:emit(str)
    self.output = self.output .. str
end

function Unparser:maybeInsertJunk()
    self.junkCounter = self.junkCounter + 1
    if self.junkCounter >= self.junkInterval then
        self.junkCounter = 0
        self.junkInterval = math.random(3, 6)
        self:emit(generateJunkCode())
    end
end

function Unparser:getNewVarName(oldName)
    -- Extensive globals list for Roblox support
    local globals = {
        -- Lua Standard
        ["print"] = true, ["warn"] = true, ["error"] = true,
        ["pairs"] = true, ["ipairs"] = true, ["next"] = true,
        ["tonumber"] = true, ["tostring"] = true, ["type"] = true,
        ["pcall"] = true, ["xpcall"] = true, ["assert"] = true,
        ["select"] = true, ["unpack"] = true, ["pack"] = true,
        ["rawget"] = true, ["rawset"] = true, ["rawequal"] = true,
        ["setmetatable"] = true, ["getmetatable"] = true,
        ["loadstring"] = true, ["loadfile"] = true, ["dofile"] = true,
        ["collectgarbage"] = true, ["gcinfo"] = true,
        ["newproxy"] = true, ["require"] = true,
        
        -- Lua Libraries
        ["math"] = true, ["string"] = true, ["table"] = true,
        ["coroutine"] = true, ["debug"] = true, ["os"] = true,
        ["io"] = true, ["bit"] = true, ["bit32"] = true,
        ["utf8"] = true,
        
        -- Global Tables
        ["_G"] = true, ["_VERSION"] = true, ["shared"] = true,
        
        -- Roblox Services
        ["game"] = true, ["workspace"] = true, ["script"] = true,
        ["plugin"] = true, ["Enum"] = true, ["Faces"] = true,
        ["Axes"] = true,
        
        -- Roblox Data Types
        ["Instance"] = true, ["Vector2"] = true, ["Vector3"] = true,
        ["CFrame"] = true, ["Color3"] = true, ["UDim"] = true,
        ["UDim2"] = true, ["Rect"] = true, ["Region3"] = true,
        ["Ray"] = true, ["BrickColor"] = true, ["TweenInfo"] = true,
        ["NumberSequence"] = true, ["ColorSequence"] = true,
        ["NumberSequenceKeypoint"] = true, ["ColorSequenceKeypoint"] = true,
        ["PhysicalProperties"] = true, ["NumberRange"] = true,
        ["Random"] = true, ["DateTime"] = true, ["PathWaypoint"] = true,
        ["OverlapParams"] = true, ["RaycastParams"] = true,
        ["DockWidgetPluginGuiInfo"] = true, ["Font"] = true,
        ["RotationCurveKey"] = true, ["FloatCurveKey"] = true,
        
        -- Roblox Functions
        ["typeof"] = true, ["spawn"] = true, ["delay"] = true,
        ["wait"] = true, ["tick"] = true, ["time"] = true,
        ["elapsedTime"] = true, ["settings"] = true, ["stats"] = true,
        ["UserSettings"] = true, ["version"] = true, ["printidentity"] = true,
        ["DebuggerManager"] = true, ["LoadLibrary"] = true,
        
        -- Roblox Task Library
        ["task"] = true,
        
        -- Executor Globals
        ["getgenv"] = true, ["getrenv"] = true, ["getfenv"] = true,
        ["setfenv"] = true, ["getsenv"] = true, ["getrawmetatable"] = true,
        ["setrawmetatable"] = true, ["setreadonly"] = true,
        ["isreadonly"] = true, ["hookfunction"] = true,
        ["hookmetamethod"] = true, ["newcclosure"] = true,
        ["islclosure"] = true, ["iscclosure"] = true,
        ["getnamecallmethod"] = true, ["setnamecallmethod"] = true,
        ["checkcaller"] = true, ["getcallingscript"] = true,
        ["getinfo"] = true, ["getupvalue"] = true, ["setupvalue"] = true,
        ["getupvalues"] = true, ["getconstant"] = true, ["setconstant"] = true,
        ["getconstants"] = true, ["getproto"] = true, ["getprotos"] = true,
        ["getstack"] = true, ["setstack"] = true, ["getconnections"] = true,
        ["firesignal"] = true, ["fireclickdetector"] = true,
        ["fireproximityprompt"] = true, ["firetouchinterest"] = true,
        ["isnetworkowner"] = true, ["gethiddenproperty"] = true,
        ["sethiddenproperty"] = true, ["setsimulationradius"] = true,
        ["getinstances"] = true, ["getnilinstances"] = true,
        ["getscripts"] = true, ["getrunningscripts"] = true,
        ["getloadedmodules"] = true, ["getcustomasset"] = true,
        ["cloneref"] = true, ["compareinstances"] = true,
        ["isexecutorclosure"] = true, ["issynapsefunction"] = true,
        ["Drawing"] = true, ["cleardrawcache"] = true,
        ["getrenderproperty"] = true, ["isrenderobj"] = true,
        ["setrenderproperty"] = true, ["setclipboard"] = true,
        ["setfflag"] = true, ["getfflag"] = true,
        ["syn"] = true, ["fluxus"] = true, ["getexecutorname"] = true,
        ["identifyexecutor"] = true, ["request"] = true, ["http_request"] = true,
        ["HttpGet"] = true, ["HttpPost"] = true, ["GetObjects"] = true,
        ["readfile"] = true, ["writefile"] = true, ["appendfile"] = true,
        ["loadfile"] = true, ["listfiles"] = true, ["isfile"] = true,
        ["isfolder"] = true, ["makefolder"] = true, ["delfolder"] = true,
        ["delfile"] = true, ["crypt"] = true, ["base64"] = true,
        ["lz4"] = true, ["lz4compress"] = true, ["lz4decompress"] = true,
        ["messagebox"] = true, ["rconsolewarn"] = true, ["rconsoleprint"] = true,
        ["rconsoleerr"] = true, ["rconsoleclear"] = true, ["rconsolename"] = true,
        ["rconsoleinput"] = true, ["rconsoleinfo"] = true, ["consolecreate"] = true,
        ["consoledestroy"] = true, ["consoleinput"] = true, ["consoleprint"] = true,
        ["consoleclear"] = true, ["consolesettitle"] = true,
        ["mouse1click"] = true, ["mouse1press"] = true, ["mouse1release"] = true,
        ["mouse2click"] = true, ["mouse2press"] = true, ["mouse2release"] = true,
        ["mousemoverel"] = true, ["mousemoveabs"] = true, ["mousescroll"] = true,
        ["keypress"] = true, ["keyrelease"] = true, ["keyclick"] = true,
        ["iswindowactive"] = true, ["getgc"] = true, ["queue_on_teleport"] = true,
        
        -- Obfuscator Runtime
        ["DEC"] = true, ["_XOR"] = true,
        
        -- Boolean/Nil
        ["true"] = true, ["false"] = true, ["nil"] = true,
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
    if not str or str == "" then
        return '""'
    end
    
    local encrypted = xorEncrypt(str, self.encryptionKey)
    local numStr = "{"
    for i, v in ipairs(encrypted) do
        -- Also obfuscate the encrypted bytes occasionally
        if math.random(1, 3) == 1 and v > 10 then
            numStr = numStr .. obfuscateNumber(v)
        else
            numStr = numStr .. v
        end
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
            self:maybeInsertJunk()
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
    
    -- MEMBER EXPRESSION (a.b atau a:b)
    elseif t == "MemberExpr" then
        self:processNode(node.Base)
        self:emit(node.Indexer)
        self:emit(node.Ident.Data)
    
    -- INDEX EXPRESSION (a[b])
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
    
    -- NUMBER (OBFUSCATE!)
    elseif t == "NumberExpr" then
        local numVal = node.Value.Data
        -- Obfuscate integers, keep floats/hex as-is
        if numVal:match("^%d+$") then
            self:emit(obfuscateNumber(numVal))
        else
            self:emit(numVal)
        end
    
    -- BOOLEAN
    elseif t == "BooleanExpr" then
        if node.Value then
            -- Obfuscate true
            if math.random(1, 2) == 1 then
                self:emit("(1==1)")
            else
                self:emit("true")
            end
        else
            -- Obfuscate false
            if math.random(1, 2) == 1 then
                self:emit("(1==0)")
            else
                self:emit("false")
            end
        end
    
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
        elseif node.Op == "-" then
            self:emit("-")
        else
            self:emit(node.Op)
        end
        self:processNode(node.Rhs)
    
    -- FUNCTION DEFINITION
    elseif t == "Function" then
        if node.IsLocal then
            if node.Name then
                self:emit("local function ")
                if type(node.Name) == "table" and node.Name.Name then
                    local newName = self:getNewVarName(node.Name.Name)
                    self:emit(newName)
                elseif type(node.Name) == "string" then
                    local newName = self:getNewVarName(node.Name)
                    self:emit(newName)
                else
                    self:processNode(node.Name)
                end
            else
                self:emit("function")
            end
        else
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
    
    -- DOTS (...)
    elseif t == "DotsExpr" then
        self:emit("...")
    
    -- EOF
    elseif t == "Eof" then
        -- Nothing
    
    -- LABEL (::label::)
    elseif t == "LabelStatement" then
        self:emit("::" .. node.Label .. ":: ")
    
    -- GOTO
    elseif t == "GotoStatement" then
        self:emit("goto " .. node.Label .. " ")
    end
end

-- ============================================
-- BAGIAN 3: RUNTIME DECRYPTOR (ENHANCED)
-- ============================================

local RUNTIME_CODE = [[
-- Protected by LuaObf Engine V2
local _ENV=_ENV or getfenv();local function _XOR(a,b)local r,m=0,1;while a>0 or b>0 do local x,y=a%2,b%2;if x~=y then r=r+m end;a,b=math.floor(a/2),math.floor(b/2);m=m*2 end;return r end;local function DEC(t,k)local r={};for i=1,#t do local v=t[i];if type(v)=="string" then v=tonumber(v) end;r[i]=string.char(_XOR(v,k))end;return table.concat(r)end;
]]

-- ============================================
-- BAGIAN 4: JUNK CODE PREFIX
-- ============================================

local function generateJunkPrefix()
    local junk = ""
    for i = 1, math.random(3, 6) do
        junk = junk .. generateJunkCode()
    end
    return junk
end

-- ============================================
-- BAGIAN 5: MAIN EXECUTION
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

-- Generate final code with junk prefix
local junkPrefix = generateJunkPrefix()
local finalCode = RUNTIME_CODE .. junkPrefix .. "\n" .. unparser.output

-- Minify: Remove extra spaces and newlines
finalCode = finalCode:gsub("\n+", " ")
finalCode = finalCode:gsub("  +", " ")

-- Output
print(finalCode)        ["tonumber"] = true, ["tostring"] = true, ["type"] = true,
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
