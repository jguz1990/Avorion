package.path = package.path .. ";/data/scripts/lib/?.lua"
require ("stringutility")

function CheckPlayerDocked(player, object, errors, generic)
    local object = object or Entity()

    return CheckShipDocked(player, player.craft, object, errors, generic)
end

function CheckShipDocked(faction, ship, object, errors, generic)
    if not faction then return false end

    local object = object or Entity()
    if not object then return false end

    -- allow docking to itself
    if ship and object and ship.id == object.id then
        return true
    end

    if not ship then
        local error = "You're not in a ship."%_T
        if faction.isPlayer then
            Player(faction.index):sendChatMessage(object, 1, error)
        end
        return false, error
    end

    local error
    if object:hasComponent(ComponentType.DockingPositions) then
        if not object:isDocked(ship) then
            error = errors[object.type] or generic or "You must be docked to the object for this."%_T
        end
    else
        if object:getNearestDistance(ship) > 50 then
            error = errors[object.type] or generic or "You must be closer to the object for this."%_T
        end
    end

    if error then
        if faction.isPlayer then
            if type(error) == "string" then
                Player(faction.index):sendChatMessage(object, 1, error)
            elseif type(error) == "table" then
                Player(faction.index):sendChatMessage(object, 1, error.text, unpack(error.args or {}))
            end
        end
        return false, error
    end

    return true
end

function AlertAbsentPlayers(messageType, message, ...)
    local sector = Sector()
    local factions = {sector:getPresentFactions()}
    local players = {sector:getPlayers()}

    local absentFactions = {}

    for _, factionIndex in pairs(factions) do
        local found = false
        for _, player in pairs(players) do
            if player.index == factionIndex or player.allianceIndex == factionIndex then
                found = true
                break
            end
        end

        if found == false then
            table.insert(absentFactions, factionIndex)
        end
    end

    for _, index in pairs(absentFactions) do
        local faction = Faction(index)
        if faction and (faction.isPlayer or faction.isAlliance) then
            faction:sendChatMessage("", messageType, message, ...)
        end
    end
end
