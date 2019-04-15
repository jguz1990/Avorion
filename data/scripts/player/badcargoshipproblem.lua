if onClient() then

package.path = package.path .. ";data/scripts/lib/?.lua"
require("utility")
require("stringutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace BadCargo
BadCargo = {}

local playerShip
local shipFaction
local illegal = false
local stolen = false
local suspicious = false
local dangerous = false

local availableLicenses = {}
local presentFactions = {}


function BadCargo.initialize()
    local player = Player()
    player:registerCallback("onShipChanged", "onShipChanged")
    player:registerCallback("onSectorChanged", "onSectorChanged")
    local entity = player.craft

    if valid(entity) then
        entity:registerCallback("onCargoChanged", "onCargoChanged")
        playerShip = entity.index

        BadCargo.updateShipFaction()
        shipFaction:registerCallback("onItemAdded", "onItemAdded")
        shipFaction:registerCallback("onItemRemoved", "onItemRemoved")

        BadCargo.updateAvailableLicenses()
        BadCargo.updatePresentFactions()
        BadCargo.updateCargos()
        BadCargo.updateLicenseCoverage()
    else
        playerShip = Uuid()
    end
end

function BadCargo.updateShipFaction()
    shipFaction = nil

    local ship = Sector():getEntity(playerShip)
    if not valid(ship) then return end

    local faction = Faction(ship.factionIndex)
    if faction.isPlayer then
        shipFaction = Player(faction.index)
    elseif faction.isAlliance then
        shipFaction = Alliance(faction.index)
    end
end

function BadCargo.onShipChanged(playerIndex, craftIndex)
    local sector = Sector()
    local oldShip = sector:getEntity(playerShip)
    local oldFactionIndex

    if oldShip then
        oldShip:unregisterCallback("onCargoChanged", "onCargoChanged")
        oldFactionIndex = oldShip.factionIndex
    end

    playerShip = craftIndex
    local ship = sector:getEntity(craftIndex)
    if not ship then return end

    ship:registerCallback("onCargoChanged", "onCargoChanged")

    -- register to new inventory if faction index changed
    if ship.factionIndex ~= oldFactionIndex then
        local oldShipFaction = shipFaction
        BadCargo.updateShipFaction()

        if valid(oldShipFaction) then
            oldShipFaction:unregisterCallback("onItemAdded", "onItemAdded")
            oldShipFaction:unregisterCallback("onItemRemoved", "onItemRemoved")
        end

        shipFaction:registerCallback("onItemAdded", "onItemAdded")
        shipFaction:registerCallback("onItemRemoved", "onItemRemoved")

        BadCargo.updateAvailableLicenses()
    end

    BadCargo.updateCargos()
    BadCargo.updateLicenseCoverage()
end

function BadCargo.onSectorChanged()
    BadCargo.updateAvailableLicenses()
    BadCargo.updatePresentFactions()
    BadCargo.updateLicenseCoverage()
end

function BadCargo.onCargoChanged(entityIndex, delta, good)
    if delta < 0 then
        BadCargo.updateCargos()
        BadCargo.updateLicenseCoverage()
    else
        BadCargo.updateSingleCargo(good)
        BadCargo.updateLicenseCoverage()
    end
end

function BadCargo.onItemAdded(item, index, amount, amountBefore, tagsChanged)
    BadCargo.updateSingleLicense(shipFaction:getInventory():find(index))
    BadCargo.updateLicenseCoverage()
end

function BadCargo.onItemRemoved(item, index, amount, amountBefore, tagsChanged)
    BadCargo.updateAvailableLicenses()
    BadCargo.updateLicenseCoverage()
end

function BadCargo.updateCargos()
    illegal = false
    stolen = false
    suspicious = false
    dangerous = false

    for tradingGood, _ in pairs(Entity(playerShip):getCargos()) do
        if tradingGood.illegal then illegal = true end
        if tradingGood.stolen then stolen = true end
        if tradingGood.suspicious then suspicious = true end
        if tradingGood.dangerous then dangerous = true end
    end
end

function BadCargo.updateLicenseCoverage()
    if (not illegal and not stolen and not suspicious and not dangerous) or tablelength(presentFactions) == 0 then
        removeShipProblem("BadTradinggood", playerShip)
        return
    end

    local status = ""
    local color
    if BadCargo.checkLicenseCoverage() then
        status = "Their transport is covered by your licenses."%_t
        color = ColorRGB(0.6, 0.6, 0.6)
    else
        status = "You might get in trouble if you don't get a transportation license."%_t
        color = ColorRGB(1, 0, 0)
    end

    addShipProblem("BadTradinggood", playerShip, BadCargo.getBadCargosString() .. status, "data/textures/icons/handcuffs.png", color)
end

function BadCargo.updateSingleCargo(tradingGood)
    if not tradingGood then return end

    if tradingGood.illegal then illegal = true end
    if tradingGood.stolen then stolen = true end
    if tradingGood.suspicious then suspicious = true end
    if tradingGood.dangerous then dangerous = true end
end

function BadCargo.updateAvailableLicenses()
    availableLicenses = {}

    if not valid(shipFaction) then return end

    local vanillaItems = shipFaction:getInventory():getItemsByType(InventoryItemType.VanillaItem)
    for _, p in pairs(vanillaItems) do
        local item = p.item

        if item:getValue("isCargoLicense") == true then
            local faction = item:getValue("faction")

            local currentLevel = availableLicenses[faction]
            if currentLevel == nil or item.rarity.value > currentLevel then
                availableLicenses[faction] = item.rarity.value
            end
        end
    end
end

function BadCargo.updateSingleLicense(item)
    if item.itemType ~= InventoryItemType.VanillaItem then return end
    if not item:getValue("isCargoLicense") then return end

    local faction = item:getValue("faction")

    local currentLevel = availableLicenses[faction]
    if currentLevel == nil or item.rarity.value > currentLevel then
        availableLicenses[faction] = item.rarity.value
    end
end

function BadCargo.getBadCargosString()
    local problems = {}

    -- ordered from lowest to highest level
    if dangerous then table.insert(problems, "dangerous"%_t) end
    if suspicious then table.insert(problems, "suspicious"%_t) end
    if stolen then table.insert(problems, "stolen"%_t) end
    if illegal then table.insert(problems, "illegal"%_t) end

    return string.format("You have %s trading goods in your cargo bay!\n"%_t, enumerate(problems))
end

function BadCargo.updatePresentFactions()
    presentFactions = {}
    for _, entity in pairs({Sector():getEntitiesByScript("data/scripts/entity/antismuggle.lua")}) do
        presentFactions[entity.factionIndex] = true
    end
end

function BadCargo.checkLicenseCoverage()
    local requiredLevel = -1
    if dangerous then requiredLevel = 0 end
    if suspicious then requiredLevel = 1 end
    if stolen then requiredLevel = 2 end
    if illegal then requiredLevel = 3 end

    for faction, _ in pairs(presentFactions) do
        if not availableLicenses[faction] then
            return false
        end

        if availableLicenses[faction] < requiredLevel then
            return false
        end
    end

    return true
end

end
