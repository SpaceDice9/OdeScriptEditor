--Create LuaTable class
local LuaTable = {}; LuaTable.__index = LuaTable

--Updates size field
function LuaTable:UpdateSize()
	local Size = 0

	for Line, _ in pairs(self.Code) do
		if Line > Size then
			Size = Line
		end
	end

	self.Size = Size

	return Size
end

--Pushes a new line with Lua code
function LuaTable:Push(Line, LuaArray)
	for RelativeLine, LuaLine in pairs(LuaArray) do
		table.insert(self.Code, Line + RelativeLine - 1, LuaLine)
	end

	self:UpdateSize()

	return self
end

--Pushes new Lua code after specified line
function LuaTable:Insert(Line, LuaArray)
	return self:Push(Line + 1, LuaArray)
end

--Adds new lua code at the end of table
function LuaTable:Add(LuaArray)
	return self:Insert(self.Size, LuaArray)
end

--Erases lua lines
function LuaTable:Erase(RegionStart, RegionLength)
	RegionLength = RegionLength or 1

	for i = 1, RegionLength do
		table.remove(self.Code, RegionStart)
	end

	self:UpdateSize()

	return self
end

--Overwrites before pushing new Lua code in specified region
function LuaTable:Write(RegionStart, RegionLength, LuaArray)
	return self
		:Erase(RegionStart, RegionLength)
		:Push(RegionStart, LuaArray)
end

function LuaTable.new(LuaLines)
	local Fields = {
		Code = LuaLines,
		Size = #LuaLines
	}

	local self = setmetatable(Fields, LuaTable)
	self:UpdateSize()

	return self
end

function LuaTable.FromArray(LuaArray)
	return LuaTable.new(LuaArray)
end

function LuaTable.FromString(str)
	return LuaTable.new(string.split(str, "\n"))
end

--Creates object
function LuaTable.FromTuple(...)
	local LuaLines = {...}

	return LuaTable.new(LuaLines)
end

--Converts raw Lua code into LuaTable object
function LuaTable.FromScript(Script)
	return LuaTable.FromString(Script.Source)
end

--Converts LuaTable object into raw Lua code
function LuaTable:ToString(RegionStart, RegionLength)
	RegionStart = math.max(RegionStart or 1, 1)

	local LuaString = ""
	local size = math.min(RegionLength or math.huge, self.Size - RegionStart + 1)

	for Line = 1, size do
		local LuaLine = self.Code[Line + RegionStart - 1] or ""
		local NextLine = "\n"

		if Line == size then
			NextLine = ""
		end

		LuaLine = LuaLine .. NextLine
		LuaString = LuaString .. LuaLine
	end

	return LuaString
end

--Converts LuaTable object into raw Lua code before overwriting a script
function LuaTable:ToScript(Script, RegionStart, RegionLength)
	Script.Source = self:ToString(RegionStart, RegionLength)
end

--Converts object into an array
function LuaTable:ToArray(RegionStart, RegionLength)
	RegionStart = math.max(RegionStart or 1, 1)

	local array = {}
	local size = math.min(RegionLength or math.huge, self.Size - RegionStart + 1)

	for index = 1, size do
		local LuaLine = self.Code[index + RegionStart - 1]

		array[index] = LuaLine or ""
	end

	return array
end

return LuaTable