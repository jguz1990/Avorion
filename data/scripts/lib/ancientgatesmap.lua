
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local GatesMap = require ("gatesmap")

local AncientGatesMap = {}
AncientGatesMap.__index = AncientGatesMap

local function new(serverSeed)
    local obj = GatesMap(serverSeed)
    obj.range = 150
    obj.range2 = obj.range * obj.range

    obj.hasGates = function(self, x, y)
        local specs = self.specs

        local regular, offgrid, blocked, home = self.specs:determineContent(x, y, self.serverSeed)
        if blocked or (not regular and not offgrid and not home) then return false end

        specs:initialize(x, y, self.serverSeed)

        return specs.ancientGates
    end

    return obj
end


return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})
