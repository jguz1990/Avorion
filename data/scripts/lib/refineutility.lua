
local oreNameByMaterial = {}
oreNameByMaterial[1] = "Iron Ore"
oreNameByMaterial[2] = "Titanium Ore"
oreNameByMaterial[3] = "Naonite Ore"
oreNameByMaterial[4] = "Trinium Ore"
oreNameByMaterial[5] = "Xanion Ore"
oreNameByMaterial[6] = "Ogonite Ore"
oreNameByMaterial[7] = "Avorion Ore"

local scrapNameByMaterial = {}
scrapNameByMaterial[1] = "Scrap Iron"
scrapNameByMaterial[2] = "Scrap Titanium"
scrapNameByMaterial[3] = "Scrap Naonite"
scrapNameByMaterial[4] = "Scrap Trinium"
scrapNameByMaterial[5] = "Scrap Xanion"
scrapNameByMaterial[6] = "Scrap Ogonite"
scrapNameByMaterial[7] = "Scrap Avorion"

function getAmountsOnShip(craft, goodNames)
    local amountsOnShip = {}
    local totalAmount = 0
    for i = 1, NumMaterials() do
        amountsOnShip[i] = 0
    end

    for good, amount in pairs(craft:getCargos()) do
        for material, name in pairs(goodNames) do
            if good.name == name and not good.stolen then
                amountsOnShip[material] = amount
                totalAmount = totalAmount + amount
            end
        end
    end

    return amountsOnShip, totalAmount
end

function getOreAmountsOnShip(craft)
    return getAmountsOnShip(craft, oreNameByMaterial)
end

function getScrapAmountsOnShip(craft)
    return getAmountsOnShip(craft, scrapNameByMaterial)
end
