-- Camera library using the new Transform features in love2d 11.0+
--
-- Copyright © 2019 Pedro Gimeno Fortea
--
-- You can do whatever you want with this software, under the sole condition
-- that this notice and any copyright notices are preserved. It is offered
-- with no warrany, not even implied.

-- Cache some functions into locals
local newTransform = love.math.newTransform
local replaceTransform, applyTransform, push, pop, getWidth, getHeight
local getScissor, intersectScissor, setScissor
local xfSetXf, xfGetMatrix
do
  local lg = love.graphics
  replaceTransform = lg.replaceTransform
  applyTransform = lg.applyTransform
  push = lg.push
  pop = lg.pop
  getWidth = lg.getWidth
  getHeight = lg.getHeight
  getScissor = lg.getScissor
  intersectScissor = lg.intersectScissor
  setScissor = lg.setScissor
  local Xf = debug.getregistry().Transform
  xfSetXf = Xf.setTransformation
  xfGetMatrix = Xf.getMatrix
end

local Camera = {}
local CameraClassMT = {__call = function (c, ...) return c.new(...) end}
local CameraInstanceMT = {__index = Camera}

local function lazyUpdateXf(self)
  if self.dirty then
    self.dirty = false
    local vp = self.vp
    self.matdirty = true
    self.invmatdirty = true
    return xfSetXf(self.xf,
                   vp[1] + (vp[3] or getWidth()) * vp[5],
                   vp[2] + (vp[4] or getHeight()) * vp[6],
                   self.angle, self.zoom, self.zoom, self.x, self.y)
  end
end

local function lazyUpdateMat(self)
  lazyUpdateXf(self)
  if self.matdirty then
    self.matdirty = false
    local mat = self.mat
    local t
    mat[1], mat[2], t, mat[5], mat[3], mat[4], t, mat[6] = xfGetMatrix(self.xf)
  end
end

local function lazyUpdateInvMat(self)
  lazyUpdateMat(self)
  if self.invmatdirty then
    self.invmatdirty = false
    local imat = self.invmat
    local mat = self.mat
    local a11, a12, a21, a22 = mat[1], mat[2], mat[3], mat[4]
    local det = a11*a22 - a12*a21
    imat[1], imat[2], imat[3], imat[4] = a22/det, a12/-det, a21/-det, a11/det
    imat[5] = mat[5]
    imat[6] = mat[6]
  end
end

function Camera:setDirty(dirty)
  self.dirty = dirty ~= false and true or false
end

function Camera:attach(clip)
  lazyUpdateXf(self)
  push()
  local vp = self.vp
  if clip or clip == nil and (vp[1] ~= 0 or vp[2] ~= 0 or vp[3] or vp[4]) then
    local x, y, w, h = getScissor()
    local scissor = self.scissor
    scissor[1] = x
    scissor[2] = y
    scissor[3] = w
    scissor[4] = h
    intersectScissor(vp[1], vp[2], vp[3] or getWidth(), vp[4] or getHeight())
  end
  return replaceTransform(self.xf)
end

function Camera:detach()
  local scissor = self.scissor
  if scissor[1] ~= false then
    setScissor(scissor[1], scissor[2], scissor[3], scissor[4])
    scissor[1] = false
  end
  return pop()
end

function Camera:setPos(x, y)
  self.dirty = self.x ~= x or self.y ~= y or self.dirty
  self.x = x
  self.y = y
end

function Camera:setZoom(zoom)
  self.dirty = self.zoom ~= zoom or self.dirty
  self.zoom = zoom
end

function Camera:setAngle(angle)
  self.dirty = self.angle ~= angle or self.dirty
  self.angle = angle
end

function Camera:setViewport(x, y, w, h, cx, cy)
  x, y = x or 0, y or 0
  w, h = w or false, h or false
  cx, cy = cx or 0.5, cy or 0.5
  if x ~= self.vp[1] or y ~= self.vp[2] or w ~= self.vp[3] or h ~= self.vp[4]
     or cx ~= self.vp[5] or cy ~= self.vp[6]
  then
    self.dirty = true
  end
  local vp = self.vp
  vp[1] = x
  vp[2] = y
  vp[3] = w
  vp[4] = h
  vp[5] = cx
  vp[6] = cy
end

function Camera:toScreen(x, y)
  lazyUpdateMat(self)
  local mat = self.mat
  return mat[1] * x + mat[2] * y + mat[5], mat[3] * x + mat[4] * y + mat[6]
end

function Camera:toWorld(x, y)
  lazyUpdateInvMat(self)
  local imat = self.invmat
  x = x - imat[5]
  y = y - imat[6]
  return imat[1] * x + imat[2] * y, imat[3] * x + imat[4] * y
end

function Camera:getTransform()
  lazyUpdateXf(self)
  return self.xf
end

function Camera:getPos()
  return self.x, self.y
end

function Camera:getX()
  return self.x
end

function Camera:getY()
  return self.y
end

function Camera:getZoom()
  return self.zoom
end

function Camera:getAngle()
  return self.angle
end

function Camera:getViewport()
  local vp = self.vp
  return vp[1], vp[2], vp[3], vp[4], vp[5], vp[6]
end

function Camera:getVPTopLeft()
  local vp = self.vp
  return vp[1], vp[2]
end

function Camera:getVPBottomRight()
  local vp = self.vp
  return vp[1] + (vp[3] or getWidth()), vp[2] + (vp[4] or getHeight())
end

function Camera:getVPFocusPoint()
  local vp = self.vp
  return vp[1] + (vp[3] or getWidth()) * vp[5],
         vp[2] + (vp[4] or getHeight()) * vp[6]
end

function Camera.new(x, y, zoom, angle, vpx, vpy, vpw, vph, cx, cy)
  vpx, vpy = vpx or 0, vpy or 0
  vpw, vph = vpw or false, vph or false
  cx, cy = cx or 0.5, cy or 0.5
  local self = {
    x = x or 0;
    y = y or 0;
    zoom = zoom or 1;
    angle = angle or 0;
    vp = {vpx, vpy, vpw, vph, cx, cy};
    xf = newTransform();
    dirty = true;
    matdirty = true;
    invmatdirty = true;
    scissor = {false,false,false,false};
    mat = {0, 0, 0, 0, 0, 0};
    invmat = {0, 0, 0, 0, 0, 0};
  }
  return setmetatable(self, CameraInstanceMT)
end

return setmetatable(Camera, CameraClassMT)
