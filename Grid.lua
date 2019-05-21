-- Grid (of cells) class

local composer = require('composer')

local Cell = require 'Cell'

local Grid = {
  -- prototype object
  group = nil,
  cells = nil,    -- array of Cell objects
  width = nil,      -- number of columns
  height = nil,      -- number of rows

  tapSound = nil,
  sectionSound = nil,
  lockedSound = nil,

  gameState = nil,
  levelText = nil,
}

function Grid:new(group, width, height)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  o.group = group

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

  -- o.tapSound = audio.loadSound('sound56.wav')
  -- o.sectionSound = audio.loadSound('sound63.wav')
  -- o.lockedSound = audio.loadSound('sound61.wav')

  o.levelText = display.newText({
    parent=group,
    text='',
    x=display.contentCenterX,
    y=display.contentCenterY,
    font=native.systemFontBold,
    fontSize=512})
  o.levelText:setFillColor(0.1,0.1,0.1)

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
  self:createGraphics()

  self.levelText.text = tostring(self.gameState.level)

  self:fadeIn()
end

function Grid:advanceLevel()
  assert(self.gameState)
  assert(self.gameState.level)
  self.gameState.level = self.gameState.level + 1
  self.levelText.text = tostring(self.gameState.level)
  self.gameState:write()
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

  local colorsPink = {
    {255,192,203}, -- Pink
    {255,105,180}, -- HotPink
    {219,112,147}, -- PaleVioletRed
    {255,20,147},  -- DeepPink
    {199,21,133},  -- MediumVioletRed

    {238,130,238}, -- Violet
  }

  local colorsBlue = {
    {25,25,112},
    {65,105,225},
    {30,144,255},
    {135,206,250},
    {176,196,222},
    {0,0,205},
  }

  local colorsOrange = {
    {255,165,0},
    {255,69,0},
    {255,127,80},
    {255,140,0},
    {255,99,71},
    {128,128,128},
  }

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
    colorsOrange,
    colorsPink,
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
  return table.find(self.cells, function(c) return c.coins ~= 0 end) == nil
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
  -- print('remove section', section)
  self:iterator( function(c)
    if c.section == section then
      c:fadeOut()
      timer.performWithDelay(1000, function() c:reset() end, 1)
    end
  end )
end

function Grid:fadeIn()
  self:iterator( function(c) c:fadeIn() end )
end

-- function Grid:fadeOut()
--   self:iterator( function(c) c:fadeOut() end )
-- end

function Grid:destroy()
  local nStopped = audio.stop()  -- stop all channels
  print('audio stop', nStopped)

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