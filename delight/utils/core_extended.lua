local core = {}

-- Function to hash all values in a table
function core.hash(table)
	local hashedTable = {}
	for key, value in pairs(table) do
		if type(value) == "table" then
			hashedTable[key] = core.hash(value)
		elseif type(value) ~= "userdata" then
			hashedTable[key] = hash(value)
		else
			hashedTable[key] = value
		end
	end
	return hashedTable
end

function core.newtable(defvalue, length)
	t = {}
	for i = 1, length, 1 do
		t[i] = defvalue
	end
	return t
end

function core.tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

return core