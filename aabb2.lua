local vec2 = require 'lithium.vec2'
local aabb2 = {}

setmetatable(aabb2, {__call = function(_, ...) return aabb2.new(...) end})

function aabb2.new(left, right, top, bottom)
	assert(left and right and top and bottom)
	return setmetatable({x1 = left, x2 = right, y1 = top, y2 = bottom}, aabb2)
end

function aabb2.fromPoint(point)
	return setmetatable({x1 = point.x, x2 = point.x, y1 = point.y, y2 = point.y}, aabb2)
end

function aabb2.fromLove()
	local width, height = love.graphics.getDimensions()
	return aabb2.new(0, width, 0, height)
end

function aabb2:vbox(bboxes, align, round)
	align = align or 0.5
	local shouldRound = false
	if round then
		shouldRound = true
		if type(round) ~= 'number' then round = 1 end
	end
	local awidth, aheight = self:getDimensions()
	local spacing = aheight
	local count = #bboxes
	assert(count >= 2) -- TODO: allow 1 element as well
	for i = 1, count do
		spacing = spacing - bboxes[i]:getHeight()
	end
	spacing = spacing / (count - 1)
	local i = 0
	local y = self.y1
	return function()
		i = i + 1
		local bbox = bboxes[i]
		if bbox == nil then
			return nil
		end
		local width, height = bbox:getDimensions()
		local x1 = self.x1 + align * (awidth - width)
		local x2 = x1 + width
		local y1 = y
		local y2 = y1 + height
		y = y + height + spacing
		if shouldRound then
			x1 = lmath.roundStep(x1, round)
			x2 = lmath.roundStep(x2, round)
			y1 = lmath.roundStep(y1, round)
			y2 = lmath.roundStep(y2, round)
		end
		return i, aabb2.new(x1, x2, y1, y2)
	end
end

function aabb2:fix()
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
	return self
end

function aabb2:padLeft(amount)
	self.x1 = self.x1 - amount
	return self
end

function aabb2:padRight(amount)
	self.x2 = self.x2 + amount
	return self
end

function aabb2:padTop(amount)
	self.y1 = self.y1 - amount
	return self
end

function aabb2:padBottom(amount)
	self.y2 = self.y2 + amount
	return self
end

function aabb2:padHorizontal(amount)
	self.x1 = self.x1 - amount
	self.x2 = self.x2 + amount
	return self
end

function aabb2:padVertical(amount)
	self.y1 = self.y1 - amount
	self.y2 = self.y2 + amount
	return self
end

function aabb2:getPosition()
	return self.x1, self.y1
end

function aabb2:setPosition(x, y)
	local dx, dy = x - self.x1, y - self.y1
	self.x1, self.x2 = x, self.x2 + dx
	self.y1, self.y2 = y, self.y2 + dy
	return self
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
	local half = math.max(0, width) / 2
	self.x1, self.x2 = mid - half, mid + half
	return self
end

function aabb2:getHeight()
	return self.y2 - self.y1
end

function aabb2:setHeight(height)
	local mid = self:getCenterY()
	local half = math.max(0, height) / 2
	self.y1, self.y2 = mid - half, mid + half
	return self
end

function aabb2:getDimensions()
	return self.x2 - self.x1, self.y2 - self.y1
end

function aabb2:setDimensions(width, height)
	local x, y = self:getCenterX(), self:getCenterY()
	local halfWidth, halfHeight = math.max(0, width) / 2, math.max(0, height) / 2
	self.x1, self.x2, self.y1, self.y2 = x - halfWidth, x + halfWidth, y - halfHeight, y + halfHeight
	return self
end

function aabb2:hasPoint(point)
	return point.x >= self.x1 and point.x < self.x2 and point.y >= self.y1 and point.y < self.y2
end

function aabb2:drawText(text, align, round)
	align = align or {x = 0.5, y = 0.5}
	local font = love.graphics.getFont()
	local twidth, theight = font:getWidth(text), font:getHeight()
	local bwidth, bheight = self:getDimensions()
	local x, y = (bwidth - twidth) * align.x, (bheight - theight) * align.y
	if round then
		if type(round) ~= 'number' then round = 1 end
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
	copy = aabb2.getCopy,
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