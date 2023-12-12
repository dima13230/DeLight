local math_ex = {}

function math_ex.distance(pos1, pos2)
	return math.sqrt(math.pow(pos2.x - pos1.x, 2) + math.pow(pos2.y - pos1.y, 2))
end

function math_ex.clamp(min, max, value)
	if value < min then
		return min
	elseif value > max then
		return max
	end
	
	return value
end

function math_ex.lerp(start, stop, t)
	return (1 - t) * start + t * stop;
end

function math_ex.logarithmic_smooth(currentValue, targetValue, smoothingFactor)
	local diff = targetValue - currentValue
	return currentValue + (diff * smoothingFactor)
end

function math_ex.random_float(lower, greater)
	return lower + math.random()  * (greater - lower);
end


return math_ex