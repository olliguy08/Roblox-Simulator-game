local CollectionService = game:GetService("CollectionService")

local JobGenerator = {}

local DeveloperMode = false

local DISHES = {
	"Sushi Roll",
	"Pepperoni Pizza",
	"Veggie Bowl",
	"Spicy Ramen",
	"Burger Combo",
	"Taco Plate",
	"Pasta Alfredo",
	"Chicken Wings",
	"Salad Box",
	"Curry Rice",
}

local function debugPrint(...)
	if DeveloperMode then
		print("[JobGenerator]", ...)
	end
end

function JobGenerator.SetDeveloperMode(enabled)
	DeveloperMode = enabled and true or false
end

local function getTaggedParts(tagName)
	local tagged = CollectionService:GetTagged(tagName)
	local results = {}
	for _, instance in ipairs(tagged) do
		if instance:IsA("BasePart") then
			table.insert(results, instance)
		end
	end
	return results
end

local function chooseRandom(list)
	return list[math.random(1, #list)]
end

local function generateDishes()
	local count = math.random(1, 3)
	local dishes = {}
	for _ = 1, count do
		table.insert(dishes, chooseRandom(DISHES))
	end
	return dishes
end

local function estimateDistance(a, b)
	return (a - b).Magnitude
end

local function estimateTimeLimit(distance)
	local base = math.clamp(distance / 6, 40, 160)
	return math.floor(base + math.random(10, 25))
end

function JobGenerator.GenerateOffers()
	local restaurants = getTaggedParts("Restaurant")
	local customers = getTaggedParts("Customer")

	if #restaurants == 0 or #customers == 0 then
		debugPrint("Missing tagged Restaurant/Customer parts.")
		return {}
	end

	local offers = {}
	for index = 1, 3 do
		local restaurant = chooseRandom(restaurants)
		local customer = chooseRandom(customers)
		local distance = estimateDistance(restaurant.Position, customer.Position)
		local pay = math.floor(25 + (distance * 0.35))
		table.insert(offers, {
			id = index,
			restaurant = restaurant,
			customer = customer,
			restaurantName = restaurant.Name,
			customerName = customer.Name,
			dishes = generateDishes(),
			basePay = pay,
			estimatedDistance = math.floor(distance),
			maxTime = estimateTimeLimit(distance),
		})
	end

	debugPrint("Generated offers:", #offers)
	return offers
end

return JobGenerator
