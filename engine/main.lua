package.path=package.path..";./?.lua;./engine/?.lua;/app/engine/?.lua"
local parser=require("parser")
math.randomseed(os.time())

local DEBUG_MODE=false
local usedNames={}
local stringTable={}
local constantTable={}
local VMKEY=math.random(50,200)

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
if n<0 or n>50000 then return ns end
if n==0 then return"((1)-(1))" end
if n==1 then return"((2)-(1))" end
local m=math.random(1,4)
local a=math.random(1,100)
if m==1 then return"(("..(n+a)..")-("..a.."))"
elseif m==2 then return"(("..(n-a)..")+("..a.."))"
elseif m==3 then return"("..math.floor(n/2).."+"..(n-math.floor(n/2))..")"
else return"(("..a.."+"..(n-a).."))" end
end

local function genOpaque(t)
local a,b=math.random(100,500),math.random(501,999)
if t then return"("..a.."<"..b..")" else return"("..b.."<"..a..")" end
end

local function genJunk()
local v=genJunkVar()
local n=math.random(100,9999)
return"local "..v.."="..obfNum(tostring(n))..";"
end

local function genOpaqueBlock()
return"if "..genOpaque(true).." then "..genJunk()..genJunk().."end;"
end

local function genDeadCode()
local v1=genJunkVar()
local n1=math.random(1000,9999)
return"if "..genOpaque(false).." then local "..v1.."="..obfNum(tostring(n1))..";end;"
end

local function genBloat()
local b=""
for i=1,math.random(3,6) do
local m=math.random(1,3)
if m==1 then b=b..genJunk()
elseif m==2 then b=b..genOpaqueBlock()
else b=b..genDeadCode() end
end
return b
end

local function genHeavyBloat()
local b=""
for i=1,math.random(8,15) do
local m=math.random(1,3)
if m==1 then b=b..genJunk()
elseif m==2 then b=b..genOpaqueBlock()
else b=b..genDeadCode() end
end
return b
end

local function addString(s)
if not s then return 1 end
for k,v in pairs(stringTable) do if v.orig==s then return k end end
local idx=#stringTable+1
stringTable[idx]={orig=s,enc=xorEnc(s,VMKEY)}
return idx
end

local function addConstant(n)
if not n then return 1 end
local num=tonumber(n)
if not num then return 1 end
for k,v in pairs(constantTable) do if v.orig==num then return k end end
local idx=#constantTable+1
local offset=math.random(1000,9999)
constantTable[idx]={orig=num,val=num+offset,off=offset}
return idx
end

local U={}
function U:new()
local o={vm={},out="",jc=0,ji=math.random(2,4)}
setmetatable(o,self)
self.__index=self
return o
end

function U:e(s) self.out=self.out..s end

function U:mj()
self.jc=self.jc+1
if self.jc>=self.ji then
self.jc=0
self.ji=math.random(2,4)
self:e(genJunk())
end
end

function U:gn(old)
if GLOBALS[old] then return old end
if not self.vm[old] then self.vm[old]=genName() end
return self.vm[old]
end

function U:es(s)
if not s or s=="" then return'""' end
local idx=addString(s)
return"_GS("..obfNum(tostring(idx))..")"
end

function U:en(ns)
local n=tonumber(ns)
if not n or n~=math.floor(n) or n<0 or n>50000 then return obfNum(ns) end
local idx=addConstant(n)
return"_GN("..obfNum(tostring(idx))..")"
end

function U:p(n)
if not n then return "" end
local t=n.AstType

if t=="Statlist" then
for _,s in ipairs(n.Body) do self:p(s) self:mj() end

elseif t=="LocalStatement" then
self:e("local ")
for i,v in ipairs(n.LocalList) do self:e(self:gn(v.Name)) if i<#n.LocalList then self:e(",") end end
if #n.InitList>0 then
self:e("=")
for i,x in ipairs(n.InitList) do self:e(self:p(x)) if i<#n.InitList then self:e(",") end end
end
self:e(" ")

elseif t=="AssignmentStatement" then
for i,l in ipairs(n.Lhs) do self:e(self:p(l)) if i<#n.Lhs then self:e(",") end end
self:e("=")
for i,r in ipairs(n.Rhs) do self:e(self:p(r)) if i<#n.Rhs then self:e(",") end end
self:e(" ")

elseif t=="CallStatement" then
self:e(self:p(n.Expression)) self:e(" ")

elseif t=="CallExpr" then
-- SAFE METHOD WRAPPER: (function(o) return o["method"](o, args) end)(obj)
if n.Base.AstType == "MemberExpr" and n.Base.Indexer == ":" then
local obj = n.Base.Base
local method = n.Base.Ident.Data
local tempVar = genJunkVar()
self:e("(function("..tempVar..") return "..tempVar.."["..self:es(method).."]("..tempVar)
if #n.Arguments > 0 then self:e(",") end
for i,a in ipairs(n.Arguments) do self:e(self:p(a)) if i<#n.Arguments then self:e(",") end end
self:e(") end)("..self:p(obj)..")")
else
self:e(self:p(n.Base).."(")
for i,a in ipairs(n.Arguments) do self:e(self:p(a)) if i<#n.Arguments then self:e(",") end end
self:e(")")
end

elseif t=="StringCallExpr" then
self:e(self:p(n.Base).."(")
for _,a in ipairs(n.Arguments) do self:e(self:p(a)) end
self:e(")")

elseif t=="TableCallExpr" then
self:e(self:p(n.Base).."(")
for _,a in ipairs(n.Arguments) do self:e(self:p(a)) end
self:e(")")

elseif t=="VarExpr" then self:e(self:gn(n.Name))

elseif t=="MemberExpr" then
-- SECURE MEMBER ACCESS: obj["Prop"] instead of obj.Prop
self:e(self:p(n.Base).."["..self:es(n.Ident.Data).."]")

elseif t=="IndexExpr" then
self:e(self:p(n.Base).."["..self:p(n.Index).."]")

elseif t=="StringExpr" then self:e(self:es(n.Value.Constant or""))

elseif t=="NumberExpr" then
local nv=n.Value.Data
if nv:match("^%d+$") and tonumber(nv)<50000 then self:e(self:en(nv)) else self:e(nv) end

elseif t=="BooleanExpr" then
if n.Value then self:e("true") else self:e("false") end

elseif t=="NilExpr" then self:e("nil")

elseif t=="Parentheses" then self:e("("..self:p(n.Inner)..")")

elseif t=="BinopExpr" then
local opMap={["+"]="ADD",["-"]="SUB",["*"]="MUL",["/"]="DIV",["^"]="POW",["%"]="MOD"}
if opMap[n.Op] then
self:e("_VM."..opMap[n.Op].."("..self:p(n.Lhs)..","..self:p(n.Rhs)..")")
else
self:e(self:p(n.Lhs).." "..n.Op.." "..self:p(n.Rhs))
end

elseif t=="UnopExpr" then
local op_str
if n.Op=="not" then op_str="not "
elseif n.Op=="-" then op_str="-"
elseif n.Op=="#" then op_str="#"
else op_str=n.Op end
self:e(op_str..self:p(n.Rhs))

elseif t=="Function" then
if n.IsLocal then
if n.Name then self:e("local function "..self:gn(type(n.Name)=="table" and n.Name.Name or n.Name))
else self:e("function") end
else self:e("function ") if n.Name then self:e(self:p(n.Name)) end end
self:e("(")
for i,a in ipairs(n.Arguments) do self:e(self:gn(a.Name)) if i<#n.Arguments then self:e(",") end end
if n.VarArg then if #n.Arguments>0 then self:e(",") end self:e("...") end
self:e(") "..genBloat())
self:e(self:p(n.Body))
self:e("end ")

elseif t=="IfStatement" then
for i,c in ipairs(n.Clauses) do
if i==1 then self:e("if "..genOpaque(true).." and "..self:p(c.Condition).." then "..genJunk())
elseif c.Condition then self:e("elseif "..genOpaque(true).." and "..self:p(c.Condition).." then "..genJunk())
else self:e("else "..genJunk()) end
self:e(self:p(c.Body))
end
self:e("end ")

elseif t=="WhileStatement" then self:e("while "..genOpaque(true).." and "..self:p(n.Condition).." do "..genJunk()) self:e(self:p(n.Body)) self:e("end ")

elseif t=="NumericForStatement" then
self:e("for "..self:gn(n.Variable.Name).."=")
self:e(self:p(n.Start)..","..self:p(n.End))
if n.Step then self:e(","..self:p(n.Step)) end
self:e(" do "..genJunk()) self:e(self:p(n.Body)) self:e("end ")

elseif t=="GenericForStatement" then
self:e("for ")
for i,v in ipairs(n.VariableList) do self:e(self:gn(v.Name)) if i<#n.VariableList then self:e(",") end end
self:e(" in ")
for i,g in ipairs(n.Generators) do self:e(self:p(g)) if i<#n.Generators then self:e(",") end end
self:e(" do "..genJunk()) self:e(self:p(n.Body)) self:e("end ")

elseif t=="RepeatStatement" then self:e("repeat "..genJunk()) self:e(self:p(n.Body)) self:e("until "..genOpaque(true).." and "..self:p(n.Condition).." ")

elseif t=="DoStatement" then self:e("do "..genJunk()) self:e(self:p(n.Body)) self:e("end ")

elseif t=="ReturnStatement" then
self:e("return ")
for i,a in ipairs(n.Arguments) do self:e(self:p(a)) if i<#n.Arguments then self:e(",") end end
self:e(" ")

elseif t=="BreakStatement" then self:e("break ")

elseif t=="ConstructorExpr" then
self:e("{")
for i,en in ipairs(n.EntryList) do
if en.Type=="Key" then self:e("[") self:e(self:p(en.Key)) self:e("]=") self:e(self:p(en.Value))
elseif en.Type=="KeyString" then self:e("["..self:es(en.Key).."]=") self:e(self:p(en.Value))
else self:e(self:p(en.Value)) end
if i<#n.EntryList then self:e(",") end
end
self:e("}")

elseif t=="DotsExpr" then self:e("...")

elseif t=="Eof" then
elseif t=="LabelStatement" then self:e("::"..n.Label..":: ")
elseif t=="GotoStatement" then self:e("goto "..n.Label.." ")
end
return ""
end

local function buildRuntime()
local r={}
r[#r+1]="local _VM={} "
r[#r+1]="function _VM.X(a,b) local r,m=0,1 while a>0 or b>0 do local x,y=a%2,b%2 if x~=y then r=r+m end a=math.floor(a/2) b=math.floor(b/2) m=m*2 end return r end "
r[#r+1]="function _VM.D(t,k) local r={} for i=1,#t do r[i]=string.char(_VM.X(t[i],k)) end return table.concat(r) end "
r[#r+1]="function _VM.ADD(a,b) return a+b end "
r[#r+1]="function _VM.SUB(a,b) return a-b end "
r[#r+1]="function _VM.MUL(a,b) return a*b end "
r[#r+1]="function _VM.DIV(a,b) return a/b end "
r[#r+1]="function _VM.MOD(a,b) return a%b end "
r[#r+1]="function _VM.POW(a,b) return a^b end "
r[#r+1]=genBloat()
return table.concat(r)
end

local function buildStringTable()
local r={}
r[#r+1]="_VM.ST={} "
for i=1,#stringTable do
local s=stringTable[i]
if s and s.enc then
local encStr="{"
for j,v in ipairs(s.enc) do encStr=encStr..obfNum(tostring(v)).."," end
encStr=encStr:sub(1,-2).."}"
r[#r+1]="_VM.ST["..obfNum(tostring(i)).."]="..encStr..";"
if i%3==0 then r[#r+1]=genJunk() end
end
end
r[#r+1]=genBloat()
r[#r+1]="local function _GS(k) local t=_VM.ST[k] if t then return _VM.D(t,"..obfNum(tostring(VMKEY))..") end return '' end "
r[#r+1]=genBloat()
return table.concat(r)
end

local function buildConstantTable()
local r={}
r[#r+1]="_VM.CT={} "
for i=1,#constantTable do
local c=constantTable[i]
if c then
r[#r+1]="_VM.CT["..obfNum(tostring(i)).."]={v="..obfNum(tostring(c.val))..",o="..obfNum(tostring(c.off)).."};"
if i%3==0 then r[#r+1]=genJunk() end
end
end
r[#r+1]=genBloat()
r[#r+1]="local function _GN(k) local c=_VM.CT[k] if c then return c.v-c.o end return 0 end "
r[#r+1]=genBloat()
return table.concat(r)
end

local function genAntiTamper()
local a={}
a[#a+1]="do "
a[#a+1]=genHeavyBloat()
a[#a+1]="if rawget(_G,'__DEOBF') then while true do end end;"
a[#a+1]="if rawget(_G,'__DEBUG') then return end;"
a[#a+1]=genHeavyBloat()
a[#a+1]="end "
return table.concat(a)
end

local function genFakeData()
local d={}
d[#d+1]="local _FAKE={"
for i=1,math.random(100,200) do
d[#d+1]="["..i.."]='"..genJunkVar().."',"
end
d[#d+1]="} "
return table.concat(d)
end

local function wrapCode(code)
local fn=genName()
local w=""
w=w.."local function "..fn.."() "
w=w..genHeavyBloat()
w=w..code
w=w..genHeavyBloat()
w=w.."end "
w=w..genBloat()
w=w..fn.."() "
return w
end

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
local strTable=buildStringTable()
local constTable=buildConstantTable()
local antiTamper=genAntiTamper()
local fakeData=genFakeData()
local body=u.out
local wrapped=wrapCode(body)

local final=runtime..fakeData..strTable..constTable..antiTamper..genHeavyBloat()..wrapped..genHeavyBloat()

if DEBUG_MODE then
io.stderr:write("\n[DEBUG] Final Size: "..#final.."\n")
end

print(final)
