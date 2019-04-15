package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = require ("SectorGenerator")
local Placer = require("placer")
require("music")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    return 300
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
    return 0, 0
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

    local numFields = math.random(0, 2)
    for i = 1, numFields do
        generator:createAsteroidField();
    end

    local numFields = math.random(2, 5)
    for i = 1, 5 - numFields do
        generator:createEmptyAsteroidField();
    end

    local stations =
    {
        "data/scripts/entity/merchants/resourcetrader.lua",
        "data/scripts/entity/merchants/shipyard.lua",
        "data/scripts/entity/merchants/repairdock.lua",
        "data/scripts/entity/merchants/tradingpost.lua",
        "data/scripts/entity/merchants/basefactory.lua",
        "data/scripts/entity/merchants/lowfactory.lua",
        "data/scripts/entity/merchants/midfactory.lua",
        "data/scripts/entity/merchants/highfactory.lua"
    }

    local probabilities = {}
    for i, v in ipairs(stations) do
        probabilities[i] = 1
    end

    local script = stations[selectByWeight(random(), probabilities)]

    local faction = Galaxy():getNearestFaction(x, y)
    local station = generator:createStation(faction, script);

    -- remove backup script so there won't be any additional ships
    for i, script in pairs(station:getScripts()) do
        if string.match(script, "backup") then
            station:removeScript(script) -- don't spawn military ships coming for help
        end
    end

    -- clear cargo bay so goods are not leaked when changing the plan
    station:clearCargoBay()

    local blockPlan = Plan(station.id):getMove()
    generator:createWreckage(faction, blockPlan, 10)

    if math.random() < generator:getWormHoleProbability() then generator:createRandomWormHole() end

    local sector = Sector()
    sector:deleteEntity(station)

    sector:addScriptOnce("data/scripts/sector/eventscheduler.lua", "events/pirateattack.lua")

    Placer.resolveIntersections()
end

return SectorTemplate
