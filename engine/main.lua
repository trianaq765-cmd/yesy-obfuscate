package.path=package.path..";./?.lua;./engine/?.lua;/app/engine/?.lua"
local parser=require("parser")
math.randomseed(os.time())
local usedNames={}
local function generateRandomName()
local charset={"I","l","1","_"}
local name
repeat name="_" for i=1,math.random(10,18)do name=name..charset[math.random(1,#charset)]end until not usedNames[name]
usedNames[name]=true
return name
end
local function generateJunkName()
local prefixes={"_jnk","_var","_tmp","_dat","_val"}
local name=prefixes[math.random(1,#prefixes)]
for i=1,math.random(5,8)do name=name..string.char(math.random(97,122))end
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
local method=math.random(1,3)
if method==1 then local a=math.random(1,500)return"("..(n-a).."+"..a..")"
elseif method==2 then local a=math.random(1,500)return"("..(n+a).."-"..a..")"
else return"("..math.floor(n/2).."+"..(n-math.floor(n/2))..")"end
end
local function generateJunkCode()
local method=math.random(1,4)
local v=generateJunkName()
local n=math.random(100,999)
if method==1 then return"local "..v.." = "..n.."; "
elseif method==2 then return"local "..v.." = "..n.." + "..math.random(1,100).."; "
elseif method==3 then return"local "..v.." = ("..n.." > 0) and "..n.." or 0; "
else return"local "..v.." = (function() return "..n.." end)(); "end
end
local function generateOpaqueBlock()
local a,b=math.random(100,500),math.random(501,999)
local methods={
function()return"if ("..a.." < "..b..") then "..generateJunkCode().."end "end,
function()return"if (("..a.." + "..b..") > "..a..") then "..generateJunkCode().."end "end,
function()return"if (type("..a..") == 'number') then "..generateJunkCode().."end "end,
function()return"if (("..a.." * 2) > "..(a-1)..") then "..generateJunkCode().."end "end
}
return methods[math.random(1,#methods)]()
end
local Unparser={}
function Unparser:new()
local obj={varMap={},encryptionKey=math.random(50,200),output="",junkCounter=0,junkInterval=math.random(5,8)}
setmetatable(obj,self)
self.__index=self
return obj
end
function Unparser:emit(str)self.output=self.output..str end
function Unparser:maybeInsertJunk()
self.junkCounter=self.junkCounter+1
if self.junkCounter>=self.junkInterval then
self.junkCounter=0
self.junkInterval=math.random(5,8)
if math.random(1,3)==1 then self:emit(generateOpaqueBlock())else self:emit(generateJunkCode())end
end
end
function Unparser:getNewVarName(oldName)
local globals={["print"]=true,["warn"]=true,["error"]=true,["pairs"]=true,["ipairs"]=true,["next"]=true,["tonumber"]=true,["tostring"]=true,["type"]=true,["pcall"]=true,["xpcall"]=true,["assert"]=true,["select"]=true,["unpack"]=true,["rawget"]=true,["rawset"]=true,["rawequal"]=true,["require"]=true,["setmetatable"]=true,["getmetatable"]=true,["loadstring"]=true,["loadfile"]=true,["dofile"]=true,["collectgarbage"]=true,["newproxy"]=true,["math"]=true,["string"]=true,["table"]=true,["coroutine"]=true,["debug"]=true,["os"]=true,["io"]=true,["bit"]=true,["bit32"]=true,["_G"]=true,["_VERSION"]=true,["shared"]=true,["game"]=true,["workspace"]=true,["script"]=true,["plugin"]=true,["Enum"]=true,["Instance"]=true,["Vector2"]=true,["Vector3"]=true,["CFrame"]=true,["Color3"]=true,["UDim"]=true,["UDim2"]=true,["Rect"]=true,["Region3"]=true,["Ray"]=true,["BrickColor"]=true,["TweenInfo"]=true,["NumberSequence"]=true,["ColorSequence"]=true,["NumberRange"]=true,["Random"]=true,["DateTime"]=true,["typeof"]=true,["spawn"]=true,["delay"]=true,["wait"]=true,["tick"]=true,["time"]=true,["elapsedTime"]=true,["settings"]=true,["stats"]=true,["UserSettings"]=true,["version"]=true,["task"]=true,["getgenv"]=true,["getrenv"]=true,["getfenv"]=true,["setfenv"]=true,["getsenv"]=true,["getrawmetatable"]=true,["setrawmetatable"]=true,["setreadonly"]=true,["isreadonly"]=true,["hookfunction"]=true,["hookmetamethod"]=true,["newcclosure"]=true,["islclosure"]=true,["iscclosure"]=true,["getnamecallmethod"]=true,["setnamecallmethod"]=true,["checkcaller"]=true,["getcallingscript"]=true,["getinfo"]=true,["getupvalue"]=true,["setupvalue"]=true,["getupvalues"]=true,["getconstant"]=true,["setconstant"]=true,["getconstants"]=true,["getproto"]=true,["getprotos"]=true,["getstack"]=true,["setstack"]=true,["getconnections"]=true,["firesignal"]=true,["fireclickdetector"]=true,["fireproximityprompt"]=true,["firetouchinterest"]=true,["gethiddenproperty"]=true,["sethiddenproperty"]=true,["setsimulationradius"]=true,["getinstances"]=true,["getnilinstances"]=true,["getscripts"]=true,["getrunningscripts"]=true,["getloadedmodules"]=true,["getcustomasset"]=true,["cloneref"]=true,["compareinstances"]=true,["Drawing"]=true,["setclipboard"]=true,["setfflag"]=true,["getfflag"]=true,["syn"]=true,["fluxus"]=true,["identifyexecutor"]=true,["request"]=true,["http_request"]=true,["HttpGet"]=true,["readfile"]=true,["writefile"]=true,["appendfile"]=true,["listfiles"]=true,["isfile"]=true,["isfolder"]=true,["makefolder"]=true,["delfolder"]=true,["delfile"]=true,["getgc"]=true,["queue_on_teleport"]=true,["DECRYPT_STR"]=true,["XOR_BYTE"]=true,["true"]=true,["false"]=true,["nil"]=true,["and"]=true,["or"]=true,["not"]=true,["if"]=true,["then"]=true,["else"]=true,["elseif"]=true,["end"]=true,["do"]=true,["while"]=true,["for"]=true,["in"]=true,["repeat"]=true,["until"]=true,["function"]=true,["local"]=true,["return"]=true,["break"]=true}
if globals[oldName]then return oldName end
if not self.varMap[oldName]then self.varMap[oldName]=generateRandomName()end
return self.varMap[oldName]
end
function Unparser:encryptString(str)
if not str or str==""then return'""'end
local encrypted=xorEncrypt(str,self.encryptionKey)
local parts={}
for i,v in ipairs(encrypted)do table.insert(parts,tostring(v))end
return"DECRYPT_STR({"..table.concat(parts,",").."},"..self.encryptionKey..")"
end
function Unparser:processNode(node)
if not node then return end
local t=node.AstType
if t=="Statlist"then
for _,stmt in ipairs(node.Body)do self:processNode(stmt)self:maybeInsertJunk()end
elseif t=="LocalStatement"then
self:emit("local ")
for i,var in ipairs(node.LocalList)do self:emit(self:getNewVarName(var.Name))if i<#node.LocalList then self:emit(", ")end end
if #node.InitList>0 then
self:emit(" = ")
for i,expr in ipairs(node.InitList)do self:processNode(expr)if i<#node.InitList then self:emit(", ")end end
end
self:emit(" ")
elseif t=="AssignmentStatement"then
for i,lhs in ipairs(node.Lhs)do self:processNode(lhs)if i<#node.Lhs then self:emit(", ")end end
self:emit(" = ")
for i,rhs in ipairs(node.Rhs)do self:processNode(rhs)if i<#node.Rhs then self:emit(", ")end end
self:emit(" ")
elseif t=="CallStatement"then
self:processNode(node.Expression)self:emit(" ")
elseif t=="CallExpr"then
self:processNode(node.Base)self:emit("(")
for i,arg in ipairs(node.Arguments)do self:processNode(arg)if i<#node.Arguments then self:emit(", ")end end
self:emit(")")
elseif t=="StringCallExpr"then
self:processNode(node.Base)self:emit("(")
for _,arg in ipairs(node.Arguments)do self:processNode(arg)end
self:emit(")")
elseif t=="TableCallExpr"then
self:processNode(node.Base)self:emit("(")
for _,arg in ipairs(node.Arguments)do self:processNode(arg)end
self:emit(")")
elseif t=="VarExpr"then
self:emit(self:getNewVarName(node.Name))
elseif t=="MemberExpr"then
self:processNode(node.Base)self:emit(node.Indexer)self:emit(node.Ident.Data)
elseif t=="IndexExpr"then
self:processNode(node.Base)self:emit("[")self:processNode(node.Index)self:emit("]")
elseif t=="StringExpr"then
self:emit(self:encryptString(node.Value.Constant or""))
elseif t=="NumberExpr"then
local numVal=node.Value.Data
if numVal:match("^%d+$")and tonumber(numVal)<10000 then self:emit(obfuscateNumber(numVal))else self:emit(numVal)end
elseif t=="BooleanExpr"then
self:emit(node.Value and"true"or"false")
elseif t=="NilExpr"then
self:emit("nil")
elseif t=="Parentheses"then
self:emit("(")self:processNode(node.Inner)self:emit(")")
elseif t=="BinopExpr"then
self:processNode(node.Lhs)self:emit(" "..node.Op.." ")self:processNode(node.Rhs)
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
else
self:emit("function ")
if node.Name then self:processNode(node.Name)end
end
self:emit("(")
for i,arg in ipairs(node.Arguments)do self:emit(self:getNewVarName(arg.Name))if i<#node.Arguments then self:emit(", ")end end
if node.VarArg then if #node.Arguments>0 then self:emit(", ")end self:emit("...")end
self:emit(") ")
self:processNode(node.Body)
self:emit("end ")
elseif t=="IfStatement"then
for i,clause in ipairs(node.Clauses)do
if i==1 then self:emit("if ")self:processNode(clause.Condition)self:emit(" then ")
elseif clause.Condition then self:emit("elseif ")self:processNode(clause.Condition)self:emit(" then ")
else self:emit("else ")end
self:processNode(clause.Body)
end
self:emit("end ")
elseif t=="WhileStatement"then
self:emit("while ")self:processNode(node.Condition)self:emit(" do ")self:processNode(node.Body)self:emit("end ")
elseif t=="NumericForStatement"then
self:emit("for ")self:emit(self:getNewVarName(node.Variable.Name).." = ")
self:processNode(node.Start)self:emit(", ")self:processNode(node.End)
if node.Step then self:emit(", ")self:processNode(node.Step)end
self:emit(" do ")self:processNode(node.Body)self:emit("end ")
elseif t=="GenericForStatement"then
self:emit("for ")
for i,var in ipairs(node.VariableList)do self:emit(self:getNewVarName(var.Name))if i<#node.VariableList then self:emit(", ")end end
self:emit(" in ")
for i,gen in ipairs(node.Generators)do self:processNode(gen)if i<#node.Generators then self:emit(", ")end end
self:emit(" do ")self:processNode(node.Body)self:emit("end ")
elseif t=="RepeatStatement"then
self:emit("repeat ")self:processNode(node.Body)self:emit("until ")self:processNode(node.Condition)self:emit(" ")
elseif t=="DoStatement"then
self:emit("do ")self:processNode(node.Body)self:emit("end ")
elseif t=="ReturnStatement"then
self:emit("return ")
for i,arg in ipairs(node.Arguments)do self:processNode(arg)if i<#node.Arguments then self:emit(", ")end end
self:emit(" ")
elseif t=="BreakStatement"then
self:emit("break ")
elseif t=="ConstructorExpr"then
self:emit("{")
for i,entry in ipairs(node.EntryList)do
if entry.Type=="Key"then self:emit("[")self:processNode(entry.Key)self:emit("] = ")self:processNode(entry.Value)
elseif entry.Type=="KeyString"then self:emit(entry.Key.." = ")self:processNode(entry.Value)
else self:processNode(entry.Value)end
if i<#node.EntryList then self:emit(", ")end
end
self:emit("}")
elseif t=="DotsExpr"then
self:emit("...")
elseif t=="Eof"then
elseif t=="LabelStatement"then
self:emit("::"..node.Label..":: ")
elseif t=="GotoStatement"then
self:emit("goto "..node.Label.." ")
end
end
local function getRuntimeCode()
local rt=""
rt=rt.."local function XOR_BYTE(a, b) "
rt=rt.."local r, m = 0, 1 "
rt=rt.."while a > 0 or b > 0 do "
rt=rt.."local x, y = a % 2, b % 2 "
rt=rt.."if x ~= y then r = r + m end "
rt=rt.."a, b = math.floor(a / 2), math.floor(b / 2) "
rt=rt.."m = m * 2 "
rt=rt.."end "
rt=rt.."return r "
rt=rt.."end "
rt=rt.."local function DECRYPT_STR(t, k) "
rt=rt.."local r = {} "
rt=rt.."for i = 1, #t do "
rt=rt.."r[i] = string.char(XOR_BYTE(t[i], k)) "
rt=rt.."end "
rt=rt.."return table.concat(r) "
rt=rt.."end "
return rt
end
local function generateJunkPrefix()
local junk=""
for i=1,math.random(2,4)do junk=junk..generateJunkCode()end
return junk
end
local filename=arg[1]
if not filename then print("-- [ERROR] No input file")return end
local f=io.open(filename,"rb")
if not f then print("-- [ERROR] Cannot open file")return end
local code=f:read("*a")
f:close()
local success,ast=parser.ParseLua(code)
if not success then print("-- [ERROR] Parsing failed:")print(ast)return end
local unparser=Unparser:new()
unparser:processNode(ast)
local runtimeCode=getRuntimeCode()
local junkPrefix=generateJunkPrefix()
local finalCode=runtimeCode..junkPrefix..unparser.output
print(finalCode)
