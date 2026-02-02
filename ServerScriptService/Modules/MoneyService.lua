local MoneyService = {}

local DeveloperMode = false

local function debugPrint(...)
	if DeveloperMode then
		print("[MoneyService]", ...)
	end
end

function MoneyService.SetDeveloperMode(enabled)
	DeveloperMode = enabled and true or false
end

function MoneyService.AddMoney(player, amount, dataService)
	if not player or not amount then
		return
	end
	local data = dataService:GetData(player)
	data.Money = (data.Money or 0) + amount
	debugPrint(player.Name, "earned", amount, "total", data.Money)
end

function MoneyService.GetMoney(player, dataService)
	local data = dataService:GetData(player)
	return data.Money or 0
end

return MoneyService
