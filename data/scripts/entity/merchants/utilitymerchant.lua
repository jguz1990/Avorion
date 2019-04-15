package.path = package.path .. ";data/scripts/lib/?.lua"
require ("utility")
require ("randomext")
require ("faction")
local ShopAPI = require ("shop")
local UpgradeGenerator = require("upgradegenerator")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace UtilityMerchant
UtilityMerchant = {}
UtilityMerchant = ShopAPI.CreateNamespace()

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function UtilityMerchant.interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, -10000)
end

local function sortSystems(a, b)
    if a.rarity.value == b.rarity.value then
        return a.price > b.price
    end

    return a.rarity.value > b.rarity.value
end

function UtilityMerchant.shop:addItems()
    local item = UsableInventoryItem("energysuppressor.lua", Rarity(RarityType.Exceptional))
    UtilityMerchant.add(item, getInt(2, 3))
end

function UtilityMerchant.initialize()
    UtilityMerchant.shop:initialize("Utility Merchant"%_t)
end

function UtilityMerchant.initUI()
    UtilityMerchant.shop:initUI("Trade Equipment"%_t, "Utility Merchant"%_t, "Utilities"%_t)
end
