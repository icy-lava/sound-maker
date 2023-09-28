local vec2 = require 'lithium.vec2'
local aabb2 = {}

setmetatable(aabb2, {__call = function(_, ...) return aabb2.new(...) end})

function aabb2.new(left, right, top, bottom)
	assert(left and right and top and bottom)
	return setmetatable({x1 = left, x2 = right, y1 = top, y2 = bottom}, aabb2):_fix()
end

function aabb2.fromPoint(point)
	return setmetatable({x1 = point.x, x2 = point.x, y1 = point.y, y2 = point.y}, aabb2)
end

function aabb2:_fix()
	if self.x1 > self.x2 then
		local mid = (self.x1 + self.x2) / 2
		self.x1, self.x2 = mid, mid
	end
	if self.y1 > self.y2 then
		local mid = (self.y1 + self.y2) / 2
		self.y1, self.y2 = mid, mid
	end
	return self
end

function aabb2:pad(amount)
	self.x1 = self.x1 - amount
	self.x2 = self.x2 + amount
	self.y1 = self.y1 - amount
	self.y2 = self.y2 + amount
	return self:_fix()
end

function aabb2:padLeft(amount)
	self.x1 = self.x1 - amount
	return self:_fix()
end

function aabb2:padRight(amount)
	self.x2 = self.x2 + amount
	return self:_fix()
end

function aabb2:padTop(amount)
	self.y1 = self.y1 - amount
	return self:_fix()
end

function aabb2:padBottom(amount)
	self.y2 = self.y2 + amount
	return self:_fix()
end

function aabb2:padWidth(amount)
	self.x1 = self.x1 - amount
	self.x2 = self.x2 + amount
	return self:_fix()
end

function aabb2:padHeight(amount)
	self.y1 = self.y1 - amount
	self.y2 = self.y2 + amount
	return self:_fix()
end

function aabb2:getCenterX()
	return (self.x1 + self.x2) / 2
end

function aabb2:getCenterY()
	return (self.y1 + self.y2) / 2
end

function aabb2:getCenter()
	return vec2.new(self:getCenterX(), self:getCenterY())
end

function aabb2:setWidth(width)
	local mid = self:getCenterX()
	half = math.max(0, width) / 2
	self.x1, self.x2 = mid - half, mid + half
	return self
end

function aabb2:setHeight(height)
	local mid = self:getCenterY()
	half = math.max(0, height) / 2
	self.y1, self.y2 = mid - half, mid + half
	return self
end

function aabb2:setDimensions(width, height)
	local x, y = self:getCenterX(), self:getCenterY()
	halfWidth, halfHeight = math.max(0, width) / 2, math.max(0, height) / 2
	self.x1, self.x2, self.y1, self.y2 = mid - halfWidth, mid + halfWidth, mid - halfHeight, mid + halfHeight
	return self
end

function aabb2:drawRectangle(roundX, roundY, precision)
	local width, height = self.x2 - self.x1, self.y2 - self.y1
	love.graphics.rectangle('fill', self.x1, self.y1, width, height, roundX, roundY, precision)
	return self
end

function aabb2:drawLine(lwidth, roundX, roundY, precision)
	lwidth = lwidth or 1
	local width, height = self.x2 - self.x1, self.y2 - self.y1
	love.graphics.push 'all'
	love.graphics.setLineWidth(lwidth)
	love.graphics.rectangle('line', self.x1, self.y1, width, height, roundX, roundY, precision)
	love.graphics.pop()
	return self
end

return aabb2