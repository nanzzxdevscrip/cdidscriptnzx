-- Teleport-to-Base on Start (client-only)
-- Fitur: Set Base Here, Start = langsung teleport ke base, optional Auto Loop
-- Aman: hanya mempengaruhi LocalPlayer.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ===== CONFIG =====
local COOLDOWN_AFTER_TELEPORT = 1     -- delay kecil setelah teleport (detik)
local AUTO_LOOP_DEFAULT = false       -- default auto-loop off
local AUTO_LOOP_INTERVAL = 8          -- detik antara teleport saat auto-loop aktif
local SAFETY_KEY = Enum.KeyCode.F     -- tekan F untuk stop auto-loop
-- ===================

-- state
local baseCFrame = nil
local autoLoop = AUTO_LOOP_DEFAULT
local autoLoopRunning = false

-- UI
local sg = Instance.new("ScreenGui")
sg.Name = "TeleportBaseUI"
sg.ResetOnSpawn = false
sg.Parent = PlayerGui

local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, 360, 0, 110)
frame.Position = UDim2.new(0, 12, 0, 12)
frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
frame.BackgroundTransparency = 0.12
frame.BorderSizePixel = 0

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, -20, 0, 36)
status.Position = UDim2.new(0, 10, 0, 6)
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamSemibold
status.TextSize = 18
status.TextColor3 = Color3.fromRGB(220,220,220)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "Base: (not set)"

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(0, 100, 0, 32)
startBtn.Position = UDim2.new(1, -112, 0, 8)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 16
startBtn.Text = "Start"
startBtn.BackgroundColor3 = Color3.fromRGB(0,170,255)
startBtn.TextColor3 = Color3.fromRGB(0,0,0)
startBtn.AutoButtonColor = true

local setBtn = Instance.new("TextButton", frame)
setBtn.Size = UDim2.new(0, 120, 0, 28)
setBtn.Position = UDim2.new(1, -134, 0, 48)
setBtn.Text = "Set Base Here"
setBtn.Font = Enum.Font.SourceSans
setBtn.TextSize = 14
setBtn.BackgroundColor3 = Color3.fromRGB(120,120,120)
setBtn.TextColor3 = Color3.fromRGB(255,255,255)
setBtn.AutoButtonColor = true

local autoToggleBtn = Instance.new("TextButton", frame)
autoToggleBtn.Size = UDim2.new(0, 100, 0, 28)
autoToggleBtn.Position = UDim2.new(0, 12, 1, -36)
autoToggleBtn.Text = autoLoop and "Auto: ON" or "Auto: OFF"
autoToggleBtn.Font = Enum.Font.SourceSans
autoToggleBtn.TextSize = 14
autoToggleBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
autoToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
autoToggleBtn.AutoButtonColor = true

local info = Instance.new("TextLabel", frame)
info.Size = UDim2.new(1, -20, 0, 18)
info.Position = UDim2.new(0, 10, 0, 80)
info.BackgroundTransparency = 1
info.Font = Enum.Font.SourceSans
info.TextSize = 13
info.TextColor3 = Color3.fromRGB(180,180,180)
info.TextXAlignment = Enum.TextXAlignment.Left
info.Text = "Set base, lalu Start untuk teleport. Tekan F untuk stop auto-loop."

-- helper: safe teleport local player
local function teleportLocalPlayerTo(cframe)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local ok,err = pcall(function()
        hrp.CFrame = cframe + Vector3.new(0,2,0)
    end)
    if not ok then warn("Teleport failed:", err) end
    return ok
end

local function setStatus(txt, color)
    status.Text = txt
    if color then status.TextColor3 = color end
end

-- Set Base Here handler
setBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        setStatus("Gagal: karakter tidak ditemukan", Color3.fromRGB(255,120,80))
        return
    end
    baseCFrame = char.HumanoidRootPart.CFrame
    setStatus("Base set! (You will teleport to base on Start)", Color3.fromRGB(120,220,120))
    task.delay(1.2, function() setStatus("Base: set", Color3.fromRGB(200,200,200)) end)
end)

-- Start button behavior: teleport immediately (and start loop if autoLoop on)
startBtn.MouseButton1Click:Connect(function()
    if not baseCFrame then
        setStatus("Base belum di-set. Tekan 'Set Base Here' terlebih dahulu.", Color3.fromRGB(255,160,60))
        return
    end

    -- immediate teleport once
    local ok = teleportLocalPlayerTo(baseCFrame)
    if ok then
        setStatus("Teleported to base.", Color3.fromRGB(120,220,120))
    else
        setStatus("Teleport gagal.", Color3.fromRGB(255,80,80))
    end
    task.wait(COOLDOWN_AFTER_TELEPORT)

    -- if autoLoop enabled, start repeating
    if autoLoop and not autoLoopRunning then
        autoLoopRunning = true
        setStatus("Auto-loop active", Color3.fromRGB(120,220,120))
        spawn(function()
            while autoLoop and autoLoopRunning do
                task.wait(AUTO_LOOP_INTERVAL)
                if not autoLoop or not autoLoopRunning then break end
                if baseCFrame then
                    teleportLocalPlayerTo(baseCFrame)
                    setStatus("Auto-loop: teleported to base", Color3.fromRGB(200,200,200))
                else
                    setStatus("Auto-loop stopped: base not set", Color3.fromRGB(255,120,80))
                    autoLoopRunning = false
                    break
                end
            end
        end)
    end
end)

-- Toggle auto loop
autoToggleBtn.MouseButton1Click:Connect(function()
    autoLoop = not autoLoop
    autoToggleBtn.Text = autoLoop and "Auto: ON" or "Auto: OFF"
    autoLoopRunning = autoLoop -- if turned off, stop loop
    setStatus(autoLoop and "Auto-loop ON" or "Auto-loop OFF", Color3.fromRGB(200,200,200))
end)

-- Safety key: F stops auto-loop
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == SAFETY_KEY then
        autoLoop = false
        autoLoopRunning = false
        autoToggleBtn.Text = "Auto: OFF"
        setStatus("Auto-loop stopped (F)", Color3.fromRGB(255,120,120))
    end
end)

-- expose helpers via getgenv if executor supports it
getgenv = getgenv or function() return _G end
getgenv().TeleportBase_Set = function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        baseCFrame = char.HumanoidRootPart.CFrame
        return true
    end
    return false
end
getgenv().TeleportBase_TeleportNow = function()
    if baseCFrame then teleportLocalPlayerTo(baseCFrame); return true end
    return false
end
getgenv().TeleportBase_EnableAutoLoop = function(val)
    autoLoop = (val == true)
    autoLoopRunning = autoLoop
    autoToggleBtn.Text = autoLoop and "Auto: ON" or "Auto: OFF"
end

setStatus("Ready. Set base then press Start.", Color3.fromRGB(200,200,200))
