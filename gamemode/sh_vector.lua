local meta = FindMetaTable("Vector")
if not meta then return end

local math = math
local math_sqrt = math.sqrt

function meta:DistanceZSkew(vec, skew)
	return math_sqrt((self.x - vec.x) ^ 2 + (self.y - vec.y) ^ 2 + ((self.z - vec.z) * skew) ^ 2)
end

function meta:__pow(len)
	self:Normalize()
	if len == 1 then
		return self
	end

	self.x = self.x * len
	self.y = self.y * len
	self.z = self.z * len

	return self
end

function meta:__mod(z)
	self.z = self.z + z
	return self
end

function meta:__len()
	return self:Length()
end