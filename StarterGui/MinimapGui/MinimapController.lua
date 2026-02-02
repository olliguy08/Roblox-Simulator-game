local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local JobStateUpdate = remotes:WaitForChild("JobStateUpdate")

local screenGui = script.Parent

local minimapFrame = screenGui:FindFirstChild("MinimapFrame") or Instance.new("Frame")
minimapFrame.Name = "MinimapFrame"
minimapFrame.Size = UDim2.new(0, 160, 0, 160)
minimapFrame.Position = UDim2.new(1, -180, 1, -180)
minimapFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
minimapFrame.BorderSizePixel = 0
minimapFrame.Parent = screenGui

local compass = minimapFrame:FindFirstChild("Compass") or Instance.new("TextLabel")
compass.Name = "Compass"
compass.Size = UDim2.new(1, 0, 1, 0)
compass.BackgroundTransparency = 1
compass.Text = "▲"
compass.Font = Enum.Font.GothamBlack
compass.TextSize = 48
compass.TextColor3 = Color3.fromRGB(255, 208, 64)
compass.Parent = minimapFrame

local objectivePosition = nil

JobStateUpdate.OnClientEvent:Connect(function(data)
	if data and data.targetPosition then
		objectivePosition = data.targetPosition
	else
		objectivePosition = nil
	end
end)

RunService.RenderStepped:Connect(function()
	if not objectivePosition then
		compass.Rotation = 0
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local direction = (objectivePosition - root.Position)
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude <= 0 then
		return
	end
	local angle = math.deg(math.atan2(flat.X, flat.Z))
	compass.Rotation = angle
end)
