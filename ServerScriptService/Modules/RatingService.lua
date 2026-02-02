local RatingService = {}

local DeveloperMode = false

local function debugPrint(...)
	if DeveloperMode then
		print("[RatingService]", ...)
	end
end

function RatingService.SetDeveloperMode(enabled)
	DeveloperMode = enabled and true or false
end

local function clamp(value, minValue, maxValue)
	return math.max(minValue, math.min(maxValue, value))
end

local function computeTipMultiplier(timeTaken, maxTime, condition)
	local timeRatio = timeTaken / maxTime
	local timeScore
	if timeRatio <= 0.7 then
		timeScore = 1.0
	elseif timeRatio <= 1.0 then
		timeScore = 0.7
	else
		timeScore = 0.3
	end

	local conditionScore = clamp(condition / 100, 0, 1)
	return clamp((timeScore * 0.6) + (conditionScore * 0.4), 0.1, 1.2)
end

local function computeStars(timeTaken, maxTime, condition)
	local timeRatio = timeTaken / maxTime
	local conditionRatio = clamp(condition / 100, 0, 1)
	local score = (1 - math.min(timeRatio, 1.5) / 1.5) * 0.6 + conditionRatio * 0.4
	local stars = math.floor(clamp(score * 5, 1, 5) + 0.5)
	return clamp(stars, 1, 5)
end

local function buildComment(timeTaken, maxTime, condition)
	local timeRatio = timeTaken / maxTime
	local conditionRatio = clamp(condition / 100, 0, 1)

	if timeRatio > 1 then
		if conditionRatio < 0.5 then
			return "Late and the food was a mess."
		end
		return "Late delivery, but the food was still okay."
	end

	if conditionRatio >= 0.85 then
		return "Fast delivery and the food was perfect!"
	elseif conditionRatio >= 0.6 then
		return "On time and the food was mostly fine."
	else
		return "On time, but the food was pretty banged up."
	end
end

function RatingService.CalculateResults(jobData)
	local timeTaken = math.max(0, jobData.timeTaken or 0)
	local maxTime = jobData.maxTime or 60
	local condition = jobData.condition or 100
	local basePay = jobData.basePay or 0

	local tipMultiplier = computeTipMultiplier(timeTaken, maxTime, condition)
	local tip = math.floor(basePay * tipMultiplier * 0.4)
	local payout = basePay + tip
	local stars = computeStars(timeTaken, maxTime, condition)
	local comment = buildComment(timeTaken, maxTime, condition)

	debugPrint("Results", payout, stars, comment)

	return {
		payout = payout,
		tip = tip,
		stars = stars,
		comment = comment,
		condition = condition,
		timeTaken = timeTaken,
		maxTime = maxTime,
	}
end

return RatingService
