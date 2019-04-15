package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("utility")
require ("tooltipmaker")
require ("inventoryitemprice")

local SellableInventoryItem = {}
SellableInventoryItem.__index = SellableInventoryItem

function SortSellableInventoryItems(a, b)
    if a.item.itemType == b.item.itemType then
        if a.rarity.value == b.rarity.value then
            if a.item.itemType == InventoryItemType.Turret or a.item.itemType == InventoryItemType.TurretTemplate then
                if a.item.weaponPrefix == b.item.weaponPrefix then
                    return a.price > b.price
                else
                    return a.item.weaponPrefix < b.item.weaponPrefix
                end
            elseif a.item.itemType == InventoryItemType.SystemUpgrade then
                if a.item.script == b.item.script then
                    return a.price > b.price
                else
                    return a.item.script < b.item.script
                end
            end
        else
            return a.rarity.value > b.rarity.value
        end
    else
        return a.item.itemType < b.item.itemType
    end
end

local function new(item, index, owner)
    local obj = setmetatable({item = item, index = index}, SellableInventoryItem)

    -- initialize the item
    obj.price = obj:getPrice()
    obj.name = obj:getName()
    obj.rarity = obj.item.rarity
    obj.material = obj:getMaterial()
    obj.icon = obj:getIcon()

    if owner and index then
        obj.amount = owner:getInventory():amount(index)
    elseif index and type(index) == "number" then
        obj.amount = index
    else
        obj.amount = 1
    end

    return obj
end

function SellableInventoryItem:getMaterial()
    local item = self.item

    if item.itemType == InventoryItemType.Turret or item.itemType == InventoryItemType.TurretTemplate then
        return item.material
    end
end

function SellableInventoryItem:getIcon()
    local item = self.item

    if item.itemType == InventoryItemType.Turret or item.itemType == InventoryItemType.TurretTemplate then
        return item.weaponIcon
    elseif item.itemType == InventoryItemType.SystemUpgrade then
        return item.icon
    elseif item.itemType == InventoryItemType.VanillaItem
        or item.itemType == InventoryItemType.UsableItem then
        return item.icon
    end
end

function SellableInventoryItem:getTooltip()
    local item = self.item

    if self.tooltip == nil then
        if item.itemType == InventoryItemType.Turret or item.itemType == InventoryItemType.TurretTemplate then
            self.tooltip = makeTurretTooltip(item)
        elseif item.itemType == InventoryItemType.SystemUpgrade then
            self.tooltip = item.tooltip
        elseif item.itemType == InventoryItemType.VanillaItem
            or item.itemType == InventoryItemType.UsableItem then
            self.tooltip = item:getTooltip()
        end
    end

    return self.tooltip
end

function SellableInventoryItem:getPrice()
    local item = self.item
    local value = 0

    if item.itemType == InventoryItemType.Turret or item.itemType == InventoryItemType.TurretTemplate then
        return round(ArmedObjectPrice(item))

    elseif item.itemType == InventoryItemType.SystemUpgrade then
        value = item.price

    elseif item.itemType == InventoryItemType.VanillaItem
        or item.itemType == InventoryItemType.UsableItem then
        value = item.price
    end

    return value
end

function SellableInventoryItem:getName()
    local item = self.item
    local name = ""

    if item.itemType == InventoryItemType.Turret or item.itemType == InventoryItemType.TurretTemplate then
        if onClient() then
            local tooltip = self:getTooltip()
            return tooltip:getLine(0).ctext
        else
            return "Turret";
        end

    elseif item.itemType == InventoryItemType.SystemUpgrade then
        return item.name
    elseif item.itemType == InventoryItemType.VanillaItem
        or item.itemType == InventoryItemType.UsableItem then
        return item.name
    end

    return name
end

function SellableInventoryItem:boughtByPlayer(ship)
    local faction = Faction(ship.factionIndex)

    if faction then
        faction:getInventory():add(self.item)
    end
end

function SellableInventoryItem:soldByPlayer(ship)

    local faction = Faction(ship.factionIndex)
    if not faction then return end

    local item = faction:getInventory():take(self.index)
    if item == nil then
        return "Item to sell not found", {}
    end

end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})


