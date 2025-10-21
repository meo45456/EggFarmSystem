getgenv().EggFarmConfig = {
	["CheckTicket"] = false,
	["CheckMagicBean"] = true,
	["CheckStarEgg"] = false,
	["TargetTicket"] = 13,
	["TargetMagicBean"] = 0,
	["TargetStarEgg"] = 20,
}

-- 🧠 ตั้งค่า
local CHECK_INTERVAL = 20 -- หน่วงเวลาการตรวจแต่ละรอบ (วินาที)
local DEBUG_MODE = false  -- true = แสดง log เพิ่ม / false = ปิด log เพื่อลดภาระ

-- 🧩 ฟังก์ชัน log แบบเบาเครื่อง
local function log(...)
	if DEBUG_MODE then
		print("[EggFarm]", ...)
	end
end

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local noInteractDup = false
local menuOpened = false

-- 🟢 ฟังก์ชันเปิดแท็บ Eggs (ใช้เฉพาะครั้งแรก)
local function openEggMenu()
	if menuOpened or noInteractDup then return end
	noInteractDup = true
	xpcall(function()
		local tab = PlayerGui.ScreenGui.Menus.ChildTabs:FindFirstChild("Eggs Tab")
		if tab then
			GuiService.SelectedObject = tab
			task.wait(0.05)
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
			task.wait(0.05)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
			GuiService.SelectedObject = nil
			menuOpened = true
			log("เปิดแท็บ Eggs สำเร็จ")
		end
		noInteractDup = false
	end, function(err)
		warn("[EggFarm] ⚠️ openEggMenu error:", err)
		noInteractDup = false
	end)
end

-- 🧮 แปลงตัวเลขจาก "x10" หรือ "10"
local function extractNumber(text)
	if not text or text == "" then return 0 end
	local number = string.match(text, "x%s*(%d+)") or string.match(text, "(%d+)")
	return tonumber(number) or 0
end

-- 🟢 รอให้ Horst พร้อมก่อนเริ่ม
local function waitForHorst(timeout)
	local t = 0
	while type(_G.Horst_AccountChangeDone) ~= "function" and t < timeout do
		if DEBUG_MODE then warn(string.format("[EggFarm] ⏳ รอ Horst โหลด... (%d/%d)", t, timeout)) end
		t += 1
		task.wait(1)
	end

	if type(_G.Horst_AccountChangeDone) == "function" then
		print("[EggFarm] ✅ Horst พร้อมแล้ว")
		return true
	else
		warn("[EggFarm] ❌ Timeout: Horst ยังไม่โหลดหลัง", timeout, "วินาที")
		return false
	end
end

-- 🟢 เริ่มระบบหลัก
task.spawn(function()
	pcall(function()
		if not waitForHorst(30) then
			warn("[EggFarm] ❌ ยกเลิกการทำงาน เพราะ Horst ยังไม่พร้อม")
			return
		end

		openEggMenu()

		while true do
			local eggRowsPath = PlayerGui.ScreenGui.Menus.Children.Eggs.Content:FindFirstChild("EggRows")
			if not eggRowsPath then
				openEggMenu()
				task.wait(CHECK_INTERVAL)
				continue
			end

			local ticketNumber, magicBeanNumber, starEggNumber = 0, 0, 0

			for _, eggRow in pairs(eggRowsPath:GetChildren()) do
				if eggRow:FindFirstChild("TypeName") and eggRow:FindFirstChild("EggSlot") then
					local t = eggRow.TypeName.Text
					local slot = eggRow.EggSlot
					if slot:FindFirstChild("Count") then
						local count = extractNumber(slot.Count.Text)
						if t == "Ticket" then
							ticketNumber = count
						elseif t == "Magic Bean" then
							magicBeanNumber = count
						elseif t == "Star Egg" then
							starEggNumber = count
						end
					end
				end
			end

			log(string.format("Ticket=%d | Bean=%d | StarEgg=%d", ticketNumber, magicBeanNumber, starEggNumber))

			local cfg = getgenv().EggFarmConfig
			local allConditionsMet = true

			if cfg["CheckTicket"] and ticketNumber ~= cfg["TargetTicket"] then
				allConditionsMet = false
				log("Ticket ยังไม่ตรงเป้า")
			end

			if cfg["CheckMagicBean"] and magicBeanNumber ~= cfg["TargetMagicBean"] then
				allConditionsMet = false
				log("Magic Bean ยังไม่ตรงเป้า")
			end

			if cfg["CheckStarEgg"] and starEggNumber ~= cfg["TargetStarEgg"] then
				allConditionsMet = false
				log("Star Egg ยังไม่ตรงเป้า")
			end

			-- ✅ ถ้าครบเงื่อนไข ส่ง Done
			if allConditionsMet then
				print("[EggFarm] 🎯 เงื่อนไขครบ เตรียมส่ง DONE")

				local ok, result = pcall(_G.Horst_AccountChangeDone)
				if ok then
					print("[EggFarm] ✅ ส่งสถานะ DONE สำเร็จ!")
				else
					warn("[EggFarm] ❌ ส่งสถานะ DONE ไม่สำเร็จ:", result)
				end
				break
			end

			task.wait(CHECK_INTERVAL) -- หน่วงเวลาตรวจรอบต่อไป
		end
	end)
end)
