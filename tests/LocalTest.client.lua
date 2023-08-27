local PlayerGui = game.Players.LocalPlayer.PlayerGui
local ScriptEditorScreen = PlayerGui:WaitForChild("ScriptEditorScreen")
local OdeFrame = ScriptEditorScreen:WaitForChild("OdeFrame")

local OdeScriptEditor = require(game.ReplicatedStorage.OdeScriptEditor)
local scriptEditor = OdeScriptEditor.Embed(OdeFrame)