local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local JobGenerator = require(script.Modules.JobGenerator)
local RatingService = require(script.Modules.RatingService)
local MoneyService = require(script.Modules.MoneyService)
local CrashService = require(script.Modules.CrashService)
local PlayerDataService = require(script.Modules.PlayerDataService)

local DeveloperMode = true

JobGenerator.SetDeveloperMode(DeveloperMode)
RatingService.SetDeveloperMode(DeveloperMode)
MoneyService.SetDeveloperMode(DeveloperMode)
CrashService.SetDeveloperMode(DeveloperMode)
PlayerDataService.SetDeveloperMode(DeveloperMode)

local function debugPrint(...)
	if DeveloperMode then
		print("[JobService]", ...)
	end
end

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name, className)
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remotesFolder
	end
	return remote
end

local RequestOffers = getOrCreateRemote("RequestOffers", "RemoteFunction")
local AcceptOffer = getOrCreateRemote("AcceptOffer", "RemoteEvent")
local JobStateUpdate = getOrCreateRemote("JobStateUpdate", "RemoteEvent")
local DeliveryResults = getOrCreateRemote("DeliveryResults", "RemoteEvent")
local RequestRatings = getOrCreateRemote("RequestRatings", "RemoteFunction")

local states = {
	IDLE = "IDLE",
	ACCEPTED = "ACCEPTED",
	PICKUP = "PICKUP",
	DELIVERY = "DELIVERY",
	COMPLETE = "COMPLETE",
	COOLDOWN = "COOLDOWN",
}

local playerState = {}

local function getState(player)
	playerState[player] = playerState[player] or {
		state = states.IDLE,
		offers = {},
		job = nil,
		cooldownEnds = 0,
	}
	return playerState[player]
end

local function sendState(player, data)
	JobStateUpdate:FireClient(player, data)
end

local function buildObjectivePayload(job)
	if not job then
		return nil
	end
	return {
		state = job.state,
		objective = job.objective,
		restaurantName = job.restaurantName,
		customerName = job.customerName,
		timeLeft = job.timeLeft,
		condition = job.condition,
		targetPosition = job.targetPosition,
	}
end

local function startCooldown(player)
	local state = getState(player)
	state.state = states.COOLDOWN
	state.cooldownEnds = os.clock() + math.random(10, 25)
	state.offers = {}
	state.job = nil
	debugPrint(player.Name, "cooldown started")
	sendState(player, { state = states.COOLDOWN })

	task.delay(state.cooldownEnds - os.clock(), function()
		local refreshed = getState(player)
		if refreshed.state == states.COOLDOWN then
			refreshed.state = states.IDLE
			debugPrint(player.Name, "cooldown ended")
			sendState(player, { state = states.IDLE })
		end
	end)
end

local function startJobLoop(player)
	local state = getState(player)
	local job = state.job
	if not job then
		return
	end

	CrashService.StartMonitoring(player, function(damage)
		if state.job and (state.job.state == states.PICKUP or state.job.state == states.DELIVERY) then
			state.job.condition = math.max(0, state.job.condition - damage)
			sendState(player, buildObjectivePayload(state.job))
		end
	end)

	local lastUpdate = 0
	task.spawn(function()
		while state.job and (state.job.state == states.PICKUP or state.job.state == states.DELIVERY) do
			local now = os.clock()
			state.job.timeLeft = math.max(0, state.job.maxTime - (now - state.job.startTime))
			if now - lastUpdate >= 1 then
				sendState(player, buildObjectivePayload(state.job))
				lastUpdate = now
			end
			if state.job.timeLeft <= 0 then
				debugPrint(player.Name, "time limit expired")
			end
			RunService.Heartbeat:Wait()
		end
	end)

	task.spawn(function()
		while state.job and (state.job.state == states.PICKUP or state.job.state == states.DELIVERY) do
			local target = state.job.targetPosition
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if target and root then
				local distance = (root.Position - target).Magnitude
				if distance <= 12 then
					if state.job.state == states.PICKUP then
						state.job.state = states.DELIVERY
						state.job.objective = "Deliver to " .. state.job.customerName
						state.job.targetPosition = state.job.customerPosition
						debugPrint(player.Name, "picked up order")
						sendState(player, buildObjectivePayload(state.job))
					elseif state.job.state == states.DELIVERY then
						state.job.state = states.COMPLETE
						debugPrint(player.Name, "delivered order")
						break
					end
				end
			end
			task.wait(0.25)
		end

		if state.job and state.job.state == states.COMPLETE then
			CrashService.StopMonitoring(player)
			local now = os.clock()
			local timeTaken = now - state.job.startTime
			local results = RatingService.CalculateResults({
				basePay = state.job.basePay,
				maxTime = state.job.maxTime,
				timeTaken = timeTaken,
				condition = state.job.condition,
			})

			MoneyService.AddMoney(player, results.payout, PlayerDataService)
			PlayerDataService.AddRating(player, {
				id = os.time(),
				stars = results.stars,
				comment = results.comment,
				timeTaken = math.floor(timeTaken),
				condition = math.floor(results.condition),
				payout = results.payout,
			})

			DeliveryResults:FireClient(player, results)
			startCooldown(player)
		end
	end)
end

local function buildOfferPayload(offer)
	return {
		id = offer.id,
		restaurantName = offer.restaurantName,
		customerName = offer.customerName,
		dishes = offer.dishes,
		basePay = offer.basePay,
		estimatedDistance = offer.estimatedDistance,
		maxTime = offer.maxTime,
	}
end

RequestOffers.OnServerInvoke = function(player)
	local state = getState(player)
	if state.state ~= states.IDLE then
		return {
			locked = true,
			state = state.state,
		}
	end

	if #state.offers == 0 then
		state.offers = JobGenerator.GenerateOffers()
	end

	local payload = {}
	for _, offer in ipairs(state.offers) do
		table.insert(payload, buildOfferPayload(offer))
	end

	return {
		locked = false,
		state = state.state,
		offers = payload,
	}
end

AcceptOffer.OnServerEvent:Connect(function(player, offerId)
	local state = getState(player)
	if state.state ~= states.IDLE then
		return
	end

	local chosen
	for _, offer in ipairs(state.offers) do
		if offer.id == offerId then
			chosen = offer
			break
		end
	end

	if not chosen then
		return
	end

	state.state = states.PICKUP
	state.job = {
		state = states.PICKUP,
		restaurantName = chosen.restaurantName,
		customerName = chosen.customerName,
		restaurantPosition = chosen.restaurant.Position,
		customerPosition = chosen.customer.Position,
		objective = "Pickup at " .. chosen.restaurantName,
		targetPosition = chosen.restaurant.Position,
		basePay = chosen.basePay,
		maxTime = chosen.maxTime,
		startTime = os.clock(),
		condition = 100,
	}
	state.offers = {}
	debugPrint(player.Name, "accepted offer", offerId)

	sendState(player, buildObjectivePayload(state.job))
	startJobLoop(player)
end)

RequestRatings.OnServerInvoke = function(player)
	local data = PlayerDataService.GetData(player)
	local ratings = data.Ratings or {}
	local total = 0
	for _, entry in ipairs(ratings) do
		total += entry.stars
	end
	local average = 0
	if #ratings > 0 then
		average = total / #ratings
	end
	return {
		average = average,
		ratings = ratings,
		money = data.Money or 0,
	}
end

Players.PlayerAdded:Connect(function(player)
	PlayerDataService.Load(player)
	getState(player)
end)

Players.PlayerRemoving:Connect(function(player)
	playerState[player] = nil
	CrashService.StopMonitoring(player)
end)
