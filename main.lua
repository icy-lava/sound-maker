local Workspace = require 'workspace'

local sampleRate = 48000
local bitDepth = 16
local channelCount = 1
local bufferSize = 1024
local bufferCount = 4

local workspace

function love.load()
	workspace = Workspace(sampleRate, channelCount)
end

function love.keypressed(...)
	local key = ...
	
	if key == 'f11' or (key == 'return' and love.keyboard.isDown('lalt', 'ralt')) then
		love.window.setFullscreen(not love.window.getFullscreen())
		workspace.cam:setDirty()
		return
	end
	
	if key == 'q' and love.keyboard.isDown('lctrl', 'rctrl') then
		love.event.quit()
		return
	end
	
	workspace:keypressed(...)
end

function love.keyreleased(...)
	workspace:keyreleased(...)
end

function love.mousepressed(...)
	workspace:mousepressed(...)
end

function love.mousereleased(...)
	workspace:mousereleased(...)
end

function love.wheelmoved(...)
	workspace:wheelmoved(...)
end

function love.resize(...)
	workspace:resize(...)
end

function love.update(dt)
	workspace:update(dt)
end

function love.draw()
	workspace:draw()
end