if not game:IsLoaded() then
	game.Loaded:Wait()
end

getgenv().HorstConfig = {
	["EnableLog"] = false,
	["Whitescreen"] = false,
	["EnableAddFriends"] = false,
	["LockFps"] = {
		["EnableLockFps"] = false,
		["LockFpsAmount"] = 20,
	},
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/HorstSpaceX/last_update/main/on_loaded.lua"))()

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local noInteractDup = false

local function interact(path)
	if noInteractDup then
		return
	end
	noInteractDup = true
	xpcall(function()
		if path then
			repeat
				task.wait()
				GuiService.SelectedObject = path
			until GuiService.SelectedObject == path
			task.wait(0.03)
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
			task.wait(0.01)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
			task.wait(0.01)
			repeat
				task.wait()
				GuiService.SelectedObject = nil
			until GuiService.SelectedObject == nil
		end
		noInteractDup = false
	end, function()
		noInteractDup = false
	end)
end

while true do
	local eggRowsPath = PlayerGui.ScreenGui.Menus.Children.Eggs.Content:FindFirstChild("EggRows")

	if not eggRowsPath then
		repeat
			interact(PlayerGui.ScreenGui.Menus.ChildTabs["Eggs Tab"])
			task.wait(0.5)
			eggRowsPath = PlayerGui.ScreenGui.Menus.Children.Eggs.Content:FindFirstChild("EggRows")
		until eggRowsPath
	end

	local ticketCount = ""
	local magicBeanCount = ""
	local starEggCount = ""

	if eggRowsPath then
		local eggRows = eggRowsPath:GetChildren()

		for _, eggRow in pairs(eggRows) do
			if eggRow:FindFirstChild("TypeName") and eggRow:FindFirstChild("EggSlot") then
				local typeName = eggRow.TypeName.Text
				local eggSlot = eggRow.EggSlot

				if typeName == "Ticket" and eggSlot:FindFirstChild("Count") then
					ticketCount = eggSlot.Count.Text
				elseif typeName == "Magic Bean" and eggSlot:FindFirstChild("Count") then
					magicBeanCount = eggSlot.Count.Text
				elseif typeName == "Star Egg" and eggSlot:FindFirstChild("Count") then
					starEggCount = eggSlot.Count.Text
				end
			end
		end
	end

	local descriptionMessage = string.format(
		"🎫 Ticket: %s - 👻 Magic Bean: %s - ⭐ Star Egg: %s",
		ticketCount,
		magicBeanCount,
		starEggCount
	)

	_G.Horst_SetDescription(descriptionMessage)
	task.wait(10)
end
