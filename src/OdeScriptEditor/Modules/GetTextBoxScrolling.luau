local TextService = game:GetService("TextService")
-- Only works when font is monospaced and x size is exactly C * width of character + 1 (6 * 7 + 1 = 43)

function getMultiLinePositions(text)
	local multilines = string.split(text, "\n")
	local multilinePositions = {}
	local cursor = 1

	for _, line in multilines do
		table.insert(multilinePositions, {cursor, cursor + string.len(line)})

		cursor += string.len(line) + 1
	end

	return multilines, multilinePositions
end

function getLinePosition(multilinePositions, position)
	for i, multilinePosition in multilinePositions do
		if (position >= multilinePosition[1] and position <= multilinePosition[2]) then
			return i, position - multilinePosition[1] + 1
		end
	end

	return -1, -1
end

function getLengthOfLine(text, textLabel: TextBox)
	local absoluteSize = TextService:GetTextSize(
		text,
		textLabel.TextSize,
		textLabel.Font,
		Vector2.new(math.huge, math.huge)
	)

	return absoluteSize.X
end

function getShiftAmount(lower, upper, x)
	if x < lower then
		return x - lower
	elseif x > upper then
		return x - upper
	else
		return 0
	end
end

local GetTextBoxScrolling = {}

function GetTextBoxScrolling.UpdateShift(textLabel: TextBox, cursorPosition, shift)
	if cursorPosition == -1 then
		return 0
	end

	local labelWindow = textLabel.AbsoluteSize.X - 1

	local multilines, multilinePositions = getMultiLinePositions(textLabel.Text)
	local linePosition, positionLength = getLinePosition(multilinePositions, cursorPosition)
	local line = multilines[linePosition]
	local stringUntilCursor = string.sub(line, 0, positionLength - 1)
	local lineLength = getLengthOfLine(stringUntilCursor, textLabel)
	local relativeShift = getShiftAmount(shift, shift + labelWindow, lineLength)

	shift += relativeShift

	return shift
end

return GetTextBoxScrolling