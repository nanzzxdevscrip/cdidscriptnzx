-- NZX Script CDID - UI Launcher (draggable logo + panel)
-- Author: ChatGPT for Nanzzx
-- Paste this LocalScript into StarterGui, or save as DeltaMenu.lua for loadstring.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")

-- Remove old GUI if present
local old = playerGui:FindFirstChild("NZXScriptGUI")
if old then old:Destroy() end

-- Root ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NZXScriptGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ============ Panel (hidden by default) ============
local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.Size = UDim2.new(0, 520, 0, 360)
panel.Position = UDim2.new(0.5, -260, 0.5, -180)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundTransparency = 0
panel.BackgroundColor3 = Color3.fromRGB(18,18,20)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

-- Background red gradient (fire-like)
local redLayer = Instance.new("Frame")
redLayer.Name = "RedLayer"
redLayer.Size = UDim2.new(1,0,1,0)
redLayer.Position = UDim2.new(0,0,0,0)
redLayer.BackgroundColor3 = Color3.fromRGB(255,40,40)
redLayer.BackgroundTransparency = 0.85
redLayer.BorderSizePixel = 0
redLayer.ZIndex = 1
redLayer.Parent = panel

local redGrad = Instance.new("UIGradient")
redGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,90,80)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220,40,20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180,10,5))
}
redGrad.Rotation = 20
redGrad.Parent = redLayer

-- Background blue gradient (water-like) overlay
local blueLayer = Instance.new("Frame")
blueLayer.Name = "BlueLayer"
blueLayer.Size = UDim2.new(1,0,1,0)
blueLayer.Position = UDim2.new(0,0,0,0)
blueLayer.BackgroundColor3 = Color3.fromRGB(30,100,255)
blueLayer.BackgroundTransparency = 0.92
blueLayer.BorderSizePixel = 0
blueLayer.ZIndex = 2
blueLayer.Parent = panel

local blueGrad = Instance.new("UIGradient")
blueGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80,160,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10,60,200))
}
blueGrad.Rotation = -20
blueGrad.Parent = blueLayer

-- subtle overlay to darken center for readability
local darkOverlay = Instance.new("Frame")
darkOverlay.Size = UDim2.new(1,0,1,0)
darkOverlay.BackgroundColor3 = Color3.fromRGB(10,10,12)
darkOverlay.BackgroundTransparency = 0.86
darkOverlay.BorderSizePixel = 0
darkOverlay.ZIndex = 3
darkOverlay.Parent = panel

-- Content area (on top)
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -40, 1, -60)
content.Position = UDim2.new(0, 20, 0, 40)
content.BackgroundTransparency = 1
content.ZIndex = 4
content.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Parent = content
title.Size = UDim2.new(1, 0, 0, 36)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 26
title.Text = "NZX SCRIPT CDID"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Parent = content
subtitle.Size = UDim2.new(1, 0, 0, 18)
subtitle.Position = UDim2.new(0,0,0,36)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.Text = "Car Driving Indonesia - Panel kosong (siap diisi)"
subtitle.TextColor3 = Color3.fromRGB(200,200,200)
subtitle.TextXAlignment = Enum.TextXAlignment.Left

-- Empty middle area (for future features)
local body = Instance.new("Frame")
body.Parent = content
body.Size = UDim2.new(1, 0, 1, -60)
body.Position = UDim2.new(0,0,0,60)
body.BackgroundTransparency = 1

local placeholder = Instance.new("TextLabel")
placeholder.Parent = body
placeholder.Size = UDim2.new(1, 0, 1, 0)
placeholder.BackgroundTransparency = 1
placeholder.Font = Enum.Font.Gotham
placeholder.TextSize = 16
placeholder.TextColor3 = Color3.fromRGB(170,170,170)
placeholder.TextWrapped = true
placeholder.Text = "Panel kosong — fitur dihapus sementara.\nKlik ikon ☠️ untuk menutup/membuka. Tarik ikon untuk memindahkan launcher."
placeholder.TextXAlignment = Enum.TextXAlignment.Left
placeholder.TextYAlignment = Enum.TextYAlignment.Top

-- Close small X button top-right
local closeBtn = Instance.new("TextButton")
closeBtn.Parent = panel
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 8)
closeBtn.AnchorPoint = Vector2.new(0,0)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.Gotham
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(230,230,230)
closeBtn.BackgroundTransparency = 0.8
closeBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 5

local cbCorner = Instance.new("UICorner")
cbCorner.CornerRadius = UDim.new(0,6)
cbCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
end)

-- ============ Floating draggable logo (launcher) ============
local logoSize = 56
local logo = Instance.new("Frame")
logo.Name = "NZXLauncher"
logo.Size = UDim2.new(0, logoSize, 0, logoSize)
logo.Position = UDim2.new(0, 20, 0, 120)
logo.BackgroundColor3 = Color3.fromRGB(18,18,20)
logo.BorderSizePixel = 0
logo.AnchorPoint = Vector2.new(0,0)
logo.Parent = screenGui
logo.ZIndex = 6

local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(0, 100)
logoCorner.Parent = logo

local logoStroke = Instance.new("UIStroke")
logoStroke.Thickness = 2
logoStroke.Color = Color3.fromRGB(200,60,255)
logoStroke.Parent = logo

local logoInner = Instance.new("Frame")
logoInner.Size = UDim2.new(0.9, 0, 0.9, 0)
logoInner.Position = UDim2.new(0.05, 0, 0.05, 0)
logoInner.BackgroundColor3 = Color3.fromRGB(28,28,30)
logoInner.BorderSizePixel = 0
logoInner.Parent = logo

local innerCorner = Instance.new("UICorner")
innerCorner.CornerRadius = UDim.new(0, 90)
innerCorner.Parent = logoInner

-- Skull icon label (use emoji)
local skull = Instance.new("TextLabel")
skull.Parent = logoInner
skull.Size = UDim2.new(1,0,1,0)
skull.BackgroundTransparency = 1
skull.Font = Enum.Font.GothamBold
skull.TextSize = 30
skull.Text = "☠️"
skull.TextColor3 = Color3.fromRGB(255, 40, 40)
skull.TextScaled = true
skull.RichText = false
skull.ZIndex = 7

-- make logo draggable
local dragging = false
local dragInput, dragStart, startPos

local function updateLogoPosition(input)
    local delta = input.Position - dragStart
    local newX = startPos.X + delta.X
    local newY = startPos.Y + delta.Y
    logo.Position = UDim2.new(0, newX, 0, newY)
end

logo.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Vector2.new(logo.AbsolutePosition.X, logo.AbsolutePosition.Y)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

logo.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging and dragInput and dragStart and startPos then
        local success, err = pcall(function()
            updateLogoPosition(dragInput)
        end)
        if not success then
            -- ignore
        end
    end
end)

-- on click: toggle panel visible
local clicked = false
logoInner.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- toggle with small tween
        clicked = not clicked
        if clicked then
            panel.Visible = true
            panel.Position = UDim2.new(0.5, -260, 0.5, -180)
            TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = UDim2.new(0.5, -260, 0.5, -200)}):Play()
            TweenService:Create(panel, TweenInfo.new(0.16), {Size = UDim2.new(0,520,0,360)}):Play()
        else
            panel.Visible = false
        end
    end
end)

-- small hover glow effect
logo.MouseEnter:Connect(function()
    TweenService:Create(logoStroke, TweenInfo.new(0.15), {Thickness = 3}):Play()
end)
logo.MouseLeave:Connect(function()
    TweenService:Create(logoStroke, TweenInfo.new(0.15), {Thickness = 2}):Play()
end)

-- animate the background gradients slowly to give 'fire & water' feel
spawn(function()
    local rRot = 0
    local bRot = 0
    while true do
        rRot = (rRot + 0.6) % 360
        bRot = (bRot - 0.8) % 360
        redGrad.Rotation = rRot
        blueGrad.Rotation = bRot
        task.wait(0.04)
    end
end)

-- final log
print("NZX SCRIPT CDID launcher loaded (UI only).")
