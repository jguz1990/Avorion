
local ShipFounding = {}

ShipFounding.costs = {}
local costs = ShipFounding.costs

costs[0] = {material = Material(MaterialType.Iron)}
costs[1] = {material = Material(MaterialType.Iron)}
costs[2] = {material = Material(MaterialType.Iron)}
costs[3] = {material = Material(MaterialType.Titanium)}
costs[4] = {material = Material(MaterialType.Titanium)}
costs[5] = {material = Material(MaterialType.Titanium)}
costs[6] = {material = Material(MaterialType.Naonite)}
costs[7] = {material = Material(MaterialType.Naonite)}
costs[8] = {material = Material(MaterialType.Trinium)}
costs[9] = {material = Material(MaterialType.Trinium)}
costs[10] = {material = Material(MaterialType.Xanion)}
costs[11] = {material = Material(MaterialType.Xanion)}
costs[12] = {material = Material(MaterialType.Xanion)}
costs[13] = {material = Material(MaterialType.Xanion)}
costs[14] = {material = Material(MaterialType.Xanion)}
costs[15] = {material = Material(MaterialType.Ogonite)}
costs[16] = {material = Material(MaterialType.Ogonite)}
costs[17] = {material = Material(MaterialType.Ogonite)}
costs[18] = {material = Material(MaterialType.Ogonite)}
costs[19] = {material = Material(MaterialType.Ogonite)}
costs[20] = {material = Material(MaterialType.Avorion)}
costs[21] = {material = Material(MaterialType.Avorion)}
costs[22] = {material = Material(MaterialType.Avorion)}
costs[23] = {material = Material(MaterialType.Avorion)}
costs[24] = {material = Material(MaterialType.Avorion)}

function ShipFounding.getCosts(ships)
    local resources = {}

    for i = 0, MaterialType.Avorion do
        resources[i+1] = 0
    end

    local highest = 24

    if ships <= highest then
        resources[costs[ships].material.value+1] = 500
    else
        resources[MaterialType.Avorion+1] = 500
    end

    return resources, ships
end

function ShipFounding.getNextShipCosts(faction)

    if faction.isAlliance then
        faction = Alliance(faction.index)
    elseif faction.isPlayer then
        faction = Player(faction.index)
    end

    -- count number of ships
    local ships = 0
    for _, name in pairs({faction:getShipNames()}) do
        if faction:getShipType(name) == EntityType.Ship then
            ships = ships + 1
        end
    end

    return ShipFounding.getCosts(ships)
end

return ShipFounding
