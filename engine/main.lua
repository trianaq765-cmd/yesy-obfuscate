package.path=package.path..";./?.lua;./engine/?.lua;/app/engine/?.lua"
local parser=require("parser")
math.randomseed(os.time())

local DEBUG_MODE=false
local usedNames={}

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
["getgc"]=1,["queue_on_teleport"]=1,["_"]=1,
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

local function encStr(s,k)
if not s or s=="" then return'""' end
local enc=xorEnc(s,k)
local p={}
for i=1,#enc do p[i]=tostring(enc[i]) end
return"_._d({"..table.concat(p,",").."},"..k..")"
end

local function obfNum(ns)
local n=tonumber(ns)
if not n then return ns end
if n~=math.floor(n) then return ns end
if n<0 or n>50000 then return ns end
if n==0 then return"((1)-( 1))" end
if n==1 then return"((2)-(1))" end
local m=math.random(1,6)
local a=math.random(1,200)
local b=math.random(1,100)
if m==1 then return"(("..(n+a)..")-("..a.."))"
elseif m==2 then return"(("..(n-a)..")+("..a.."))"
elseif m==3 then return"((("..(n*2)..")/2))"
elseif m==4 then return"(("..a.."+"..(n-a).."))"
elseif m==5 then return"((("..b.."*"..math.floor(n/b+1)..")-("..(b*math.floor(n/b+1)-n).."))"
else return"(("..(n+a+b)..")-("..a..")-("..b.."))" end
end

local function genOpaque(t)
local a,b=math.random(100,500),math.random(501,999)
if t then
local m=math.random(1,8)
if m==1 then return"("..a.."<"..b..")"
elseif m==2 then return"(("..a.."+"..b..")>"..a..")"
elseif m==3 then return"(type('')=='string')"
elseif m==4 then return"(#''==0)"
elseif m==5 then return"((1+1)==2)"
elseif m==6 then return"(not not true)"
elseif m==7 then return"(''=='')"
else return"(nil==nil)" end
else
local m=math.random(1,6)
if m==1 then return"("..b.."<"..a..")"
elseif m==2 then return"(type(1)=='string')"
elseif m==3 then return"(#''~=0)"
elseif m==4 then return"((1+1)==3)"
elseif m==5 then return"(not true)"
else return"(''~='')" end
end
end

local function genJunk()
local m=math.random(1,8)
local v=genJunkVar()
local n=math.random(100,9999)
if m==1 then return"local "..v.."="..obfNum(tostring(n)).." "
elseif m==2 then return"local "..v.."="..obfNum(tostring(n)).."+"..obfNum(tostring(math.random(1,100))).." "
elseif m==3 then return"local "..v.."="..genOpaque(true).." and "..obfNum(tostring(n)).." or "..obfNum(tostring(0)).." "
elseif m==4 then return"local "..v.."=(function() return "..obfNum(tostring(n)).." end)() "
elseif m==5 then return"local "..v.."={} "..v.."["..obfNum(tostring(1)).."]="..obfNum(tostring(n)).." "
elseif m==6 then return"local "..v.."="..obfNum(tostring(n)).." "..v.."="..v.."+("..obfNum(tostring(math.random(1,50)))..") "
elseif m==7 then return"local "..v.."="..obfNum(tostring(n)).." if "..genOpaque(false).." then "..v.."="..obfNum(tostring(0)).." end "
else return"local "..v..";"..v.."="..obfNum(tostring(n)).." " end
end

local function genOpaqueBlock()
local m=math.random(1,6)
if m==1 then return"if "..genOpaque(true).." then "..genJunk()..genJunk().."end "
elseif m==2 then return"if "..genOpaque(false).." then "..genJunk().."else "..genJunk()..genJunk().."end "
elseif m==3 then return"while "..genOpaque(false).." do "..genJunk().."break end "
elseif m==4 then return"do "..genJunk()..genJunk().."end "
elseif m==5 then return"if "..genOpaque(true).." then if "..genOpaque(true).." then "..genJunk().."end end "
else return"for _="..obfNum(tostring(1))..","..obfNum(tostring(0)).." do "..genJunk().."end " end
end

local function genDeadCode()
local m=math.random(1,5)
local v1,v2=genJunkVar(),genJunkVar()
local n1,n2=math.random(1000,9999),math.random(1000,9999)
if m==1 then return"if "..genOpaque(false).." then local "..v1.."="..obfNum(tostring(n1)).." local "..v2.."="..obfNum(tostring(n2)).." "..v1.."="..v2.." end "
elseif m==2 then return"if "..genOpaque(false).." then for "..v1.."="..obfNum(tostring(1))..","..obfNum(tostring(n1)).." do local "..v2.."="..obfNum(tostring(n2)).." end end "
elseif m==3 then return"if "..genOpaque(false).." then while true do local "..v1.."="..obfNum(tostring(n1)).." break end end "
elseif m==4 then return"if "..genOpaque(false).." then repeat local "..v1.."="..obfNum(tostring(n1)).." until true end "
else return"if "..genOpaque(false).." then local "..v1.."=function() return "..obfNum(tostring(n1)).." end local "..v2.."="..v1.."() end " end
end

local function genBloat()
local b=""
local count=math.random(5,10)
for i=1,count do
local m=math.random(1,10)
if m<=4 then b=b..genJunk()
elseif m<=7 then b=b..genOpaqueBlock()
else b=b..genDeadCode() end
end
return b
end

local U={}
function U:new()
local o={vm={},out="",jc=0,ji=math.random(3,5),ek=math.random(50,200)}
setmetatable(o,self)
self.__index=self
return o
end

function U:e(s) self.out=self.out..s end

function U:mj()
self.jc=self.jc+1
if self.jc>=self.ji then
self.jc=0
self.ji=math.random(3,5)
local m=math.random(1,10)
if m<=3 then self:e(genJunk())
elseif m<=6 then self:e(genOpaqueBlock())
elseif m<=8 then self:e(genDeadCode())
else self:e(genBloat()) end
end
end

function U:gn(old)
if GLOBALS[old] then return old end
if not self.vm[old] then self.vm[old]=genName() end
return self.vm[old]
end

function U:es(s)
if not s or s=="" then return'""' end
local k=math.random(50,200)
local enc=xorEnc(s,k)
local p={}
for i=1,#enc do p[i]=obfNum(tostring(enc[i])) end
return"_._d({"..table.concat(p,",").."},"..obfNum(tostring(k))..")"
end

function U:em(s)
if not s or s=="" then return'""' end
local k=math.random(50,200)
local enc=xorEnc(s,k)
local p={}
for i=1,#enc do p[i]=obfNum(tostring(enc[i])) end
return"_._d({"..table.concat(p,",").."},"..obfNum(tostring(k))..")"
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
local idx=n.Indexer
local nm=n.Ident.Data
self:e("[")
self:e(self:em(nm))
self:e("]")

elseif t=="IndexExpr" then
self:p(n.Base) self:e("[") self:p(n.Index) self:e("]")

elseif t=="StringExpr" then
self:e(self:es(n.Value.Constant or""))

elseif t=="NumberExpr" then
local nv=n.Value.Data
if nv:match("^%d+$") and tonumber(nv)<5000 then self:e(obfNum(nv)) else self:e(nv) end

elseif t=="BooleanExpr" then
if n.Value then
if math.random(1,2)==1 then self:e("("..genOpaque(true)..")") else self:e("true") end
else
if math.random(1,2)==1 then self:e("("..genOpaque(false)..")") else self:e("false") end
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
self:e(genBloat())
self:p(n.Body)
self:e("end ")

elseif t=="IfStatement" then
for i,c in ipairs(n.Clauses) do
if i==1 then self:e("if ") self:p(c.Condition) self:e(" then ") self:e(genJunk())
elseif c.Condition then self:e("elseif ") self:p(c.Condition) self:e(" then ") self:e(genJunk())
else self:e("else ") self:e(genJunk()) end
self:p(c.Body)
end
self:e("end ")

elseif t=="WhileStatement" then
self:e("while ") self:p(n.Condition) self:e(" do ") self:e(genJunk()) self:p(n.Body) self:e("end ")

elseif t=="NumericForStatement" then
self:e("for ") self:e(self:gn(n.Variable.Name).."=")
self:p(n.Start) self:e(",") self:p(n.End)
if n.Step then self:e(",") self:p(n.Step) end
self:e(" do ") self:e(genJunk()) self:p(n.Body) self:e("end ")

elseif t=="GenericForStatement" then
self:e("for ")
for i,v in ipairs(n.VariableList) do self:e(self:gn(v.Name)) if i<#n.VariableList then self:e(",") end end
self:e(" in ")
for i,g in ipairs(n.Generators) do self:p(g) if i<#n.Generators then self:e(",") end end
self:e(" do ") self:e(genJunk()) self:p(n.Body) self:e("end ")

elseif t=="RepeatStatement" then
self:e("repeat ") self:e(genJunk()) self:p(n.Body) self:e("until ") self:p(n.Condition) self:e(" ")

elseif t=="DoStatement" then
self:e("do ") self:e(genJunk()) self:p(n.Body) self:e("end ")

elseif t=="ReturnStatement" then
self:e("return ")
for i,a in ipairs(n.Arguments) do self:p(a) if i<#n.Arguments then self:e(",") end end
self:e(" ")

elseif t=="BreakStatement" then
self:e("break ")

elseif t=="ConstructorExpr" then
self:e("{")
for i,en in ipairs(n.EntryList) do
if en.Type=="Key" then
self:e("[") self:p(en.Key) self:e("]=") self:p(en.Value)
elseif en.Type=="KeyString" then
self:e("[") self:e(self:em(en.Key)) self:e("]=") self:p(en.Value)
else
self:p(en.Value)
end
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

local RUNTIME=[[local _={} _._x=function(a,b) local r,m=0,1 while a>0 or b>0 do local x,y=a%2,b%2 if x~=y then r=r+m end a=math.floor(a/2) b=math.floor(b/2) m=m*2 end return r end _._d=function(t,k) local r={} for i=1,#t do r[i]=string.char(_._x(t[i],k)) end return table.concat(r) end _._c=function(s) local h=0 for i=1,#s do h=h+string.byte(s,i) end return h end ]]

local function genAntiTamper()
local c={}
c[#c+1]="do "
c[#c+1]="local "..genJunkVar().."="..obfNum(tostring(math.random(1000,9999))).." "
c[#c+1]="if rawget(_G,'__DEBUG__') then while true do end end "
c[#c+1]="if rawget(_G,'__DEOBF__') then return end "
c[#c+1]=genBloat()
c[#c+1]="end "
return table.concat(c)
end

local function genPrefix()
local j=""
j=j..genAntiTamper()
j=j..genBloat()
j=j..genBloat()
return j
end

local function genSuffix()
local s=""
s=s..genBloat()
s=s..genBloat()
return s
end

local function wrapCode(code)
local w=""
local wrapperName=genName()
w=w.."local function "..wrapperName.."() "
w=w..genBloat()
w=w..code
w=w..genBloat()
w=w.."end "
w=w..genBloat()
w=w..wrapperName.."() "
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

local body=u.out
local wrapped=wrapCode(body)
local final=RUNTIME..genPrefix()..wrapped..genSuffix()

if DEBUG_MODE then
print("--[[ DEBUG ]]")
print("--[[ RUNTIME ]]")
print(RUNTIME)
print("--[[ BODY SIZE: "..#body.." ]]")
print("--[[ FINAL SIZE: "..#final.." ]]")
else
print(final)
end
