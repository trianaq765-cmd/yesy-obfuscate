package.path=package.path..";./?.lua;./engine/?.lua;/app/engine/?.lua"
local parser=require("parser")
math.randomseed(os.time())

-- DEBUG MODE: Set ke true untuk melihat output terpisah
local DEBUG_MODE = true

local usedNames={}
local function generateRandomName()
local charset={"I","l","1","_"}
local name
repeat name="_" for i=1,math.random(10,18)do name=name..charset[math.random(1,#charset)]end until not usedNames[name]
usedNames[name]=true
return name
end

local function generateJunkName()
local prefixes={"_a","_b","_c","_d","_e"}
local name=prefixes[math.random(1,#prefixes)]
for i=1,math.random(3,5)do name=name..string.char(math.random(97,122))end
return name
end

local function xorEncrypt(str,key)
local result={}
for i=1,#str do
local byte=string.byte(str,i)
local xored,pow,a,b=0,1,byte,key
while a>0 or b>0 do
local aa,bb=a%2,b%2
if aa~=bb then xored=xored+pow end
a,b=math.floor(a/2),math.floor(b/2)
pow=pow*2
end
table.insert(result,xored)
end
return result
end

local function obfuscateNumber(numStr)
local n=tonumber(numStr)
if not n or n~=math.floor(n)or n<0 or n>50000 then return numStr end
if n==0 then return"(1-1)"end
if n==1 then return"(2-1)"end
local a=math.random(1,100)
return"("..(n+a).."-"..a..")"
end

local function generateJunkCode()
local v=generateJunkName()
local n=math.random(100,999)
return"local "..v.."="..n.." "
end

local Unparser={}
function Unparser:new()
local obj={varMap={},encryptionKey=math.random(50,200),output="",jc=0,ji=math.random(8,12)}
setmetatable(obj,self)
self.__index=self
return obj
end

function Unparser:emit(str)
self.output=self.output..str
end

function Unparser:maybeJunk()
self.jc=self.jc+1
if self.jc>=self.ji then
self.jc=0
self.ji=math.random(8,12)
self:emit(generateJunkCode())
end
end

function Unparser:getName(old)
local gl={["print"]=1,["warn"]=1,["error"]=1,["pairs"]=1,["ipairs"]=1,["next"]=1,["tonumber"]=1,["tostring"]=1,["type"]=1,["pcall"]=1,["xpcall"]=1,["assert"]=1,["select"]=1,["unpack"]=1,["rawget"]=1,["rawset"]=1,["rawequal"]=1,["require"]=1,["setmetatable"]=1,["getmetatable"]=1,["loadstring"]=1,["loadfile"]=1,["dofile"]=1,["collectgarbage"]=1,["newproxy"]=1,["math"]=1,["string"]=1,["table"]=1,["coroutine"]=1,["debug"]=1,["os"]=1,["io"]=1,["bit"]=1,["bit32"]=1,["_G"]=1,["_VERSION"]=1,["shared"]=1,["game"]=1,["workspace"]=1,["script"]=1,["plugin"]=1,["Enum"]=1,["Instance"]=1,["Vector2"]=1,["Vector3"]=1,["CFrame"]=1,["Color3"]=1,["UDim"]=1,["UDim2"]=1,["Rect"]=1,["Region3"]=1,["Ray"]=1,["BrickColor"]=1,["TweenInfo"]=1,["NumberSequence"]=1,["ColorSequence"]=1,["NumberRange"]=1,["Random"]=1,["DateTime"]=1,["typeof"]=1,["spawn"]=1,["delay"]=1,["wait"]=1,["tick"]=1,["time"]=1,["elapsedTime"]=1,["settings"]=1,["stats"]=1,["UserSettings"]=1,["version"]=1,["task"]=1,["getgenv"]=1,["getrenv"]=1,["getfenv"]=1,["setfenv"]=1,["getsenv"]=1,["getrawmetatable"]=1,["setrawmetatable"]=1,["setreadonly"]=1,["isreadonly"]=1,["hookfunction"]=1,["hookmetamethod"]=1,["newcclosure"]=1,["islclosure"]=1,["iscclosure"]=1,["getnamecallmethod"]=1,["setnamecallmethod"]=1,["checkcaller"]=1,["getcallingscript"]=1,["getinfo"]=1,["getupvalue"]=1,["setupvalue"]=1,["getupvalues"]=1,["getconstant"]=1,["setconstant"]=1,["getconstants"]=1,["getproto"]=1,["getprotos"]=1,["getstack"]=1,["setstack"]=1,["getconnections"]=1,["firesignal"]=1,["fireclickdetector"]=1,["fireproximityprompt"]=1,["firetouchinterest"]=1,["gethiddenproperty"]=1,["sethiddenproperty"]=1,["setsimulationradius"]=1,["getinstances"]=1,["getnilinstances"]=1,["getscripts"]=1,["getrunningscripts"]=1,["getloadedmodules"]=1,["getcustomasset"]=1,["cloneref"]=1,["compareinstances"]=1,["Drawing"]=1,["setclipboard"]=1,["setfflag"]=1,["getfflag"]=1,["syn"]=1,["fluxus"]=1,["identifyexecutor"]=1,["request"]=1,["http_request"]=1,["HttpGet"]=1,["readfile"]=1,["writefile"]=1,["appendfile"]=1,["listfiles"]=1,["isfile"]=1,["isfolder"]=1,["makefolder"]=1,["delfolder"]=1,["delfile"]=1,["getgc"]=1,["queue_on_teleport"]=1,["___D"]=1,["___X"]=1,["true"]=1,["false"]=1,["nil"]=1}
if gl[old] then return old end
if not self.varMap[old] then self.varMap[old]=generateRandomName() end
return self.varMap[old]
end

function Unparser:encStr(str)
if not str or str=="" then return'""' end
local enc=xorEncrypt(str,self.encryptionKey)
local p={}
for _,v in ipairs(enc) do table.insert(p,tostring(v)) end
return"___D({"..table.concat(p,",").."},"..self.encryptionKey..")"
end

function Unparser:proc(node)
if not node then return end
local t=node.AstType

if t=="Statlist" then
for _,s in ipairs(node.Body) do self:proc(s) self:maybeJunk() end

elseif t=="LocalStatement" then
self:emit("local ")
for i,v in ipairs(node.LocalList) do
self:emit(self:getName(v.Name))
if i<#node.LocalList then self:emit(",") end
end
if #node.InitList>0 then
self:emit("=")
for i,e in ipairs(node.InitList) do
self:proc(e)
if i<#node.InitList then self:emit(",") end
end
end
self:emit(" ")

elseif t=="AssignmentStatement" then
for i,l in ipairs(node.Lhs) do self:proc(l) if i<#node.Lhs then self:emit(",") end end
self:emit("=")
for i,r in ipairs(node.Rhs) do self:proc(r) if i<#node.Rhs then self:emit(",") end end
self:emit(" ")

elseif t=="CallStatement" then
self:proc(node.Expression)
self:emit(" ")

elseif t=="CallExpr" then
self:proc(node.Base)
self:emit("(")
for i,a in ipairs(node.Arguments) do self:proc(a) if i<#node.Arguments then self:emit(",") end end
self:emit(")")

elseif t=="StringCallExpr" then
self:proc(node.Base)
self:emit("(")
for _,a in ipairs(node.Arguments) do self:proc(a) end
self:emit(")")

elseif t=="TableCallExpr" then
self:proc(node.Base)
self:emit("(")
for _,a in ipairs(node.Arguments) do self:proc(a) end
self:emit(")")

elseif t=="VarExpr" then
self:emit(self:getName(node.Name))

elseif t=="MemberExpr" then
self:proc(node.Base)
self:emit(node.Indexer)
self:emit(node.Ident.Data)

elseif t=="IndexExpr" then
self:proc(node.Base)
self:emit("[")
self:proc(node.Index)
self:emit("]")

elseif t=="StringExpr" then
self:emit(self:encStr(node.Value.Constant or""))

elseif t=="NumberExpr" then
local nv=node.Value.Data
if nv:match("^%d+$") and tonumber(nv)<5000 then
self:emit(obfuscateNumber(nv))
else
self:emit(nv)
end

elseif t=="BooleanExpr" then
self:emit(node.Value and "true" or "false")

elseif t=="NilExpr" then
self:emit("nil")

elseif t=="Parentheses" then
self:emit("(")
self:proc(node.Inner)
self:emit(")")

elseif t=="BinopExpr" then
self:proc(node.Lhs)
self:emit(" "..node.Op.." ")
self:proc(node.Rhs)

elseif t=="UnopExpr" then
if node.Op=="not" then self:emit("not ")
elseif node.Op=="-" then self:emit("-")
elseif node.Op=="#" then self:emit("#")
else self:emit(node.Op) end
self:proc(node.Rhs)

elseif t=="Function" then
if node.IsLocal then
if node.Name then
self:emit("local function ")
if type(node.Name)=="table" and node.Name.Name then
self:emit(self:getName(node.Name.Name))
elseif type(node.Name)=="string" then
self:emit(self:getName(node.Name))
else
self:proc(node.Name)
end
else
self:emit("function")
end
else
self:emit("function ")
if node.Name then self:proc(node.Name) end
end
self:emit("(")
for i,a in ipairs(node.Arguments) do
self:emit(self:getName(a.Name))
if i<#node.Arguments then self:emit(",") end
end
if node.VarArg then
if #node.Arguments>0 then self:emit(",") end
self:emit("...")
end
self:emit(") ")
self:proc(node.Body)
self:emit("end ")

elseif t=="IfStatement" then
for i,c in ipairs(node.Clauses) do
if i==1 then
self:emit("if ")
self:proc(c.Condition)
self:emit(" then ")
elseif c.Condition then
self:emit("elseif ")
self:proc(c.Condition)
self:emit(" then ")
else
self:emit("else ")
end
self:proc(c.Body)
end
self:emit("end ")

elseif t=="WhileStatement" then
self:emit("while ")
self:proc(node.Condition)
self:emit(" do ")
self:proc(node.Body)
self:emit("end ")

elseif t=="NumericForStatement" then
self:emit("for ")
self:emit(self:getName(node.Variable.Name).."=")
self:proc(node.Start)
self:emit(",")
self:proc(node.End)
if node.Step then self:emit(",") self:proc(node.Step) end
self:emit(" do ")
self:proc(node.Body)
self:emit("end ")

elseif t=="GenericForStatement" then
self:emit("for ")
for i,v in ipairs(node.VariableList) do
self:emit(self:getName(v.Name))
if i<#node.VariableList then self:emit(",") end
end
self:emit(" in ")
for i,g in ipairs(node.Generators) do
self:proc(g)
if i<#node.Generators then self:emit(",") end
end
self:emit(" do ")
self:proc(node.Body)
self:emit("end ")

elseif t=="RepeatStatement" then
self:emit("repeat ")
self:proc(node.Body)
self:emit("until ")
self:proc(node.Condition)
self:emit(" ")

elseif t=="DoStatement" then
self:emit("do ")
self:proc(node.Body)
self:emit("end ")

elseif t=="ReturnStatement" then
self:emit("return ")
for i,a in ipairs(node.Arguments) do
self:proc(a)
if i<#node.Arguments then self:emit(",") end
end
self:emit(" ")

elseif t=="BreakStatement" then
self:emit("break ")

elseif t=="ConstructorExpr" then
self:emit("{")
for i,e in ipairs(node.EntryList) do
if e.Type=="Key" then
self:emit("[")
self:proc(e.Key)
self:emit("]=")
self:proc(e.Value)
elseif e.Type=="KeyString" then
self:emit(e.Key.."=")
self:proc(e.Value)
else
self:proc(e.Value)
end
if i<#node.EntryList then self:emit(",") end
end
self:emit("}")

elseif t=="DotsExpr" then
self:emit("...")

elseif t=="Eof" then

elseif t=="LabelStatement" then
self:emit("::"..node.Label..":: ")

elseif t=="GotoStatement" then
self:emit("goto "..node.Label.." ")
end
end

local function getRuntime()
local r = {}
table.insert(r, "local function ___X(a,b)")
table.insert(r, "local r,m=0,1 ")
table.insert(r, "while a>0 or b>0 do ")
table.insert(r, "local x,y=a%2,b%2 ")
table.insert(r, "if x~=y then r=r+m end ")
table.insert(r, "a=math.floor(a/2) ")
table.insert(r, "b=math.floor(b/2) ")
table.insert(r, "m=m*2 ")
table.insert(r, "end ")
table.insert(r, "return r ")
table.insert(r, "end ")
table.insert(r, "local function ___D(t,k)")
table.insert(r, "local r={} ")
table.insert(r, "for i=1,#t do ")
table.insert(r, "r[i]=string.char(___X(t[i],k)) ")
table.insert(r, "end ")
table.insert(r, "return table.concat(r) ")
table.insert(r, "end ")
return table.concat(r)
end

local function getJunkPrefix()
local j=""
for i=1,math.random(2,3) do j=j..generateJunkCode() end
return j
end

-- MAIN
local fn=arg[1]
if not fn then print("-- ERROR: No input file") return end

local f=io.open(fn,"rb")
if not f then print("-- ERROR: Cannot open file") return end
local code=f:read("*a")
f:close()

local ok,ast=parser.ParseLua(code)
if not ok then print("-- PARSE ERROR: "..tostring(ast)) return end

local u=Unparser:new()
u:proc(ast)

local runtime=getRuntime()
local junk=getJunkPrefix()
local body=u.output
local final=runtime..junk..body

if DEBUG_MODE then
print("-- ========== DEBUG: RUNTIME ==========")
print(runtime)
print("-- ========== DEBUG: JUNK ==========")
print(junk)
print("-- ========== DEBUG: BODY ==========")
print(body)
print("-- ========== DEBUG: END ==========")
else
print(final)
endif globals[oldName]then return oldName end
if not self.varMap[oldName]then self.varMap[oldName]=generateRandomName()end
return self.varMap[oldName]
end
function Unparser:encryptString(str)
if not str or str==""then return'""'end
local encrypted=xorEncrypt(str,self.encryptionKey)
local parts={}
for i,v in ipairs(encrypted)do table.insert(parts,tostring(v))end
return"DStr({"..table.concat(parts,",").."},"..self.encryptionKey..")"
end
function Unparser:processNode(node)
if not node then return end
local t=node.AstType
if t=="Statlist"then for _,stmt in ipairs(node.Body)do self:processNode(stmt)self:maybeInsertJunk()end
elseif t=="LocalStatement"then
self:emit("local ")
for i,var in ipairs(node.LocalList)do self:emit(self:getNewVarName(var.Name))if i<#node.LocalList then self:emit(",")end end
if #node.InitList>0 then self:emit("=")for i,expr in ipairs(node.InitList)do self:processNode(expr)if i<#node.InitList then self:emit(",")end end end
self:emit("; ")
elseif t=="AssignmentStatement"then
for i,lhs in ipairs(node.Lhs)do self:processNode(lhs)if i<#node.Lhs then self:emit(",")end end
self:emit("=")
for i,rhs in ipairs(node.Rhs)do self:processNode(rhs)if i<#node.Rhs then self:emit(",")end end
self:emit("; ")
elseif t=="CallStatement"then self:processNode(node.Expression)self:emit("; ")
elseif t=="CallExpr"then
self:processNode(node.Base)self:emit("(")
for i,arg in ipairs(node.Arguments)do self:processNode(arg)if i<#node.Arguments then self:emit(",")end end
self:emit(")")
elseif t=="StringCallExpr"then self:processNode(node.Base)self:emit("(")for _,arg in ipairs(node.Arguments)do self:processNode(arg)end self:emit(")")
elseif t=="TableCallExpr"then self:processNode(node.Base)self:emit("(")for _,arg in ipairs(node.Arguments)do self:processNode(arg)end self:emit(")")
elseif t=="VarExpr"then self:emit(self:getNewVarName(node.Name))
elseif t=="MemberExpr"then self:processNode(node.Base)self:emit(node.Indexer)self:emit(node.Ident.Data)
elseif t=="IndexExpr"then self:processNode(node.Base)self:emit("[")self:processNode(node.Index)self:emit("]")
elseif t=="StringExpr"then self:emit(self:encryptString(node.Value.Constant or""))
elseif t=="NumberExpr"then
local numVal=node.Value.Data
if numVal:match("^%d+$")and tonumber(numVal)<10000 then self:emit(obfuscateNumber(numVal))else self:emit(numVal)end
elseif t=="BooleanExpr"then self:emit(node.Value and"true"or"false")
elseif t=="NilExpr"then self:emit("nil")
elseif t=="Parentheses"then self:emit("(")self:processNode(node.Inner)self:emit(")")
elseif t=="BinopExpr"then self:processNode(node.Lhs)self:emit(" "..node.Op.." ")self:processNode(node.Rhs)
elseif t=="UnopExpr"then
if node.Op=="not"then self:emit("not ")elseif node.Op=="-"then self:emit("-")elseif node.Op=="#"then self:emit("#")else self:emit(node.Op)end
self:processNode(node.Rhs)
elseif t=="Function"then
if node.IsLocal then
if node.Name then
self:emit("local function ")
if type(node.Name)=="table"and node.Name.Name then self:emit(self:getNewVarName(node.Name.Name))
elseif type(node.Name)=="string"then self:emit(self:getNewVarName(node.Name))
else self:processNode(node.Name)end
else self:emit("function")end
else self:emit("function ")if node.Name then self:processNode(node.Name)end end
self:emit("(")
for i,arg in ipairs(node.Arguments)do self:emit(self:getNewVarName(arg.Name))if i<#node.Arguments then self:emit(",")end end
if node.VarArg then if #node.Arguments>0 then self:emit(",")end self:emit("...")end
self:emit(") ")self:processNode(node.Body)self:emit("end ")
elseif t=="IfStatement"then
for i,clause in ipairs(node.Clauses)do
if i==1 then self:emit("if ")self:processNode(clause.Condition)self:emit(" then ")
elseif clause.Condition then self:emit("elseif ")self:processNode(clause.Condition)self:emit(" then ")
else self:emit("else ")end
self:processNode(clause.Body)
end
self:emit("end ")
elseif t=="WhileStatement"then self:emit("while ")self:processNode(node.Condition)self:emit(" do ")self:processNode(node.Body)self:emit("end ")
elseif t=="NumericForStatement"then
self:emit("for ")self:emit(self:getNewVarName(node.Variable.Name).."=")
self:processNode(node.Start)self:emit(",")self:processNode(node.End)
if node.Step then self:emit(",")self:processNode(node.Step)end
self:emit(" do ")self:processNode(node.Body)self:emit("end ")
elseif t=="GenericForStatement"then
self:emit("for ")
for i,var in ipairs(node.VariableList)do self:emit(self:getNewVarName(var.Name))if i<#node.VariableList then self:emit(",")end end
self:emit(" in ")
for i,gen in ipairs(node.Generators)do self:processNode(gen)if i<#node.Generators then self:emit(",")end end
self:emit(" do ")self:processNode(node.Body)self:emit("end ")
elseif t=="RepeatStatement"then self:emit("repeat ")self:processNode(node.Body)self:emit("until ")self:processNode(node.Condition)self:emit(" ")
elseif t=="DoStatement"then self:emit("do ")self:processNode(node.Body)self:emit("end ")
elseif t=="ReturnStatement"then
self:emit("return ")
for i,arg in ipairs(node.Arguments)do self:processNode(arg)if i<#node.Arguments then self:emit(",")end end
self:emit(" ")
elseif t=="BreakStatement"then self:emit("break ")
elseif t=="ConstructorExpr"then
self:emit("{")
for i,entry in ipairs(node.EntryList)do
if entry.Type=="Key"then self:emit("[")self:processNode(entry.Key)self:emit("]=")self:processNode(entry.Value)
elseif entry.Type=="KeyString"then self:emit(entry.Key.."=")self:processNode(entry.Value)
else self:processNode(entry.Value)end
if i<#node.EntryList then self:emit(",")end
end
self:emit("}")
elseif t=="DotsExpr"then self:emit("...")
elseif t=="Eof"then
elseif t=="LabelStatement"then self:emit("::"..node.Label..":: ")
elseif t=="GotoStatement"then self:emit("goto "..node.Label.." ")
end
end
local RUNTIME="local function XByte(a,b) local r,m=0,1; while a>0 or b>0 do local x,y=a%2,b%2; if x~=y then r=r+m; end; a=math.floor(a/2); b=math.floor(b/2); m=m*2; end; return r; end; local function DStr(t,k) local r={}; for i=1,#t do r[i]=string.char(XByte(t[i],k)); end; return table.concat(r); end; "
local function generateJunkPrefix()
local junk=""
for i=1,math.random(2,3)do junk=junk..generateJunkCode()end
return junk
end
local filename=arg[1]
if not filename then print("-- ERROR: No input")return end
local f=io.open(filename,"rb")
if not f then print("-- ERROR: Cannot open")return end
local code=f:read("*a")
f:close()
local success,ast=parser.ParseLua(code)
if not success then print("-- ERROR: "..tostring(ast))return end
local unparser=Unparser:new()
unparser:processNode(ast)
print(RUNTIME..generateJunkPrefix()..unparser.output)
