local AutoIndent = {}

local function testForIndent(codeField, code, start, keyword)
	if start - keyword:len() <= 0 then
		return
	end

	local previousRawText = codeField.Text:sub(start - keyword:len(), start - 1)
	local previousText = code:sub(start - keyword:len(), start - 1)

	if previousRawText == keyword and previousRawText == previousText then
		return true
	end
end

local function countTabs(line)
	-- local init = 1
	-- local count = 0

	-- repeat
	-- 	local Start, End = string.find(line, "\9", init)

	-- 	if Start and End then
	-- 		init = Start + 1
	-- 		count += 1
	-- 	end
	-- until not (Start and End)

	-- return count

	return string.match(line, "^\9*"):len()
end

local indentKeywords = {
	["do"] = 1,
	["then"] = 1,
	["repeat"] = 1,
	["{"] = 1,
	["function()"] = 1,
}

function findCurrentLine(code, position)
	local lines = string.split(code, "\n")
	local selection = 0
	local currentLineNumber = 0

	for i, line in lines do
		selection += 1 + line:len()

		if position <= selection then
			currentLineNumber = i

			break
		end
	end

	if not currentLineNumber then
		warn("Failed to find current line number")
		return false
	end

	return currentLineNumber, lines
end

function AutoIndent.OnScriptChange(scriptEditor, data)
	local code = data.Code

	local codeField = scriptEditor.Background.CodeField
	local position = codeField.CursorPosition
	local canIndent = false

	local additionalTabs = 0

	for keyword, tabs in indentKeywords do
		if testForIndent(codeField, code, position, keyword .. "\n") and data.Gain == 1 then
			canIndent = true
			additionalTabs = tabs

			break
		end
	end

	local currentLineNumber, lines = findCurrentLine(code, position)
	local previousLineNumber = currentLineNumber - 1

	local currentText = lines[currentLineNumber]
	local previousText = lines[previousLineNumber]

	local justReached = previousText and currentText == "" and data.Gain == 1

	if not canIndent and justReached then
		--lonely function case

		local funcPatterns = {
			"^%s*function%s+[%w%.:]+%b()%s*",
			"^%s*local%s+function%s+[%w%.:]+%b()%s*",
			"^%s*function%s*%b()%s*",
		}

		for _, funcPattern in funcPatterns do
			if previousText:match(funcPattern) == previousText then
				canIndent = true
				additionalTabs = 1

				break
			end
		end
	end

	--previous indent case
	if not canIndent and justReached then
		local previousTabs = countTabs(previousText)

		if previousTabs > 0 then
			canIndent = true
			additionalTabs = 0
		end
	end

	if canIndent and previousLineNumber then
		--print(lines)
		--print(previousLineNumber)

		local tabsCount = countTabs(lines[previousLineNumber]) + additionalTabs

		--print(tabsCount)
		--print(string.split(code:sub(1, position - 1) .. string.rep("    ", tabsCount) .. code:sub(position), "\n"))

		data.Cursor += tabsCount
		data.Code = code:sub(1, position - 1) .. string.rep("\9", tabsCount) .. code:sub(position)
	end
end

return AutoIndent
