package.path = package.path .. ";data/scripts/lib/?.lua"
require("stringutility")
require("utility")
require("randomext")

function receiveTransactionTax(station, amount)
    if not amount then return end
    amount = round(amount)
    if amount == 0 then return end

    local stationOwner = Faction(station.factionIndex)
    local x, y = Sector():getCoordinates()

    if stationOwner then
        local msg = Format("\\s(%1%:%2%) %3%: Gained %4% credits transaction tax."%_T,
            x,
            y,
            station.title)

        stationOwner:receive(msg, amount)
    end

end


function getTurretFactorySoldGoods()
    local goods =
    {
        "Servo",
		"Steel Tube",
		"Ammunition S",
		"Steel",
		"Aluminium",
		"Lead",
        "High Pressure Tube",
		"Ammunition M",
		"Explosive Charge",
        "Laser Head",
		"Laser Compressor",
		"High Capacity Lens",
		"Laser Modulator",
		"Crystal",
        "Plasma Cell",
		"Energy Tube",
		"Conductor",
		"Energy Container",
        "Warhead",
		"Wire",
        "Rocket",
		"Fuel",
		"Targeting Card",
        "Electromagnetic Charge",
		"Electro Magnet",
		"Gauss Rail",
		"Copper",
        "Nanobot",
		"Transformator",
		"Gold",
        "Force Generator",
		"Energy Inverter",
		"Zinc",
        "Industrial Tesla Coil",
		"Energy Cell",
        "Military Tesla Coil"
    }

    local selected = {}
	local selected_str = ""

for i = 1, 23 do
    local tempValue = randomEntry(random(), goods)
    while (string.match(selected_str ,  "," .. tempValue .. ",")) do
        tempValue = randomEntry(random(), goods)
    end
    selected_str = selected_str .. "," .. tempValue .. ","
    selected[tempValue] = true
end

    local used = {}

    for good, _ in pairs(selected) do
        table.insert(used, good)
    end

    return used
end
