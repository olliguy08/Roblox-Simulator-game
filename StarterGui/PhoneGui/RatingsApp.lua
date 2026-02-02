local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestRatings = remotes:WaitForChild("RequestRatings")

local frame = script.Parent

local function ensureLabel(name, parent, text, position, size)
	local label = parent:FindFirstChild(name) or Instance.new("TextLabel")
	label.Name = name
	label.Size = size or UDim2.new(1, -20, 0, 24)
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = parent
	return label
end

local title = ensureLabel("Title", frame, "Ratings", UDim2.new(0, 10, 0, 10))
title.Font = Enum.Font.GothamBold
title.TextSize = 16

local averageLabel = ensureLabel("Average", frame, "Average: --", UDim2.new(0, 10, 0, 40))

local moneyLabel = ensureLabel("Money", frame, "Money: $0", UDim2.new(0, 10, 0, 60))

local refreshButton = frame:FindFirstChild("RefreshButton") or Instance.new("TextButton")
refreshButton.Name = "RefreshButton"
refreshButton.Size = UDim2.new(0, 120, 0, 28)
refreshButton.Position = UDim2.new(1, -130, 0, 6)
refreshButton.Text = "Refresh"
refreshButton.Font = Enum.Font.GothamSemibold
refreshButton.TextSize = 14
refreshButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
refreshButton.TextColor3 = Color3.new(1, 1, 1)
refreshButton.Parent = frame

local scroll = frame:FindFirstChild("RatingsScroll") or Instance.new("ScrollingFrame")
scroll.Name = "RatingsScroll"
scroll.Size = UDim2.new(1, -20, 1, -100)
scroll.Position = UDim2.new(0, 10, 0, 90)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = frame

local entries = {}

local function clearEntries()
	for _, item in ipairs(entries) do
		item:Destroy()
	end
	entries = {}
end

local function renderRatings(payload)
	clearEntries()
	averageLabel.Text = string.format("Average: %.1f ★", payload.average or 0)
	moneyLabel.Text = string.format("Money: $%d", payload.money or 0)

	local y = 0
	for _, entry in ipairs(payload.ratings or {}) do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -10, 0, 48)
		label.Position = UDim2.new(0, 0, 0, y)
		label.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Text = string.format("%d★ | $%d | %ss | %d%%\n%s",
			entry.stars,
			entry.payout,
			entry.timeTaken,
			entry.condition,
			entry.comment
		)
		label.Parent = scroll
		table.insert(entries, label)
		y += 54
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, y)
end

local function refreshRatings()
	local payload = RequestRatings:InvokeServer()
	renderRatings(payload)
end

refreshButton.MouseButton1Click:Connect(refreshRatings)

refreshRatings()
