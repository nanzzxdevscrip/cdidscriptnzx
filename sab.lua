-- AUTO FLY BY CHATGPT (Speed 50, Full Kebal, GUI Switch Kiri Atas)

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local flying = false
local flySpeed = 50
local bodyGyro, bodyVel

-- Anti Damage Full Kebal (Disable Humanoid Damage)
local function setGodMode(state)
    local hum = character:FindFirstChild("Humanoid")
    if hum then
        if state then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        else
            hum.MaxHealth = 100
            hum.Health = 100
        end
    end
end

-- Mulai Fly
local function startFly()
    if flying then return end
    flying = true
    bodyGyro = Instance.new("BodyGyro", hrp)
    bodyVel = Instance.new("BodyVelocity", hrp)

    bodyGyro.P = 9e4
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    setGodMode(true)

    spawn(function()
        while flying do
            bodyGyro.CFrame = workspace.CurrentCamera.CFrame
            bodyVel.Velocity = workspace.CurrentCamera.CFrame.LookVector * flySpeed
            task.wait()
        end
    end)
end

-- Berhenti Fly
local function stopFly()
    flying = false
    setGodMode(false)
    if bodyGyro then bodyGyro:Destroy() end
    if bodyVel then bodyVel:Destroy() end
end

-- GUI Switch (Kiri Atas)
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Button = Instance.new("TextButton", ScreenGui)

Button.Size = UDim2.new(0, 120, 0, 40)
Button.Position = UDim2.new(0, 10, 0, 10) -- Kiri Atas
Button.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.Font = Enum.Font.SourceSansBold
Button.TextSize = 18
Button.Text = "Fly: OFF"

Button.MouseButton1Click:Connect(function()
    if flying then
        stopFly()
        Button.Text = "Fly: OFF"
        Button.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    else
        startFly()
        Button.Text = "Fly: ON"
        Button.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    end
end)

print("✅ Auto Fly Loaded! Tekan Tombol di Kiri Atas")
