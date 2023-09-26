local buffer_new = require 'buffer'.new
local Module = require 'module'

local source
local buffer
local currentGeneration
local lastGeneration

local sampleRate = 48000
local bitDepth = 16
local channelCount = 1
local bufferSize = 1024
local bufferCount = 4

local rootModule

local function nextGeneration()
	currentGeneration = currentGeneration + 1
end

local function registerModules()
	Module.register {
		name = 'sine',
		create = function()
			local mod = {}
			
			mod.pos = 0
			mod.width = 240
			mod.height = 200
			mod.freq = 440
			mod.inputs = {}
			mod.outputs = {}
			
			table.insert(mod.outputs, {
				buffer = buffer_new(bufferSize)
			})
			
			return mod
		end,
		process = function(self)
			local buf = self:getOutput(1).buffer
			for i = 0, self.bufferSize do
				local freq = self.freq
				buf[i] = math.sin(self.pos % 1 * math.pi * 2)
				self.pos = self.pos + freq / sampleRate
			end
		end,
		draw = function(self)
			love.graphics.setColor(0.4, 0.4, 0.4, 1)
			love.graphics.rectangle('fill', 0, 0, self.width, self.height, 12, nil, 32)
		end
	}
	
	Module.register {
		name = 'delay',
		create = function()
			local mod = {}
			
			mod.width = 240
			mod.height = 160
			mod.delay = 0.5
			-- mod.feedback = 0.1
			mod.maxDelay = 1
			mod.delaySamples = lmath.round(mod.maxDelay * sampleRate)
			mod.delayBuffer = buffer_new(mod.delaySamples)
			mod.delayIndex = 0
			mod.inputs = {}
			mod.outputs = {}
			
			table.insert(mod.inputs, {
				buffer = buffer_new(bufferSize),
			})
			
			table.insert(mod.outputs, {
				buffer = buffer_new(bufferSize),
			})
			
			return mod
		end,
		process = function(self)
			self:receiveInputs(currentGeneration)
			local ibuf = self:getInput(1).buffer
			local obuf = self:getOutput(1).buffer
			for i = 0, self.bufferSize - 1 do
				self.delayBuffer[self.delayIndex] = ibuf[i]
				
				local delayOffset = math.min(self.delay, self.maxDelay) / self.maxDelay
				local index = self.delayIndex - (self.delaySamples - 1) * delayOffset
				local index0 = math.floor(index) % self.delaySamples
				local index1 = math.ceil(index) % self.delaySamples
				local fraction = index % 1
				local sample = lmath.lerp(fraction, self.delayBuffer[index0], self.delayBuffer[index1])
				
				obuf[i] = sample
				self.delayIndex = (self.delayIndex + 1) % self.delaySamples
			end
		end,
		draw = function(self)
			love.graphics.setColor(0.4, 0.4, 0.4, 1)
			love.graphics.rectangle('fill', 0, 0, self.width, self.height, 12, nil, 32)
		end
	}
end

function love.load()
	source = love.audio.newQueueableSource(sampleRate, bitDepth, channelCount, bufferCount)
	source:setVolume(0.1)
	buffer = love.sound.newSoundData(bufferSize, sampleRate, bitDepth, channelCount)
	currentGeneration = 0
	lastGeneration = currentGeneration - 1
	registerModules()
	
	local osc = Module.instance('sine', bufferSize, 400, 100)
	rootModule = Module.instance('delay', bufferSize, 100, 100)
	rootModule:connect(osc, 1, 1)
end

local function fillBuffer()
	rootModule:process(currentGeneration)
	for i = 0, bufferSize - 1 do
		buffer:setSample(i, rootModule.outputs[1].buffer[i])
	end
end

function love.update()
	while true do
		if lastGeneration ~= currentGeneration then
			fillBuffer()
			lastGeneration = currentGeneration
		end
		local status = source:queue(buffer)
		if not source:isPlaying() then source:play() end
		if not status then break end
		nextGeneration()
	end
end

function love.draw()
	rootModule:draw()
end

function love.keypressed(key)
	if key == 'f11' or (key == 'return' and love.keyboard.isDown('lalt', 'ralt')) then
		love.window.setFullscreen(not love.window.getFullscreen())
	end
end
