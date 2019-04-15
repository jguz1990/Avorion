
if not onClient() then return end -- purely client sided script

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

local SectorSpecifics = require("sectorspecifics")
require("stringutility")
require("galaxy")
require("utility")
require("music")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace MusicCoordinator
MusicCoordinator = {}
local self = MusicCoordinator

local function make_set(array)
    array = array or {}
    local set = {}

    for _, element in pairs(array) do
        set[element] = true
    end

    return set
end


function MusicCoordinator.initialize()
    Player():registerCallback("onSectorChanged", "onSectorChanged")
end

function MusicCoordinator.onSectorChanged(x, y)
    -- Override cases:
    -- Empty Sector / No Tracks -> neutral tracks
    -- Home Sector -> particle & happy tracks
    -- Everything destroyed -> desolate tracks
    -- Sector rebuilt -> happy/populated tracks
    -- Inside Ring -> mostly desolate + threatening

    local inside = Balancing_InsideRing(x, y)

    local primary = {}
    local secondary = {}

    local specs = SectorSpecifics()
    specs:initialize(x, y, Seed(GameSettings().seed))

    -- check relations to faction controlling this sector
    local relation = 0
    local controllingIndex = Galaxy():getControllingFaction(x, y)

    if controllingIndex then
        local faction = Galaxy():getPlayerCraftFaction()
        relation = faction:getRelations(controllingIndex)
    end

    local expectedStations = 0

    if specs.generationTemplate and specs.generationTemplate.musicTracks then
        local good, neutral, bad = specs.generationTemplate.musicTracks()

        print ("music of " .. specs.generationTemplate.path)

        if type(good) ~= "table" then good = {} end
        if type(neutral) ~= "table" then neutral = {} end
        if type(bad) ~= "table" then bad = {} end

        -- choose good, neutral, bad based on relations to current faction
        local chosen = nil

        if relation > 30000 then
            chosen = good
            print ("selected good relations")
        elseif relation < -20000 then
            chosen = bad
            print ("selected bad relations")
        else
            chosen = neutral
            print ("selected neutral ")
        end

        primary = chosen.primary
        secondary = chosen.secondary

        -- check if stations/ships are supposed to be there
        expectedStations, _ = specs.generationTemplate.stations(x, y)
        expectedStations = expectedStations or 0

        -- if yes, check if they're still there
        if expectedStations > 0 then
            local station = Sector():getEntitiesByType(EntityType.Station)

            -- if no longer there, add desolate/melancholic/wreckage field tracks
            if not station then
                print ("sector was destroyed, play desolate + sad music")
                primary = combine(TrackCollection.Desolate(), TrackCollection.Melancholic())
                secondary = {}
            end
        end
    end

    -- no music specified by template or anything else, play neutral songs
    if tablelength(primary) == 0 and tablelength(secondary) == 0 then
        print ("nothing specified, playing unknown songs")

        -- if there are tons of wreckages & no stations, play desolate music
        local stations = Sector():getNumEntitiesByType(EntityType.Station)
        local wreckages = Sector():getNumEntitiesByType(EntityType.Wreckage)
        local asteroids = Sector():getNumEntitiesByType(EntityType.Asteroid)
        local ships = Sector():getNumEntitiesByType(EntityType.Ship)

        if stations == 0 and wreckages > asteroids / 10 and wreckages > ships then
            primary = combine(TrackCollection.Desolate(), TrackCollection.Melancholic())
            secondary = {}
        else
            primary = TrackCollection.Neutral()
            secondary = TrackCollection.All()
        end

    end

    primary = make_set(primary)
    secondary = make_set(secondary)

    -- check if it's inside the ring and adjust tracks
    if inside then
        print ("modifying because we're inside the ring")

        -- remove too happy tracks
        local toRemove = {TrackType.Particle, TrackType.BlindingNebula, TrackType.Exhale, TrackType.InSight, TrackType.LightDance}

        -- add a few desolate ones
        local toAdd = {TrackType.Befog, TrackType.LongForgotten, TrackType.Impact, TrackType.Found, }

        for _, type in pairs(toRemove) do
            primary[type] = nil
            secondary[type] = nil
        end

        for _, type in pairs(toAdd) do
            primary[type] = true
            secondary[type] = true
        end
    end

    -- check if there are stations (ie. if sector was (re)built) and add matching tracks,
    -- remove too desolate/depressing tracks
    if not expectedStations or expectedStations == 0 then
        local actualStations = #{Sector():getEntitiesByType(EntityType.Station)}
        if actualStations >= 2 then

            print ("modifying because we're in a rebuilt sector")

            -- remove too desolate tracks, but only if no bad relations
            local toRemove = {}
            if relation > -20000 then
                toRemove = {TrackType.Befog, TrackType.LongForgotten, TrackType.Impact, TrackType.Found, }
            end

            -- add a few happy ones
            local toAdd = {TrackType.BlindingNebula, TrackType.InSight, TrackType.LightDance}

            for _, type in pairs(toRemove) do
                primary[type] = nil
                secondary[type] = nil
            end

            for _, type in pairs(toAdd) do
                primary[type] = true
                secondary[type] = true
            end

        end
    end


    -- check if it's the player's home sector and set primary list to particle & light dance only
    local hx, hy = Player():getHomeSectorCoordinates()
    if hx == x and hy == y then
        primary = {}
        primary[TrackType.Particle] = true
        primary[TrackType.LightDance] = true
    end

    -- clean up a little, everything in primary is implicitly in secondary
    for id, _ in pairs(primary) do
        secondary[id] = nil
    end

    -- actually set the tracks for playing
    local ptracks = {}
    local stracks = {}

    for id, _ in pairs(primary) do
        table.insert(ptracks, Tracks[id].path)
    end

    for id, _ in pairs(secondary) do
        table.insert(stracks, Tracks[id].path)
    end

    Music():setAmbientTrackLists(ptracks, stracks)

end




--[[

Title
 -> Variation von "Float" die ab etwa 2:25 beginnt

TrackType.Particle
 Verspielt
 Niedlich
 Weit
 Fröhlich
 Herzlich
 -> Startsektor, sehr beliebte Verbündete

TrackType.BlindingNebula
 Kalt
 Weit
 Verspielt
 Herzlich
 Neugierig
 -> Neutral, Erkunden, passt zu fliegen
 -> Neutraler, bis freundlicher Allrounder

TrackType.Exhale
 Freundlich
 Geborgen
 Weit
 -> Freundlich, Neutral, Allrounder

TrackType.Float
 Freundlich
 Geborgen
 Weit
 Episch
 Beeindruckend
 Groß
 -> Freundlich, Neutral, Allrounder, Erkunden
 -> Title!

TrackType.HappilyLost
 Kalt
 Weit
 Eindrucksvoll
 Einsam
 -> Neutral, Passt zu unbekanntem, Erkunden

TrackType.Beyond
 Weit!
 Einsam
 Neutral bis Kalt
 Etwas bedrohlich
 -> Neutral bis Bedrohlich, passt zu unbekanntem, zu Fremdem, Erkunden, feindliche Sektoren
 -> Nicht unbedingt Mitte


TrackType.InSight
 Fröhlich
 Warm
 Weit
 Hell
 -> Fröhlicher Allrounder

TrackType.Befog
 Eindrucksvoll
 Duster
 Drones
 Kalt
 Einsam
 -> Mitte, Asteroidenfelder, Xsotan-Sektoren, feindliche Sektoren

TrackType.LightDance
 Flott(er)
 Rhythmisch
 Fröhlich
 Belebt
 -> Colony, bewohnter Sektor

TrackType.LongForgotten
 Duster
 Bedrohlich
 Desolat
 Einsam
 Viele Drones
 Gefährlich
 Kalt
 -> Man stellt sich irgendwie ein altes Wrack vor

TrackType.Interim
 Anspruchsvoll
 Episch
 Beeindruckend
 Voll
 Weit
 Hell
 Fröhlich
 -> Fröhlicher Allrounder

TrackType.Impact
 Duster
 Gruselig
 Bedrückend
 -> Mitte!
 Melancholisch, Traurig
 Gegen Ende Fröhlicher

TrackType.Found
 Duster
 Drones
 Desolate
 -> Scrapyard, Mitte
 Stark melancholisch & traurig

TrackType.BehindStorms
 Etwas Duster
 Etwas Desolat
 Rel. Neutral
 -> Neutral/Duster/Fröhlich wechselnder Allrounder
 -> Passt zu erkunden / fliegen

*/
]]

