# Ode Script Editor: A simple embedded script editor entirely in Roblox.

**Ode Script Editor** is a simple and embedded Luau source-code editor in Roblox that can run both in-game and contained in a plugin. It includes some QoL features such as syntax highlighting and auto-indentation.

Here is a very simple snippet that demonstrates its usage. It works almost entirely out of the box with no tinkering required!

```lua
local OdeSE = require(path.to.OdeScriptEditor)
local FrameInstance: Frame = path.to.FrameInstance

local scriptEditor = OdeSE.Embed(FrameInstance)
```

# Documentation

This README does not provide documentation but it can be found in the associated Roblox DevForum post.