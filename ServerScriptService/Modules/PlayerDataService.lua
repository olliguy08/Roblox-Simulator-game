local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerDataService = {}

local DeveloperMode = false

local function debugPrint(...)
	if DeveloperMode then
		print("[PlayerDataService]", ...)
	end
end

function PlayerDataService.SetDeveloperMode(enabled)
	DeveloperMode = enabled and true or false
end

local DATASTORE_NAME = "FoodDeliveryData"
local store = DataStoreService:GetDataStore(DATASTORE_NAME)
local cache = {}

local function defaultData()
	return {
		Money = 0,
		Ratings = {},
	}
end

function PlayerDataService.GetData(player)
	cache[player] = cache[player] or defaultData()
	return cache[player]
end

function PlayerDataService.AddRating(player, entry)
	local data = PlayerDataService.GetData(player)
	data.Ratings = data.Ratings or {}
	table.insert(data.Ratings, 1, entry)
	while #data.Ratings > 20 do
		table.remove(data.Ratings)
	end
end

function PlayerDataService.Load(player)
	if RunService:IsStudio() then
		debugPrint("Studio mode: using in-memory data for", player.Name)
		cache[player] = cache[player] or defaultData()
		return
	end

	local success, result = pcall(function()
		return store:GetAsync(player.UserId)
	end)

	if success and result then
		cache[player] = result
		debugPrint("Loaded data for", player.Name)
	else
		cache[player] = defaultData()
		debugPrint("Using default data for", player.Name)
	end
end

function PlayerDataService.Save(player)
	local data = cache[player]
	if not data then
		return
	end
	if RunService:IsStudio() then
		debugPrint("Studio mode: skipping DataStore save for", player.Name)
		return
	end
	local success, err = pcall(function()
		store:SetAsync(player.UserId, data)
	end)
	if not success then
		warn("Failed to save data for", player.Name, err)
	else
		debugPrint("Saved data for", player.Name)
	end
end

Players.PlayerRemoving:Connect(function(player)
	PlayerDataService.Save(player)
	cache[player] = nil
end)

return PlayerDataService
