-- NZX CDID Truck Autofarm — Safe Fly Version (Delta-ready)
-- Features: Start/Stop GUI, auto teleport job, respawn-find truck box/kayu,
-- auto enter truck (best-effort), smooth/slow "fly" using BodyVelocity, 5s cooldown per waypoint.
-- IMPORTANT: This is best-effort template. Some games block client-side vehicle control.

if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

-- ==========================
-- CONFIG - adjust these
-- ==========================
local JOB_TELEPORT_POS = Vector3.new(-1200, 6, 890)    -- where the job / vehicle spawn is
local VEHICLES_FOLDER = workspace:FindFirstChild("Vehicles") or workspace -- where vehicles live
local TRUCK_KEYWORDS = {"truck","truk"}
local TRUCK_TYPE_KEYWORDS = {"box","kayu","wood"}
local WAYPOINTS = {
    Vector3.new(2500, 40, 1700),
    Vector3.new(2700, 40, -1200),
    Vector3.new(1500, 40, 500)
}
local MAX_SPAWN_ATTEMPTS = 30
local SPAWN_WAIT = 2            -- seconds to wait after teleport/spawn attempt
local ARRIVE_DIST = 12         -- distance to consider arrived
local COOLDOWN_AT_DEST = 5     -- seconds at each waypoint
local SAFE_FLY_SPEED = 50      -- studs/sec (reduced to be less suspicious)
local BV_MAX_FORCE = 1e5       -- moderate force
local SMOOTHING = 0.12         -- interpolation factor for velocity smoothing (0-1)
-- ==========================

-- state
local running = false
local stopFlag = false

-- UTIL
local function notify(text, dur)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {Title = "NZX TruckFarm", Text = tostring(text), Duration = dur or 4})
    end)
end

local function isTruckModel(m)
    if not m or not m.Name then return false end
    local n = string.lower(m.Name)
    for _,k in ipairs(TRUCK_KEYWORDS) do
        if string.find(n, k) then
            return true
        end
    end
    return false
end

local function hasDesiredType(m)
    if not m then return false end
    local n = string.lower(m.Name)
    for _,k in ipairs(TRUCK_TYPE_KEYWORDS) do
        if string.find(n, k) then return true end
    end
    for _,d in ipairs(m:GetDescendants()) do
        if d:IsA("BasePart") or d:IsA("Model") then
            local dn = string.lower(d.Name)
            for _,k in ipairs(TRUCK_TYPE_KEYWORDS) do
                if string.find(dn, k) then return true end
            end
        end
    end
    return false
end

local function findNearestTruck(desiredOnly)
    local best,bd = nil,math.huge
    for _,m in ipairs(VEHICLES_FOLDER:GetDescendants()) do
        if m:IsA("Model") and isTruckModel(m) then
            local prim = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
            if prim and prim.Position and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                local d = (prim.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude
                if d < bd then
                    if not desiredOnly or hasDesiredType(m) then
                        best,bd = m,d
                    end
                end
            end
        end
    end
    return best,bd
end

local function teleportTo(pos)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
    if hrp then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
        return true
    end
    return false
end

local function trySitSeat(seat)
    if not seat or not seat:IsA("VehicleSeat") and not seat:IsA("Seat") then return false end
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    -- teleport close then set Sit true
    local sitPos = seat.Position - (seat.CFrame.LookVector * 1.5) + Vector3.new(0,2,0)
    teleportTo(sitPos)
    task.wait(0.3)
    pcall(function() humanoid.Sit = true end)
    local t0 = tick()
    while tick()-t0 < 3 do
        if seat.Occupant and seat.Occupant.Parent == char then return true end
        RunService.Heartbeat:Wait()
    end
    return (seat.Occupant and seat.Occupant.Parent == char)
end

-- Smoothly control truck's main part using BodyVelocity (client-side)
local function smoothFlyModel(model, waypoints)
    if not model or not model.PrimaryPart then return false end
    local main = model.PrimaryPart
    -- create BV and BG
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(BV_MAX_FORCE, BV_MAX_FORCE, BV_MAX_FORCE)
    bv.P = 3000
    bv.Velocity = Vector3.new(0,0,0)
    bv.Parent = main

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    bg.P = 3000
    bg.Parent = main

    local currentVel = Vector3.new(0,0,0)

    for _,wp in ipairs(waypoints) do
        if stopFlag then break end
        -- Move until within ARRIVE_DIST
        local startTime = tick()
        while not stopFlag do
            local dir = (wp - main.Position)
            local dist = dir.Magnitude
            if dist <= ARRIVE_DIST then break end

            local desiredVel = dir.Unit * SAFE_FLY_SPEED
            -- bias Y slightly to maintain altitude but allow downward movement
            desiredVel = Vector3.new(desiredVel.X, desiredVel.Y * 0.6, desiredVel.Z)

            -- smoothing (lerp)
            currentVel = currentVel:Lerp(desiredVel, SMOOTHING)
            bv.Velocity = currentVel

            -- orient main toward movement direction
            if dir.Magnitude > 1 then
                local lookCFrame = CFrame.new(main.Position, main.Position + Vector3.new(dir.X, 0, dir.Z))
                bg.CFrame = lookCFrame
            end

            RunService.Heartbeat:Wait()
            -- safety timeout per waypoint
            if tick() - startTime > 60 then break end
        end

        -- stop movement briefly
        bv.Velocity = Vector3.new(0,0,0)
        task.wait(COOLDOWN_AT_DEST)
    end

    if bv and bv.Parent then bv:Destroy() end
    if bg and bg.Parent then bg:Destroy() end
    return true
end

-- Try to "respawn" job / vehicle by teleporting to JOB_TELEPORT_POS repeatedly
local function ensureTruckAvailable()
    local attempts = 0
    while attempts < MAX_SPAWN_ATTEMPTS and not stopFlag do
        attempts = attempts + 1
        -- look for desired truck first
        local found = findNearestTruck(true)
        if found then return found end
        -- teleport to job spawn and wait short time (many servers spawn vehicle on player arrival)
        teleportTo(JOB_TELEPORT_POS)
        task.wait(0.6)
        -- small wait while scanning workspace
        local t0 = tick()
        while tick() - t0 < SPAWN_WAIT and not stopFlag do
            local f2 = findNearestTruck(true)
            if f2 then return f2 end
            RunService.Heartbeat:Wait()
        end
        -- small delay before next attempt
        task.wait(0.8)
    end
    return nil
end

-- Main autofarm routine
local function autofarmRoutine()
    notify("Autofarm: START", 4)
    while not stopFlag do
        -- ensure truck exists (box/kayu)
        local truck = ensureTruckAvailable()
        if stopFlag then break end
        if not truck then
            notify("Gagal temukan truk box/kayu setelah beberapa percobaan.", 5)
            break
        end

        -- attempt to enter
        -- find seat inside truck
        local seat
        for _,d in ipairs(truck:GetDescendants()) do
            if d:IsA("VehicleSeat") or d:IsA("Seat") then
                seat = d
                break
            end
        end

        if not seat then
            notify("Truk ditemukan tapi kursi tidak ada (skip).", 3)
            task.wait(1)
            continue
        end

        -- teleport near and try sit
        local sat = trySitSeat(seat)
        if not sat then
            -- if can't sit, try teleporting char closer to the truck main part and continue
            teleportTo(truck.PrimaryPart and truck.PrimaryPart.Position or JOB_TELEPORT_POS)
            task.wait(1)
        end

        -- control truck to fly to waypoints (best-effort)
        -- small safety: ensure PrimaryPart exists
        if not truck.PrimaryPart then
            -- try set PrimaryPart from first BasePart
            for _,p in ipairs(truck:GetDescendants()) do
                if p:IsA("BasePart") then
                    truck.PrimaryPart = p
                    break
                end
            end
        end

        if truck.PrimaryPart then
            -- raise truck slightly to avoid ground clipping (smoothly)
            local safeStartPos = truck.PrimaryPart.Position + Vector3.new(0, 15, 0)
            pcall(function() truck:SetPrimaryPartCFrame(CFrame.new(safeStartPos)) end)
            task.wait(0.25)
            smoothFlyModel(truck, WAYPOINTS)
        else
            warn("[NZX] Truck primary part not found, skipping fly.")
        end

        -- after finishing, small wait then look for next truck / job
        task.wait(1)
    end

    running = false
    stopFlag = false
    notify("Autofarm: STOPPED", 3)
end

-- ==========================
-- GUI (Delta-ready)
-- ==========================
local coreGui = game:GetService("CoreGui")
-- remove old GUI if present
pcall(function() coreGui:FindFirstChild("NZX_TruckFarm_GUI"):Destroy() end)

local screen = Instance.new("ScreenGui")
screen.Name = "NZX_TruckFarm_GUI"
screen.Parent = coreGui
screen.ResetOnSpawn = false

local frame = Instance.new("Frame", screen)
frame.Size = UDim2.new(0,240,0,120)
frame.Position = UDim2.new(0.03,0,0.25,0)
frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-12,0,28)
title.Position = UDim2.new(0,6,0,6)
title.BackgroundTransparency = 1
title.Text = "🚚 NZX Truck Autofarm (Safe Fly)"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(200,255,200)
title.TextXAlignment = Enum.TextXAlignment.Left

local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(1,-12,0,20)
statusLabel.Position = UDim2.new(0,6,0,36)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: OFF"
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextSize = 13
statusLabel.TextColor3 = Color3.fromRGB(200,200,200)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(0.46,-6,0,36)
startBtn.Position = UDim2.new(0.02,0,0.62,0)
startBtn.Text = "Start"
startBtn.Font = Enum.Font.SourceSansBold
startBtn.TextSize = 16
startBtn.BackgroundColor3 = Color3.fromRGB(0,200,80)
startBtn.TextColor3 = Color3.fromRGB(0,0,0)
startBtn.AutoButtonColor = true

local stopBtn = Instance.new("TextButton", frame)
stopBtn.Size = UDim2.new(0.46,-6,0,36)
stopBtn.Position = UDim2.new(0.52,0,0.62,0)
stopBtn.Text = "Stop"
stopBtn.Font = Enum.Font.SourceSansBold
stopBtn.TextSize = 16
stopBtn.BackgroundColor3 = Color3.fromRGB(200,40,40)
stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
stopBtn.AutoButtonColor = true

startBtn.MouseButton1Click:Connect(function()
    if running then notify("Sudah berjalan") return end
    running = true
    stopFlag = false
    statusLabel.Text = "Status: RUNNING"
    task.spawn(function()
        autofarmRoutine()
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    if not running then notify("Belum berjalan") return end
    stopFlag = true
    statusLabel.Text = "Status: STOPPING..."
end)

notify("NZX Truck Autofarm siap. Tekan Start untuk mulai.", 4)
print("[NZX] Safe Fly Autofarm loaded.")
