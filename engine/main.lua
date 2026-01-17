package.path=package.path..";./?.lua;./engine/?.lua;/app/engine/?.lua"
local parser=require("parser")
math.randomseed(os.time())

-- CONFIG
local JUNK_INTENSITY = 15 -- Semakin tinggi, semakin besar file (Luraph style)
local VMKEY = math.random(50, 200)

local usedNames={}
local stringTable={}
local constantTable={}

local GLOBALS={
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
["true"]=1,["false"]=1,["nil"]=1
}

-- === GENERATORS === --

local function genName()
    local cs={"I","l","1","_"}
    local n
    repeat n="_" for i=1,math.random(15,25) do n=n..cs[math.random(1,4)] end until not usedNames[n]
    usedNames[n]=true
    return n
end

local function genJunkVar()
    local n="_"..string.char(math.random(97,122))
    for i=1,math.random(5,10) do n=n..string.char(math.random(97,122)) end
    return n
end

local function xorEnc(s,k)
    local r={}
    for i=1,#s do
        local b=string.byte(s,i)
        local x,p,a,bb=0,1,b,k
        while a>0 or bb>0 do
            local aa,bbb=a%2,bb%2
            if aa~=bbb then x=x+p end
            a=math.floor(a/2)
            bb=math.floor(bb/2)
            p=p*2
        end
        r[#r+1]=x
    end
    return r
end

local function obfNum(ns)
    local n=tonumber(ns)
    if not n then return ns end
    if n~=math.floor(n) then return ns end
    if n<0 or n>999999 then return ns end
    if n==0 then return"((1)-(1))" end
    if n==1 then return"((2)-(1))" end
    
    local m=math.random(1,5)
    local a=math.random(1,100)
    if m==1 then return"(("..(n+a)..")-("..a.."))"
    elseif m==2 then return"(("..(n-a)..")+("..a.."))"
    elseif m==3 then return"("..math.floor(n/2).."+"..(n-math.floor(n/2))..")"
    elseif m==4 then return"(("..a.."+"..(n-a).."))"
    else return"(("..(n*2)..")/2)" end
end

local function genOpaque(t)
    local a,b=math.random(100,500),math.random(501,999)
    if t then return "("..a.."<"..b..")" else return "("..b.."<"..a..")" end
end

-- AMAN: Junk code hanya berupa variable definition lokal yang tidak mempengaruhi logic
local function genJunk()
    local v=genJunkVar()
    local n=math.random(100,9999)
    return "local "..v.."="..obfNum(tostring(n))..";"
end

-- AMAN: Block tertutup
local function genSafeBlock()
    local v=genJunkVar()
    return "do local "..v.."="..obfNum(tostring(math.random(1,100))).." end "
end

-- GENERATE MASSIVE BLOAT (Untuk memperbesar ukuran file)
local function genBloat()
    local b=""
    for i=1,math.random(5, JUNK_INTENSITY) do
        if math.random(1,2)==1 then b=b..genJunk() else b=b..genSafeBlock() end
    end
    return b
end

-- === VM REGISTRY === --

local function addString(s)
    if not s then return nil end
    for k,v in pairs(stringTable) do if v.orig==s then return k end end
    local idx=#stringTable+1
    stringTable[idx]={orig=s,enc=xorEnc(s,VMKEY)}
    return idx
end

local function addConstant(n)
    if not n then return nil end
    local num=tonumber(n)
    if not num then return nil end
    for k,v in pairs(constantTable) do if v.orig==num then return k end end
    local idx=#constantTable+1
    local offset=math.random(1000,9999)
    constantTable[idx]={orig=num,val=num+offset,off=offset}
    return idx
end

-- === UNPARSER === --

local U={}
function U:new()
    local o={vm={},out=""}
    setmetatable(o,self)
    self.__index=self
    return o
end

function U:e(s) self.out=self.out..s end

function U:gn(old)
    if GLOBALS[old] then return old end
    if not self.vm[old] then self.vm[old]=genName() end
    return self.vm[old]
end

function U:es(s)
    if not s or s=="" then return'""' end
    local idx=addString(s)
    return "_S["..obfNum(tostring(idx)).."]"
end

function U:en(ns)
    local n=tonumber(ns)
    if not n or n~=math.floor(n) or n<0 or n>999999 then return obfNum(ns) end
    local idx=addConstant(n)
    return "_N["..obfNum(tostring(idx)).."]"
end

-- PROCESS AST
function U:p(n)
    if not n then return end
    local t=n.AstType

    if t=="Statlist" then
        for _,s in ipairs(n.Body) do
            self:p(s)
            self:e(genBloat()) -- Massive bloat between lines
        end

    elseif t=="LocalStatement" then
        self:e("local ")
        for i,v in ipairs(n.LocalList) do
            self:e(self:gn(v.Name))
            if i<#n.LocalList then self:e(",") end
        end
        if #n.InitList>0 then
            self:e("=")
            for i,x in ipairs(n.InitList) do
                self:p(x)
                if i<#n.InitList then self:e(",") end
            end
        end
        self:e(" ")

    elseif t=="AssignmentStatement" then
        for i,l in ipairs(n.Lhs) do self:p(l) if i<#n.Lhs then self:e(",") end end
        self:e("=")
        for i,r in ipairs(n.Rhs) do self:p(r) if i<#n.Rhs then self:e(",") end end
        self:e(" ")

    elseif t=="CallStatement" then
        self:p(n.Expression) self:e(" ")

    elseif t=="CallExpr" then
        -- SAFE METHOD HIDING: obj:Name(...) -> obj["Name"](obj, ...)
        if n.Base.AstType == "MemberExpr" and n.Base.Indexer == ":" then
            self:p(n.Base.Base)
            self:e("[")
            self:e(self:es(n.Base.Ident.Data)) -- Encrypt Method Name
            self:e("](")
            self:p(n.Base.Base) -- Pass Self
            if #n.Arguments > 0 then self:e(",") end
            for i,a in ipairs(n.Arguments) do self:p(a) if i<#n.Arguments then self:e(",") end end
            self:e(")")
        else
            self:p(n.Base)
            self:e("(")
            for i,a in ipairs(n.Arguments) do self:p(a) if i<#n.Arguments then self:e(",") end end
            self:e(")")
        end

    elseif t=="StringCallExpr" then
        self:p(n.Base) self:e("(") for _,a in ipairs(n.Arguments) do self:p(a) end self:e(")")

    elseif t=="TableCallExpr" then
        self:p(n.Base) self:e("(") for _,a in ipairs(n.Arguments) do self:p(a) end self:e(")")

    elseif t=="VarExpr" then
        self:e(self:gn(n.Name))

    elseif t=="MemberExpr" then
        -- HIDE PROPERTIES: obj.Prop -> obj["Prop"]
        self:p(n.Base)
        self:e("[")
        self:e(self:es(n.Ident.Data)) -- Encrypt Property Name
        self:e("]")

    elseif t=="IndexExpr" then
        self:p(n.Base) self:e("[") self:p(n.Index) self:e("]")

    elseif t=="StringExpr" then
        self:e(self:es(n.Value.Constant or""))

    elseif t=="NumberExpr" then
        local nv=n.Value.Data
        if nv:match("^%d+$") then self:e(self:en(nv)) else self:e(nv) end

    elseif t=="BooleanExpr" then
        if n.Value then self:e("true") else self:e("false") end

    elseif t=="NilExpr" then self:e("nil")

    elseif t=="Parentheses" then
        self:e("(") self:p(n.Inner) self:e(")")

    elseif t=="BinopExpr" then
        -- VIRTUALIZE ARITHMETIC
        local opMap={["+"]="_ADD",["-"]="_SUB",["*"]="_MUL",["/"]="_DIV",["^"]="_POW"}
        if opMap[n.Op] then
            self:e("_VM."..opMap[n.Op].."(")
            self:p(n.Lhs)
            self:e(",")
            self:p(n.Rhs)
            self:e(")")
        else
            self:p(n.Lhs) self:e(" "..n.Op.." ") self:p(n.Rhs)
        end

    elseif t=="UnopExpr" then
        self:e((n.Op=="not" and "not " or n.Op)) self:p(n.Rhs)

    elseif t=="Function" then
        if n.IsLocal then
            if n.Name then self:e("local function "..self:gn(type(n.Name)=="table" and n.Name.Name or n.Name))
            else self:e("function") end
        else self:e("function ") if n.Name then self:p(n.Name) end end
        self:e("(")
        for i,a in ipairs(n.Arguments) do self:e(self:gn(a.Name)) if i<#n.Arguments then self:e(",") end end
        if n.VarArg then if #n.Arguments>0 then self:e(",") end self:e("...") end
        self:e(") ")
        self:e(genBloat()) -- Junk inside function body
        self:p(n.Body)
        self:e("end ")

    elseif t=="IfStatement" then
        for i,c in ipairs(n.Clauses) do
            if i==1 then self:e("if ") self:p(c.Condition) self:e(" then ") self:e(genBloat())
            elseif c.Condition then self:e("elseif ") self:p(c.Condition) self:e(" then ") self:e(genBloat())
            else self:e("else ") self:e(genBloat()) end
            self:p(c.Body)
        end
        self:e("end ")

    elseif t=="WhileStatement" then
        self:e("while ") self:p(n.Condition) self:e(" do ") self:e(genBloat()) self:p(n.Body) self:e("end ")

    elseif t=="NumericForStatement" then
        self:e("for "..self:gn(n.Variable.Name).."=")
        self:p(n.Start) self:e(",") self:p(n.End)
        if n.Step then self:e(",") self:p(n.Step) end
        self:e(" do ") self:e(genBloat()) self:p(n.Body) self:e("end ")

    elseif t=="GenericForStatement" then
        self:e("for ")
        for i,v in ipairs(n.VariableList) do self:e(self:gn(v.Name)) if i<#n.VariableList then self:e(",") end end
        self:e(" in ")
        for i,g in ipairs(n.Generators) do self:p(g) if i<#n.Generators then self:e(",") end end
        self:e(" do ") self:e(genBloat()) self:p(n.Body) self:e("end ")

    elseif t=="RepeatStatement" then
        self:e("repeat ") self:e(genBloat()) self:p(n.Body) self:e("until ") self:p(n.Condition) self:e(" ")

    elseif t=="DoStatement" then
        self:e("do ") self:e(genBloat()) self:p(n.Body) self:e("end ")

    elseif t=="ReturnStatement" then
        self:e("return ")
        for i,a in ipairs(n.Arguments) do self:p(a) if i<#n.Arguments then self:e(",") end end
        self:e(" ")

    elseif t=="BreakStatement" then self:e("break ")

    elseif t=="ConstructorExpr" then
        self:e("{")
        for i,en in ipairs(n.EntryList) do
            if en.Type=="Key" then
                self:e("[") self:p(en.Key) self:e("]=") self:p(en.Value)
            elseif en.Type=="KeyString" then
                -- ENCRYPT KEYS
                self:e("[") self:e(self:es(en.Key)) self:e("]=") self:p(en.Value)
            else
                self:p(en.Value)
            end
            if i<#n.EntryList then self:e(",") end
        end
        self:e("}")

    elseif t=="DotsExpr" then self:e("...")
    elseif t=="Eof" then
    elseif t=="LabelStatement" then self:e("::"..n.Label..":: ")
    elseif t=="GotoStatement" then self:e("goto "..n.Label.." ")
    end
end

-- === BUILDERS === --

local function buildRuntime()
    local r={}
    r[#r+1]="local _VM={} "
    r[#r+1]="_VM.X=function(a,b) local r,m=0,1 while a>0 or b>0 do local x,y=a%2,b%2 if x~=y then r=r+m end a=math.floor(a/2) b=math.floor(b/2) m=m*2 end return r end "
    r[#r+1]="_VM.D=function(t,k) local r={} for i=1,#t do r[i]=string.char(_VM.X(t[i],k)) end return table.concat(r) end "
    -- VM ARITHMETIC
    r[#r+1]="_VM._ADD=function(a,b) return a+b end "
    r[#r+1]="_VM._SUB=function(a,b) return a-b end "
    r[#r+1]="_VM._MUL=function(a,b) return a*b end "
    r[#r+1]="_VM._DIV=function(a,b) return a/b end "
    r[#r+1]="_VM._POW=function(a,b) return a^b end "
    return table.concat(r)
end

local function buildStringTable()
    local r={}
    r[#r+1]="local _ST={} "
    for i=1,#stringTable do
        local s=stringTable[i]
        local encStr="{"
        for j,v in ipairs(s.enc) do encStr=encStr..v.."," end
        encStr=encStr:sub(1,-2).."}"
        r[#r+1]="_ST["..obfNum(tostring(i)).."]="..encStr.." "
    end
    r[#r+1]="local _S=setmetatable({},{__index=function(_,k) local t=_ST[k] if t then return _VM.D(t,"..obfNum(tostring(VMKEY))..") end return '' end}) "
    return table.concat(r)
end

local function buildConstantTable()
    local r={}
    r[#r+1]="local _CT={} "
    for i=1,#constantTable do
        local c=constantTable[i]
        r[#r+1]="_CT["..obfNum(tostring(i)).."]={v="..obfNum(tostring(c.val))..",o="..obfNum(tostring(c.off)).."} "
    end
    r[#r+1]="local _N=setmetatable({},{__index=function(_,k) local c=_CT[k] if c then return c.v-c.o end return 0 end}) "
    return table.concat(r)
end

local function genFakeData()
    local d={}
    d[#d+1]="local _MEM={} "
    -- Buat 500+ entri sampah untuk bloat size
    for i=1,math.random(500,800) do
        local s=""
        for j=1,math.random(10,20) do s=s..string.char(math.random(65,90)) end
        d[#d+1]="_MEM["..i.."]='"..s.."' "
    end
    return table.concat(d)
end

local function genAntiTamper()
    local a=""
    a=a.."if rawget(_G,'__DEOBF') then while true do end end "
    return a
end

local function wrapCode(code)
    local fn=genName()
    return "local function "..fn.."() "..genBloat()..code..genBloat().." end "..fn.."() "
end

-- === MAIN === --

local fn=arg[1]
if not fn then print("-- ERROR: No input") return end
local f=io.open(fn,"rb")
if not f then print("-- ERROR: Cannot open") return end
local code=f:read("*a")
f:close()

local ok,ast=parser.ParseLua(code)
if not ok then print("-- PARSE ERROR: "..tostring(ast)) return end

local u=U:new()
u:p(ast)

local runtime=buildRuntime()
local fake=genFakeData()
local strTable=buildStringTable()
local constTable=buildConstantTable()
local antiTamper=genAntiTamper()
local body=u.out
local wrapped=wrapCode(body)

local final=runtime..fake..strTable..constTable..antiTamper..genBloat()..wrapped..genBloat()

print(final)
