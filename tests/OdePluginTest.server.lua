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
local ReloadOse = PluginToolbar:CreateButton("Reload OSE Plugin", "Reload OSE Plugin", "rbxassetid://6023565901")
OpenScript.ClickableWhenViewportHidden = true
ReloadOse.ClickableWhenViewportHidden = true

-- local OSE = require(OSEModule)
-- local scriptEditor = OSE.Embed(OSEWidget)
local OSE
local scriptEditor
local outputScript = nil

function onEdit(source)
	if outputScript then
		outputScript.Source = source
	end
end

function reloadOse()
	if outputScript then
		warn("Failed to reload. Unload script first to reload")
		return
	end

	if scriptEditor then
		scriptEditor:Destroy()
	end
	script:ClearAllChildren()

	local updatedOseModule = OSEModule:Clone()
	updatedOseModule.Parent = script

	OSE = require(updatedOseModule)
	scriptEditor = OSE.Embed(OSEWidget)

	scriptEditor.OnEdit:Connect(onEdit)
	scriptEditor:ApplyStudioTheme(settings().Studio)
end

task.defer(reloadOse)

OpenScript.Click:Connect(function()
	local selectedScript = game:GetService("Selection"):Get()[1]

	if selectedScript and selectedScript:IsA("LuaSourceContainer") and selectedScript:GetAttribute("OSE_Test") then
		OSEWidget.Enabled = true

		scriptEditor:SetScriptAsync(selectedScript)
		outputScript = selectedScript
	end
end)

ReloadOse.Click:Connect(function()
	task.defer(reloadOse)
end)

OSEWidget:BindToClose(function()
	OSEWidget.Enabled = false
	outputScript = nil

	scriptEditor:Unload()
end)