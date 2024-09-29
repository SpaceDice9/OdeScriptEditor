-- TextBoxPlus was created by :: zack@boatbomber.com
-- https://create.roblox.com/store/asset/4471070171/TextBoxPlus?externalSource=www
-- https://devforum.roblox.com/t/textbox-plus-expanded-textbox-functionality/397530

local module	= {}
local Inputs	= {}
local Ignores	= {}
local WaypointStack	= {}

local UIS	= game:GetService("UserInputService")
local TS	= game:GetService("TextService")
local RS	= game:GetService("RunService")

local function isShiftKeyDown()
	return UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
end

UIS.InputBegan:Connect(function(Input,GP)
	if not GP then return end
	if  Input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	
	local TextBox = UIS:GetFocusedTextBox()
	
	if Inputs[TextBox] then
		
		wait() -- Let the keypress be handle by the TextBox
		
		--[=[
		TODO: Figure out how to determine lines when LineWrapped so Up/Down is possible
		--]=]
		
		if Input.KeyCode == Enum.KeyCode.Up then
			-- Go to line above
			
			if TextBox.MultiLine and not TextBox.TextWrapped then
				
				local TextLines = string.split(TextBox.Text, "\n")
				
				local CurrentLineNumber = #string.split(string.sub(TextBox.Text,1,TextBox.CursorPosition-1), "\n")
				
				
				if CurrentLineNumber>1 then
				
					local CurrentLinePos = {
						Start = #table.concat(TextLines,"\n",1,CurrentLineNumber-1)+2;
						End = #table.concat(TextLines,"\n",1,CurrentLineNumber)+1;
					}
									
					local CursorPosRelativeInLine = TextBox.CursorPosition-CurrentLinePos.Start
					
					local PreviousLinePos = {
						Start = #table.concat(TextLines,"\n",1,CurrentLineNumber-2)+2;
						End = #table.concat(TextLines,"\n",1,CurrentLineNumber-1)+1;
					}
							
					-- Changing the cursor position is not necessary when embedded in OseScriptEditor
					--TextBox.CursorPosition = math.clamp(PreviousLinePos.Start + CursorPosRelativeInLine, PreviousLinePos.Start, PreviousLinePos.End)
					
				end
				
			end
			
		elseif Input.KeyCode == Enum.KeyCode.Down then
			-- Go to line below
			
			if TextBox.MultiLine and not TextBox.TextWrapped then
				
				local TextLines = string.split(TextBox.Text, "\n")
				
				local CurrentLineNumber = #string.split(string.sub(TextBox.Text,1,TextBox.CursorPosition-1), "\n")
				
				
				if CurrentLineNumber<#TextLines then
				
					local CurrentLinePos = {
						Start = #table.concat(TextLines,"\n",1,CurrentLineNumber-1)+2;
						End = #table.concat(TextLines,"\n",1,CurrentLineNumber)+1;
					}
									
					local CursorPosRelativeInLine = TextBox.CursorPosition-CurrentLinePos.Start
					
					local NextLinePos = {
						Start = #table.concat(TextLines,"\n",1,CurrentLineNumber)+2;
						End = #table.concat(TextLines,"\n",1,CurrentLineNumber+1)+1;
					}
					-- Changing the cursor position is not necessary when embedded in OseScriptEditor
					--TextBox.CursorPosition = math.clamp(NextLinePos.Start + CursorPosRelativeInLine, NextLinePos.Start, NextLinePos.End)
				end
				
			end
			
		elseif UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
			-- Handle shortcuts
			
			if Input.KeyCode == Enum.KeyCode.D then
				-- Select current word
				
				local _,w2 = string.find(string.sub(TextBox.Text, TextBox.CursorPosition), "^%w+")
				local w3 = string.find(string.sub(TextBox.Text, 1,TextBox.CursorPosition), "%w+$")
				
				if w2 and w3 then
					TextBox.SelectionStart = w3
					TextBox.CursorPosition = w2+TextBox.CursorPosition
				end
				
			elseif Input.KeyCode == Enum.KeyCode.Z then
				if isShiftKeyDown() then
					-- Redo
					WaypointStack[TextBox]:Redo()				
				else
					-- Undo
					WaypointStack[TextBox]:Undo()
				end
			elseif Input.KeyCode == Enum.KeyCode.Y then
				-- Redo
				
				WaypointStack[TextBox]:Redo()
				
			end
			
		end
		
	end
	
end)

function module.new(Frame, Settings, convertExistingTextLabel)
	
	if not (Frame and typeof(Frame)=="Instance" and Frame:IsA("GuiObject")) then
		warn("Invalid frame for TextPlus")
		return
	end
	
	Settings = Settings or {}
	
	local Settings_TextSize				= Settings.TextSize				or 16
	local Settings_TextWrapped			= (Settings.TextWrapped == nil and true)		or Settings.TextWrapped
	local Settings_MultiLine			= (Settings.Multiline == nil and true)			or Settings.Multiline
	local Settings_Padded				= (Settings.Padded == nil and true)				or Settings.Padded
	local Settings_ClearTextOnFocus		= (Settings.ClearTextOnFocus == nil and false)	or Settings.ClearTextOnFocus
	local Settings_TextColor3			= Settings.TextColor3			or Color3.new()
	local Settings_Font					= Settings.Font					or Enum.Font.SourceSans
	local Settings_Name					= Settings.Name					or "TextPlus"
	local Settings_TextXAlignment		= Settings.TextXAlignment		or Enum.TextXAlignment.Left
	local Settings_TextYAlignment		= Settings.TextYAlignment		or Enum.TextYAlignment.Top
	local Settings_PlaceholderText		= Settings.PlaceholderText		or ""
	local Settings_PlaceholderColor3	= Settings.PlaceholderColor3	or Color3.new(0.1,0.1,0.1)
	
	local Scroller = Instance.new("ScrollingFrame")
	local Input = nil
	
	if convertExistingTextLabel then
		Input = Frame
	else
		Scroller.Name						= Settings_Name
		Scroller.BackgroundTransparency		= 1
		Scroller.Size						= UDim2.new(1,0,1,0)
		Scroller.BorderSizePixel			= 0
		Scroller.BottomImage				= Scroller.MidImage
		Scroller.TopImage					= Scroller.MidImage
		Scroller.ScrollBarImageColor3		= Color3.fromRGB(117,117,117)
		Scroller.ScrollBarThickness			= Settings_TextSize*0.5
		Scroller.VerticalScrollBarInset		= Enum.ScrollBarInset.ScrollBar
		Scroller.HorizontalScrollBarInset	= Enum.ScrollBarInset.ScrollBar
		Scroller.CanvasSize					= UDim2.new()
		
		
		Input = Instance.new("TextBox")
		Input.Name						= "Input"
		Input.Parent = Scroller
		Scroller.Parent = Frame
		Input.BackgroundTransparency	= 1
		Input.Size						= UDim2.new(1,-Settings_TextSize,1,-Settings_TextSize)
		Input.Position					= UDim2.new(0,Settings_TextSize*0.5,0,Settings_TextSize*0.5)
		Input.MultiLine					= Settings_MultiLine
		Input.TextWrapped				= Settings_TextWrapped
		Input.ClearTextOnFocus			= Settings_ClearTextOnFocus
		Input.TextSize					= Settings_TextSize
		Input.Text						= ""
		Input.Font						= Settings_Font
		Input.TextColor3				= Settings_TextColor3
		Input.PlaceholderText			= Settings_PlaceholderText
		Input.PlaceholderColor3			= Settings_PlaceholderColor3
		Input.TextXAlignment			= Settings_TextXAlignment
		Input.TextYAlignment			= Settings_TextYAlignment
	end

			
			
		
	
	
	local LastTextChange	= tick()
	local LastSnapshot		= tick()
	local LastText			= ""
	
	local HistoryController = {
		UndoStack = {}; RedoStack = {};
	};
	
		function HistoryController:TakeSnapshot()
			
			--print("Take snapshot")
			
			--Add to undo
			self.UndoStack[#self.UndoStack+1] = {
				Text			= Input.Text;
				CursorPosition	= Input.CursorPosition;
				SelectionStart	= Input.SelectionStart;
			};
			
			-- Clear redo
			if #self.RedoStack > 0 then
				self.RedoStack = {}
			end
			
			-- Limit undo size
			while #self.UndoStack > 30 do -- max of 30 snapshots (except for ones that come back from the redo stack)
				table.remove(self.UndoStack,1)
			end
		end
		
		function HistoryController:Undo()
			if #self.UndoStack > 1 then
				
				--print("Undo")
				
				Ignores[Input] = true
				
				local Waypoint = self.UndoStack[#self.UndoStack - 1]
				for Prop, Value in pairs(Waypoint) do
					Input[Prop] = Value
				end
				
				self.RedoStack[#self.RedoStack + 1] = self.UndoStack[#self.UndoStack]
				self.UndoStack[#self.UndoStack] = nil
			end
		end
		
		function HistoryController:Redo()
			if #self.RedoStack > 0 then
				
				--print("Redo")
				
				Ignores[Input] = true
				
				local Waypoint = self.RedoStack[#self.RedoStack]
				for Prop, Value in pairs(Waypoint) do
					Input[Prop] = Value
				end
								
				self.UndoStack[#self.UndoStack + 1] = Waypoint
				self.RedoStack[#self.RedoStack] = nil
			end
		end
		
		function HistoryController:Clear()
			
			--print("Clear history")
			
			self.UndoStack = {}
			self.RedoStack = {}
		end
		
	local TextPlus = {
		TextBox = Input;
	}
	
	function TextPlus.Write(Text,Start,End)
		Input.Text = string.sub(Input.Text,1,Start).. Text .. string.sub(Input.Text,End+1)
	end
	
	function TextPlus.SetContent(Text)
		Input.Text = Text
		HistoryController:Clear()
	end
	
	function TextPlus:Undo()
		HistoryController:Undo()
	end
	
	function TextPlus:Redo()
		HistoryController:Redo()
	end
	
	Input:GetPropertyChangedSignal("Text"):Connect(function()
				
		LastTextChange = tick()
		if convertExistingTextLabel == false then
			local TextBounds = TS:GetTextSize(Input.Text,Input.TextSize,Input.Font, Vector2.new(Settings_TextWrapped and Scroller.AbsoluteWindowSize.X or 99999,99999))
			Scroller.CanvasSize = UDim2.new(
				0,TextBounds.X - 10,
				0,TextBounds.Y+(Settings_Padded and Scroller.AbsoluteWindowSize.Y-Settings_TextSize or 0)
			)
		end
	end)
	
	
	Inputs[Input] = TextPlus
	WaypointStack[Input] = HistoryController
	
	--Have the first snap be the blank GUI
	HistoryController:TakeSnapshot()
	
	RS.Heartbeat:Connect(function()
		if LastText == Input.Text then
			return
		end
		
		if Ignores[Input] then
			Ignores[Input] = nil
			LastText = Input.Text
			return
		end
		
		if (tick()-LastTextChange > 0.5) or (tick()-LastSnapshot > 2) or (math.abs(#LastText-#Input.Text)>10) then
			
			HistoryController:TakeSnapshot()
			
			LastSnapshot = tick()
			LastText = Input.Text
		end
		
	end)
	
	return TextPlus
end

return module

