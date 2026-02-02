local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local JobStateUpdate = remotes:WaitForChild("JobStateUpdate")
local DeliveryResults = remotes:WaitForChild("DeliveryResults")

local screenGui = script.Parent

local function ensureLabel(name, position)
	local label = screenGui:FindFirstChild(name) or Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(0, 300, 0, 24)
	label.Position = position
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamSemibold
	label.TextSize = 14
	label.Parent = screenGui
	return label
end

local objectiveLabel = ensureLabel("ObjectiveLabel", UDim2.new(0, 20, 0, 20))
local timerLabel = ensureLabel("TimerLabel", UDim2.new(0, 20, 0, 48))
local conditionLabel = ensureLabel("ConditionLabel", UDim2.new(0, 20, 0, 76))

objectiveLabel.Text = "Objective: Idle"
timerLabel.Text = "Time Left: --"
conditionLabel.Text = "Condition: --"

JobStateUpdate.OnClientEvent:Connect(function(data)
	if not data then
		return
	end

	objectiveLabel.Text = "Objective: " .. (data.objective or data.state or "Idle")

	if data.timeLeft then
		timerLabel.Text = string.format("Time Left: %ds", math.floor(data.timeLeft))
	else
		timerLabel.Text = "Time Left: --"
	end

	if data.condition then
		conditionLabel.Text = string.format("Condition: %d%%", math.floor(data.condition))
	else
		conditionLabel.Text = "Condition: --"
	end
end)

DeliveryResults.OnClientEvent:Connect(function(results)
	if results then
		objectiveLabel.Text = string.format("Complete! $%d, %d★", results.payout, results.stars)
	end
end)
