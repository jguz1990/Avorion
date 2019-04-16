package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("utility")
require ("randomext")
require ("faction")
require ("sellableinventoryitem")
require ("stringutility")
local TorpedoGenerator = require("torpedogenerator")
local Dialog = require("dialogutility")
local ShopAPI = require ("shop")
local SellableTorpedo = require ("sellabletorpedo")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace TorpedoMerchant
TorpedoMerchant = {}
TorpedoMerchant = ShopAPI.CreateNamespace()

-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function TorpedoMerchant.interactionPossible(playerIndex, option)
    return CheckFactionInteraction(playerIndex, 0)
end

local function comp(a, b)
    local ta = a.torpedo;
    local tb = b.torpedo;

    if ta.rarity == tb.rarity then
        return ta.name < tb.name
    else
        return ta.rarity.value > tb.rarity.value
    end
end

function TorpedoMerchant.shop:addItems()

    local station = Entity()

    if station.title == "" then
        station.title = "Torpedo Merchant"%_t
    end

    -- create all torpedoes
    local allTorpedoes = {}

    for i = 1, 38 do
        local torpedo = TorpedoGenerator.generate(Sector():getCoordinates())

        for _, p in pairs(allTorpedoes) do
            if torpedo.name == p.torpedo.name and torpedo.rarity == p.torpedo.rarity then
                goto continue
            end
        end

        local pair = {}
        pair.torpedo = torpedo
        pair.amount = 1

        if torpedo.rarity.value == RarityType.Exotic then
            pair.amount = getInt(100, 200)
        elseif torpedo.rarity.value == RarityType.Exceptional then
            pair.amount = getInt(300, 400)
        elseif torpedo.rarity.value == RarityType.Rare then
            pair.amount = getInt(500, 600)
        elseif torpedo.rarity.value == RarityType.Uncommon then
            pair.amount = getInt(700, 800)
        end

        table.insert(allTorpedoes, pair)

        ::continue::
    end

    table.sort(allTorpedoes, comp)

    for _, pair in pairs(allTorpedoes) do
        TorpedoMerchant.shop:add(pair.torpedo, pair.amount)
    end

end

function TorpedoMerchant.initialize()
    TorpedoMerchant.shop:initialize("Torpedo Merchant"%_t)

    if onClient() and EntityIcon().icon == "" then
        EntityIcon().icon = "data/textures/icons/pixel/trade.png" -- TODO @Philipp
    end
end

function TorpedoMerchant.initUI()
    TorpedoMerchant.shop:initUI("Trade Equipment"%_t, "Torpedo Merchant"%_t, "Torpedoes"%_t)
end

TorpedoMerchant.shop.ItemWrapper = SellableTorpedo
TorpedoMerchant.shop.SortFunction = comp
