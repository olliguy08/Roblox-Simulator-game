local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local CrashService = {}

local DeveloperMode = false

local monitors = {}

local function debugPrint(...)
	if DeveloperMode then
		print("[CrashService]", ...)
	end
end

function CrashService.SetDeveloperMode(enabled)
	DeveloperMode = enabled and true or false
end

local function isInDeliveryVehicle(player)
	local character = player.Character
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	local seatPart = humanoid.SeatPart
	if not seatPart then
		return false
	end
	local vehicle = seatPart:FindFirstAncestorWhichIsA("Model")
	if not vehicle then
		return false
	end
	return CollectionService:HasTag(vehicle, "DeliveryVehicle")
end

local function getVelocity(player)
	local character = player.Character
	if not character then
		return Vector3.zero
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return Vector3.zero
	end
	return root.AssemblyLinearVelocity
end

function CrashService.StartMonitoring(player, onDamage)
	if monitors[player] then
		return
	end

	local lastVelocity = getVelocity(player)
	local connection
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not player.Parent then
			return
		end
		if not isInDeliveryVehicle(player) then
			lastVelocity = getVelocity(player)
			return
		end

		local velocity = getVelocity(player)
		local deltaSpeed = (velocity - lastVelocity).Magnitude
		lastVelocity = velocity

		if deltaTime > 0.2 then
			return
		end

		if deltaSpeed >= 40 then
			local damage = math.clamp((deltaSpeed - 30) * 0.4, 5, 25)
			debugPrint(player.Name, "crash damage", damage)
			onDamage(damage)
		end
	end)

	monitors[player] = connection
end

function CrashService.StopMonitoring(player)
	local connection = monitors[player]
	if connection then
		connection:Disconnect()
	end
	monitors[player] = nil
end

return CrashService
