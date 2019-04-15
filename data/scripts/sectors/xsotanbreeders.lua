
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorGenerator = require ("SectorGenerator")
local Xsotan = require("story/xsotan")
local Placer = require("placer")
local Balancing = require("galaxy")
require("music")

local SectorTemplate = {}

-- must be defined, will be used to get the probability of this sector
function SectorTemplate.getProbabilityWeight(x, y)
    local d2 = length2(vec2(x, y))

    if d2 < Balancing.BlockRingMin2 then
        return 750
    else
        return 0
    end
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
    return 5, 10
end

-- this function returns how many stations there will be in the sector (from, to)
function SectorTemplate.stations(x, y)
    return 0, 0
end

function SectorTemplate.musicTracks()
    local good = {
        primary = combine(TrackCollection.Desolate(), TrackCollection.Melancholic()),
        secondary = combine(TrackCollection.Melancholic()),
    }

    local neutral = {
        primary = combine(TrackCollection.Desolate(), TrackCollection.Melancholic()),
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

    local numFields = math.random(2, 3)
    for i = 1, numFields do
        local position = generator:createAsteroidField(0.075);
        if math.random() < 0.35 then generator:createBigAsteroid(position) end
    end

    local w = 10
    local h = 15
    for i = 1, w do
        for j = 1, h do
            if math.random() < 0.9 then
                local translation = vec3(j * 70, 0, i * 70)
                local asteroid = Xsotan.createSmallInfectedAsteroid(translation, 2)

                asteroid.orientation = MatrixLookUp(vec3(1, 0, 0), vec3(0, 1, 0))
            end
        end
    end

    for i = 1, h do
        for j = 1, w do
            if math.random() < 0.9 then
                local translation = vec3(j * 70, 0, i * 70) + vec3(500, 500, 350)
                local asteroid = Xsotan.createSmallInfectedAsteroid(translation, 2)

                asteroid.orientation = MatrixLookUp(vec3(1, 0, 0), vec3(0, 1, 0))
            end
        end
    end

    for i = 1, h do
        for j = 1, w do
            if math.random() < 0.9 then
                local translation = vec3(j * 70, 0, i * 70) + vec3(-500, -500, 350)
                local asteroid = Xsotan.createSmallInfectedAsteroid(translation, 2)

                asteroid.orientation = MatrixLookUp(vec3(1, 0, 0), vec3(0, 1, 0))
            end
        end
    end

    local numShips = math.random(5, 10)
    for i = 1, numShips do
        Xsotan.createShip(generator:getPositionInSector(), random():getFloat(0.5, 2.0))
    end

    local numAsteroids = math.random(2, 4)
    for i = 1, numAsteroids do
        Xsotan.createBigInfectedAsteroid(generator:getPositionInSector().pos)
    end

    if math.random() < generator:getWormHoleProbability() then generator:createRandomWormHole() end

    generator:addOffgridAmbientEvents()
    Placer.resolveIntersections()
end

return SectorTemplate
