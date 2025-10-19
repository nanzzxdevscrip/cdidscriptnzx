--[[
NZX AUTO TRUCK FARM CDID
Hanya aktif di wilayah Jawa Tengah (Java Sedara)
Executor: Delta / Fluxus / ArceusX / Codex / Hydrogen
By: nanzzxdev
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- GUI START/STOP
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local StartBtn = Instance.new("TextButton")
local StopBtn = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Parent = game.CoreGui
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
Frame.Size = UDim2.new(0,150,0,100)
Frame.Position = UDim2.new(0.5,-75,0.8,-50)
Frame.Active = true
Frame.Draggable = true
UICorner.Parent = Frame

StartBtn.Parent = Frame
StartBtn.BackgroundColor3 = Color3.fromRGB(0,255,100)
StartBtn.Size = UDim2.new(1,0,0.5,0)
StartBtn.Text = "🚚 START"
UICorner:Clone().Parent = StartBtn

StopBtn.Parent = Frame
StopBtn.BackgroundColor3 = Color3.fromRGB(255,50,50)
StopBtn.Position = UDim2.new(0,0,0.5,0)
StopBtn.Size = UDim2.new(1,0,0.5,0)
StopBtn.Text = "🛑 STOP"
UICorner:Clone().Parent = StopBtn

local running = false

-- CEK WILAYAH
function isInRegion()
    local plr = game.Players.LocalPlayer
    local gui = plr:FindFirstChild("PlayerGui")
    if not gui then return false end

    local areaLabel = gui:FindFirstChild("AreaLabel", true)
    if areaLabel and areaLabel:IsA("TextLabel") then
        local text = string.lower(areaLabel.Text)
        if string.find(text, "java sedara") or string.find(text, "jawa tengah") then
            return true
        end
    end
    return false
end

-- COORDINATE JOB TRUK DAN TUJUAN
local JOB_TELEPORT_POS = Vector3.new(-1292, 40, 2184) -- titik job truk (contoh)
local WAYPOINTS = {
    Vector3.new(-2300, 45, 3100),
    Vector3.new(-1400, 50, 2500),
    Vector3.new(-1900, 45, 3500),
}

-- FUNGSI TELEPORT
function tp(pos)
    local char = game.Players.LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char:MoveTo(pos)
    end
end

-- CARI TRUK BOX/KAYU
function findTruck()
    for _,v in pairs(workspace.Vehicles:GetChildren()) do
        if v.Name:lower():find("truck") and (v.Name:lower():find("box") or v.Name:lower():find("kayu")) then
            return v
        end
    end
end

-- AUTOFARM LOOP
function startFarm()
    if not isInRegion() then
        game.StarterGui:SetCore("SendNotification", {
            Title = "❌ Gagal Mulai",
            Text = "Script hanya dapat digunakan di wilayah Jawa Tengah (Java Sedara)!",
            Duration = 6
        })
        return
    end

    running = true
    game.StarterGui:SetCore("SendNotification", {
        Title = "🚚 NZX Autofarm",
        Text = "Mulai Farming Otomatis di Jawa Tengah!",
        Duration = 5
    })

    task.spawn(function()
        while running do
            tp(JOB_TELEPORT_POS)
            task.wait(3)

            local truck = findTruck()
            if not truck then
                task.wait(2)
            else
                local hrp = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = truck.PrimaryPart.CFrame + Vector3.new(0,3,0)
                end

                for _,loc in ipairs(WAYPOINTS) do
                    if not running then break end
                    for i=1,50 do
                        if truck and truck.PrimaryPart then
                            truck:SetPrimaryPartCFrame(CFrame.new(loc + Vector3.new(0,50,0)))
                        end
                        task.wait(0.1)
                    end
                    task.wait(5) -- cooldown antar lokasi
                end
            end
        end
    end)
end

-- STOP FARM
function stopFarm()
    running = false
    game.StarterGui:SetCore("SendNotification", {
        Title = "🛑 NZX Autofarm",
        Text = "Autofarm telah dihentikan!",
        Duration = 5
    })
end

StartBtn.MouseButton1Click:Connect(startFarm)
StopBtn.MouseButton1Click:Connect(stopFarm)

game.StarterGui:SetCore("SendNotification", {
    Title = "✅ NZX CDID Autofarm",
    Text = "Script siap digunakan! Klik START untuk mulai.",
    Duration = 7
})
