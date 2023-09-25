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

return Module
