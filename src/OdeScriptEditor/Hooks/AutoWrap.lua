local AutoWrap = {}

function isCharWhitespace(char)
	return char == "\n" or char == " "
end

function AutoWrap.OnScriptChange(scriptEditor, data)
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

		if lastChar == "\"" and lastSelectedString ~= "\"" and lastSelectedString ~= "" and (scriptEditor._LastPreviousChar ~= "\"" or nextLastChar == "\"") then
			code = string.sub(code, 1, lastCharPosition) .. lastSelectedString .. "\"" .. string.sub(code, lastCharPosition + 1)

			codeField.SelectionStart = if lastSelectedString ~= "" then lastCharPosition + 1 else -1
			data.Cursor += lastSelectedString:len()
		end
	end

	data.Code = code
end

return AutoWrap