local RunService = game:GetService("RunService")
local OSEModule = game:GetService("ReplicatedStorage"):FindFirstChild("OdeScriptEditor")

if not OSEModule then
	coroutine.yield(coroutine.running())
end

if RunService:IsRunning() then
	coroutine.yield(coroutine.running())
end

local OSEWidgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	true,
	true,
	300,
	350,
	450,
	450
)

local OSEWidget = plugin:CreateDockWidgetPluginGui("OdeScriptEditor", OSEWidgetInfo)
OSEWidget.Title = "OdeScriptEditor"

local PluginToolbar = plugin:CreateToolbar("OSE Test")
local OpenScript = PluginToolbar:CreateButton("Open Script", "Open Script", "rbxassetid://10734943448")
OpenScript.ClickableWhenViewportHidden = true

local OSE = require(OSEModule)
local scriptEditor = OSE.Embed(OSEWidget)
local outputScript = nil

OpenScript.Click:Connect(function()
	local selectedScript = game:GetService("Selection"):Get()[1]

	if selectedScript:IsA("LuaSourceContainer") and selectedScript:GetAttribute("OSE_Test") then
		OSEWidget.Enabled = true

		scriptEditor:LoadScriptAsync(selectedScript)
		outputScript = selectedScript
	end
end)

scriptEditor.OnEdit:Connect(function(source)
	if outputScript then
		outputScript.Source = source
	end
end)

OSEWidget:BindToClose(function()
	OSEWidget.Enabled = false
	outputScript = nil

	scriptEditor:Unload()
end)