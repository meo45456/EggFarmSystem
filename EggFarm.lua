-- 🧠 ตั้งค่าเบื้องต้นจาก Loader
local cfg = getgenv().EggFarmConfig or {}
local settings = getgenv().EggFarmSettings or {}

local CHECK_INTERVAL = settings.CheckInterval or 20 -- หน่วงเวลาตรวจแต่ละรอบ
local DEBUG_MODE = settings.EnableLog or false      -- เปิด log เพิ่ม
local RETRY_ATTEMPTS = 3                            -- จำนวนครั้ง retry ถ้า Horst ส่งไม่สำเร็จ

function Clicked_Ui(path)
    game:GetService("GuiService").SelectedObject = path
    task.wait(.1)
    game:GetService("VirtualInputManager"):SendKeyEvent(true, 13, false, game)
    wait(.1)
    game:GetService("VirtualInputManager"):SendKeyEvent(false, 13, false, game)
    task.wait(.1)
    game:GetService("GuiService").SelectedObject = nil
end

-- 🧩 ฟังก์ชัน log แบบเบาเครื่อง
local function log(...)
	if DEBUG_MODE then
		print("[EggFarm]", ...)
	end
end

-- 🧩 Service พื้นฐาน
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local noInteractDup = false
local menuOpened = false

local Players = game:GetService("Players").LocalPlayer
local Players_Gui = Players:WaitForChild("PlayerGui")
local Egg_Gui = Players_Gui.ScreenGui.Menus.ChildTabs:WaitForChild("Eggs Tab")

-- 🧮 แปลงตัวเลขจาก "x10" หรือ "10"
local function extractNumber(text)
	if not text or text == "" then return 0 end
	local number = string.match(text, "x%s*(%d+)") or string.match(text, "(%d+)")
	return tonumber(number) or 0
end

-- 🟢 รอให้ Horst พร้อมก่อนเริ่ม (ไม่มี timeout)
local function waitForHorstBlocking()
	local t = 0
	while type(_G.Horst_AccountChangeDone) ~= "function" do
		task.wait(1)
		t += 1
		if DEBUG_MODE then
			warn(("[EggFarm] ⏳ รอ Horst Core โหลด... (%ds)"):format(t))
		end
	end
	print("[EggFarm] ✅ Horst พร้อมแล้ว")
end

-- 🟢 ระบบส่ง DONE แบบ Retry 3 ครั้ง
local function sendDone()
	for i = 1, RETRY_ATTEMPTS do
		local ok, err = pcall(_G.Horst_AccountChangeDone)
		if ok then
			print("[EggFarm] ✅ DONE สำเร็จ (ครั้งที่ " .. i .. ")")
			return true
		else
			warn("[EggFarm] ❌ ส่ง DONE ล้มเหลว ครั้งที่", i, ":", err)
			task.wait(2)
		end
	end
	return false
end

-- 🟢 เริ่มระบบหลัก
print("Scripts Loaded!")
task.spawn(function()
	local success, error = pcall(function()
		waitForHorstBlocking()
		Clicked_Ui(Egg_Gui)
		task.wait(0.5) -- เผื่อ GUI update ช้า

		while true do
			local eggRowsPath = PlayerGui:FindFirstChild("ScreenGui") 
				and PlayerGui.ScreenGui.Menus.Children.Eggs.Content:FindFirstChild("EggRows")

			if not eggRowsPath then
				Clicked_Ui(Egg_Gui)
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
				task.wait(1) -- เผื่อ GUI delay
				sendDone()
				break
			end

			task.wait(CHECK_INTERVAL) -- หน่วงเวลาตรวจรอบต่อไป
		end
	end)
    print(success, error)
end)

