-- Grid (of cells) class

local composer = require('composer')

local Cell = require 'Cell'

local Grid = {
  -- prototype object
  gridGroup = nil,
  shapeGroup = nil,
  cells = nil,    -- array of Cell objects
  width = nil,      -- number of columns
  height = nil,      -- number of rows

  complete = nil,

  tapSound = nil,
  sectionSound = nil,
  lockedSound = nil,
}

function Grid:new(gridGroup, shapesGroup, width, height)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  o.gridGroup = gridGroup
  o.shapesGroup = shapesGroup

  o.cells = {}
  o.width = width
  o.height = height

  for y = 1, height do
    for x = 1, width do
      local c = Cell:new(o, x, y)
      table.insert(o.cells, c) -- push
    end
  end

  o:linkCells2()

  o.complete = false

  o.tapSound = audio.loadSound('sound56.wav')
  o.sectionSound = audio.loadSound('sound63.wav')
  o.lockedSound = audio.loadSound('sound61.wav')

  return o
end

function Grid:reset()
  -- clear out the Cells
  self:iterator(function(c)
    c:reset()
  end)

  do
    local last_using = composer.getVariable('last_using')
    if not last_using then
      last_using = 0
    end
    local before = collectgarbage('count')
    collectgarbage('collect')
    local after = collectgarbage('count')
    print('collected', math.floor(before - after), 'KBytes, using', math.floor(after), 'KBytes', 'leaked', after-last_using)
    composer.setVariable('last_using', after)
  end

  self:newLevel()
end

function Grid:newLevel()
  self:placeCoins()
  self:colorCoins()
  self:jumbleCoins()
  self:createGraphics(0)

  self:fadeIn()

  self.complete = false
end

function Grid:sound(type)
  if type == 'tap' then
    if self.tapSound then audio.play(self.tapSound) end
  elseif type == 'section' then
    if self.sectionSound then audio.play(self.sectionSound) end
  elseif type == 'locked' then
    if self.lockedSound then audio.play(self.lockedSound) end
  end
end

function Grid:linkCells2()
  for _,c in ipairs(self.cells) do
    c.n = self:findCell(c.x, c.y - 1)
    c.e = self:findCell(c.x + 1, c.y)
    c.s = self:findCell(c.x, c.y + 1)
    c.w = self:findCell(c.x - 1, c.y)
  end
end

function Grid:iterator(fn)
  for _,c in ipairs(self.cells) do
    fn(c)
  end
end

function Grid:findCell(x,y)
  for _,c in ipairs(self.cells) do
    if c.x == x and c.y == y then
      return c
    end
  end
  -- print('*** cannot find cell', x, y)
  return nil
end

function Grid:randomCell()
  return self.cells[math.random(#self.cells)]
end

function Grid:createGraphics()
  self:iterator(function(c) c:createGraphics(0) end)
end

function Grid:placeCoins()
  self:iterator(function(c) c:placeCoin() end)
  self:iterator(function(c) c:calcHammingWeight() end)
end

function Grid:colorCoins()
  -- https://en.wikipedia.org/wiki/Web_colors
  local colorsGreen = {
    {0,100,0},  -- DarkGreen
    {85,107,47},  -- DarkOliveGreen
    {107,142,35},  -- OliveDrab
    {139,69,19},  -- SaddleBrown
    {80,80,0},  -- Olive
    {154,205,50},  -- YellowGreen
    {46,139,87}, -- SeaGreen
    {128,128,128},
  }
--[[
  local colorsPink = {
    {255,192,203}, -- Pink
    {255,105,180}, -- HotPink
    {219,112,147}, -- PaleVioletRed
    {255,20,147},  -- DeepPink
    {199,21,133},  -- MediumVioletRed

    {238,130,238}, -- Violet
  }
]]
  local colorsBlue = {
    {25,25,112},
    {65,105,225},
    {30,144,255},
    {135,206,250},
    {176,196,222},
    {0,0,205},
  }
--[[
  local colorsOrange = {
    {255,165,0},
    {255,69,0},
    {255,127,80},
    {255,140,0},
    {255,99,71},
    {128,128,128},
  }
]]
  local colorsGray = {
    {128,128,128},
    {192,192,192},
    {112,128,144},
    {220,220,220},
    {49,79,79},
  }
  local colorsAll = {
    colorsGreen,
    colorsBlue,
    -- colorsOrange,
    -- colorsPink,
    colorsGray,
  }
  local colors = colorsAll[math.random(#colorsAll)]
  for _,row in ipairs(colors) do
    for i = 1,3 do
      row[i] = row[i] * 4 / 1020
    end
  end

  local nColor = 1
  local section = 1
  local c = table.find(self.cells, function(d) return d.coins ~= 0 and d.color == nil end)
  while c do
    c:colorConnected(colors[nColor], section)
    nColor = nColor + 1
    if nColor > #colors then
      nColor = 1
    end
    section = section + 1
    c = table.find(self.cells, function(d) return d.coins ~= 0 and d.color == nil end)
  end
end

function Grid:jumbleCoins()
  self:iterator( function(c) c:jumbleCoin() end )
end

function Grid:isComplete()
  for n = 1, #self.cells do
    if not self.cells[n]:isComplete() then
      return false
    end
  end
  self.complete = true
  return true
end

function Grid:isSectionComplete(section)
  local arr = table.filter(self.cells, function(c) return c.section == section end)
  for n = 1, #arr do
    if not arr[n]:isComplete(section) then
      return false
    end
  end
  for n = 1, #arr do
    arr[n].section = 0  -- lock cell from moving
  end
  return true
end

function Grid:removeSection(section)
  self:iterator( function(c)
    if c.section == section then
      c:fadeOut(function()
        c:reset()
        c:createGraphics()
      end)
    end
  end )
end

function Grid:isRowEmpty(row)
  local c = self:findCell(1,row)
  local coins = 0
  while c do
    coins = coins + c.coins
    c = c.e
  end
  return coins == 0
end

function Grid:rollDown()
  local cRow = self:findCell(1, self.height)
  while cRow.n do
    local c = cRow
    while c do
      c.coins = c.n.coins
      c.bitCount = c.n.bitCount
      c.color = c.n.color
      c.section = c.n.section
      c:createGraphics()
      c.n:reset()
      c = c.e
    end
    cRow = cRow.n
  end
end

function Grid:colorComplete()
  self:iterator( function(c) c:colorComplete() end )
end

function Grid:fadeIn()
  self:iterator( function(c) c:fadeIn() end )
end

function Grid:fadeOut()
  self:iterator( function(c) c:fadeOut() end )
end

function Grid:destroy()
  audio.stop()  -- stop all channels
  if self.sectionSound then
    audio.dispose(self.sectionSound)
    self.sectionSound = nil
  end
  if self.tapSound then
    audio.dispose(self.tapSound)
    self.tapSound = nil
  end
  if self.lockedSound then
    audio.dispose(self.lockedSound)
    self.lockedSound = nil
  end
end

return Grid