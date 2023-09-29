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

function aabb2.fromLove()
	local width, height = love.graphics.getDimensions()
	return aabb2.new(0, width, 0, height)
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

function aabb2:getWidth()
	return self.x2 - self.x1
end

function aabb2:setWidth(width)
	local mid = self:getCenterX()
	half = math.max(0, width) / 2
	self.x1, self.x2 = mid - half, mid + half
	return self
end

function aabb2:getHeight()
	return self.y2 - self.y1
end

function aabb2:setHeight(height)
	local mid = self:getCenterY()
	half = math.max(0, height) / 2
	self.y1, self.y2 = mid - half, mid + half
	return self
end

function aabb2:getDimensions()
	return self.x2 - self.x1, self.y2 - self.y1
end

function aabb2:setDimensions(width, height)
	local x, y = self:getCenterX(), self:getCenterY()
	halfWidth, halfHeight = math.max(0, width) / 2, math.max(0, height) / 2
	self.x1, self.x2, self.y1, self.y2 = mid - halfWidth, mid + halfWidth, mid - halfHeight, mid + halfHeight
	return self
end

function aabb2:hasPoint(point)
	return point.x >= self.x1 and point.x < self.x2 and point.y >= self.y1 and point.y < self.y2
end

function aabb2:drawText(text, align, round)
	align = align or {x = 0.5, y = 0.5}
	font = love.graphics.getFont()
	local twidth, theight = font:getWidth(text), font:getHeight()
	local bwidth, bheight = self:getDimensions()
	local x, y = (bwidth - twidth) * align.x, (bheight - theight) * align.y
	if round then
		if type(round) ~= number then round = 1 end
		x = lmath.roundStep(self.x1 + x, round)
		y = lmath.roundStep(self.y1 + y, round)
	end
	love.graphics.print(text, x, y)
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

function aabb2:getCopy()
	return aabb2.new(self.x1, self.x2, self.y1, self.y2)
end

local getters = {
	copy = vec2.getCopy,
}

function aabb2:__index(key)
	local field = aabb2[key]
	if field ~= nil then
		return field
	end
	local getter = getters[key]
	if getter then
		return getter(self)
	end
	return nil
end

return aabb2