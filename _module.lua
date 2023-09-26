local ffi = require 'ffi'
local Module = {}
Module.__index = Module
Module._registeredModules = {}

function Module.register(moduleInfo)
   table.insert(Module._registeredModules, moduleInfo)
end

function Module.instance(name, bufferSize, x, y)
   for _, module in ipairs(Module._registeredModules) do
      if module.name == name then
         local mod = setmetatable(module.create(bufferSize), Module)
         mod._process = module.process
         mod._draw = module.draw
         mod.name = name
         mod.bufferSize = bufferSize
         mod.x, mod.y = x, y
         mod.generation = -1
         mod.inputConnections = {}
         mod.outputConnections = {}
         return mod
      end
   end
   error(string.format('could not find module %q', name))
end

function Module:process(generation)
   if self.generation ~= generation then
      self:_process()
      self.generation = generation
   end
end

function Module:draw()
   love.graphics.push 'all'
   love.graphics.translate(self.x, self.y)
   self:_draw()
   love.graphics.pop()
end

function Module:getStart()
   return self.generation * self.bufferSize
end

function Module:connect(other, otherOutput, input)
   table.insert(self.inputConnections, {other, otherOutput, input})
end

local floatSize = ffi.sizeof 'float'
function Module:receiveInputs(generation)
   assert(generation)
   for i = 1, self:getInputCount() do
      -- zero-fill buffer
      ffi.fill(self:getInput(i).buffer, self.bufferSize * floatSize)
   end
   for _, connection in ipairs(self.inputConnections) do
      connection[1]:process(generation)
      local ibuf = self:getInput(connection[3]).buffer
      local obuf = connection[1]:getOutput(connection[2]).buffer
      for i = 0, self.bufferSize - 1 do
         ibuf[i] = ibuf[i] + obuf[i]
      end
   end
end

function Module:getInput(index)
   return assert(self.inputs[index])
end

function Module:getInputCount()
   return #self.inputs
end

function Module:getOutput(index)
   return assert(self.outputs[index])
end

function Module:getOutputCount()
   return #self.outputs
end

return Module
