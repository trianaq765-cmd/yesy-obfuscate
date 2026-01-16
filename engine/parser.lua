-- engine/parser.lua (Standalone Version)
-- Sudah termasuk Util dan Scope di dalamnya.

-- 1. BAGIAN UTIL (Pengganti Util.lua)
local function lookupify(t)
    local newt = {}
    for _, v in pairs(t) do newt[v] = true end
    return newt
end

-- 2. BAGIAN SCOPE (Pengganti Scope.lua)
local Scope = {}
Scope.__index = Scope

function Scope:new(parent)
    local obj = {
        Parent = parent,
        Locals = {}, -- List urut
        LocalMap = {}, -- Map nama -> object
        Globals = {},
    }
    setmetatable(obj, Scope)
    return obj
end

function Scope:CreateLocal(name)
    local var = {
        Name = name,
        Scope = self,
        References = 0,
        CanRename = true
    }
    table.insert(self.Locals, var)
    self.LocalMap[name] = var
    return var
end

function Scope:GetLocal(name)
    -- Cek scope sendiri
    if self.LocalMap[name] then return self.LocalMap[name] end
    -- Cek parent
    if self.Parent then return self.Parent:GetLocal(name) end
    return nil
end

function Scope:GetGlobal(name)
    if self.Globals[name] then return self.Globals[name] end
    if self.Parent then return self.Parent:GetGlobal(name) end
    return nil
end

function Scope:CreateGlobal(name)
    -- Global selalu ada di root (top scope), tapi kita simpan referensinya
    local var = {
        Name = name,
        References = 0,
        IsGlobal = true
    }
    self.Globals[name] = var
    return var
end

function Scope:ObfuscateLocals()
    -- Placeholder function agar tidak error saat dipanggil parser
end


-- 3. BAGIAN LEXER & PARSER UTAMA
local WhiteChars = lookupify{' ', '\n', '\t', '\r'}
local EscapeLookup = {['\r'] = '\\r', ['\n'] = '\\n', ['\t'] = '\\t', ['"'] = '\\"', ["'"] = "\\'"}
local LowerChars = lookupify{'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i',
							 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r',
							 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}
local UpperChars = lookupify{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
							 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
							 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'}
local Digits = lookupify{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}
local HexDigits = lookupify{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
							'A', 'a', 'B', 'b', 'C', 'c', 'D', 'd', 'E', 'e', 'F', 'f'}

local Symbols = lookupify{'+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#'}

local Keywords = lookupify{
	'and', 'break', 'do', 'else', 'elseif',
	'end', 'false', 'for', 'function', 'goto', 'if',
	'in', 'local', 'nil', 'not', 'or', 'repeat',
	'return', 'then', 'true', 'until', 'while',
};

local function LexLua(src)
	local tokens = {}
	local st, err = pcall(function()
		local p = 1
		local line = 1
		local char = 1

		local function get()
			local c = src:sub(p,p)
			if c == '\n' then
				char = 1
				line = line + 1
			else
				char = char + 1
			end
			p = p + 1
			return c
		end
		local function peek(n)
			n = n or 0
			return src:sub(p+n,p+n)
		end
		local function consume(chars)
			local c = peek()
			for i = 1, #chars do
				if c == chars:sub(i,i) then return get() end
			end
		end

		local function generateError(err)
			return error(">> :"..line..":"..char..": "..err, 0)
		end

		local function tryGetLongString()
			local start = p
			if peek() == '[' then
				local equalsCount = 0
				local depth = 1
				while peek(equalsCount+1) == '=' do
					equalsCount = equalsCount + 1
				end
				if peek(equalsCount+1) == '[' then
					for _ = 0, equalsCount+1 do get() end
					local contentStart = p
					while true do
						if peek() == '' then
							generateError("Expected `]"..string.rep('=', equalsCount).."]` near <eof>.", 3)
						end
						local foundEnd = true
						if peek() == ']' then
							for i = 1, equalsCount do
								if peek(i) ~= '=' then foundEnd = false end
							end
							if peek(equalsCount+1) ~= ']' then foundEnd = false end
						else
							if peek() == '[' then
								local embedded = true
								for i = 1, equalsCount do
									if peek(i) ~= '=' then embedded = false break end
								end
								if peek(equalsCount + 1) == '[' and embedded then
									depth = depth + 1
									for i = 1, (equalsCount + 2) do get() end
								end
							end
							foundEnd = false
						end
						if foundEnd then
							depth = depth - 1
							if depth == 0 then break else
								for i = 1, equalsCount + 2 do get() end
							end
						else
							get()
						end
					end
					local contentString = src:sub(contentStart, p-1)
					for i = 0, equalsCount+1 do get() end
					local longString = src:sub(start, p-1)
					return contentString, longString
				else
					return nil
				end
			else
				return nil
			end
		end

		while true do
			local leading = { }
			local leadingWhite = ''
			local longStr = false
			while true do
				local c = peek()
				if c == '#' and peek(1) == '!' and line == 1 then
					get(); get()
					leadingWhite = "#!"
					while peek() ~= '\n' and peek() ~= '' do
						leadingWhite = leadingWhite .. get()
					end
					local token = {Type = 'Comment', CommentType = 'Shebang', Data = leadingWhite, Line = line, Char = char}
					leadingWhite = ""
					table.insert(leading, token)
				end
				if c == ' ' or c == '\t' then
					local c2 = get()
					table.insert(leading, { Type = 'Whitespace', Line = line, Char = char, Data = c2 })
				elseif c == '\n' or c == '\r' then
					local nl = get()
					if leadingWhite ~= "" then
						local token = {Type = 'Comment', CommentType = longStr and 'LongComment' or 'Comment', Data = leadingWhite, Line = line, Char = char}
						table.insert(leading, token)
						leadingWhite = ""
					end
					table.insert(leading, { Type = 'Whitespace', Line = line, Char = char, Data = nl })
				elseif c == '-' and peek(1) == '-' then
					get(); get()
					leadingWhite = leadingWhite .. '--'
					local _, wholeText = tryGetLongString()
					if wholeText then
						leadingWhite = leadingWhite..wholeText
						longStr = true
					else
						while peek() ~= '\n' and peek() ~= '' do
							leadingWhite = leadingWhite..get()
						end
					end
				else
					break
				end
			end
			if leadingWhite ~= "" then
				local token = {Type = 'Comment', CommentType = longStr and 'LongComment' or 'Comment', Data = leadingWhite, Line = line, Char = char}
				table.insert(leading, token)
			end

			local thisLine = line
			local thisChar = char
			local c = peek()
			local toEmit = nil

			if c == '' then
				toEmit = { Type = 'Eof' }
			elseif UpperChars[c] or LowerChars[c] or c == '_' then
				local start = p
				repeat
					get()
					c = peek()
				until not (UpperChars[c] or LowerChars[c] or Digits[c] or c == '_')
				local dat = src:sub(start, p-1)
				if Keywords[dat] then
					toEmit = {Type = 'Keyword', Data = dat}
				else
					toEmit = {Type = 'Ident', Data = dat}
				end
			elseif Digits[c] or (peek() == '.' and Digits[peek(1)]) then
				local start = p
				if c == '0' and peek(1) == 'x' then
					get();get()
					while HexDigits[peek()] do get() end
					if consume('Pp') then consume('+-'); while Digits[peek()] do get() end end
				else
					while Digits[peek()] do get() end
					if consume('.') then while Digits[peek()] do get() end end
					if consume('Ee') then consume('+-'); while Digits[peek()] do get() end end
				end
				toEmit = {Type = 'Number', Data = src:sub(start, p-1)}
			elseif c == '\'' or c == '\"' then
				local start = p
				local delim = get()
				local contentStart = p
				while true do
					local c = get()
					if c == '\\' then get()
					elseif c == delim then break
					elseif c == '' then generateError("Unfinished string near <eof>")
					end
				end
				local content = src:sub(contentStart, p-2)
				local constant = src:sub(start, p-1)
				toEmit = {Type = 'String', Data = constant, Constant = content}
			elseif c == '[' then
				local content, wholetext = tryGetLongString()
				if wholetext then
					toEmit = {Type = 'String', Data = wholetext, Constant = content}
				else
					get()
					toEmit = {Type = 'Symbol', Data = '['}
				end
			elseif consume('>=<') then
				if consume('=') then toEmit = {Type = 'Symbol', Data = c..'='}
				else toEmit = {Type = 'Symbol', Data = c} end
			elseif consume('~') then
				if consume('=') then toEmit = {Type = 'Symbol', Data = '~='}
				else generateError("Unexpected symbol `~` in source.", 2) end
			elseif consume('.') then
				if consume('.') then
					if consume('.') then toEmit = {Type = 'Symbol', Data = '...'}
					else toEmit = {Type = 'Symbol', Data = '..'} end
				else toEmit = {Type = 'Symbol', Data = '.'} end
			elseif consume(':') then
				if consume(':') then toEmit = {Type = 'Symbol', Data = '::'}
				else toEmit = {Type = 'Symbol', Data = ':'} end
			elseif Symbols[c] then
				get()
				toEmit = {Type = 'Symbol', Data = c}
			else
				local contents, all = tryGetLongString()
				if contents then
					toEmit = {Type = 'String', Data = all, Constant = contents}
				else
					generateError("Unexpected Symbol `"..c.."` in source.", 2)
				end
			end
			toEmit.LeadingWhite = leading
			toEmit.Line = thisLine
			toEmit.Char = thisChar
			tokens[#tokens+1] = toEmit
			if toEmit.Type == 'Eof' then break end
		end
	end)
	if not st then return false, err end

	local tok = {}
	local savedP = {}
	local p = 1
	function tok:getp() return p end
	function tok:setp(n) p = n end
	function tok:getTokenList() return tokens end
	function tok:Peek(n) n = n or 0; return tokens[math.min(#tokens, p+n)] end
	function tok:Get(tokenList)
		local t = tokens[p]
		p = math.min(p + 1, #tokens)
		if tokenList then table.insert(tokenList, t) end
		return t
	end
	function tok:Is(t) return tok:Peek().Type == t end
	function tok:Save() savedP[#savedP+1] = p end
	function tok:Commit() savedP[#savedP] = nil end
	function tok:Restore() p = savedP[#savedP]; savedP[#savedP] = nil end
	function tok:ConsumeSymbol(symb, tokenList)
		local t = self:Peek()
		if t.Type == 'Symbol' then
			if symb then
				if t.Data == symb then self:Get(tokenList); return true
				else return nil end
			else self:Get(tokenList); return t end
		else return nil end
	end
	function tok:ConsumeKeyword(kw, tokenList)
		local t = self:Peek()
		if t.Type == 'Keyword' and t.Data == kw then self:Get(tokenList); return true
		else return nil end
	end
	function tok:IsKeyword(kw) local t = tok:Peek(); return t.Type == 'Keyword' and t.Data == kw end
	function tok:IsSymbol(s) local t = tok:Peek(); return t.Type == 'Symbol' and t.Data == s end
	function tok:IsEof() return tok:Peek().Type == 'Eof' end
	return true, tok
end

local function ParseLua(src)
	local st, tok
	if type(src) ~= 'table' then st, tok = LexLua(src)
	else st, tok = true, src end
	if not st then return false, tok end

	local function GenerateError(msg)
		return ">> :"..tok:Peek().Line..":"..tok:Peek().Char..": "..msg.."\n"
	end

	local function CreateScope(parent)
		local scope = Scope:new(parent)
		scope.RenameVars = scope.ObfuscateLocals
		scope.ObfuscateVariables = scope.ObfuscateLocals
		return scope
	end

	local ParseExpr, ParseStatementList, ParseSimpleExpr, ParseSubExpr, ParsePrimaryExpr, ParseSuffixedExpr

	local function ParseFunctionArgsAndBody(scope, tokenList)
		local funcScope = CreateScope(scope)
		if not tok:ConsumeSymbol('(', tokenList) then return false, GenerateError("`(` expected.") end
		local argList = {}
		local isVarArg = false
		while not tok:ConsumeSymbol(')', tokenList) do
			if tok:Is('Ident') then
				local arg = funcScope:CreateLocal(tok:Get(tokenList).Data)
				argList[#argList+1] = arg
				if not tok:ConsumeSymbol(',', tokenList) then
					if tok:ConsumeSymbol(')', tokenList) then break else return false, GenerateError("`)` expected.") end
				end
			elseif tok:ConsumeSymbol('...', tokenList) then
				isVarArg = true
				if not tok:ConsumeSymbol(')', tokenList) then return false, GenerateError("`...` must be the last argument.") end
				break
			else return false, GenerateError("Argument name or `...` expected") end
		end
		local st, body = ParseStatementList(funcScope)
		if not st then return false, body end
		if not tok:ConsumeKeyword('end', tokenList) then return false, GenerateError("`end` expected") end
		local nodeFunc = {AstType='Function', Scope=funcScope, Arguments=argList, Body=body, VarArg=isVarArg, Tokens=tokenList}
		return true, nodeFunc
	end

	function ParsePrimaryExpr(scope)
		local tokenList = {}
		if tok:ConsumeSymbol('(', tokenList) then
			local st, ex = ParseExpr(scope)
			if not st then return false, ex end
			if not tok:ConsumeSymbol(')', tokenList) then return false, GenerateError("`)` Expected.") end
			local parensExp = {AstType='Parentheses', Inner=ex, Tokens=tokenList}
			return true, parensExp
		elseif tok:Is('Ident') then
			local id = tok:Get(tokenList)
			local var = scope:GetLocal(id.Data)
			if not var then
				var = scope:GetGlobal(id.Data)
				if not var then var = scope:CreateGlobal(id.Data)
				else var.References = var.References + 1 end
			else var.References = var.References + 1 end
			local nodePrimExp = {AstType='VarExpr', Name=id.Data, Variable=var, Tokens=tokenList}
			return true, nodePrimExp
		else return false, GenerateError("primary expression expected") end
	end

	function ParseSuffixedExpr(scope, onlyDotColon)
		local st, prim = ParsePrimaryExpr(scope)
		if not st then return false, prim end
		while true do
			local tokenList = {}
			if tok:IsSymbol('.') or tok:IsSymbol(':') then
				local symb = tok:Get(tokenList).Data
				if not tok:Is('Ident') then return false, GenerateError("<Ident> expected.") end
				local id = tok:Get(tokenList)
				local nodeIndex = {AstType='MemberExpr', Base=prim, Indexer=symb, Ident=id, Tokens=tokenList}
				prim = nodeIndex
			elseif not onlyDotColon and tok:ConsumeSymbol('[', tokenList) then
				local st, ex = ParseExpr(scope)
				if not st then return false, ex end
				if not tok:ConsumeSymbol(']', tokenList) then return false, GenerateError("`]` expected.") end
				local nodeIndex = {AstType='IndexExpr', Base=prim, Index=ex, Tokens=tokenList}
				prim = nodeIndex
			elseif not onlyDotColon and tok:ConsumeSymbol('(', tokenList) then
				local args = {}
				while not tok:ConsumeSymbol(')', tokenList) do
					local st, ex = ParseExpr(scope)
					if not st then return false, ex end
					args[#args+1] = ex
					if not tok:ConsumeSymbol(',', tokenList) then
						if tok:ConsumeSymbol(')', tokenList) then break else return false, GenerateError("`)` Expected.") end
					end
				end
				local nodeCall = {AstType='CallExpr', Base=prim, Arguments=args, Tokens=tokenList}
				prim = nodeCall
			elseif not onlyDotColon and tok:Is('String') then
				local nodeCall = {AstType='StringCallExpr', Base=prim, Arguments={tok:Get(tokenList)}, Tokens=tokenList}
				prim = nodeCall
			elseif not onlyDotColon and tok:IsSymbol('{') then
				local st, ex = ParseSimpleExpr(scope)
				if not st then return false, ex end
				local nodeCall = {AstType='TableCallExpr', Base=prim, Arguments={ex}, Tokens=tokenList}
				prim = nodeCall
			else break end
		end
		return true, prim
	end

	function ParseSimpleExpr(scope)
		local tokenList = {}
		if tok:Is('Number') then
			local nodeNum = {AstType='NumberExpr', Value=tok:Get(tokenList), Tokens=tokenList}
			return true, nodeNum
		elseif tok:Is('String') then
			local nodeStr = {AstType='StringExpr', Value=tok:Get(tokenList), Tokens=tokenList}
			return true, nodeStr
		elseif tok:ConsumeKeyword('nil', tokenList) then
			local nodeNil = {AstType='NilExpr', Tokens=tokenList}
			return true, nodeNil
		elseif tok:IsKeyword('false') or tok:IsKeyword('true') then
			local nodeBoolean = {AstType='BooleanExpr', Value=(tok:Get(tokenList).Data == 'true'), Tokens=tokenList}
			return true, nodeBoolean
		elseif tok:ConsumeSymbol('...', tokenList) then
			local nodeDots = {AstType='DotsExpr', Tokens=tokenList}
			return true, nodeDots
		elseif tok:ConsumeSymbol('{', tokenList) then
			local v = {AstType='ConstructorExpr', EntryList={}}
			while true do
				if tok:IsSymbol('[', tokenList) then
					tok:Get(tokenList)
					local st, key = ParseExpr(scope)
					if not st then return false, GenerateError("Key Expected") end
					if not tok:ConsumeSymbol(']', tokenList) then return false, GenerateError("`]` Expected") end
					if not tok:ConsumeSymbol('=', tokenList) then return false, GenerateError("`=` Expected") end
					local st, value = ParseExpr(scope)
					if not st then return false, GenerateError("Value Expected") end
					v.EntryList[#v.EntryList+1] = {Type='Key', Key=key, Value=value}
				elseif tok:Is('Ident') then
					local lookahead = tok:Peek(1)
					if lookahead.Type == 'Symbol' and lookahead.Data == '=' then
						local key = tok:Get(tokenList)
						if not tok:ConsumeSymbol('=', tokenList) then return false, GenerateError("`=` Expected") end
						local st, value = ParseExpr(scope)
						if not st then return false, GenerateError("Value Expected") end
						v.EntryList[#v.EntryList+1] = {Type='KeyString', Key=key.Data, Value=value}
					else
						local st, value = ParseExpr(scope)
						if not st then return false, GenerateError("Value Expected") end
						v.EntryList[#v.EntryList+1] = {Type='Value', Value=value}
					end
				elseif tok:ConsumeSymbol('}', tokenList) then break
				else
					local st, value = ParseExpr(scope)
					if not st then return false, GenerateError("Value Expected") end
					v.EntryList[#v.EntryList+1] = {Type='Value', Value=value}
				end
				if tok:ConsumeSymbol(';', tokenList) or tok:ConsumeSymbol(',', tokenList) then
				elseif tok:ConsumeSymbol('}', tokenList) then break
				else return false, GenerateError("`}` or table entry Expected") end
			end
			v.Tokens = tokenList
			return true, v
		elseif tok:ConsumeKeyword('function', tokenList) then
			local st, func = ParseFunctionArgsAndBody(scope, tokenList)
			if not st then return false, func end
			func.IsLocal = true
			return true, func
		else return ParseSuffixedExpr(scope) end
	end

	local unops = lookupify{'-', 'not', '#'}
	local priority = {
		['+'] = {6,6}; ['-'] = {6,6}; ['%'] = {7,7}; ['/'] = {7,7}; ['*'] = {7,7}; ['^'] = {10,9}; ['..'] = {5,4};
		['=='] = {3,3}; ['<'] = {3,3}; ['<='] = {3,3}; ['~='] = {3,3}; ['>'] = {3,3}; ['>='] = {3,3};
		['and'] = {2,2}; ['or'] = {1,1};
	}
	function ParseSubExpr(scope, level)
		local st, exp
		if unops[tok:Peek().Data] then
			local tokenList = {}
			local op = tok:Get(tokenList).Data
			st, exp = ParseSubExpr(scope, 8)
			if not st then return false, exp end
			exp = {AstType='UnopExpr', Rhs=exp, Op=op, OperatorPrecedence=8, Tokens=tokenList}
		else
			st, exp = ParseSimpleExpr(scope)
			if not st then return false, exp end
		end
		while true do
			local prio = priority[tok:Peek().Data]
			if prio and prio[1] > level then
				local tokenList = {}
				local op = tok:Get(tokenList).Data
				local st, rhs = ParseSubExpr(scope, prio[2])
				if not st then return false, rhs end
				exp = {AstType='BinopExpr', Lhs=exp, Op=op, OperatorPrecedence=prio[1], Rhs=rhs, Tokens=tokenList}
			else break end
		end
		return true, exp
	end

	ParseExpr = function(scope) return ParseSubExpr(scope, 0) end

	local function ParseStatement(scope)
		local stat = nil
		local tokenList = {}
		if tok:ConsumeKeyword('if', tokenList) then
			local nodeIfStat = {AstType='IfStatement', Clauses={}}
			repeat
				local st, nodeCond = ParseExpr(scope)
				if not st then return false, nodeCond end
				if not tok:ConsumeKeyword('then', tokenList) then return false, GenerateError("`then` expected.") end
				local st, nodeBody = ParseStatementList(scope)
				if not st then return false, nodeBody end
				nodeIfStat.Clauses[#nodeIfStat.Clauses+1] = {Condition=nodeCond, Body=nodeBody}
			until not tok:ConsumeKeyword('elseif', tokenList)
			if tok:ConsumeKeyword('else', tokenList) then
				local st, nodeBody = ParseStatementList(scope)
				if not st then return false, nodeBody end
				nodeIfStat.Clauses[#nodeIfStat.Clauses+1] = {Body=nodeBody}
			end
			if not tok:ConsumeKeyword('end', tokenList) then return false, GenerateError("`end` expected.") end
			nodeIfStat.Tokens = tokenList
			stat = nodeIfStat
		elseif tok:ConsumeKeyword('while', tokenList) then
			local st, nodeCond = ParseExpr(scope)
			if not st then return false, nodeCond end
			if not tok:ConsumeKeyword('do', tokenList) then return false, GenerateError("`do` expected.") end
			local st, nodeBody = ParseStatementList(scope)
			if not st then return false, nodeBody end
			if not tok:ConsumeKeyword('end', tokenList) then return false, GenerateError("`end` expected.") end
			stat = {AstType='WhileStatement', Condition=nodeCond, Body=nodeBody, Tokens=tokenList}
		elseif tok:ConsumeKeyword('do', tokenList) then
			local st, nodeBlock = ParseStatementList(scope)
			if not st then return false, nodeBlock end
			if not tok:ConsumeKeyword('end', tokenList) then return false, GenerateError("`end` expected.") end
			stat = {AstType='DoStatement', Body=nodeBlock, Tokens=tokenList}
		elseif tok:ConsumeKeyword('for', tokenList) then
			if not tok:Is('Ident') then return false, GenerateError("<ident> expected.") end
			local baseVarName = tok:Get(tokenList)
			if tok:ConsumeSymbol('=', tokenList) then
				local forScope = CreateScope(scope)
				local forVar = forScope:CreateLocal(baseVarName.Data)
				local st, startEx = ParseExpr(scope)
				if not st then return false, startEx end
				if not tok:ConsumeSymbol(',', tokenList) then return false, GenerateError("`,` Expected") end
				local st, endEx = ParseExpr(scope)
				if not st then return false, endEx end
				local st, stepEx
				if tok:ConsumeSymbol(',', tokenList) then
					st, stepEx = ParseExpr(scope)
					if not st then return false, stepEx end
				end
				if not tok:ConsumeKeyword('do', tokenList) then return false, GenerateError("`do` expected") end
				local st, body = ParseStatementList(forScope)
				if not st then return false, body end
				if not tok:ConsumeKeyword('end', tokenList) then return false, GenerateError("`end` expected") end
				stat = {AstType='NumericForStatement', Scope=forScope, Variable=forVar, Start=startEx, End=endEx, Step=stepEx, Body=body, Tokens=tokenList}
			else
				local forScope = CreateScope(scope)
				local varList = { forScope:CreateLocal(baseVarName.Data) }
				while tok:ConsumeSymbol(',', tokenList) do
					if not tok:Is('Ident') then return false, GenerateError("for variable expected.") end
					varList[#varList+1] = forScope:CreateLocal(tok:Get(tokenList).Data)
				end
				if not tok:ConsumeKeyword('in', tokenList) then return false, GenerateError("`in` expected.") end
				local generators = {}
				local st, firstGen = ParseExpr(scope)
				if not st then return false, firstGen end
				generators[1] = firstGen
				while tok:ConsumeSymbol(',', tokenList) do
					local st, gen = ParseExpr(scope)
					if not st then return false, gen end
					generators[#generators+1] = gen
				end
				if not tok:ConsumeKeyword('do', tokenList) then return false, GenerateError("`do` expected.") end
				local st, body = ParseStatementList(forScope)
				if not st then return false, body end
				if not tok:ConsumeKeyword('end', tokenList) then return false, GenerateError("`end` expected.") end
				stat = {AstType='GenericForStatement', Scope=forScope, VariableList=varList, Generators=generators, Body=body, Tokens=tokenList}
			end
		elseif tok:ConsumeKeyword('repeat', tokenList) then
			local st, body = ParseStatementList(scope)
			if not st then return false, body end
			if not tok:ConsumeKeyword('until', tokenList) then return false, GenerateError("`until` expected.") end
			local st, cond = ParseExpr(body.Scope)
			if not st then return false, cond end
			stat = {AstType='RepeatStatement', Condition=cond, Body=body, Tokens=tokenList}
		elseif tok:ConsumeKeyword('function', tokenList) then
			if not tok:Is('Ident') then return false, GenerateError("Function name expected") end
			local st, name = ParseSuffixedExpr(scope, true)
			if not st then return false, name end
			local st, func = ParseFunctionArgsAndBody(scope, tokenList)
			if not st then return false, func end
			func.IsLocal = false
			func.Name = name
			stat = func
		elseif tok:ConsumeKeyword('local', tokenList) then
			if tok:Is('Ident') then
				local varList = { tok:Get(tokenList).Data }
				while tok:ConsumeSymbol(',', tokenList) do
					if not tok:Is('Ident') then return false, GenerateError("local var name expected") end
					varList[#varList+1] = tok:Get(tokenList).Data
				end
				local initList = {}
				if tok:ConsumeSymbol('=', tokenList) then
					repeat
						local st, ex = ParseExpr(scope)
						if not st then return false, ex end
						initList[#initList+1] = ex
					until not tok:ConsumeSymbol(',', tokenList)
				end
				for i, v in pairs(varList) do varList[i] = scope:CreateLocal(v) end
				stat = {AstType='LocalStatement', LocalList=varList, InitList=initList, Tokens=tokenList}
			elseif tok:ConsumeKeyword('function', tokenList) then
				if not tok:Is('Ident') then return false, GenerateError("Function name expected") end
				local name = tok:Get(tokenList).Data
				local localVar = scope:CreateLocal(name)
				local st, func = ParseFunctionArgsAndBody(scope, tokenList)
				if not st then return false, func end
				func.Name = localVar
				func.IsLocal = true
				stat = func
			else return false, GenerateError("local var or function def expected") end
		elseif tok:ConsumeSymbol('::', tokenList) then
			if not tok:Is('Ident') then return false, GenerateError('Label name expected') end
			local label = tok:Get(tokenList).Data
			if not tok:ConsumeSymbol('::', tokenList) then return false, GenerateError("`::` expected") end
			stat = {AstType='LabelStatement', Label=label, Tokens=tokenList}
		elseif tok:ConsumeKeyword('return', tokenList) then
			local exList = {}
			if not tok:IsKeyword('end') then
				local st, firstEx = ParseExpr(scope)
				if st then
					exList[1] = firstEx
					while tok:ConsumeSymbol(',', tokenList) do
						local st, ex = ParseExpr(scope)
						if not st then return false, ex end
						exList[#exList+1] = ex
					end
				end
			end
			stat = {AstType='ReturnStatement', Arguments=exList, Tokens=tokenList}
		elseif tok:ConsumeKeyword('break', tokenList) then
			stat = {AstType='BreakStatement', Tokens=tokenList}
		elseif tok:ConsumeKeyword('goto', tokenList) then
			if not tok:Is('Ident') then return false, GenerateError("Label expected") end
			stat = {AstType='GotoStatement', Label=tok:Get(tokenList).Data, Tokens=tokenList}
		else
			local st, suffixed = ParseSuffixedExpr(scope)
			if not st then return false, suffixed end
			if tok:IsSymbol(',') or tok:IsSymbol('=') then
				local lhs = { suffixed }
				while tok:ConsumeSymbol(',', tokenList) do
					local st, lhsPart = ParseSuffixedExpr(scope)
					if not st then return false, lhsPart end
					lhs[#lhs+1] = lhsPart
				end
				if not tok:ConsumeSymbol('=', tokenList) then return false, GenerateError("`=` Expected.") end
				local rhs = {}
				local st, firstRhs = ParseExpr(scope)
				if not st then return false, firstRhs end
				rhs[1] = firstRhs
				while tok:ConsumeSymbol(',', tokenList) do
					local st, rhsPart = ParseExpr(scope)
					if not st then return false, rhsPart end
					rhs[#rhs+1] = rhsPart
				end
				stat = {AstType='AssignmentStatement', Lhs=lhs, Rhs=rhs, Tokens=tokenList}
			elseif suffixed.AstType == 'CallExpr' or suffixed.AstType == 'TableCallExpr' or suffixed.AstType == 'StringCallExpr' then
				stat = {AstType='CallStatement', Expression=suffixed, Tokens=tokenList}
			else return false, GenerateError("Assignment Statement Expected") end
		end
		if tok:IsSymbol(';') then stat.Semicolon = tok:Get(stat.Tokens) end
		return true, stat
	end

	local statListCloseKeywords = lookupify{'end', 'else', 'elseif', 'until'}
	ParseStatementList = function(scope)
		local nodeStatlist = {Scope=CreateScope(scope), AstType='Statlist', Body={}, Tokens={}}
		while not statListCloseKeywords[tok:Peek().Data] and not tok:IsEof() do
			local st, nodeStatement = ParseStatement(nodeStatlist.Scope)
			if not st then return false, nodeStatement end
			nodeStatlist.Body[#nodeStatlist.Body + 1] = nodeStatement
		end
		if tok:IsEof() then
			nodeStatlist.Body[#nodeStatlist.Body + 1] = {AstType='Eof', Tokens={tok:Get()}}
		end
		return true, nodeStatlist
	end

	local function mainfunc()
		local topScope = CreateScope()
		return ParseStatementList(topScope)
	end

	local st, main = mainfunc()
	return st, main
end

return { LexLua = LexLua, ParseLua = ParseLua }
