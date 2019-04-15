
if onClient() then return end

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require("stringutility")
require("goods")
require("refineutility")
local DockAI = require ("entity/ai/dock")

local partner
local status
local totalTime
local passedTime

RefineAI = {
    DockAtStation = 1,
    WaitForProcessing = 2,
    CollectResources = 3
}

function secure()
    local data = {status = status, partner = partner, totalTime = totalTime, passedTime = passedTime}

    DockAI.secure(data)

    return data
end

function restore(data)
    status = data.status
    partner = data.partner
    totalTime = data.totalTime
    passedTime = data.passedTime

    DockAI.restore(data)
end

function getUpdateInterval()
    return 1
end

function updateServer(timeStep)
    local craft = Entity()

    if not partner then
        -- are there any ores to refine?
        local ores, totalOres = getOreAmountsOnShip(craft)
        local scraps, totalScraps = getScrapAmountsOnShip(craft)

        if totalOres + totalScraps == 0 then
    --        print("nothing to refine")
            terminate()
            return
        end

        -- find best refinery
        partner = findRefinery()
        status = RefineAI.DockAtStation

        if not partner then
            sendError("Sir, we can't find a refinery in \\s(%s)."%_T, "No refinery found in sector %s."%_T)
            terminate()
            return
        end
    end

    local station = Sector():getEntity(partner)
    if not station then
        sendError("Sir, we can't find a refinery in \\s(%s)."%_T, "No refinery found in sector %s."%_T)
        terminate()
        return
    end

    if status == RefineAI.DockAtStation then
        ShipAI():setStatus("Refining Ores - Docking /* ship AI status */"%_T, {})

        local finished = function() status = RefineAI.WaitForProcessing end
        DockAI.updateDockingUndocking(timeStep, station, 1, startProcessing, finished, true --[[skip undocking--]])

    elseif status == RefineAI.WaitForProcessing then
        ShipAI():setStatus("Refining Ores - Waiting for Processing /* ship AI status */"%_T, {})
        passedTime = (passedTime or 0) + timeStep

        if passedTime >= totalTime + 5 then
            status = RefineAI.CollectResources
            DockAI.reset()
        end

    elseif status == RefineAI.CollectResources then
        ShipAI():setStatus("Refining Ores - Collecting Resources /* ship AI status */"%_T, {})

        local transaction = function(craft)
            station:invokeFunction("data/scripts/entity/merchants/refinery.lua", "onTakeAllPressed", craft.index)
        end

        local finish = function() terminate() end

        DockAI.updateDockingUndocking(timeStep, station, 1, transaction, finish)
    end
end

function sendError(chatMessage, errorMessage)
    local craft = Entity()
    local faction = Faction(craft.factionIndex)
    if faction then
        local x, y = Sector():getCoordinates()
        local coords = tostring(x) .. ":" .. tostring(y)

        faction:sendChatMessage(craft.name or "", ChatMessageType.Error, errorMessage, coords)
        faction:sendChatMessage(craft.name or "", ChatMessageType.Normal, chatMessage, coords)
    end
end

function findRefinery()
    local craft = Entity()
    local shipFaction = Faction(craft.factionIndex)

    local best = {}

    for _, station in pairs({Sector():getEntitiesByScript("data/scripts/entity/merchants/refinery.lua")}) do
        local relations = shipFaction:getRelations(station.factionIndex)

        if best.relations == nil or relations > best.relations then
            if #{station:getDockingPositions()} > 0 then
                best.relations = relations
                best.stationId = station.id
            end
        end
    end

    return best.stationId and best.stationId.string or nil
end

function startProcessing(craft, station)
    local ores, totalOres = getOreAmountsOnShip(craft)
    local scraps, totalScraps = getScrapAmountsOnShip(craft)

    if totalOres + totalScraps == 0 then
--        print("nothing to refine")
        terminate()
        return
    end

    station:invokeFunction("data/scripts/entity/merchants/refinery.lua", "addJob", craft.index, ores, scraps, true)
    local ret, time = station:invokeFunction("data/scripts/entity/merchants/refinery.lua", "getRefiningTime", ores, scraps)
    if ret ~= 0 then
--        print("call to getRefiningTime failed: " .. ret)
        terminate()
        return
    end

    if not time then
--        print("time is nil")
        terminate()
        return
    end

    totalTime = time
    passedTime = 0
end
