package.path=package.path..";./?.lua;./engine/?.lua;/app/engine/?.lua"
local parser=require("parser")
math.randomseed(os.time())

local DEBUG_MODE=true
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
repeat n="_" for i=1,math.random(12,20) do n=n..cs[math.random(1,4)] end until not usedNames[n]
usedNames[n]=true
return n
end

local function genJunkVar()
local n="_"..string.char(math.random(97,122))
for i=1,math.random(4,8) do n=n..string.char(math.random(97,122)) end
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
local m=math.random(1,5)
local a=math.random(1,100)
local b=math.random(1,50)
if m==1 then return"(("..(n+a)..")-("..a.."))"
elseif m==2 then return"(("..(n-a)..")+("..a.."))"
elseif m==3 then return"("..math.floor(n/2).."+"..(n-math.floor(n/2))..")"
elseif m==4 then return"(("..a.."+"..(n-a).."))"
else return"((("..a.."+"..b..")+"..(n-a-b).."))" end
end

local function genOpaque(t)
local a,b=math.random(100,500),math.random(501,999)
if t then
local m=math.random(1,6)
if m==1 then return"("..a.."<"..b..")"
elseif m==2 then return"(type('')=='string')"
elseif m==3 then return"(#''==0)"
elseif m==4 then return"((1+1)==2)"
elseif m==5 then return"(not not true)"
else return"(''=='')" end
else
local m=math.random(1,4)
if m==1 then return"("..b.."<"..a..")"
elseif m==2 then return"(type(1)=='string')"
elseif m==3 then return"((1+1)==3)"
else return"(not true)" end
end
end

local function genJunk()
local m=math.random(1,8)
local v=genJunkVar()
local n=math.random(100,9999)
if m==1 then return"local "..v.."="..obfNum(tostring(n))..";"
elseif m==2 then return"local "..v.."="..obfNum(tostring(n)).."+"..obfNum(tostring(math.random(1,100)))..";"
elseif m==3 then return"local "..v.."="..genOpaque(true).." and "..obfNum(tostring(n)).." or 0;"
elseif m==4 then return"local "..v.."=(function() return "..obfNum(tostring(n)).." end)();"
elseif m==5 then return"local "..v.."={};"
elseif m==6 then return"local "..v..";"..v.."="..obfNum(tostring(n))..";"
elseif m==7 then return"local "..v.."="..obfNum(tostring(n))..";if "..genOpaque(false).." then "..v.."=0;end;"
else return"local "..v.."="..obfNum(tostring(n))..";do local _="..v..";end;" end
end

local function genOpaqueBlock()
local m=math.random(1,5)
if m==1 then return"if "..genOpaque(true).." then "..genJunk()..genJunk()..genJunk().."end;"
elseif m==2 then return"if "..genOpaque(false).." then "..genJunk().."else "..genJunk()..genJunk().."end;"
elseif m==3 then return"do "..genJunk()..genJunk()..genJunk().."end;"
elseif m==4 then return"for _="..obfNum("1")..","..obfNum("0").." do "..genJunk()..genJunk().."end;"
else return"while "..genOpaque(false).." do "..genJunk().."break;end;" end
end

local function genDeadCode()
local m=math.random(1,4)
local v1,v2=genJunkVar(),genJunkVar()
local n1,n2=math.random(1000,9999),math.random(1000,9999)
if m==1 then return"if "..genOpaque(false).." then local "..v1.."="..obfNum(tostring(n1))..";local "..v2.."="..obfNum(tostring(n2))..";end;"
elseif m==2 then return"if "..genOpaque(false).." then for _=1,10 do local "..v1.."="..obfNum(tostring(n1))..";end;end;"
elseif m==3 then return"if "..genOpaque(false).." then repeat local "..v1.."="..obfNum(tostring(n1))..";until true;end;"
else return"if "..genOpaque(false).." then local function "..v1.."() return "..obfNum(tostring(n1))..";end;"..v1.."();end;" end
end

local function genBloat()
local b=""
for i=1,math.random(4,8) do
local m=math.random(1,10)
if m<=4 then b=b..genJunk()
elseif m<=7 then b=b..genOpaqueBlock()
else b=b..genDeadCode() end
end
return b
end

local function genHeavyBloat()
local b=""
for i=1,math.random(10,18) do
local m=math.random(1,10)
if m<=4 then b=b..genJunk()
elseif m<=7 then b=b..genOpaqueBlock()
else b=b..genDeadCode() end
end
return b
end

local function genMassiveBloat()
local b=""
for i=1,math.random(15,25) do
local m=math.random(1,10)
if m<=3 then b=b..genJunk()
elseif m<=6 then b=b..genOpaqueBlock()
elseif m<=8 then b=b..genDeadCode()
else b=b..genBloat() end
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
local m=math.random(1,10)
if m<=4 then self:e(genJunk())
elseif m<=7 then self:e(genOpaqueBlock())
else self:e(genDeadCode()) end
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
if not n then return end
local t=n.AstType

if t=="Statlist" then
for _,s in ipairs(n.Body) do self:p(s) self:mj() end

elseif t=="LocalStatement" then
self:e("local ")
for i,v in ipairs(n.LocalList) do self:e(self:gn(v.Name)) if i<#n.LocalList then self:e(",") end end
if #n.InitList>0 then
self:e("=")
for i,x in ipairs(n.InitList) do self:p(x) if i<#n.InitList then self:e(",") end end
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
self:p(n.Base) self:e("(")
for i,a in ipairs(n.Arguments) do self:p(a) if i<#n.Arguments then self:e(",") end end
self:e(")")

elseif t=="StringCallExpr" then
self:p(n.Base) self:e("(")
for _,a in ipairs(n.Arguments) do self:p(a) end
self:e(")")

elseif t=="TableCallExpr" then
self:p(n.Base) self:e("(")
for _,a in ipairs(n.Arguments) do self:p(a) end
self:e(")")

elseif t=="VarExpr" then
self:e(self:gn(n.Name))

elseif t=="MemberExpr" then
self:p(n.Base)
self:e(n.Indexer)
self:e(n.Ident.Data)

elseif t=="IndexExpr" then
self:p(n.Base) self:e("[") self:p(n.Index) self:e("]")

elseif t=="StringExpr" then
self:e(self:es(n.Value.Constant or""))

elseif t=="NumberExpr" then
local nv=n.Value.Data
if nv:match("^%d+$") and tonumber(nv)<50000 then
self:e(self:en(nv))
else
self:e(nv)
end

elseif t=="BooleanExpr" then
if n.Value then
if math.random(1,3)==1 then self:e("("..genOpaque(true)..")") else self:e("true") end
else
if math.random(1,3)==1 then self:e("("..genOpaque(false)..")") else self:e("false") end
end

elseif t=="NilExpr" then
self:e("nil")

elseif t=="Parentheses" then
self:e("(") self:p(n.Inner) self:e(")")

elseif t=="BinopExpr" then
self:p(n.Lhs) self:e(" "..n.Op.." ") self:p(n.Rhs)

elseif t=="UnopExpr" then
if n.Op=="not" then self:e("not ")
elseif n.Op=="-" then self:e("-")
elseif n.Op=="#" then self:e("#")
else self:e(n.Op) end
self:p(n.Rhs)

elseif t=="Function" then
if n.IsLocal then
if n.Name then
self:e("local function ")
if type(n.Name)=="table" and n.Name.Name then self:e(self:gn(n.Name.Name))
elseif type(n.Name)=="string" then self:e(self:gn(n.Name))
else self:p(n.Name) end
else self:e("function") end
else
self:e("function ")
if n.Name then self:p(n.Name) end
end
self:e("(")
for i,a in ipairs(n.Arguments) do self:e(self:gn(a.Name)) if i<#n.Arguments then self:e(",") end end
if n.VarArg then if #n.Arguments>0 then self:e(",") end self:e("...") end
self:e(") ")
self:e(genHeavyBloat())
self:p(n.Body)
self:e(genBloat())
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
self:e("for ") self:e(self:gn(n.Variable.Name).."=")
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

elseif t=="BreakStatement" then
self:e("break ")

elseif t=="ConstructorExpr" then
self:e("{")
for i,en in ipairs(n.EntryList) do
if en.Type=="Key" then self:e("[") self:p(en.Key) self:e("]=") self:p(en.Value)
elseif en.Type=="KeyString" then self:e("["..self:es(en.Key).."]=") self:p(en.Value)
else self:p(en.Value) end
if i<#n.EntryList then self:e(",") end
end
self:e("}")

elseif t=="DotsExpr" then
self:e("...")

elseif t=="Eof" then

elseif t=="LabelStatement" then
self:e("::"..n.Label..":: ")

elseif t=="GotoStatement" then
self:e("goto "..n.Label.." ")
end
end

local function buildRuntime()
local r={}
r[#r+1]="local _VM={} "
r[#r+1]=genBloat()
r[#r+1]="_VM.X=function(a,b) local r,m=0,1 while a>0 or b>0 do local x,y=a%2,b%2 if x~=y then r=r+m end a=math.floor(a/2) b=math.floor(b/2) m=m*2 end return r end "
r[#r+1]=genBloat()
r[#r+1]="_VM.D=function(t,k) local r={} for i=1,#t do r[i]=string.char(_VM.X(t[i],k)) end return table.concat(r) end "
r[#r+1]=genBloat()
return table.concat(r)
end

local function buildStringTable()
local r={}
r[#r+1]="_VM.ST={} "
r[#r+1]=genBloat()
for i=1,#stringTable do
local s=stringTable[i]
if s and s.enc then
local encStr="{"
for j,v in ipairs(s.enc) do
encStr=encStr..obfNum(tostring(v))
if j<#s.enc then encStr=encStr.."," end
end
encStr=encStr.."}"
r[#r+1]="_VM.ST["..obfNum(tostring(i)).."]="..encStr.." "
r[#r+1]=genJunk()
end
end
r[#r+1]=genBloat()
r[#r+1]="local function _GS(k) "
r[#r+1]=genJunk()
r[#r+1]="local t=_VM.ST[k] "
r[#r+1]="if t then return _VM.D(t,"..obfNum(tostring(VMKEY))..") end "
r[#r+1]="return '' "
r[#r+1]="end "
r[#r+1]=genBloat()
return table.concat(r)
end

local function buildConstantTable()
local r={}
r[#r+1]="_VM.CT={} "
r[#r+1]=genBloat()
for i=1,#constantTable do
local c=constantTable[i]
if c then
r[#r+1]="_VM.CT["..obfNum(tostring(i)).."]={v="..obfNum(tostring(c.val))..",o="..obfNum(tostring(c.off)).."} "
r[#r+1]=genJunk()
end
end
r[#r+1]=genBloat()
r[#r+1]="local function _GN(k) "
r[#r+1]=genJunk()
r[#r+1]="local c=_VM.CT[k] "
r[#r+1]="if c then return c.v-c.o end "
r[#r+1]="return 0 "
r[#r+1]="end "
r[#r+1]=genBloat()
return table.concat(r)
end

local function genAntiTamper()
local a={}
a[#a+1]="do "
a[#a+1]=genMassiveBloat()
a[#a+1]="local _chk="..obfNum(tostring(math.random(10000,99999)))..";"
a[#a+1]="if rawget(_G,'__DEOBF') then while true do end end;"
a[#a+1]="if rawget(_G,'__DEBUG') then return end;"
a[#a+1]="if rawget(_G,'__TAMPER') then error('') end;"
a[#a+1]=genMassiveBloat()
a[#a+1]="end "
return table.concat(a)
end

local function wrapLayer1(code)
local fn=genName()
local w=""
w=w.."local function "..fn.."() "
w=w..genMassiveBloat()
w=w..code
w=w..genMassiveBloat()
w=w.."end "
w=w..genHeavyBloat()
w=w..fn.."() "
return w
end

local function wrapLayer2(code)
local fn1,fn2=genName(),genName()
local w=""
w=w.."local "..fn1.." "
w=w..genHeavyBloat()
w=w..fn1.."=function() "
w=w..genMassiveBloat()
w=w.."local "..fn2.."=function() "
w=w..genHeavyBloat()
w=w..code
w=w..genHeavyBloat()
w=w.."end "
w=w..genBloat()
w=w.."return "..fn2.."() "
w=w.."end "
w=w..genHeavyBloat()
w=w.."return "..fn1.."() "
return w
end

local function wrapLayer3(code)
local fn=genName()
local w=""
w=w.."do "
w=w..genMassiveBloat()
w=w.."local "..fn.."=(function() "
w=w..genHeavyBloat()
w=w.."return function() "
w=w..genBloat()
w=w..code
w=w..genBloat()
w=w.."end "
w=w.."end)() "
w=w..genHeavyBloat()
w=w.."if "..genOpaque(true).." then "
w=w..genJunk()
w=w..fn.."() "
w=w.."end "
w=w..genMassiveBloat()
w=w.."end "
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
local body=u.out

local wrapped=wrapLayer1(body)
wrapped=wrapLayer2(wrapped)
wrapped=wrapLayer3(wrapped)

local final=""
final=final..runtime
final=final..strTable
final=final..constTable
final=final..antiTamper
final=final..genMassiveBloat()
final=final..wrapped
final=final..genMassiveBloat()

if DEBUG_MODE then
print("--[[ =============================== ]]")
print("--[[ OBFUSCATOR ENGINE V6 - DEBUG   ]]")
print("--[[ =============================== ]]")
print("--[[ VMKEY: "..VMKEY.." ]]")
print("--[[ Strings Collected: "..#stringTable.." ]]")
print("--[[ Constants Collected: "..#constantTable.." ]]")
print("--[[ Body Size: "..#body.." bytes ]]")
print("--[[ Final Size: "..#final.." bytes ]]")
print("--[[ =============================== ]]")
print("")
print(final)
else
print(final)
end
