local Workspace = require 'workspace'
local Module = require 'module'
local Sine = require 'module.sine'
local Output = require 'module.output'

local sampleRate = 48000
local bitDepth = 16
local channelCount = 1
local bufferSize = 1024
local bufferCount = 4

local workspace

function love.load()
	workspace = Workspace(sampleRate, channelCount)
	local modA = Sine(workspace, vec2(600, 50))
	local modB = Sine(workspace, vec2(100, 100))
	local modC = Output(workspace, vec2(1000, 50))
	workspace:addModule(modA)
	workspace:addModule(modB)
	workspace:addModule(modC)
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