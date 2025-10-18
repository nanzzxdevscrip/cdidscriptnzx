--// Steel a Brainrot - Auto Lock Base Script by nanzzxdev
--// Fungsi: Teleport ke base kamu & cegah server teleport ke base orang lain

local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", gui)
local startButton = Instance.new("TextButton", frame)
local stopButton = Instance.new("TextButton", frame)
local baseCFrame = nil
local stayAtBase = false

-- UI Styling
gui.ResetOnSpawn = false
frame.Size = UDim2.new(0, 180, 0, 100)
frame.Position = UDim2.new(0.5, -90, 0.5, -50)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 2
frame.BorderColor3 = Color3.fromRGB(0, 255, 0)
frame.Active = true
frame.Draggable = true

startButton.Size = UDim2.new(1, -20, 0, 40)
startButton.Position = UDim2.new(0, 10, 0, 10)
startButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.Text = "🚀 START"
startButton.Font = Enum.Font.GothamBold
startButton.TextSize = 18
startButton.BorderSizePixel = 0

stopButton.Size = UDim2.new(1, -20, 0, 30)
stopButton.Position = UDim2.new(0, 10, 0, 60)
stopButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.Text = "🛑 STOP"
stopButton.Font = Enum.Font.GothamBold
stopButton.TextSize = 16
stopButton.BorderSizePixel = 0

-- Get base (lokasi awal pemain)
local function setBase()
	repeat task.wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	baseCFrame = player.Character.HumanoidRootPart.CFrame
end

-- Fungsi start teleport & lock
local function startLock()
	if not baseCFrame then
		setBase()
	end
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = baseCFrame + Vector3.new(0, 3, 0)
	end
	stayAtBase = true
	game.StarterGui:SetCore("SendNotification", {
		Title = "Steel a Brainrot";
		Text = "🔒 Base lock aktif!";
		Duration = 3;
	})

	task.spawn(function()
		while stayAtBase do
			task.wait(1)
			local c = player.Character
			if c and c:FindFirstChild("HumanoidRootPart") and baseCFrame then
				local dist = (c.HumanoidRootPart.Position - baseCFrame.Position).Magnitude
				if dist > 20 then
					c.HumanoidRootPart.CFrame = baseCFrame + Vector3.new(0, 3, 0)
				end
			end
		end
	end)
end

-- Fungsi stop
local function stopLock()
	stayAtBase = false
	game.StarterGui:SetCore("SendNotification", {
		Title = "Steel a Brainrot";
		Text = "❌ Base lock dimatikan.";
		Duration = 3;
	})
end

-- Tombol
startButton.MouseButton1Click:Connect(startLock)
stopButton.MouseButton1Click:Connect(stopLock)

-- Notif awal
game.StarterGui:SetCore("SendNotification", {
	Title = "Steel a Brainrot Script";
	Text = "UI aktif ✅ Klik START untuk teleport & kunci posisi.";
	Duration = 5;
})
