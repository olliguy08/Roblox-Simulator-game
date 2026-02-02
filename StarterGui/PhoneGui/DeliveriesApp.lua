local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestOffers = remotes:WaitForChild("RequestOffers")
local AcceptOffer = remotes:WaitForChild("AcceptOffer")
local JobStateUpdate = remotes:WaitForChild("JobStateUpdate")

local frame = script.Parent

local function ensureLabel(name, parent, text, position)
	local label = parent:FindFirstChild(name) or Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, -20, 0, 24)
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.Text = text
	label.Parent = parent
	return label
end

local title = ensureLabel("Title", frame, "Delivery Offers", UDim2.new(0, 10, 0, 10))
title.Font = Enum.Font.GothamBold
title.TextSize = 16

local statusLabel = ensureLabel("Status", frame, "", UDim2.new(0, 10, 0, 40))

local offersContainer = frame:FindFirstChild("OffersContainer") or Instance.new("Frame")
offersContainer.Name = "OffersContainer"
offersContainer.Size = UDim2.new(1, -20, 1, -90)
offersContainer.Position = UDim2.new(0, 10, 0, 70)
offersContainer.BackgroundTransparency = 1
offersContainer.Parent = frame

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

local offerButtons = {}

local function clearOffers()
	for _, button in ipairs(offerButtons) do
		button:Destroy()
	end
	offerButtons = {}
end

local function renderOffers(payload)
	clearOffers()
	if payload.locked then
		if payload.state == "COOLDOWN" then
			statusLabel.Text = "Waiting for new requests..."
		else
			statusLabel.Text = "Already on a job."
		end
		return
	end

	statusLabel.Text = "Choose a delivery to start."

	for index, offer in ipairs(payload.offers or {}) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 80)
		button.Position = UDim2.new(0, 0, 0, (index - 1) * 86)
		button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.Gotham
		button.TextSize = 14
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.TextYAlignment = Enum.TextYAlignment.Top
		button.Text = string.format("%s → %s\nDishes: %s\nPay: $%d | Dist: %dm | Max: %ds",
			offer.restaurantName,
			offer.customerName,
			table.concat(offer.dishes, ", "),
			offer.basePay,
			offer.estimatedDistance,
			offer.maxTime
		)
		button.Parent = offersContainer
		button.MouseButton1Click:Connect(function()
			AcceptOffer:FireServer(offer.id)
			statusLabel.Text = "Offer accepted. Head to pickup."
			clearOffers()
		end)
		table.insert(offerButtons, button)
	end
end

local function refreshOffers()
	local payload = RequestOffers:InvokeServer()
	renderOffers(payload)
end

refreshButton.MouseButton1Click:Connect(refreshOffers)

JobStateUpdate.OnClientEvent:Connect(function(data)
	if data and (data.state == "COOLDOWN" or data.state == "IDLE") then
		refreshOffers()
	end
end)

refreshOffers()
