package.path=package.path..";./?.lua;./engine/?.lua;/app/engine/?.lua"
local parser=require("parser")
math.randomseed(os.time())

local DEBUG_MODE = false
local usedNames = {}
local stringTable = {}
local constantTable = {}
local VMKEY = math.random(50, 200)

local GLOBALS = {
    ["print"]=1,["warn"]=1,["error"]=1,["pairs"]=1,["ipairs"]=1,["next"]=1,
    ["tonumber"]=1,["tostring"]=1,["type"]=1,["pcall"]=1,["xpcall"]=1,
    ["assert"]=1,["select"]=1,["unpack"]=1,["rawget"]=1,["rawset"]=1,
    ["rawequal"]=1,["require"]=1,["setmetatable"]=1,["getmetatable"]=1,
    ["loadstring"]=1,["loadfile"]=1,["dofile"]=1,["collectgarbage"]=1,
    ["newproxy"]=1,["math"]=1,["string"]=1,["table"]=1,["coroutine"]=1,
    ["debug"]=1,["os"]=1,["io"]=1,["bit"]=1,["bit32"]=1,["_G"]=1,
    ["_VERSION"]=1,["shared"]=1,["game"]=1,["workspace"]=1,["script"]=1,
    ["plugin"]=1,["Enum"]=1,["Instance"]=1,["Vector2"]=1,["Vector3"]=1,
    ["CFrame"]=1,["Color3"]=1,["UDim"]=1,["UDim2"]=1,["Rect"]=1,
    ["Region3"]=1,["Ray"]=1,["BrickColor"]=1,["TweenInfo"]=1,
    ["NumberSequence"]=1,["ColorSequence"]=1,["NumberRange"]=1,
    ["Random"]=1,["DateTime"]=1,["typeof"]=1,["spawn"]=1,["delay"]=1,
    ["wait"]=1,["tick"]=1,["time"]=1,["elapsedTime"]=1,["settings"]=1,
    ["stats"]=1,["UserSettings"]=1,["version"]=1,["task"]=1,
    ["getgenv"]=1,["getrenv"]=1,["getfenv"]=1,["setfenv"]=1,["getsenv"]=1,
    ["getrawmetatable"]=1,["setrawmetatable"]=1,["setreadonly"]=1,
    ["isreadonly"]=1,["hookfunction"]=1,["hookmetamethod"]=1,
    ["newcclosure"]=1,["islclosure"]=1,["iscclosure"]=1,
    ["getnamecallmethod"]=1,["setnamecallmethod"]=1,["checkcaller"]=1,
    ["getcallingscript"]=1,["getinfo"]=1,["getupvalue"]=1,["setupvalue"]=1,
    ["getupvalues"]=1,["getconstant"]=1,["setconstant"]=1,["getconstants"]=1,
    ["getproto"]=1,["getprotos"]=1,["getstack"]=1,["setstack"]=1,
    ["getconnections"]=1,["firesignal"]=1,["fireclickdetector"]=1,
    ["fireproximityprompt"]=1,["firetouchinterest"]=1,["gethiddenproperty"]=1,
    ["sethiddenproperty"]=1,["setsimulationradius"]=1,["getinstances"]=1,
    ["getnilinstances"]=1,["getscripts"]=1,["getrunningscripts"]=1,
    ["getloadedmodules"]=1,["getcustomasset"]=1,["cloneref"]=1,
    ["compareinstances"]=1,["Drawing"]=1,["setclipboard"]=1,["setfflag"]=1,
    ["getfflag"]=1,["syn"]=1,["fluxus"]=1,["identifyexecutor"]=1,
    ["request"]=1,["http_request"]=1,["HttpGet"]=1,["readfile"]=1,
    ["writefile"]=1,["appendfile"]=1,["listfiles"]=1,["isfile"]=1,
    ["isfolder"]=1,["makefolder"]=1,["delfolder"]=1,["delfile"]=1,
    ["getgc"]=1,["queue_on_teleport"]=1,
    ["true"]=1,["false"]=1,["nil"]=1,["self"]=1
}

local function genName()
    local cs = {"I", "l", "O", "_"}
    local n
    repeat 
        n = "_" 
        for i = 1, math.random(10, 16) do 
            n = n .. cs[math.random(1, 4)] 
        end 
    until not usedNames[n]
    usedNames[n] = true
    return n
end

local function genJunkVar()
    local n = "_" .. string.char(math.random(97, 122))
    for i = 1, math.random(4, 8) do 
        n = n .. string.char(math.random(97, 122)) 
    end
    return n
end

-- Simple XOR dengan key tunggal
local function xorByte(b, k)
    -- Manual XOR implementation
    local result = 0
    local power = 1
    for i = 0, 7 do
        local b1 = math.floor(b / power) % 2
        local b2 = math.floor(k / power) % 2
        if b1 ~= b2 then
            result = result + power
        end
        power = power * 2
    end
    return result
end

-- Encode string ke array of XORed bytes
local function encodeString(s, key)
    local r = {}
    for i = 1, #s do
        local b = string.byte(s, i)
        local k = ((key + i) % 256)  -- Vary key per position
        r[i] = xorByte(b, k)
    end
    return r
end

local function obfNum(ns)
    local n = tonumber(ns)
    if not n then return tostring(ns) end
    if n ~= math.floor(n) then return tostring(ns) end
    if n < 0 or n > 50000 then return tostring(ns) end
    if n == 0 then return "((1)-(1))" end
    if n == 1 then return "((2)-(1))" end
    local m = math.random(1, 3)
    local a = math.random(1, 100)
    if m == 1 then return "((" .. (n + a) .. ")-(" .. a .. "))"
    elseif m == 2 then return "((" .. (n - a) .. ")+(" .. a .. "))"
    else return "(" .. math.floor(n / 2) .. "+" .. (n - math.floor(n / 2)) .. ")" end
end

local function genOpaque(t)
    if t then
        return "(1<2)"
    else
        return "(2<1)"
    end
end

local function genSafeJunk()
    local v = genJunkVar()
    local n = math.random(100, 9999)
    local m = math.random(1, 4)
    if m == 1 then 
        return "local " .. v .. "=" .. n .. " "
    elseif m == 2 then 
        return "local " .. v .. "={} "
    elseif m == 3 then
        return "local " .. v .. "=" .. n .. "+" .. math.random(1, 100) .. " "
    else
        return "local " .. v .. " " .. v .. "=" .. n .. " "
    end
end

local function genSafeBlock()
    local v = genJunkVar()
    local n = math.random(100, 9999)
    local m = math.random(1, 3)
    if m == 1 then 
        return "do local " .. v .. "=" .. n .. " end "
    elseif m == 2 then
        return "if (1<2) then local " .. v .. "=" .. n .. " end "
    else
        return "for " .. v .. "=1,0 do end "
    end
end

local function genBloat()
    local b = ""
    for i = 1, math.random(2, 4) do
        if math.random(1, 3) == 1 then
            b = b .. genSafeBlock()
        else
            b = b .. genSafeJunk()
        end
    end
    return b
end

local function genHeavyBloat()
    local b = ""
    for i = 1, math.random(4, 6) do
        if math.random(1, 3) == 1 then
            b = b .. genSafeBlock()
        else
            b = b .. genSafeJunk()
        end
    end
    return b
end

local function addString(s)
    if not s then return 1 end
    for k, v in pairs(stringTable) do 
        if v.orig == s then return k end 
    end
    local idx = #stringTable + 1
    stringTable[idx] = {orig = s, enc = encodeString(s, VMKEY)}
    return idx
end

local function addConstant(n)
    if not n then return 1 end
    local num = tonumber(n)
    if not num then return 1 end
    for k, v in pairs(constantTable) do 
        if v.orig == num then return k end 
    end
    local idx = #constantTable + 1
    local offset = math.random(1000, 9999)
    constantTable[idx] = {orig = num, val = num + offset, off = offset}
    return idx
end

-- ============================================
-- OBFUSCATOR CLASS
-- ============================================
local U = {}

function U:new()
    local o = {
        vm = {},
        out = "",
        jc = 0,
        ji = math.random(3, 5),
        inExpr = false
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function U:e(s) 
    self.out = self.out .. s 
end

function U:mj()
    self.jc = self.jc + 1
    if self.jc >= self.ji then
        self.jc = 0
        self.ji = math.random(3, 5)
        self:e(genSafeJunk())
    end
end

function U:gn(old)
    if not old or type(old) ~= "string" or old == "" then 
        return genName() 
    end
    if GLOBALS[old] then return old end
    if not self.vm[old] then self.vm[old] = genName() end
    return self.vm[old]
end

function U:es(s)
    if not s or s == "" then return '""' end
    local idx = addString(s)
    return "_S(" .. idx .. ")"
end

function U:en(ns)
    local n = tonumber(ns)
    if not n or n ~= math.floor(n) or n < 0 or n > 50000 then 
        return tostring(ns) 
    end
    local idx = addConstant(n)
    return "_N(" .. idx .. ")"
end

function U:getName(n)
    if not n then return nil end
    if type(n) == "string" and n ~= "" then return n end
    if type(n) == "table" then
        if n.Name and type(n.Name) == "string" then return n.Name end
        if n.Data and type(n.Data) == "string" then return n.Data end
        if n.AstType == "VarExpr" and n.Name then return n.Name end
    end
    return nil
end

function U:outFuncName(n)
    if not n then return false end
    
    local t = type(n) == "table" and n.AstType or nil
    
    if type(n) == "string" and n ~= "" then
        self:e(self:gn(n))
        return true
    end
    
    if t == "VarExpr" then
        local name = n.Name
        if name and type(name) == "string" then
            self:e(self:gn(name))
            return true
        end
        return false
        
    elseif t == "MemberExpr" then
        if n.Base then
            self:outFuncName(n.Base)
        end
        self:e(n.Indexer or ".")
        local ident = n.Ident
        if ident then
            local id = ident.Data or ident.Name or (type(ident) == "string" and ident)
            if id then
                self:e(id)
                return true
            end
        end
        self:e("_fn")
        return true
        
    elseif t == "IndexExpr" then
        if n.Base then
            self:outFuncName(n.Base)
        end
        self:e("[")
        if n.Index then
            self:pExpr(n.Index)
        else
            self:e('"_"')
        end
        self:e("]")
        return true
    end
    
    local name = self:getName(n)
    if name then
        self:e(self:gn(name))
        return true
    end
    
    return false
end

function U:pExpr(n)
    if not n then 
        self:e("nil")
        return 
    end
    
    local t = n.AstType
    local oldInExpr = self.inExpr
    self.inExpr = true
    
    if t == "StringExpr" then
        local val = ""
        if n.Value then
            if type(n.Value) == "string" then val = n.Value
            elseif type(n.Value) == "table" then val = n.Value.Constant or n.Value.Data or ""
            end
        end
        self:e(self:es(val))

    elseif t == "NumberExpr" then
        local nv = "0"
        if n.Value then
            if type(n.Value) == "string" then nv = n.Value
            elseif type(n.Value) == "table" and n.Value.Data then nv = n.Value.Data
            elseif type(n.Value) == "number" then nv = tostring(n.Value)
            end
        end
        if nv:match("^%-?%d+$") and tonumber(nv) and math.abs(tonumber(nv)) < 50000 then
            self:e(self:en(nv))
        else
            self:e(nv)
        end

    elseif t == "BooleanExpr" then
        self:e(n.Value and "true" or "false")

    elseif t == "NilExpr" then
        self:e("nil")

    elseif t == "VarExpr" then
        local name = n.Name
        if name and type(name) == "string" then
            self:e(self:gn(name))
        else
            self:e("nil")
        end

    elseif t == "DotsExpr" or t == "VarargExpr" or t == "VarargsExpr" then
        self:e("...")

    elseif t == "MemberExpr" then
        if n.Base then self:pExpr(n.Base) end
        self:e(n.Indexer or ".")
        local ident = n.Ident
        if ident then
            local id = ident.Data or ident.Name or (type(ident) == "string" and ident)
            self:e(id or "_")
        else
            self:e("_")
        end

    elseif t == "IndexExpr" then
        if n.Base then self:pExpr(n.Base) end
        self:e("[")
        if n.Index then self:pExpr(n.Index) else self:e("1") end
        self:e("]")

    elseif t == "CallExpr" then
        if n.Base then self:pExpr(n.Base) end
        self:e("(")
        local args = n.Arguments or {}
        for i, a in ipairs(args) do
            self:pExpr(a)
            if i < #args then self:e(",") end
        end
        self:e(")")

    elseif t == "StringCallExpr" or t == "TableCallExpr" then
        if n.Base then self:pExpr(n.Base) end
        self:e("(")
        for _, a in ipairs(n.Arguments or {}) do self:pExpr(a) end
        self:e(")")

    elseif t == "Parentheses" or t == "ParenthesesExpr" then
        self:e("(")
        self:pExpr(n.Inner or n.Expression)
        self:e(")")

    elseif t == "BinopExpr" or t == "BinaryExpr" then
        self:pExpr(n.Lhs)
        self:e(" " .. (n.Op or n.Operator or "+") .. " ")
        self:pExpr(n.Rhs)

    elseif t == "UnopExpr" or t == "UnaryExpr" then
        local op = n.Op or n.Operator or "-"
        if op == "not" then self:e("not ")
        elseif op == "-" then self:e("-")
        elseif op == "#" then self:e("#")
        else self:e(op) end
        self:pExpr(n.Rhs or n.Operand)

    elseif t == "Function" or t == "FunctionExpr" then
        self:e("function(")
        local args = n.Arguments or n.ArgList or {}
        for i, a in ipairs(args) do
            local name = self:getName(a) or ("_a" .. i)
            self:e(self:gn(name))
            if i < #args then self:e(",") end
        end
        if n.VarArg then
            if #args > 0 then self:e(",") end
            self:e("...")
        end
        self:e(") ")
        self:e(genBloat())
        if n.Body then self:p(n.Body) end
        self:e(genBloat())
        self:e(" end")

    elseif t == "ConstructorExpr" or t == "TableExpr" or t == "TableConstructorExpr" then
        self:e("{")
        local elist = n.EntryList or n.Fields or {}
        for i, en in ipairs(elist) do
            local etype = en.Type or en.EntryType
            if etype == "Key" then
                self:e("[")
                if en.Key then self:pExpr(en.Key) else self:e("1") end
                self:e("]=")
                if en.Value then self:pExpr(en.Value) else self:e("nil") end
            elseif etype == "KeyString" then
                if en.Key and type(en.Key) == "string" then
                    self:e("[" .. self:es(en.Key) .. "]=")
                end
                if en.Value then self:pExpr(en.Value) else self:e("nil") end
            else
                if en.Value then self:pExpr(en.Value) end
            end
            if i < #elist then self:e(",") end
        end
        self:e("}")

    else
        self:e("nil")
    end
    
    self.inExpr = oldInExpr
end

function U:p(n)
    if not n then return end
    
    local t = n.AstType

    if t == "Statlist" then
        for _, s in ipairs(n.Body or {}) do
            self:p(s)
            self:mj()
        end

    elseif t == "LocalStatement" then
        self:e("local ")
        local llist = n.LocalList or {}
        for i, v in ipairs(llist) do
            local name = self:getName(v) or ("_l" .. i)
            self:e(self:gn(name))
            if i < #llist then self:e(",") end
        end
        local ilist = n.InitList or {}
        if #ilist > 0 then
            self:e("=")
            for i, x in ipairs(ilist) do
                self:pExpr(x)
                if i < #ilist then self:e(",") end
            end
        end
        self:e(" ")

    elseif t == "AssignmentStatement" then
        local lhs = n.Lhs or {}
        for i, l in ipairs(lhs) do
            self:pExpr(l)
            if i < #lhs then self:e(",") end
        end
        self:e("=")
        local rhs = n.Rhs or {}
        for i, r in ipairs(rhs) do
            self:pExpr(r)
            if i < #rhs then self:e(",") end
        end
        self:e(" ")

    elseif t == "CallStatement" then
        if n.Expression then
            self:pExpr(n.Expression)
        end
        self:e(" ")

    elseif t == "Function" and not self.inExpr then
        if n.Name or n.IsLocal then
            if n.IsLocal then
                self:e("local function ")
            else
                self:e("function ")
            end
            if n.Name then
                if not self:outFuncName(n.Name) then
                    self:e(genName())
                end
            else
                self:e(genName())
            end
            self:e("(")
            local args = n.Arguments or n.ArgList or {}
            for i, a in ipairs(args) do
                local name = self:getName(a) or ("_a" .. i)
                self:e(self:gn(name))
                if i < #args then self:e(",") end
            end
            if n.VarArg then
                if #args > 0 then self:e(",") end
                self:e("...")
            end
            self:e(") ")
            self:e(genHeavyBloat())
            if n.Body then self:p(n.Body) end
            self:e(genBloat())
            self:e(" end ")
        else
            self:e("do local _ = ")
            self:pExpr(n)
            self:e(" end ")
        end

    elseif t == "FunctionStatement" or t == "FunctionDeclaration" or t == "FunctionDeclStatement" then
        if n.IsLocal then
            self:e("local function ")
        else
            self:e("function ")
        end
        if n.Name then
            if not self:outFuncName(n.Name) then
                self:e(genName())
            end
        else
            self:e(genName())
        end
        self:e("(")
        local args = n.Arguments or n.ArgList or {}
        for i, a in ipairs(args) do
            local name = self:getName(a) or ("_a" .. i)
            self:e(self:gn(name))
            if i < #args then self:e(",") end
        end
        if n.VarArg then
            if #args > 0 then self:e(",") end
            self:e("...")
        end
        self:e(") ")
        self:e(genHeavyBloat())
        if n.Body then self:p(n.Body) end
        self:e(genBloat())
        self:e(" end ")

    elseif t == "IfStatement" then
        local clauses = n.Clauses or {}
        for i, c in ipairs(clauses) do
            if i == 1 then
                self:e("if ")
                if c.Condition then self:pExpr(c.Condition) else self:e("true") end
                self:e(" then ")
                self:e(genBloat())
            elseif c.Condition then
                self:e(" elseif ")
                self:pExpr(c.Condition)
                self:e(" then ")
                self:e(genBloat())
            else
                self:e(" else ")
                self:e(genBloat())
            end
            if c.Body then self:p(c.Body) end
        end
        self:e(" end ")

    elseif t == "WhileStatement" then
        self:e("while ")
        if n.Condition then self:pExpr(n.Condition) else self:e("true") end
        self:e(" do ")
        self:e(genBloat())
        if n.Body then self:p(n.Body) end
        self:e(" end ")

    elseif t == "NumericForStatement" then
        self:e("for ")
        local varName = self:getName(n.Variable) or "_i"
        self:e(self:gn(varName))
        self:e("=")
        if n.Start then self:pExpr(n.Start) else self:e("1") end
        self:e(",")
        if n.End then self:pExpr(n.End) else self:e("1") end
        if n.Step then
            self:e(",")
            self:pExpr(n.Step)
        end
        self:e(" do ")
        self:e(genBloat())
        if n.Body then self:p(n.Body) end
        self:e(" end ")

    elseif t == "GenericForStatement" then
        self:e("for ")
        local vlist = n.VariableList or {}
        for i, v in ipairs(vlist) do
            local name = self:getName(v) or ("_v" .. i)
            self:e(self:gn(name))
            if i < #vlist then self:e(",") end
        end
        self:e(" in ")
        local gens = n.Generators or {}
        for i, g in ipairs(gens) do
            self:pExpr(g)
            if i < #gens then self:e(",") end
        end
        self:e(" do ")
        self:e(genBloat())
        if n.Body then self:p(n.Body) end
        self:e(" end ")

    elseif t == "RepeatStatement" then
        self:e("repeat ")
        self:e(genBloat())
        if n.Body then self:p(n.Body) end
        self:e(" until ")
        if n.Condition then self:pExpr(n.Condition) else self:e("true") end
        self:e(" ")

    elseif t == "DoStatement" then
        self:e("do ")
        self:e(genBloat())
        if n.Body then self:p(n.Body) end
        self:e(" end ")

    elseif t == "ReturnStatement" then
        self:e("return ")
        local args = n.Arguments or {}
        for i, a in ipairs(args) do
            self:pExpr(a)
            if i < #args then self:e(",") end
        end
        self:e(" ")

    elseif t == "BreakStatement" then
        self:e("break ")

    elseif t == "ContinueStatement" then
        self:e("continue ")

    elseif t == "LabelStatement" then
        local label = n.Label
        if type(label) == "table" then label = label.Data or label.Name end
        if label and type(label) == "string" then
            self:e("::" .. label .. ":: ")
        end

    elseif t == "GotoStatement" then
        local label = n.Label
        if type(label) == "table" then label = label.Data or label.Name end
        if label and type(label) == "string" then
            self:e("goto " .. label .. " ")
        end

    elseif t == "Eof" then
        -- ignore
    end
end

-- ============================================
-- RUNTIME - XOR harus SAMA dengan encoder
-- ============================================
local function buildRuntime()
    local r = {}
    
    -- XOR function - SAMA dengan xorByte di atas
    r[#r + 1] = "local function _X(b,k) "
    r[#r + 1] = "local r=0 local p=1 "
    r[#r + 1] = "for i=0,7 do "
    r[#r + 1] = "local b1=math.floor(b/p)%2 "
    r[#r + 1] = "local b2=math.floor(k/p)%2 "
    r[#r + 1] = "if b1~=b2 then r=r+p end "
    r[#r + 1] = "p=p*2 "
    r[#r + 1] = "end "
    r[#r + 1] = "return r "
    r[#r + 1] = "end "
    
    return table.concat(r)
end

local function buildStringTable()
    local r = {}
    local key = VMKEY
    
    r[#r + 1] = "local _ST={} "
    
    for i = 1, #stringTable do
        local s = stringTable[i]
        if s and s.enc then
            local encStr = "{"
            for j, v in ipairs(s.enc) do
                encStr = encStr .. v
                if j < #s.enc then encStr = encStr .. "," end
            end
            encStr = encStr .. "}"
            r[#r + 1] = "_ST[" .. i .. "]=" .. encStr .. " "
        end
    end
    
    -- Decode function - key varies per position, SAMA dengan encodeString
    r[#r + 1] = "local function _S(i) "
    r[#r + 1] = "local t=_ST[i] "
    r[#r + 1] = "if not t then return '' end "
    r[#r + 1] = "local r={} "
    r[#r + 1] = "for j=1,#t do "
    r[#r + 1] = "local k=((" .. key .. "+j)%256) "  -- SAMA dengan encoder
    r[#r + 1] = "r[j]=string.char(_X(t[j],k)) "
    r[#r + 1] = "end "
    r[#r + 1] = "return table.concat(r) "
    r[#r + 1] = "end "
    
    return table.concat(r)
end

local function buildConstantTable()
    local r = {}
    
    r[#r + 1] = "local _CT={} "
    
    for i = 1, #constantTable do
        local c = constantTable[i]
        if c then
            r[#r + 1] = "_CT[" .. i .. "]={" .. c.val .. "," .. c.off .. "} "
        end
    end
    
    r[#r + 1] = "local function _N(i) "
    r[#r + 1] = "local c=_CT[i] "
    r[#r + 1] = "if c then return c[1]-c[2] end "
    r[#r + 1] = "return 0 "
    r[#r + 1] = "end "
    
    return table.concat(r)
end

local function wrapCode(code)
    local fn = genName()
    local w = ""
    w = w .. "local function " .. fn .. "() "
    w = w .. genHeavyBloat()
    w = w .. code
    w = w .. genBloat()
    w = w .. " end "
    w = w .. fn .. "() "
    return w
end

-- ============================================
-- MAIN
-- ============================================
local fn = arg[1]
if not fn then 
    print("-- ERROR: No input file")
    return 
end

local f = io.open(fn, "rb")
if not f then 
    print("-- ERROR: Cannot open: " .. fn) 
    return 
end
local code = f:read("*a")
f:close()

local ok, ast = parser.ParseLua(code)
if not ok then 
    print("-- PARSE ERROR: " .. tostring(ast)) 
    return 
end

local u = U:new()
u:p(ast)

local runtime = buildRuntime()
local strTable = buildStringTable()
local constTable = buildConstantTable()
local body = u.out

local wrapped = wrapCode(body)

local final = ""
final = final .. runtime
final = final .. strTable
final = final .. constTable
final = final .. genBloat()
final = final .. wrapped

if DEBUG_MODE then
    io.stderr:write("-- VMKEY: " .. VMKEY .. "\n")
    io.stderr:write("-- Strings: " .. #stringTable .. "\n")
    io.stderr:write("-- Output: " .. #final .. " bytes\n")
    
    -- Test decode
    io.stderr:write("\n-- String decode test:\n")
    for i = 1, math.min(3, #stringTable) do
        local s = stringTable[i]
        if s then
            io.stderr:write("-- [" .. i .. "] Original: " .. s.orig:sub(1, 30) .. "\n")
            -- Verify decode
            local dec = {}
            for j, v in ipairs(s.enc) do
                local k = ((VMKEY + j) % 256)
                dec[j] = string.char(xorByte(v, k))
            end
            io.stderr:write("-- [" .. i .. "] Decoded:  " .. table.concat(dec):sub(1, 30) .. "\n")
        end
    end
end

print(final)
