
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local OperationExodus = require ("story/operationexodus")
local SectorGenerator = require ("SectorGenerator")
local PirateGenerator = require ("pirategenerator")
local Placer = require("placer")
require("music")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    return 450
end

function SectorTemplate.offgrid(x, y)
    return true
end

-- this function returns whether or not a sector should have space gates
function SectorTemplate.gates(x, y)
    return false
end

-- this function returns how many ships there will be in the sector (from, to)
function SectorTemplate.ships(x, y)
    return 0, 18
end

-- this function returns how many stations there will be in the sector (from, to)
function SectorTemplate.stations(x, y)
    return 0, 0
end

function SectorTemplate.musicTracks()
    local good = {
        primary = combine(TrackCollection.Desolate()),
        secondary = combine(TrackCollection.Melancholic()),
    }

    local neutral = {
        primary = combine(TrackCollection.Desolate()),
        secondary = combine(TrackCollection.Melancholic(), TrackCollection.Middle()),
    }

    local bad = {
        primary = combine(TrackCollection.Middle(), TrackCollection.Desolate()),
        secondary = TrackCollection.Neutral(),
    }

    return good, neutral, bad
end

-- player is the player who triggered the creation of the sector (only set in start sector, otherwise nil)
function SectorTemplate.generate(player, seed, x, y)
    math.randomseed(seed);

    local generator = SectorGenerator(x, y)

    local faction = Galaxy():getNearestFaction(x, y);

    for i = 0, 30 do
        generator:createWreckage(faction);
    end

    if math.random() < 0.3 then
        local numSmallFields = math.random(0, 3)
        for i = 1, numSmallFields do
            generator:createSmallAsteroidField()
        end
    end

    OperationExodus.tryGenerateBeacon(generator)

    local numShips = math.random(3, 8)

    -- skip creating pirates in some cases
    if math.random(1, 4) == 1 then numShips = 0 end

    PirateGenerator.createRaider(generator:getPositionInSector(5000))
    PirateGenerator.createRavager(generator:getPositionInSector(5000))

    for i = 1, numShips do
        PirateGenerator.createMarauder(generator:getPositionInSector(5000))
        PirateGenerator.createBandit(generator:getPositionInSector(5000))
    end

    if math.random() < generator:getWormHoleProbability() then generator:createRandomWormHole() end

    Sector():addScriptOnce("data/scripts/sector/eventscheduler.lua", "events/pirateattack.lua")

    generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate
