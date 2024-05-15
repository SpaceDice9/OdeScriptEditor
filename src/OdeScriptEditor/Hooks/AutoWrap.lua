local AutoWrap = {}

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

function AutoWrap.OnScriptChange(scriptEditor, data)
	if not scriptEditor.AutoWrapEnabled then
		return
	end

	local code = data.Code
	local cursor = data.Cursor
	local codeField: TextBox = scriptEditor.Background.CodeField

	if codeField.CursorPosition ~= -1 then
		-- local lastChar = string.sub(codeField.Text, codeField.CursorPosition - 1, codeField.CursorPosition - 1)
		local lastCharPosition = codeField.CursorPosition - 1 + cursor
		local lastChar = string.sub(code, lastCharPosition, lastCharPosition)
		local lastSelectedString = scriptEditor._LastSelectedString

		local cursorChar = string.sub(code, lastCharPosition + 1, lastCharPosition + 1)
		local nextLastChar = string.sub(code, lastCharPosition - 1, lastCharPosition - 1)

		for _, wrappedCharData in allowedWraps do
			local startingWrappedChar = wrappedCharData[1]

			if lastChar == startingWrappedChar and lastSelectedString ~= startingWrappedChar and lastSelectedString ~= "" and (scriptEditor._LastPreviousChar ~= startingWrappedChar or nextLastChar == startingWrappedChar) then
				code = string.sub(code, 1, lastCharPosition) .. lastSelectedString .. wrappedCharData[2] .. string.sub(code, lastCharPosition + 1)

				codeField.SelectionStart = if lastSelectedString ~= "" then lastCharPosition + 1 else -1
				data.Cursor += lastSelectedString:len()
			end
		end
	end

	data.Code = code
end

return AutoWrap