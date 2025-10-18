-- Auto Truck Job Farming (Generic, ready-to-run)
-- Works client-side on many car/truck job setups (Car Driving Indonesia style)
-- Features: auto find truck/seat/start/end -> enter seat -> wait arrival -> cooldown 5s -> repeat
-- Safety: press F to stop. Use at your own risk.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- ======= CONFIG (biasanya tidak perlu diubah) =======
local CONFIG = {
    COOLDOWN_AFTER_ARRIVAL = 5,      -- detik cooldown ketika sampai
    DEST_REACH_RADIUS = 25,          -- radius stud untuk dianggap "sampai"
    TRUCK_PRIMARY_PART_MIN_SPEED = 0.5, -- threshold speed untuk deteksi truk bergerak
    TRIP_TIMEOUT = 300,              -- max detik menunggu satu trip
    SEARCH_INTERVAL = 2,             -- detik antara pencarian objek jika tidak ketemu
    SAFETY_STOP_KEY = Enum.KeyCode.F, -- tombol untuk stop cepat
    RANDOM_DELAY_MIN = 0.6,          -- delay random minimal antar aksi (agar natural)
    RANDOM_DELAY_MAX = 1.2,          -- delay random maksimal antar aksi
}
-- =====================================================

-- common names to try (fallback)
local COMMON_TRUCK_NAMES = {
    "DeliveryTruck", "Truck", "TruckModel", "Delivery_Vehicle", "Vehicle_Truck", "Truck1",
    "Delivery", "TruckModel1"
}
local COMMON_SEAT_NAMES = {"DriverSeat","Seat","VehicleSeat","Driver","SeatDriver"}
local COMMON_START_NAMES = {"TruckJobStart","JobStart","StartMarker","SpawnPoint","TruckStart"}
local COMMON_END_NAMES = {"TruckJobEnd","JobEnd","EndMarker","DestPoint","TruckEnd"}

-- helper random
local function randSleep(minv, maxv)
    task.wait((minv or CONFIG.RANDOM_DELAY_MIN) + math.random() * ((maxv or CONFIG.RANDOM_DELAY_MAX) - (minv or CONFIG.RANDOM_DELAY_MIN)))
end

-- refresh character reference
local function refreshCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

-- safe move character (tween then fallback)
local function safeMoveTo(cframe, duration)
    refreshCharacter()
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    duration = duration or 0.6
    local ok = pcall(function()
        local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = cframe})
        tween:Play()
        tween.Completed:Wait()
    end)
    if not ok then
        pcall(function() hrp.CFrame = cframe end)
    end
    return true
end

-- find first model by possible names
local function findTruckModel()
    for _,name in ipairs(COMMON_TRUCK_NAMES) do
        local found = workspace:FindFirstChild(name, true)
        if found and found:IsA("Model") then return found end
    end
    -- fallback: find any model that has VehicleSeat or Seat descendant (likely a vehicle)
    for _,m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") then
            for _,d in ipairs(m:GetDescendants()) do
                if d:IsA("VehicleSeat") or d:IsA("Seat") then
                    return m
                end
            end
        end
    end
    return nil
end

-- find seat inside model
local function findDriverSeat(model)
    if not model then return nil end
    for _,n in ipairs(COMMON_SEAT_NAMES) do
        local seat = model:FindFirstChild(n, true)
        if seat and (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then return seat end
    end
    -- fallback: first seat descendant
    for _,d in ipairs(model:GetDescendants()) do
        if d:IsA("Seat") or d:IsA("VehicleSeat") then return d end
    end
    return nil
end

-- find marker by common names in workspace
local function findMarker(list)
    for _,n in ipairs(list) do
        local p = workspace:FindFirstChild(n, true)
        if p and p:IsA("BasePart") then return p end
    end
    -- fallback: find part with matching name anywhere
    for _,d in ipairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local lname = d.Name:lower()
            for _,n in ipairs(list) do
                if lname:find(n:lower()) then return d end
            end
        end
    end
    return nil
end

-- compute speed of a part by sampling positions
local function computeSpeed(part, dt)
    if not part then return 0 end
    local pos1 = part.Position
    task.wait(dt or 0.1)
    local pos2 = part.Position
    return (pos2 - pos1).Magnitude / (dt or 0.1)
end

-- check if truck is near destination
local function truckAtDestination(truck, dest)
    if not truck or not dest then return false end
    local primary = truck.PrimaryPart or truck:FindFirstChildWhichIsA("BasePart", true)
    if not primary then return false end
    return (primary.Position - dest.Position).Magnitude <= CONFIG.DEST_REACH_RADIUS
end

-- UI
local UI = {}
do
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoTruckFarmUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", screenGui)
    frame.Size = UDim2.new(0, 360, 0, 90)
    frame.Position = UDim2.new(0, 12, 0, 12)
    frame.BackgroundTransparency = 0.12
    frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(0,0)

    local status = Instance.new("TextLabel", frame)
    status.Size = UDim2.new(1, -20, 0, 40)
    status.Position = UDim2.new(0, 10, 0, 6)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.GothamSemibold
    status.TextSize = 18
    status.TextColor3 = Color3.fromRGB(220,220,220)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Text = "Status: Idle"

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 120, 0, 32)
    btn.Position = UDim2.new(1, -132, 1, -40)
    btn.Text = "Start"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.BackgroundColor3 = Color3.fromRGB(0,170,255)
    btn.TextColor3 = Color3.fromRGB(0,0,0)
    btn.AutoButtonColor = true
    btn.Name = "StartStopBtn"

    local info = Instance.new("TextLabel", frame)
    info.Size = UDim2.new(1, -20, 0, 36)
    info.Position = UDim2.new(0, 10, 0, 44)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.SourceSans
    info.TextSize = 14
    info.TextColor3 = Color3.fromRGB(180,180,180)
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.Text = "Job: Truck | Mode: Auto | Stop: F"

    UI.ScreenGui = screenGui
    UI.Frame = frame
    UI.Status = status
    UI.Button = btn
    UI.Info = info
end

-- state
local running = false

local function setStatus(txt, color)
    if UI and UI.Status then
        UI.Status.Text = "Status: "..tostring(txt)
        if color then UI.Status.TextColor3 = color end
    end
end

-- main farming logic
local function farmingLoop()
    running = true
    setStatus("Searching job objects...", Color3.fromRGB(255,210,80))

    while running do
        -- find truck, seat, start, end
        local truck = findTruckModel()
        local seat = truck and findDriverSeat(truck) or nil
        local startMarker = findMarker(COMMON_START_NAMES)
        local endMarker = findMarker(COMMON_END_NAMES)

        if not truck or not seat or not startMarker or not endMarker then
            setStatus("Job objects not found. Retrying...", Color3.fromRGB(255,150,0))
            task.wait(CONFIG.SEARCH_INTERVAL)
            continue
        end

        -- ensure truck has PrimaryPart
        if not truck.PrimaryPart then
            -- try set primary
            for _,v in ipairs(truck:GetDescendants()) do
                if v:IsA("BasePart") then
                    truck.PrimaryPart = v
                    break
                end
            end
        end

        -- move player close to seat and attempt to sit
        setStatus("Moving to truck...", Color3.fromRGB(255,255,255))
        local seatPos = seat.CFrame + Vector3.new(0, 1.2, 0)
        safeMoveTo(seatPos, 0.6)
        randSleep()

        -- try force position into seat area
        refreshCharacter()
        local hrp = Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function() hrp.CFrame = seat.CFrame + Vector3.new(0,1.2,0) end)
        end
        local humanoid = Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            pcall(function()
                humanoid.Sit = true
            end)
        end

        setStatus("Riding truck - waiting arrival...", Color3.fromRGB(0,170,255))

        -- wait until truck is near destination (or timeout)
        local elapsed = 0
        local primary = truck.PrimaryPart
        while running and elapsed < CONFIG.TRIP_TIMEOUT and not truckAtDestination(truck, endMarker) do
            -- safety: if primary is nil or destroyed, break to retry
            if not primary or not primary.Parent then
                setStatus("Truck lost, retrying...", Color3.fromRGB(255,120,80))
                break
            end
            task.wait(1)
            elapsed = elapsed + 1
        end

        if not running then break end

        if elapsed >= CONFIG.TRIP_TIMEOUT then
            setStatus("Trip timeout. Retrying...", Color3.fromRGB(255,100,0))
            -- attempt to reposition to start and continue
            if startMarker and hrp then
                pcall(function() hrp.CFrame = startMarker.CFrame + Vector3.new(0,2,0) end)
            end
            task.wait(1.2)
            continue
        end

        -- arrived
        setStatus("Arrived. Cooldown "..tostring(CONFIG.COOLDOWN_AFTER_ARRIVAL).."s", Color3.fromRGB(0,220,120))
        for i = CONFIG.COOLDOWN_AFTER_ARRIVAL, 1, -1 do
            if not running then break end
            setStatus("Cooldown: "..i.."s", Color3.fromRGB(200,200,200))
            task.wait(1)
        end

        -- move back to start to trigger next job
        if startMarker and hrp then
            pcall(function() hrp.CFrame = startMarker.CFrame + Vector3.new(0,2,0) end)
        end

        randSleep(0.8, 1.6)
    end

    setStatus("Stopped", Color3.fromRGB(255,120,120))
end

-- UI button handler
UI.Button.MouseButton1Click:Connect(function()
    if not running then
        UI.Button.Text = "Stop"
        UI.Button.BackgroundColor3 = Color3.fromRGB(255,80,80)
        spawn(farmingLoop)
    else
        running = false
        UI.Button.Text = "Start"
        UI.Button.BackgroundColor3 = Color3.fromRGB(0,170,255)
    end
end)

-- Safety key to stop
local UserInput = game:GetService("UserInputService")
UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == CONFIG.SAFETY_STOP_KEY then
        running = false
        UI.Button.Text = "Start"
        UI.Button.BackgroundColor3 = Color3.fromRGB(0,170,255)
        setStatus("Stopped by user (F)", Color3.fromRGB(255,120,120))
    end
end)

-- auto start
spawn(function()
    task.wait(0.4)
    UI.Button.Text = "Stop"
    UI.Button.BackgroundColor3 = Color3.fromRGB(255,80,80)
    spawn(farmingLoop)
end)
