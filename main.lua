-- main.lua

-- require 'Strict'

local composer = require 'composer'

print(_VERSION)
print('origin', display.screenOriginX, display.screenOriginY)
print('content', display.contentWidth, display.contentHeight)
print('pixels', display.pixelWidth, display.pixelHeight)
print('actual content', display.actualContentWidth, display.actualContentHeight)
print('viewable content', display.viewableContentWidth, display.viewableContentHeight)

print('maxTextureSize', system.getInfo('maxTextureSize'))

print('model', system.getInfo('model'))
print('environment', system.getInfo('environment'))

native.setProperty('windowTitleText', 'Tetra Loops') -- Win32

math.randomseed(os.time())

-- our one global, an object containing useful precalculated dimensions
dimensions = {}

-- for k,v in pairs( _G ) do
--   print( k , v )
-- end

if not table.find then
  function table.find(tbl, fn)
    for _,v in ipairs(tbl) do
      if fn(v) then
        return v
      end
    end
    return nil
  end
end
print('table find', type(table.find))

if not table.filter then
  table.filter = function(t, filterIter)
    local out = {}

    for k, v in pairs(t) do
      if filterIter(v, k, t) then table.insert(out, v) end
    end

    return out
  end
end
print('table filter', type(table.filter))

--[[
if not table.copy then
  function table.copy(t) -- shallow-copy a table
    if type(t) ~= 'table' then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do target[k] = v end
    setmetatable(target, meta)
    return target
  end
end
print('table copy', type(table.copy))
]]

--[[
if not table.clone then
  function table.clone(t) -- deep-copy a table
    if type(t) ~= 'table' then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do 
      if type(v) == 'table' then
        target[k] = table.clone(v)
      else
        target[k] = v
      end
    end
    setmetatable(target, meta)
    return target
  end
end
print('table clone', type(table.clone))
]]

composer.gotoScene('Splash', {effect='fade', params={scene='Tetra'}})
