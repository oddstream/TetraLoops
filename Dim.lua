-- Dim.lua

local Dim = {
  Q = nil,

  W = nil,
  W75 = nil,
  W50 = nil,
  W25 = nil,

  H = nil,
  H75 = nil,
  H50 = nil,
  H25 = nil,

  Q50 = nil,
  Q33 = nil,
  Q20 = nil,
  Q16 = nil,
  Q10 = nil,
  Q8 = nil,

  NORTH = 1,
  EAST = 2,
  SOUTH = 4,
  WEST = 8,

  MASK = 15,

  cellData = nil,
  cellSquare = nil,
}

-- https://www.redblobgames.com/grids/hexagons/
-- when packed, 2 hex occupy 1.5 wide, not 2
-- and in pointy top, 2 vertical occupy 1.75, not 2

function Dim:new(Q)
  local o = {}
  self.__index = self
  setmetatable(o, self)

  o.Q = Q

  o.Q50 = math.floor(Q/2)
  o.Q33 = math.floor(Q/3.333333)
  o.Q20 = math.floor(Q/5)
  o.Q16 = math.floor(Q*0.16)
  o.Q10 = math.floor(Q/10)
  o.Q8 = math.floor(Q*0.08)

  o.cellData = {
    { bit=o.NORTH,  oppBit=o.SOUTH,   link='n',  c2eX=0,      c2eY=-o.Q50, },
    { bit=o.EAST,   oppBit=o.WEST,    link='e',  c2eX=o.Q50,  c2eY=0,    },
    { bit=o.SOUTH,  oppBit=o.NORTH,   link='s',  c2eX=0,      c2eY=o.Q50,  },
    { bit=o.WEST,   oppBit=o.EAST,    link='w',  c2eX=-o.Q50, c2eY=0,    },
  }

  o.cellSquare = {
    -o.Q50, -o.Q50,   -- top left
    o.Q50, -o.Q50,    -- top right
    o.Q50, o.Q50,     -- bottom right
    -o.Q50, o.Q50,    -- bottom left
  }

  return o
end

return Dim