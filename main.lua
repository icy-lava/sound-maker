local Workspace = require 'workspace'
local Module = require 'module'

local sampleRate = 48000
local bitDepth = 16
local channelCount = 1
local bufferSize = 1024
local bufferCount = 4

local workspace

function love.load()
	workspace = Workspace(sampleRate, channelCount)
	local modA = Module(vec2(600, 50))
	local modB = Module(vec2(100, 100))
	modA:connect(modB, 1, 1)
	
	workspace:addModule(modA)
	workspace:addModule(modB)
end

function love.keypressed(...)
	local key = ...
	
	if key == 'f11' or (key == 'return' and love.keyboard.isDown('lalt', 'ralt')) then
		love.window.setFullscreen(not love.window.getFullscreen())
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

function love.update(dt)
	workspace:update(dt)
end

function love.draw()
	workspace:draw()
end