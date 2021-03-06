--------------------------------------------------------------------------------
-- EVENT BALANCING LIB ---------------------------------------------------------
--------------------------------------------------------------------------------
-- darkconsole <darkcee.legit@gmail.com> ---------------------------------------

--[[ SEE README.MD FOR DETAILS YO ]]--

--------------------------------------------------------------------------------
-- STOCK FILE MODIFICATIONS ----------------------------------------------------
--------------------------------------------------------------------------------

-- + means section needs to be added added.
-- - means section needs to be removed.
-- ~ means section replaces some stock code.

-- player\eventscheduler.lua
-- + require event balancer
-- ~ increase event delay
-- ~ disable multiple players speeding up events
-- + determine if event should be skipped

-- events\pirateattack.lua
-- + require event balancer
-- + determine if event should be skipped
-- ~ increase event delay

--------------------------------------------------------------------------------
-- MOD CONFIG ------------------------------------------------------------------
--------------------------------------------------------------------------------

EventBalance = {
	PauseMultiplier   = 1,     -- mutiplier for delay between events
	SkipWindowCap     = 10,    -- max ships before we stop curving chance
	SkipWindowFlex    = 0.75,  -- multiplier for ship count impact
	SkipWindowFloat   = 750,   -- float the sector's expected average
	SkipWindow        = 33.0,  -- percentage of sector volume ripe for attack
	SkipChance        = 66.0,  -- percentage flat chance to ALLOW event
	SkipChanceVolume  = 20.0,  -- percentage flat chance to ALLOW for volume
	Debug             = true   -- if we should print stupid things to console
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- vscode-fold=1

require("galaxy")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function EventBalance.GetSectorShipInfo(Coord)
-- @argv vec2 SectorCoords
-- @return [ int Count, float Volume, float VolumeAverage ]
-- find out some information about the ships in this sector.
-- Float Volume of Ships

	local Key
	local Value

	local Count = 0
	local Volume = 0
	local VolumeAverage = 0

	--------
	-- find all the ships, counting how many we have and how much total volume
	-- they take up in this sector.
	--------

	for Key,Value in pairs({Sector(Coord):getEntitiesByType(EntityType.Ship)})
	do
		Volume = Volume + Value.volume
		Count = Count + 1
	end

	--------
	-- determine the mean volume of the ships in this sector.
	--------

	VolumeAverage = Volume / Count

	--------

	return Count, Volume, VolumeAverage
end

function EventBalance.GetFactoredSkipWindow(ShipCount)
-- @argv Float SkipWindow, Int ShipCount
-- @argv Float
-- modify the skip window based on how many ships are in this sector. this is to
-- attempt to simulate the pirates needing to be sure they want to attack the
-- sector by narrowing the window the more ships there are.

	if(ShipCount > EventBalance.SkipWindowCap) then
		ShipCount = EventBalance.SkipWindowCap
	elseif(ShipCount < 1) then
		ShipCount = 0
	end

	return EventBalance.SkipWindow - (ShipCount * EventBalance.SkipWindowFlex)
end

function EventBalance.ShouldSkipEvent(Event)
-- the purpose of this method is to determine if we should skip the event that
-- tried to happen. this is based on the "power" of a sector. the more empty a
-- sector is the less likely pirates will think it worth attacking. on the flip
-- side once the sector becomes too strong pirates should think twice about
-- attempting to pillage it.

	--------
	-- passive events that won't fuck up your day are always allowed.
	--------

	if(Event.script == "spawntravellingmerchant")
	then
		return false
	end

	if(Event.script == "convoidistresssignal")
	then
		return false
	end

	--------
	-- chances that an event may be skipped
	--------

	if(EventBalance.ShouldSkipEvent_BySectorVolume(Event) == true) then
		return true
	end

	if(EventBalance.ShouldSkipEvent_ByFlatChance(Event,false) == true) then
		return true
	end

	--------
	--------

	return false
end

function EventBalance.ShouldSkipEvent_BySectorVolume(Event)
-- analyze the sector and decide if we should skip this event based on the
-- volume of ships within it.

	local
		ShipTotalCount,
		ShipTotalVolume,
		ShipAverageVolume
	= EventBalance.GetSectorShipInfo(Sector():getCoordinates())

	local SectorAverageVolume = Balancing_GetSectorShipVolume(Sector():getCoordinates())
	local SectorAllowedDiff = (EventBalance.GetFactoredSkipWindow(ShipTotalCount) * SectorAverageVolume) / 100

	if(EventBalance.Debug)
	then
		print("---- Event Balancer: Sector Analysis (" .. Event.script .. ")")
		print("-- Ships In Sector: Total(" .. ShipTotalCount .. "), Volume(" .. ShipTotalVolume .. "), AverageVolume(" .. ShipAverageVolume .. ")")
		print("-- Sector Values: AverageVolume(" .. SectorAverageVolume .. ") AllowedDiff(" .. SectorAllowedDiff .. " (" .. EventBalance.SkipWindow .. "%))")
	end

	if(ShipAverageVolume <= (SectorAverageVolume + EventBalance.SkipWindowFloat) - SectorAllowedDiff) then
		if(EventBalance.Debug)
		then
			print(">> " .. ShipAverageVolume .. " <= " .. (SectorAverageVolume - SectorAllowedDiff) .. " + " .. EventBalance.SkipWindowFloat)
			print(">> sector too boring for attack")
			print(" ")
		end

		return EventBalance.ShouldSkipEvent_ByFlatChance(Event,true)
	elseif(ShipAverageVolume >= (SectorAverageVolume + EventBalance.SkipWindowFloat) + SectorAllowedDiff) then
		if(EventBalance.Debug)
		then
			print(">> " .. ShipAverageVolume .. " >= " .. (SectorAverageVolume + SectorAllowedDiff) .. " + " .. EventBalance.SkipWindowFloat)
			print(">> sector too strong for attack")
			print(" ")
		end

		return EventBalance.ShouldSkipEvent_ByFlatChance(Event,true)
	end

	return false
end

function EventBalance.ShouldSkipEvent_ByFlatChance(Event, FactorVolume)
-- decide if we should skip the event based on a stupid flat chance.

	local SkipChance

	if(FactorVolume) then
		SkipChance = EventBalance.SkipChanceVolume
	else
		SkipChance = EventBalance.SkipChance
	end

	if(EventBalance.SkipChance > 0) then
		return random():getInt(1,100) > SkipChance
	end

	return false
end
