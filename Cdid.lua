-- NZX SCRIPT - CDID AUTO FARM TRUCK
-- Buat Delta Executor

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NZX_AutoFarm"
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 180, 0, 120)
Frame.Position = UDim2.new(0.8, 0, 0.7, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Text = "🚚 NZX AutoFarm"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.Parent = Frame

local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0.8, 0, 0, 30)
StartBtn.Position = UDim2.new(0.1, 0, 0.4, 0)
StartBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
StartBtn.Text = "Start"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.Parent = Frame
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 8)

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0.8, 0, 0, 30)
StopBtn.Position = UDim2.new(0.1, 0, 0.7, 0)
StopBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
StopBtn.Text = "Stop"
StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopBtn.Parent = Frame
Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 8)

-- Variabel utama
local aktif = false
local lokasiPekerjaan = Vector3.new(-1200, 5, 890) -- ubah sesuai posisi job truk
local lokasiTujuan = {
    Vector3.new(2500, 10, 1700),
    Vector3.new(2700, 10, -1200),
    Vector3.new(1500, 10, 500)
}

-- Fungsi teleport
local function teleport(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char:MoveTo(pos)
    end
end

-- Fungsi respawn truk otomatis
local function spawnTruk()
    for i = 1, 10 do
        -- ini simulasi tekan tombol spawn truck (ganti ke remote event sebenarnya)
        print("[NZX] Spawn truk attempt:", i)
        task.wait(1)
    end
end

-- Fungsi cari truk box/kayu
local function cariTruk()
    for _, v in pairs(workspace.Vehicles:GetChildren()) do
        if v.Name:lower():find("box") or v.Name:lower():find("kayu") then
            return v
        end
    end
end

-- Fungsi autofarm utama
local function mulaiAutofarm()
    aktif = true
    teleport(lokasiPekerjaan)
    spawnTruk()
    task.wait(3)

    local truk = cariTruk()
    if truk then
        print("[NZX] Truk ditemukan:", truk.Name)
        teleport(truk.PrimaryPart.Position + Vector3.new(0, 3, 0))
        task.wait(1)

        for _, tujuan in ipairs(lokasiTujuan) do
            if not aktif then break end
            print("[NZX] Menuju lokasi tujuan...")
            local tween = TweenService:Create(truk.PrimaryPart, TweenInfo.new(5, Enum.EasingStyle.Linear), {Position = tujuan + Vector3.new(0, 25, 0)})
            tween:Play()
            tween.Completed:Wait()
            print("[NZX] Tiba di tujuan, cooldown 5 detik...")
            task.wait(5)
        end
    else
        warn("[NZX] Truk tidak ditemukan! Coba lagi.")
    end
end

-- Tombol
StartBtn.MouseButton1Click:Connect(function()
    if not aktif then
        task.spawn(mulaiAutofarm)
    end
end)

StopBtn.MouseButton1Click:Connect(function()
    aktif = false
    print("[NZX] AutoFarm dihentikan.")
end)

print("[NZX] AutoFarm Script Loaded!")
