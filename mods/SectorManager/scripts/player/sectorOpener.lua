if onServer() then
package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")
require ("utility")

local lib = require ("mods/SectorManager/scripts/lib/sectorManagerLib")
local config = require ("mods/SectorManager/config/SectorManagerConfig")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace sectorOpener
sectorOpener = {}


local updateTime = 0

-- const
local PLAYER = Player()
local STORAGESTRING = "loadedSectorList"
local TIMEBETWEENREFRESH = 5
local TIMETOKEEP = 300

function sectorOpener.initialize()

end

function sectorOpener.getUpdateInterval()
    return 1
end

function sectorOpener.updateServer(timestep)
    updateTime = updateTime + timestep
    if updateTime > TIMEBETWEENREFRESH then  --  refreshing keepSector every 5s, because it unloads sectors every 15s (unaffected by TIMETOKEEP)
        updateTime = 0
        local l = lib.stringToSectorList(PLAYER:getValue(STORAGESTRING))
        local count = config.maxSectorPerPlayer
        for _,s in ipairs(l) do
            count = count - 1
            if not Galaxy():sectorLoaded(s.x, s.y) then
                Galaxy():loadSector(s.x, s.y)
            else
                Galaxy():keepSector(s.x, s.y, TIMETOKEEP)
            end
            if count < 1 then break end
        end
    end
end

end
