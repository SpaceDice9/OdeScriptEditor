local InitGui = {}
InitGui.NIL = newproxy()

function trySet(instance, property, value)
	return pcall(function()
		instance[property] = value
	end)
end

function InitGui.instance(properties)
	local className = properties.ClassName
	local instance = Instance.new(className)

	for k, v in properties do
		if k ~= "ClassName" and k ~= "Parent" then
			if v == InitGui.NIL then
				v = nil
			end

			trySet(instance, k, v)
		end
	end

	instance.Parent = properties.Parent

	return instance
end

function InitGui.init()
	local oseBackground = InitGui.instance {
		Name = "OSEBackground",
		ClassName = "Frame",
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0)
	}

	InitGui.instance {
		Name = "LineNumberBackground",
		ClassName = "Frame",
		BackgroundColor3 = Color3.fromRGB(51, 51, 51),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 16, 1, -10),
		Parent = oseBackground,
	}

	local lineNumberContainer = InitGui.instance {
		Name = "LineNumberContainer",
		ClassName = "Frame",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 5),
		Size = UDim2.new(0, 16, 1, -10),
		ZIndex = 2,
		Parent = oseBackground
	}

	InitGui.instance {
		ClassName = "UIListLayout",
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = lineNumberContainer,
	}

	local richOverlayContainer = InitGui.instance {
		Name = "RichOverlayContainer",
		ClassName = "Frame",
		BackgroundTransparency = 1,
		Active = true,
		Position = UDim2.new(0, 25, 0, 5),
		Size = UDim2.new(1, -30, 1, -10),
		ClipsDescendants = true,
		Parent = oseBackground
	}

	local shiftContainer = InitGui.instance {
		Name = "ShiftContainer",
		ClassName = "Frame",
		BackgroundTransparency = 1,
		Active = true,
		Position = UDim2.new(),
		Size = UDim2.new(3, 0, 1, 0),
		ClipsDescendants = false,
		Parent = richOverlayContainer,
	}

	InitGui.instance {
		ClassName = "UIListLayout",
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = shiftContainer,	
	}

	InitGui.instance {
		Name = "CodeField",
		ClassName = "TextBox",
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		MultiLine = true,
		Position = UDim2.new(0, 25, 0, 5),
		Size = UDim2.new(1, -30, 1, -10),
		Font = Enum.Font.Code,
		Text = "",
		TextColor3 = Color3.new(.8, .8, .8),
		TextSize = 14,
		TextTransparency = .5,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		ClipsDescendants = true,
		Parent = oseBackground,
	}

	return oseBackground
end

function InitGui.storage()
	local storage = InitGui.instance {
		Name = "Storage",
		ClassName = "Folder"
	}

	InitGui.instance {
		Name = "LineNumber",
		ClassName = "TextLabel",
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -6, 0, 0),
		ZIndex = 5,
		Font = Enum.Font.SourceSans,
		TextColor3 = Color3.new(.8, .8, .8),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = storage,
	}

	InitGui.instance {
		Name = "RichOverlayLabel",
		ClassName = "TextLabel",
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		ZIndex = 5,
		Font = Enum.Font.Code,
		TextColor3 = Color3.new(.8, .8, .8),
		RichText = true,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = storage,
	}

	return storage
end

return InitGui