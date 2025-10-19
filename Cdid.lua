--[[
NZX CDID Truck Autofarm
Hanya aktif di wilayah Jawa Tengah
Buat Delta Executor | Versi 1.0
]]

-- 🧩 CONFIGURASI UTAMA
local JOB_TELEPORT_POS = Vector3.new(1020, 15, -450)
local WAYPOINTS = {
    Vector3.new(1500, 20, -500),
    Vector3.new(1800, 25, -800),
    Vector3.new(2100, 25, -1000),
}
local REGION_BOUNDS = {minX = -5000, maxX = 5000, minZ = -7000, maxZ = 3000}
local VALID_TRUCKS = {"TrukBox", "TrukKayu"}
local COOLDOWN_TIME = 5

-- 🧠 VARIABEL SISTEM
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local active = false
local gui = nil

-- 🪟 GUI NZX
function createGUI()
    if gui then gui:Destroy() end

    gui = Instance.new("ScreenGui")
    gui.Name = "NZXTruckAutofarm"
    gui.ResetOnSpawn = false
    gui.Parent = game.CoreGui

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 200, 0, 120)
    main.Position = UDim2.new(0.05, 0, 0.3, 0)
    main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "🚛 CDID Truck Autofarm by NZX"
    title.TextColor3 = Color3.fromRGB(0, 255, 127)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 14
    title.Parent = main

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.8, 0, 0, 40)
    button.Position = UDim2.new(0.1, 0, 0.5, 0)
    button.BackgroundColor3 = Color3.fromRGB(0, 255, 127)
    button.Text = "Start"
    button.TextColor3 = Color3.new(0, 0, 0)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 18
    button.Parent = main

    button.MouseButton1Click:Connect(function()
        active = not active
        button.Text = active and "Stop" or "Start"
        button.BackgroundColor3 = active and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(0, 255, 127)
        if active then
            startAutofarm()
        end
    end)
end

-- 🌍 CEK WILAYAH JAWA TENGAH
function isInRegion(pos)
    return pos.X >= REGION_BOUNDS.minX and pos.X <= REGION_BOUNDS.maxX
       and pos.Z >= REGION_BOUNDS.minZ and pos.Z <= REGION_BOUNDS.maxZ
end

-- 🚛 CARI TRUK VALID
function findTruck()
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") then
            for _, validName in ipairs(VALID_TRUCKS) do
                if string.find(string.lower(v.Name), string.lower(validName)) then
                    return v
                end
            end
        end
    end
    return nil
end

-- 🛞 MASUK TRUK
function seatInTruck(truck)
    local seat = truck:FindFirstChildWhichIsA("VehicleSeat", true)
    if seat and LocalPlayer.Character then
        LocalPlayer.Character:MoveTo(seat.Position + Vector3.new(0, 3, 0))
        task.wait(1)
        seat:Sit(LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
    end
end

-- ✈️ FLY KE TUJUAN
function flyTo(pos)
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end
    local tween = TweenService:Create(char.PrimaryPart, TweenInfo.new(5), {CFrame = CFrame.new(pos)})
    tween:Play()
    tween.Completed:Wait()
end

-- 🚀 PROSES UTAMA AUTOFARM
function startAutofarm()
    task.spawn(function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        if not isInRegion(char.PrimaryPart.Position) then
            game.StarterGui:SetCore("SendNotification", {
                Title = "NZX Autofarm",
                Text = "Hanya tersedia di wilayah Jawa Tengah!",
                Duration = 4
            })
            active = false
            return
        end

        -- Teleport ke job
        char:SetPrimaryPartCFrame(CFrame.new(JOB_TELEPORT_POS))
        task.wait(2)

        -- Cari truk
        local truck = nil
        repeat
            truck = findTruck()
            task.wait(2)
        until truck or not active

        if not truck then return end

        seatInTruck(truck)
        task.wait(2)

        -- Jalankan rute
        for _, waypoint in ipairs(WAYPOINTS) do
            if not active then break end
            flyTo(waypoint)
            task.wait(COOLDOWN_TIME)
        end

        game.StarterGui:SetCore("SendNotification", {
            Title = "NZX Autofarm",
            Text = "Rute selesai!",
            Duration = 5
        })

        active = false
    end)
end

-- Jalankan GUI
createGUI()
