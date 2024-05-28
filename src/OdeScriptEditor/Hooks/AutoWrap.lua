local AutoWrap = {
	RunOrder = 2,
}

function isCharWhitespace(char)
	return char == "\n" or char == " "
end

local allowedWraps = {
	{"\"", "\""},
	{"'", "'"},

	{"(", ")"},
	{"[", "]"},
	{"{", "}"},
}

function getLastSelectedString(scriptEditor, autoWrapState)
	local codeField = scriptEditor.Background.CodeField

	autoWrapState._LastCursorPosition = codeField.CursorPosition
	autoWrapState._LastSelectionStart = codeField.SelectionStart

	local start = math.min(autoWrapState._LastCursorPosition, autoWrapState._LastSelectionStart)
	local finish = math.max(autoWrapState._LastCursorPosition, autoWrapState._LastSelectionStart, 1) - 1

	if start == -1 then
		start = finish + 1
	end

	autoWrapState._LastSelectedString = string.sub(codeField.Text, start, finish)
	autoWrapState._LastPreviousChar = string.sub(codeField.Text, start - 1, start - 1)
end

function AutoWrap.OnScriptEditorInstantiation(scriptEditor)
	local codeField = scriptEditor.Background.CodeField

	local autoWrapState = {
		_LastSelectionStart = -1,
		_LastCursorPosition = -1,
		_LastSelectedString = "",
		_LastPreviousChar = "",
	}

	scriptEditor._AutoWrapState = autoWrapState

	codeField:GetPropertyChangedSignal("CursorPosition"):Connect(function()
		task.defer(getLastSelectedString, scriptEditor, autoWrapState)
	end)

	codeField:GetPropertyChangedSignal("SelectionStart"):Connect(function()
		task.defer(getLastSelectedString, scriptEditor, autoWrapState)
	end)
end

function AutoWrap.OnScriptChange(scriptEditor, data)
	if not scriptEditor.AutoWrapEnabled then
		return
	end

	local autoWrapState = scriptEditor._AutoWrapState

	local code = data.Code
	local cursor = data.Cursor
	local codeField: TextBox = scriptEditor.Background.CodeField

	if codeField.CursorPosition ~= -1 then
		-- local lastChar = string.sub(codeField.Text, codeField.CursorPosition - 1, codeField.CursorPosition - 1)
		local lastCharPosition = codeField.CursorPosition - 1 + cursor
		local lastChar = string.sub(code, lastCharPosition, lastCharPosition)
		local lastSelectedString = autoWrapState._LastSelectedString

		local cursorChar = string.sub(code, lastCharPosition + 1, lastCharPosition + 1)
		local nextLastChar = string.sub(code, lastCharPosition - 1, lastCharPosition - 1)

		for _, wrappedCharData in allowedWraps do
			local startingWrappedChar = wrappedCharData[1]

			if lastChar == startingWrappedChar and lastSelectedString ~= startingWrappedChar and lastSelectedString ~= "" and (autoWrapState._LastPreviousChar ~= startingWrappedChar or nextLastChar == startingWrappedChar) then
				code = string.sub(code, 1, lastCharPosition) .. lastSelectedString .. wrappedCharData[2] .. string.sub(code, lastCharPosition + 1)

				codeField.SelectionStart = if lastSelectedString ~= "" then lastCharPosition + 1 else -1
				data.Cursor += lastSelectedString:len()
			end
		end
	end

	data.Code = code
end

return AutoWrap