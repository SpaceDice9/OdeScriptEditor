local Modules = script.Modules
local FastLexer = require(Modules.fastlexer)
local LuaTable = require(Modules.LuaTable)
local SignalModule = require(Modules.SignalModule)

local Storage = script.Storage

local OdeScriptEditor = {}
OdeScriptEditor.__index = OdeScriptEditor

local OdeDefaultTheme = {
	background = Color3.fromRGB(37, 37, 37),

	sidebar = Color3.fromRGB(47, 47, 47),

	text = Color3.fromRGB(204, 204, 204),

	keyword = {
		color = Color3.fromRGB(248, 109, 124),
		isBold = true,
	},

	builtin = {
		color = Color3.fromRGB(132, 214, 247),
		isBold = true,
	},

	string = {
		color = Color3.fromRGB(173, 241, 149),
		isBold = false,
	},

	number = {
		color = Color3.fromRGB(255, 198, 0),
		isBold = false,
	},

	comment = {
		color = Color3.fromRGB(102, 102, 102),
		isBold = false,
	},


	lprop = {
		color = Color3.fromRGB(97, 161, 241),
		isBold = false,
	},

	lmethod = {
		color = Color3.fromRGB(253, 251, 172),
		isBold = false,
	},

	bool = {
		color = Color3.fromRGB(255, 198, 0),
		isBold = true,
	},


	operator = {
		color = Color3.fromRGB(204, 204, 204),
		isBold = false,
	},

	method = {
		color = Color3.fromRGB(253, 251, 172),
		isBold = false,
	},

	luau = {
		color = Color3.fromRGB(248, 109, 124),
		isBold = true,
	},

	["nil"] = {
		color = Color3.fromRGB(248, 109, 124),
		isBold = true,
	},

	["function"] = {
		color = Color3.fromRGB(248, 109, 124),
		isBold = true,
	},

	["local"] = {
		color = Color3.fromRGB(248, 109, 124),
		isBold = true,
	},

	["self"] = {
		color = Color3.fromRGB(248, 109, 124),
		isBold = true,
	},
}

local lib_methods = {
	bit32 = true,
	coroutine = true,
	debug = true,
	math = true,
	os = true,
	string = true,
	table = true,
	utf8 = true,

	task = true,

	Axes = 'builtin', BrickColor = 'builtin', CFrame = 'builtin', Color3 = 'builtin', ColorSequence = 'builtin', ColorSequenceKeypoint = 'builtin', DateTime = 'builtin', DockWidgetPluginGuiInfo = 'builtin',
	Faces = 'builtin', Instance = 'builtin', NumberRange = 'builtin', NumberSequence = 'builtin', NumberSequenceKeypoint = 'builtin', PathWaypoint = 'builtin', PhysicalProperties = 'builtin', Random = 'builtin',
	Ray = 'builtin', RaycastParams = 'builtin', Rect = 'builtin', Region3 = 'builtin', Region3int16 = 'builtin', TweenInfo = 'builtin', UDim = 'builtin', UDim2 = 'builtin', Vector2 = 'builtin',
	Vector2int16 = 'builtin', Vector3 = 'builtin', Vector3int16 = 'builtin',

	CatalogSearchParams = 'builtin', FloatCurveKey = 'builtin', Font = 'builtin', OverlapParams = 'builtin', SharedTable = 'builtin',
}

local odeHighlightColorsInfo = {
	keyword = {"Keyword Color", true},
	builtin = {"Built-in Function Color", true},
	string = {"String Color", false},
	number = {"Number Color", false},
	comment = {"Comment Color", false},

	lprop = {"Property Color", false},
	lmethod = {"Method Color", false},
	method = {"Function Name Color", false},
	bool = {"Bool Color", true},

	operator = {"Operator Color", false},
	luau = {"Luau Keyword Color", true},
	["nil"] = {"\"nil\" Color", true},
	["function"] = {"\"function\" Color", true},
	["local"] = {"\"local\" Color", true},
	["self"] = {"\"self\" Color", true},
}

local tokenNameTypes = {
	["local"] = "local",
	["function"] = "function",
	["self"] = "self",
	["nil"] = "nil",
	["true"] = "bool",
	["false"] = "bool",

	["type"] = "luau",
	["typeof"] = "luau",
	["export"] = "luau",
	["continue"] = "luau",
}

local function replace(str, s, e, replacementString)
	local before = string.sub(str, 1, s - 1)
	local after = string.sub(str, e + 1, str:len())

	return before .. replacementString .. after
end

local function rawWrapString(str, substr, Start, End, color, isBold)
	local r, g, b = math.ceil(color.R*255), math.ceil(color.G*255), math.ceil(color.B*255)
	local colorStrStart = '<font color="' .. 'rgb(' .. r .. ',' .. g .. ',' .. b .. ')">'
	local bold = ''
	local afterbold = ''

	if isBold then
		bold = '<b>'
		afterbold = '</b>'
	end

	return replace(str, Start, End, colorStrStart .. bold .. substr .. afterbold .. '</font>')
end

local function iterateThruAndReplace(str, pattern, replacement)
	local cleanStr, replacements = string.gsub(str, pattern, replacement)
	return cleanStr
end

--https://stackoverflow.com/questions/51181222/lua-trailing-space-removal
local function trimWhitespace(str)
	return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

local function getTrueTokenData(i, tokenData, scanData)
	local prevTokenData = scanData[i - 1]
	local nextTokenData = scanData[i + 1]

	local token = tokenData.token

	if token == "identifier" then
		local prevIndexData = scanData[i - 2]

		if prevTokenData and prevTokenData.src == "." then
			if prevIndexData and lib_methods[prevIndexData.src] then
				return "builtin"
			else
				token = "lprop"
			end
		end

		if nextTokenData and nextTokenData.src:match("%(") then
			if prevTokenData and prevTokenData.src == "." then
				token = "lmethod"
			else
				token = "method"
			end
		end
	end

	local tokenText = trimWhitespace(tokenData.src)
	local trueToken = tokenNameTypes[tokenText]

	if trueToken then
		token = trueToken
	end

	return token
end

local function escapeRich(code)
	local cleanCode = iterateThruAndReplace(code, "&", "&amp;")

	cleanCode = iterateThruAndReplace(cleanCode, "<", "&lt;")
	cleanCode = iterateThruAndReplace(cleanCode, ">", "&gt;")

	cleanCode = iterateThruAndReplace(cleanCode, "\"", "&quot;")
	cleanCode = iterateThruAndReplace(cleanCode, "\'", "&apos;")

	return cleanCode
end

local function tabsToSpaces(code)
	return iterateThruAndReplace(code, "\9", "    ")
end

local function spacesToTabs(code)
	return iterateThruAndReplace(code, "    ", "\9")
end

local function colorify(code, theme)
	theme = theme or OdeDefaultTheme

	local highlight = code

	local size = code:len()
	local increase = 0

	local scanData = FastLexer.scan(code)

	for i, tokenData in scanData do
		local token = tokenData.token
		token = getTrueTokenData(i, tokenData, scanData)

		local colorData = theme[token]

		if colorData then
			local trim = tokenData.trim
			local src = tokenData.src

			--takes care of strange bug where given trim is larger than reality
			if tokenData.token == "string" and not (string.match(src, '%b""') or string.match(src, "%b''") or string.match(src, "%b``")) then
				trim -= 1
			end

			local End = trim - 1 + increase
			local Start = trim - src:len() + increase

			local color = colorData.color
			local isBold = colorData.isBold

			local escapedToken = escapeRich(src)

			highlight = rawWrapString(highlight, escapedToken, Start, End, color, isBold)--wrapstring(highlight, Start, End, color, isBold)
			increase = math.abs(highlight:len() - size)
		end
	end
	--trim, token, src

	return highlight
end

local registerEditEvent = true

local function rawEditCodeField(scriptEditor, text)
	registerEditEvent = false
	scriptEditor.Background.CodeField.Text = text

	task.defer(function()
		registerEditEvent = true
	end)
end

local function onCodeFieldEdit(scriptEditor)
	if not registerEditEvent then
		registerEditEvent = true

		return
	end

	local background = scriptEditor.Background
	local codeField = background.CodeField

	local newText = codeField.Text
	local lines = string.split(newText, "\n")

	for _, lineNumberLabel in background.LineNumberContainer:GetChildren() do
		if lineNumberLabel:IsA("TextLabel") then
			lineNumberLabel:Destroy()
		end
	end

	for _, richOverlayLabel in background.RichOverlayContainer:GetChildren() do
		if richOverlayLabel:IsA("TextLabel") then
			richOverlayLabel:Destroy()
		end
	end

	local lineNumberWidth = 6*math.ceil(math.log10(#scriptEditor.SourceData.Code + .1))
	background.LineNumberContainer.Size = UDim2.new(0, lineNumberWidth + 6, 1, -10)
	background.LineNumberBackground.Size = UDim2.new(0, lineNumberWidth + 6, 1, 0)

	codeField.Position = UDim2.new(0, lineNumberWidth + 9, 0, 5)
	codeField.Size = UDim2.new(1, -(lineNumberWidth + 9 + 5), 1, -10)

	background.RichOverlayContainer.Position = UDim2.new(0, lineNumberWidth + 9, 0, 5)
	background.RichOverlayContainer.Size = UDim2.new(1, -(lineNumberWidth + 9 + 5), 1, -10)

	local luaArray = string.split(newText--[[spacesToTabs(newText)]], "\n")
	scriptEditor.SourceData:Write(scriptEditor.LineFocused, scriptEditor.VisibleLines, luaArray)
	scriptEditor.RawSource = scriptEditor.SourceData:ToString()

	local finalRawCode = newText

	for i = 1, scriptEditor.VisibleLines do
		local line = scriptEditor.SourceData.Code[scriptEditor.LineFocused + i - 1]--lines[i]

		if not line then
			break
		end

		local lineNumberLabel = Storage.LineNumber:Clone()
		lineNumberLabel.Text = i + scriptEditor.LineFocused - 1
		lineNumberLabel.LayoutOrder = i
		lineNumberLabel.Parent = background.LineNumberContainer

		local untabbedLine = tabsToSpaces(line)
		local enrichedLine = colorify(untabbedLine--[[escapeRich(untabbedLine)]], scriptEditor.Theme)
		local richTextOverlay = Storage.RichOverlayLabel:Clone()
		richTextOverlay.Text = enrichedLine
		richTextOverlay.LayoutOrder = i
		richTextOverlay.Parent = background.RichOverlayContainer
	end

	if #lines < scriptEditor.VisibleLines then
		for i = #lines + 1, scriptEditor.VisibleLines do
			local line = scriptEditor.SourceData.Code[scriptEditor.LineFocused + i - 1]

			if not line then
				break
			end

			local untabbedLine = line--tabsToSpaces(line)
			finalRawCode = finalRawCode .. "\n" .. untabbedLine
		end
	elseif #lines > scriptEditor.VisibleLines then
		local replacementText = lines[1]

		for i = 2, scriptEditor.VisibleLines do
			replacementText = replacementText .. "\n" .. lines[i]
		end

		finalRawCode = replacementText
	end

	local hookModules = script.Hooks:GetChildren()

	table.sort(hookModules, function(a, b)
		return a:GetAttribute("RunOrder") < b:GetAttribute("RunOrder")
	end)

	local data = {
		Code = finalRawCode,
		Gain = finalRawCode:len() - scriptEditor.DisplayCode:len(),
		Cursor = 0,
		Selection = 0,
	}

	--runs thru hooks and runs their custom behavior
	--postprocessing code
	for _, hookModule in script.Hooks:GetChildren() do
		local method = require(hookModule)["OnScriptChange"]

		if method then
			method(scriptEditor, data)
		end
	end

	finalRawCode = data.Code

	if finalRawCode ~= newText then
		--temporarily moves selection to the beginning to make sure autoindent doesn't repeatedly fire and crash
		local prevPosition = codeField.CursorPosition
		codeField.CursorPosition = -1

		codeField.Text = finalRawCode
		codeField.CursorPosition = prevPosition + data.Cursor
	else
		scriptEditor.OnEdit:Fire(scriptEditor.RawSource)
	end

	scriptEditor.DisplayCode = finalRawCode
end

local function addLinesAfterResize(scriptEditor, originalSize)
	local background = scriptEditor.Background

	for i = originalSize + 1, scriptEditor.VisibleLines do
		local line = scriptEditor.SourceData.Code[scriptEditor.LineFocused + i - 1]

		if not line then
			break
		end

		local lineNumberLabel = Storage.LineNumber:Clone()
		lineNumberLabel.Text = i + scriptEditor.LineFocused - 1
		lineNumberLabel.LayoutOrder = i
		lineNumberLabel.Parent = background.LineNumberContainer

		local enrichedLine = colorify(tabsToSpaces(line), scriptEditor.Theme)
		local richTextOverlay = Storage.RichOverlayLabel:Clone()
		richTextOverlay.Text = enrichedLine
		richTextOverlay.LayoutOrder = i
		richTextOverlay.Parent = background.RichOverlayContainer

		rawEditCodeField(scriptEditor, scriptEditor.Background.CodeField.Text .. "\n" .. line--[[tabsToSpaces(line)]])
	end
end

local function repack(t, separator)
	local str = t[1]

	for i = 2, #t do
		if not t[i] then
			--print(i)
		end

		str = str .. separator .. t[i]
	end

	return str
end

local function removeLinesAfterResize(scriptEditor, originalSize)
	local background = scriptEditor.Background

	for _, richTextOverlay in background.RichOverlayContainer:GetChildren() do
		if richTextOverlay:IsA("TextLabel") then
			if richTextOverlay.LayoutOrder > scriptEditor.VisibleLines then
				richTextOverlay:Destroy()
			end
		end
	end

	for _, lineNumberLabel in background.LineNumberContainer:GetChildren() do
		if lineNumberLabel:IsA("TextLabel") then
			if lineNumberLabel.LayoutOrder > scriptEditor.VisibleLines then
				lineNumberLabel:Destroy()
			end
		end
	end

	local lines = string.split(background.CodeField.Text, "\n")

	for i = scriptEditor.VisibleLines + 1, originalSize do
		lines[i] = nil
	end

	rawEditCodeField(scriptEditor, repack(lines, "\n"))
end

local function recountVisibleLines(scriptEditor)
	local visibleLines = math.ceil(scriptEditor.Background.CodeField.AbsoluteSize.Y/14)

	scriptEditor.VisibleLines = visibleLines
end

function OdeScriptEditor:ApplyTheme(odeThemeData)
	odeThemeData = odeThemeData or self.Theme
	self.Theme = odeThemeData

	local background = self.Background

	if #background:GetChildren() == 0 then
		return
	end

	background.BackgroundColor3 = odeThemeData.background
	background.LineNumberBackground.BackgroundColor3 = odeThemeData.sidebar
	background.CodeField.TextColor3 = odeThemeData.text

	Storage.LineNumber.TextColor3 = odeThemeData.text
	Storage.RichOverlayLabel.TextColor3 = odeThemeData.text

	for _, lineLabel: Instance in pairs(background.LineNumberContainer:GetChildren()) do
		if lineLabel:IsA("TextLabel") then
			lineLabel.TextColor3 = odeThemeData.text
		end
	end

	for _, lineLabel: Instance in pairs(background.RichOverlayContainer:GetChildren()) do
		if lineLabel:IsA("TextLabel") then
			lineLabel.TextColor3 = odeThemeData.text
		end
	end

	self:JumpTo()
end

function OdeScriptEditor:ApplyStudioTheme(studio: Studio)
	local theme = {
		background = studio["Background Color"],
		text = studio["Text Color"],
		sidebar = studio["Script Editor Scrollbar Background Color"],
	}

	for odeThemePropertyName, highlightData in odeHighlightColorsInfo do
		theme[odeThemePropertyName] = {
			color = studio[highlightData[1]],
			isBold = highlightData[2]
		}
	end

	self:ApplyTheme(theme)
end

function OdeScriptEditor:JumpTo(lineNumber: number)
	lineNumber = lineNumber or self.LineFocused
	self.LineFocused = lineNumber

	local lines = string.split(self.RawSource, "\n")
	local displayCode = ""

	for i = lineNumber, lineNumber + self.VisibleLines - 1 do
		local line = lines[i]

		if line then
			displayCode = displayCode .. line .. "\n"
		end
	end

	displayCode = string.sub(displayCode, 1, displayCode:len() - 1)
	displayCode = displayCode--tabsToSpaces(displayCode)

	if self.Background.CodeField.Text == displayCode then
		onCodeFieldEdit(self)
	else
		self.Background.CodeField.Text = displayCode
	end
end

function OdeScriptEditor:LoadStringAsync(str: string, lineNumber: number)
	self.Background.CodeField.Visible = false
	self.Background.RichOverlayContainer.Visible = false
	self.Background.LineNumberContainer.Visible = false

	-- the delay is for the specific case where Ode is embedded to a disabled plugin widget
	task.delay(1/30, function()
		recountVisibleLines(self)
		self.RawSource = str
		self.SourceData = LuaTable.FromString(str)

		self.Background.CodeField.Visible = true
		self.Background.RichOverlayContainer.Visible = true
		self.Background.LineNumberContainer.Visible = true

		self:JumpTo(lineNumber or 1)
	end)
end

function OdeScriptEditor:LoadScriptAsync(scriptObject: LuaSourceContainer, lineNumber: number)
	self:LoadStringAsync(scriptObject.Source, lineNumber)
end

function OdeScriptEditor:Unload()
	self:LoadStringAsync("")
end

function OdeScriptEditor:ReadOnly(allowEditing: boolean?)
	self.Background.CodeField.TextEditable = allowEditing or false
end

function OdeScriptEditor.Embed(frame: GuiBase2d)
	local background = script.OSEBackground:Clone()
	background.Parent = frame

	local scriptEditor = {
		LineFocused = 1,
		RawSource = "",
		SourceData = LuaTable.FromString(""),
		DisplayCode = "",
		Background = background,
		VisibleLines = 1,
		OutputScript = nil,

		OnEdit = SignalModule.new(),

		Theme = OdeDefaultTheme,
	}

	setmetatable(scriptEditor, OdeScriptEditor)

	local codeField = background.CodeField

	codeField:GetPropertyChangedSignal("Text"):Connect(function()
		onCodeFieldEdit(scriptEditor)
	end)

	background:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local originalSize = scriptEditor.VisibleLines

		recountVisibleLines(scriptEditor)

		local newSize = scriptEditor.VisibleLines

		if newSize > originalSize then
			addLinesAfterResize(scriptEditor, originalSize)
		elseif newSize < originalSize then
			removeLinesAfterResize(scriptEditor, originalSize)
		end
	end)

	codeField.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local newLineFocused = math.clamp(scriptEditor.LineFocused - input.Position.Z*3, 1, #string.split(scriptEditor.RawSource, "\n"))

			codeField:ReleaseFocus()

			scriptEditor:JumpTo(newLineFocused)
		end
	end)

	scriptEditor:LoadStringAsync("")

	return scriptEditor
end

function OdeScriptEditor:Relocate(newFrame: GuiBase2d)
	local background = self.Background
	background.Parent = newFrame
end

return OdeScriptEditor
