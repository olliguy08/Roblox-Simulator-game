local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestRatings = remotes:WaitForChild("RequestRatings")

local playerGui = script.Parent
local screenGui = playerGui:FindFirstAncestorOfClass("ScreenGui") or script.Parent

local function createFrame(name, parent)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(0, 320, 0, 420)
	frame.Position = UDim2.new(0, 20, 0.5, -210)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

local mainFrame = screenGui:FindFirstChild("PhoneRoot") or createFrame("PhoneRoot", screenGui)

local header = mainFrame:FindFirstChild("Header") or Instance.new("TextLabel")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
header.TextColor3 = Color3.new(1, 1, 1)
header.Font = Enum.Font.GothamBold
header.TextSize = 18
header.Text = "Food Delivery"
header.Parent = mainFrame

local tabs = mainFrame:FindFirstChild("Tabs") or Instance.new("Frame")
tabs.Name = "Tabs"
tabs.Size = UDim2.new(1, 0, 0, 36)
tabs.Position = UDim2.new(0, 0, 0, 40)
tabs.BackgroundTransparency = 1
tabs.Parent = mainFrame

local deliveriesButton = tabs:FindFirstChild("DeliveriesButton") or Instance.new("TextButton")
deliveriesButton.Name = "DeliveriesButton"
deliveriesButton.Size = UDim2.new(0.5, -5, 1, 0)
deliveriesButton.Position = UDim2.new(0, 0, 0, 0)
deliveriesButton.Text = "Deliveries"
deliveriesButton.Font = Enum.Font.GothamSemibold
deliveriesButton.TextSize = 16
deliveriesButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
deliveriesButton.TextColor3 = Color3.new(1, 1, 1)
deliveriesButton.Parent = tabs

local ratingsButton = tabs:FindFirstChild("RatingsButton") or Instance.new("TextButton")
ratingsButton.Name = "RatingsButton"
ratingsButton.Size = UDim2.new(0.5, -5, 1, 0)
ratingsButton.Position = UDim2.new(0.5, 5, 0, 0)
ratingsButton.Text = "Ratings"
ratingsButton.Font = Enum.Font.GothamSemibold
ratingsButton.TextSize = 16
ratingsButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
ratingsButton.TextColor3 = Color3.new(1, 1, 1)
ratingsButton.Parent = tabs

local deliveriesFrame = mainFrame:FindFirstChild("DeliveriesApp") or createFrame("DeliveriesApp", mainFrame)
deliveriesFrame.Position = UDim2.new(0, 0, 0, 76)
deliveriesFrame.Size = UDim2.new(1, 0, 1, -76)

local ratingsFrame = mainFrame:FindFirstChild("RatingsApp") or createFrame("RatingsApp", mainFrame)
ratingsFrame.Position = UDim2.new(0, 0, 0, 76)
ratingsFrame.Size = UDim2.new(1, 0, 1, -76)
ratingsFrame.Visible = false

local function showDeliveries()
	deliveriesFrame.Visible = true
	ratingsFrame.Visible = false
end

local function showRatings()
	deliveriesFrame.Visible = false
	ratingsFrame.Visible = true
	RequestRatings:InvokeServer()
end

deliveriesButton.MouseButton1Click:Connect(showDeliveries)
ratingsButton.MouseButton1Click:Connect(showRatings)

showDeliveries()
