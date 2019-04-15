package.path = package.path .. ";data/scripts/lib/?.lua"
require ("sellableinventoryitem")

local SellableTorpedoItem = {}
SellableTorpedoItem.__index = SellableTorpedoItem

local function new(torpedo, index, player)
    local obj = setmetatable({torpedo = torpedo, item = torpedo, index = index}, SellableTorpedoItem)

    -- initialize the item
    obj.price = obj:getPrice()
    obj.rarity = obj.torpedo.rarity

    obj.name = obj.torpedo.name
    obj.icon = obj.torpedo.icon

    if player and index then
        obj.amount = player:getInventory():amount(index)
    elseif index and type(index) == "number" then
        obj.amount = index
    else
        obj.amount = 1
    end

    return obj
end

function SellableTorpedoItem:getTooltip()

    if self.tooltip == nil then
        self.tooltip = makeTorpedoTooltip(self.torpedo)
    end

    return self.tooltip
end

function SellableTorpedoItem:getPrice()
    return TorpedoPrice(self.torpedo)
end

function SellableTorpedoItem:boughtByPlayer(ship)
    local launcher = TorpedoLauncher(ship.index)

    if not launcher then
        return "Your ship doesn't have a torpedo launcher."%_t, {}
    end

    if self.torpedo.size > launcher.freeStorage then
        return "Your ship doesn't have enough free torpedo storage."%_t, {}
    end

    launcher:addTorpedo(self.torpedo)
end

function SellableTorpedoItem:soldByPlayer(ship)
    local launcher = TorpedoLauncher(ship.index)

    if not launcher then
        return "Your ship doesn't have a torpedo launcher."%_t, {}
    end

    self.torpedo = launcher:getTorpedo(self.shaftIndex, self.torpedoIndex)

    if self.torpedo == nil then
        return "Torpedo to sell not found"%_t, {}
    end

    local price = getTorpedoPrice(self.torpedo) / 8.0
    launcher:removeTorpedo(self.shaftIndex, self.torpedoIndex)
end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})
