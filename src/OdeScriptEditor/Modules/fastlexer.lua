--[=[
	A Lua lexical scanner
	BSD 2-Clause Licence
	Copyright ©, 2020 - Blockzez (devforum.roblox.com/u/Blockzez and github.com/Blockzez)
	All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	1. Redistributions of source code must retain the above copyright notice, this
	   list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above copyright notice,
	   this list of conditions and the following disclaimer in the documentation
	   and/or other materials provided with the distribution.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
	OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]=]
local lexer = { };

-- 
local identifiers = {
	-- Reserved keywords
	['and'] = 'keyword', ['break'] = 'keyword', ['continue'] = 'keyword', ['do'] = 'keyword', ['else'] = 'keyword', ['elseif'] = 'keyword', ['end'] = 'keyword',
	['false'] = 'keyword', ['for'] = 'keyword', ['function'] = 'keyword', ['goto'] = 'keyword', ['if'] = 'keyword', ['in'] = 'keyword', ['local'] = 'keyword',
	['nil'] = 'keyword', ['not'] = 'keyword', ['or'] = 'keyword', ['repeat'] = 'keyword', ['return'] = 'keyword', ['then'] = 'keyword', ['true'] = 'keyword',
	['until'] = 'keyword', ['while'] = 'keyword',
	
	['type'] = 'keyword', ['typeof'] = 'keyword', ['export'] = 'keyword',

	-- Lua globals
	assert = 'builtin', collectgarbage = 'builtin', error = 'builtin', getfenv = 'builtin', getmetatable = 'builtin', ipairs = 'builtin', loadstring = 'builtin', next = 'builtin', newproxy = 'builtin',
	pairs = 'builtin', pcall = 'builtin', print = 'builtin', rawequal = 'builtin', rawget = 'builtin', rawset = 'builtin', select = 'builtin', setfenv = 'builtin', setmetatable = 'builtin',
	tonumber = 'builtin', tostring = 'builtin', --[[type = 'builtin',]] unpack = 'builtin', xpcall = 'builtin',
	--
	_G = 'builtin', _VERSION = 'builtin',
	
	-- Lua libraries
	bit32 = 'builtin', coroutine = 'builtin', debug = 'builtin', math = 'builtin', os = 'builtin', string = 'builtin', table = 'builtin', utf8 = 'builtin',

	-- Roblox globals
	delay = 'builtin', elapsedTime = 'builtin', require = 'builtin', settings = 'builtin', spawn = 'builtin', stats = 'builtin', tick = 'builtin', UserSettings = 'builtin', wait = 'builtin', warn = 'builtin',
	--
	Enum = 'builtin', game = 'builtin', shared = 'builtin', script = 'builtin', plugin = 'builtin', workspace = 'builtin',
	
	task = 'builtin',

	-- Depcreated
	printidentity = 'builtin_deprecated', version = 'builtin_deprecated',
	
	-- Roblox types
	Axes = 'builtin', BrickColor = 'builtin', CFrame = 'builtin', Color3 = 'builtin', ColorSequence = 'builtin', ColorSequenceKeypoint = 'builtin', DateTime = 'builtin', DockWidgetPluginGuiInfo = 'builtin',
	Faces = 'builtin', Instance = 'builtin', NumberRange = 'builtin', NumberSequence = 'builtin', NumberSequenceKeypoint = 'builtin', PathWaypoint = 'builtin', PhysicalProperties = 'builtin', Random = 'builtin',
	Ray = 'builtin', RaycastParams = 'builtin', Rect = 'builtin', Region3 = 'builtin', Region3int16 = 'builtin', TweenInfo = 'builtin', UDim = 'builtin', UDim2 = 'builtin', Vector2 = 'builtin',
	Vector2int16 = 'builtin', Vector3 = 'builtin', Vector3int16 = 'builtin',
};

local operator = {
	[0x2B] = true, [0x2D] = true, [0x2A] = true, [0x2F] = true, [0x25] = true,
	[0x3C] = true, [0x3E] = true, [0x3D] = true, [0x7E] = true,
	[0x26] = true, [0x7C] = true, [0x5E] = true,
	[0x23] = true, [0x2E] = true,
	[0x28] = true, [0x29] = true, [0x2C] = true,
	[0x5B] = true, [0x5D] = true, [0x3A] = true,
	[0x7B] = true, [0x7D] = true--, [0x2E] = true,
};

local bases = {
	[0x42] = 2, [0x62] = 2,
	[0x4F] = 8, [0x6F] = 8,
	[0x58] = 16, [0x78] = 16
};

local function to_char_array(self)
	local len = #self;
	if len <= 7997 then
		return { s = self, string.byte(self, 1, len) };
	end;
	local clen = math.ceil(len / 7997);
	local ret = table.create(len);
	for i = 1, clen do
		local c = table.pack(string.byte(self, i * 7997 - 7996, i * 7997 - (i == clen and 7997 - ((len - 1) % 7997 + 1) or 0)));
		table.move(c, 1, c.n, i * 7997 - 7996, ret);
	end;
	ret.s = self;
	return ret;
end;

local function next_lex(codes, i0)
	local c = codes[i0];
	if not c then
		return;
	end;
	local ttype = 'other';
	local i1 = i0;
	if (c >= 0x30 and c <= 0x39) or (c == 0x2E and (codes[i0 + 1] and codes[i0 + 1] >= 0x30 and codes[i0 + 1] <= 0x39)) then
		-- Numbers
		local isfloat, has_expt = c == 0x2E, false;
		if c == 0x30 and bases[codes[i1 + 1]] then
			i1 += 2;
		end;
		while true do
			i1 += 1;
			c = codes[i1];
			if c == 0x2E then
				if isfloat then
					break;
				end;
				isfloat = true;
			elseif c == 0x45 or c == 0x65 then
				if isfloat or has_expt then
					break
				end;
				has_expt = true;
			elseif (not c) or (c < 0x30 or c > 0x39 and c ~= 0x5F) then
				break;
			end;
		end;
		ttype = 'number';
	elseif c == 0x22 or c == 0x27 then
		-- Strings
		repeat
			i1 += 1;
			if codes[i1] == 0x5C then
				i1 += 1;
				local c2 = codes[i1];
				if c2 == 0x75 then
					i1 += 5;
				elseif c2 == 0x78 then
					i1 += 3;
				else
					i1 += 1;
				end;
			end;
		until codes[i1] == c or not codes[i1];
		i1 += 1;
		ttype = 'string';
	elseif operator[c] then
		-- Operators/Comments/Strings
		if c == 0x2D and codes[i0 + 1] == 0x2D then
			i1 += 2;
			local eq_sign = -1;
			if codes[i1] == 0x5B then
				repeat
					i1 += 1;
					eq_sign += 1;
				until codes[i1] ~= 0x3D or not codes[i1];
			end;
			if eq_sign > -1 then
				repeat
					i1 = table.find(codes, 0x5D, i1 + 1) or #codes + 1;
					local c = eq_sign;
					while c > 0 and codes[i1 + 1] == 0x3D do
						c -= 1;
						i1 += 1;
					end;
				until c == 0 or not codes[i1];
				i1 += eq_sign + 2;
			else
				repeat
					i1 += 1;
				until codes[i1] == 0x0A or not codes[i1];
			end;
			ttype = "comment";
		elseif c == 0x5B and (codes[i0 + 1] == 0x5B or codes[i0 + 1] == 0x3D) then
			local eq_sign = -1;
			repeat
				i1 += 1;
				eq_sign += 1;
			until codes[i1] ~= 0x3D or not codes[i1];
			repeat
				i1 = table.find(codes, 0x5D, i1 + 1) or #codes + 1;
				local c = eq_sign;
				while c > 0 and codes[i1 + 1] == 0x3D do
					c -= 1;
					i1 += 1;
				end;
			until c == 0 or not codes[i1];
			i1 += eq_sign + 2;
			ttype = "string";
		else
			ttype = "operator";
			repeat
				i1 += 1;
			until not operator[codes[i1]];
		end;
	elseif (c >= 0x41 and c <= 0x5A) or (c >= 0x61 and c <= 0x7A) or c == 0x5F then
		-- Identifiers
		repeat
			i1 += 1;
			c = codes[i1];
		until (not c) or (c < 0x30 or c > 0x39) and (c < 0x41 or c > 0x5A) and (c < 0x61 or c > 0x7A) and c ~= 0x5F;
		ttype = identifiers[string.sub(codes.s, i0, i1 - 1)] or "identifier";
	else
		-- Others
		repeat
			i1 += 1;
			c = codes[i1];
		until (not c) or (c < 0x30 or c > 0x39) and (c < 0x41 or c > 0x5A) and (c < 0x61 or c > 0x7A) and c ~= 0x5F and c ~= 0x22 and c ~= 0x27 and not operator[c];
		ttype = "other"
	end;
	-- Whitespaces
	while codes[i1] and ((codes[i1] >= 0x09 and codes[i1] <= 0x0D) or codes[i1] == 0x20) do
		i1 += 1;
	end;
	return i1, ttype, string.sub(codes.s, i0, i1 - 1);
end;

function lexer.lex(str)
	return next_lex, to_char_array(str), 1;
end;

function lexer.scan(str)
	local scanResult = {}
	
	for trim, token, src in lexer.lex(str) do
		table.insert(scanResult, {trim = trim, token = token, src = src})
	end
	
	return scanResult
end

function lexer.navigator()

	local nav = {
		Source = "";
		TokenCache = table.create(50);

		_RealIndex = 0;
		_UserIndex = 0;
		_ScanThread = nil;
	}

	function nav:Destroy()
		self.Source = nil
		self._RealIndex = nil;
		self._UserIndex = nil;
		self.TokenCache = nil;
		self._ScanThread = nil;
	end

	function nav:SetSource(SourceString)
		self.Source = SourceString

		self._RealIndex = 0;
		self._UserIndex = 0;
		table.clear(self.TokenCache)

		self._ScanThread = coroutine.create(function()
			for trim, Token,Src in lexer.lex(self.Source) do
				self._RealIndex += 1
				self.TokenCache[self._RealIndex] = {trim; Token; Src;}
				coroutine.yield(trim, Token,Src)
			end
		end)
	end

	function nav.Next()
		nav._UserIndex += 1

		if nav._RealIndex >= nav._UserIndex then
			-- Already scanned, return cached
			return table.unpack(nav.TokenCache[nav._UserIndex])
		else
			if coroutine.status(nav._ScanThread) == 'dead' then
				-- Scan thread dead
				return
			else
				local success, trim, token, src = coroutine.resume(nav._ScanThread)
				if success and token then
					-- Scanned new data
					return trim, token,src
				else
					-- Lex completed
					return
				end
			end
		end

	end

	function nav.Peek(PeekAmount)
		local GoalIndex = nav._UserIndex + PeekAmount

		if nav._RealIndex >= GoalIndex then
			-- Already scanned, return cached
			if GoalIndex > 0 then
				return table.unpack(nav.TokenCache[GoalIndex])
			else
				-- Invalid peek
				return
			end
		else
			if coroutine.status(nav._ScanThread) == 'dead' then
				-- Scan thread dead
				return
			else

				local IterationsAway = GoalIndex - nav._RealIndex

				local success, trim, token, src = nil,nil,nil, nil

				for i=1, IterationsAway do
					success, trim, token, src = coroutine.resume(nav._ScanThread)
					if not (success or token) then
						-- Lex completed
						break
					end
				end

				return trim, token,src
			end
		end

	end

	return nav
end

return lexer;