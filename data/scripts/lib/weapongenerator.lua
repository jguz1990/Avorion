package.path = package.path .. ";data/scripts/lib/?.lua"

require("galaxy")
require("randomext")
require("weapontype")

local WEAPON_STRENGTHMINVARIATION = 1 -- these values mark the variation of strength that a randomly generated weapon may have.
local WEAPON_STRENGTHMAXVARIATION = 2.0

local WeaponGenerator = {}

function WeaponGenerator.generateBolter(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setProjectile()

    local fireDelay = rand:getFloat(0.1, 0.3)
    local reach = rand:getFloat(550, 800)
    local damage = dps * fireDelay * 1.5--bolterbuff
    local velocity = rand:getFloat(1000, 1500)
    local maximumTime = reach / velocity

    weapon.pvelocity = velocity
    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.appearance = WeaponAppearance.Bolter
    weapon.name = "Bolter /* Weapon Name*/"%_t
    weapon.prefix = "Bolter /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/bolter.png" -- previously sentry-gun.png
    weapon.sound = "bolter"
    weapon.accuracy = 0.99 - rand:getFloat(0, 0.03)

    weapon.damage = damage
    weapon.damageType = DamageType.Physical
    weapon.hullDamageMultiplicator = 1.2 + rand:getFloat(0, 0.2) + rarity.value * 0.2
    weapon.impactParticles = ImpactParticles.Physical
    weapon.impactSound = 1

    weapon.psize = rand:getFloat(0.15, 0.25)
    weapon.pmaximumTime = maximumTime
    local color = Color()
    color:setHSV(rand:getFloat(10, 60), 0.7, 1)
    weapon.pcolor = color

    if rand:test(0.05) then
        local shots = {2, 2, 2, 2, 2, 3, 4}
        weapon.shotsFired = shots[rand:getInt(1, #shots)]
        weapon.damage = weapon.damage * 1.5 / weapon.shotsFired
    end

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    weapon.recoil = weapon.damage * 16

    return weapon
end

function WeaponGenerator.generateMiningLaser(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setBeam()

    weapon.fireDelay = 0.2
    weapon.appearanceSeed = rand:getInt()
    weapon.reach = 300
    weapon.recoil = 0
    weapon.continuousBeam = true
    weapon.appearance = WeaponAppearance.MiningLaser
    weapon.name = "Mining Laser /* Weapon Name*/"%_t
    weapon.prefix = "Mining /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/mining-laser.png" -- previously mining.png
    weapon.sound = "mining"

    weapon.damage = dps * weapon.fireDelay
    weapon.damageType = DamageType.Energy
    weapon.smaterial = material
    weapon.stoneDamageMultiplicator = WeaponGenerator.getStoneDamageMultiplicator()
    weapon.shieldDamageMultiplicator = 0
    weapon.stoneRefinedEfficiency = math.abs(0.12 + rand:getFloat(0, 0.01) + rarity.value * 0.01) * 3

    weapon.bshape = BeamShape.Straight
    weapon.bouterColor = ColorRGB(0.1, 0.1, 0.1)
    weapon.binnerColor = ColorARGB(material.color.a * 0.5, material.color.r * 0.5, material.color.g * 0.5, material.color.b * 0.5)
    weapon.bwidth = 0.5
    weapon.bauraWidth = 1
    weapon.banimationSpeed = 4

    WeaponGenerator.adaptMiningLaser(rand, weapon, tech, material, rarity)

    return weapon
end

function WeaponGenerator.generateSalvagingLaser(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setBeam()

    weapon.fireDelay = 0.2
    weapon.appearanceSeed = rand:getInt()
    weapon.reach = 300
    weapon.recoil = 0
    weapon.continuousBeam = true
    weapon.appearance = WeaponAppearance.MiningLaser
    weapon.name = "Salvaging Laser /* Weapon Name*/"%_t
    weapon.prefix = "Salvaging /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/salvage-laser.png" -- previously recycle.png
    weapon.sound = "mining"

    weapon.damage = dps * weapon.fireDelay
    weapon.damageType = DamageType.Energy
    weapon.smaterial = material
    weapon.stoneDamageMultiplicator = 0.01
    weapon.shieldDamageMultiplicator = 0
    weapon.metalRefinedEfficiency = math.abs(0.08 + rand:getFloat(0, 0.01) + rarity.value * 0.01) * 5

    weapon.blength = weapon.reach
    weapon.bshape = BeamShape.Straight
    weapon.bouterColor = ColorRGB(0.1, 0.1, 0.1)
    weapon.binnerColor = ColorARGB(material.color.a * 0.5, material.color.r * 0.5, material.color.g * 0.5, material.color.b * 0.5)
    weapon.bwidth = 0.5
    weapon.bauraWidth = 1
    weapon.banimationSpeed = 4

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    return weapon
end

function WeaponGenerator.generateRawMiningLaser(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setBeam()

    weapon.fireDelay = 0.2
    weapon.appearanceSeed = rand:getInt()
    weapon.reach = 300
    weapon.recoil = 0
    weapon.continuousBeam = true
    weapon.appearance = WeaponAppearance.MiningLaser
    weapon.name = "R-Mining Laser /* Weapon Name*/"%_t
    weapon.prefix = "R-Mining /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/mining-laser.png"
    weapon.sound = "mining"

    weapon.damage = dps * weapon.fireDelay
    weapon.damageType = DamageType.Energy
    weapon.smaterial = material
    weapon.stoneDamageMultiplicator = WeaponGenerator.getStoneDamageMultiplicator()
    weapon.shieldDamageMultiplicator = 0
    weapon.stoneRawEfficiency = math.abs(0.63 + rand:getFloat(0, 0.06) + rarity.value * 0.06)

    weapon.blength = weapon.reach
    weapon.bshape = BeamShape.Straight
    weapon.bouterColor = ColorRGB(0.1, 0.1, 0.1)
    weapon.binnerColor = ColorARGB(material.color.a * 0.5, material.color.r * 0.5, material.color.g * 0.5, material.color.b * 0.5)
    weapon.bwidth = 0.5
    weapon.bauraWidth = 1
    weapon.banimationSpeed = 4

    WeaponGenerator.adaptMiningLaser(rand, weapon, tech, material, rarity)

    return weapon
end

function WeaponGenerator.generateRawSalvagingLaser(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setBeam()

    weapon.fireDelay = 0.2
    weapon.appearanceSeed = rand:getInt()
    weapon.reach = 300
    weapon.recoil = 0
    weapon.continuousBeam = true
    weapon.appearance = WeaponAppearance.MiningLaser
    weapon.name = "R-Salvaging Laser /* Weapon Name*/"%_t
    weapon.prefix = "R-Salvaging /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/salvage-laser.png"
    weapon.sound = "mining"

    weapon.damage = dps * weapon.fireDelay
    weapon.damageType = DamageType.Energy
    weapon.smaterial = material
    weapon.stoneDamageMultiplicator = 0.01
    weapon.shieldDamageMultiplicator = 0
    weapon.metalRawEfficiency = math.abs(0.10 + rand:getFloat(0, 0.05) + rarity.value * 0.05)

    weapon.blength = weapon.reach
    weapon.bshape = BeamShape.Straight
    weapon.bouterColor = ColorRGB(0.1, 0.1, 0.1)
    weapon.binnerColor = ColorARGB(material.color.a * 0.5, material.color.r * 0.5, material.color.g * 0.5, material.color.b * 0.5)
    weapon.bwidth = 0.5
    weapon.bauraWidth = 1
    weapon.banimationSpeed = 4

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    return weapon
end

function WeaponGenerator.generateLightningGun(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setBeam()

    local fireDelay = rand:getFloat(1, 2.5)
    local reach = rand:getFloat(950, 1400)
    local damage = dps * fireDelay

    weapon.fireDelay = fireDelay
    weapon.appearanceSeed = rand:getInt()
    weapon.reach = reach
    weapon.continuousBeam = false
    weapon.appearance = WeaponAppearance.Tesla
    weapon.name = "Lightning Gun /* Weapon Name*/"%_t
    weapon.prefix = "Lightning /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/lightning-gun.png" -- previously lightning-branches.png
    weapon.sound = "railgun"
    weapon.accuracy = 0.99 - rand:getFloat(0, 0.02)

    weapon.damage = damage
    weapon.damageType = DamageType.Energy
    weapon.impactParticles = ImpactParticles.Energy
    weapon.shieldDamageMultiplicator = 2.6 + rand:getFloat(0, 0.4) + rarity.value * 0.6
    weapon.stoneDamageMultiplicator = 0
    weapon.impactSound = 1

    weapon.blength = weapon.reach
    weapon.bshape = BeamShape.Lightning
    weapon.bwidth = 0.5
    weapon.bauraWidth = 3
    weapon.banimationSpeed = 0
    weapon.banimationAcceleration = 0
    weapon.bshapeSize = 13

    -- shades of blue
    weapon.bouterColor = ColorHSV(rand:getFloat(180, 260), rand:getFloat(0.5, 1), rand:getFloat(0.1, 0.5))
    weapon.binnerColor = ColorHSV(rand:getFloat(180, 260), rand:getFloat(0.1, 0.5), 1)

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    weapon.recoil = weapon.damage * 5

    return weapon
end

function WeaponGenerator.generateTeslaGun(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setBeam()

    local fireDelay = 0.2 -- always the same with beams, does not really matter
    local reach = rand:getFloat(300, 450)
    local damage = dps * fireDelay * 1.5

    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.continuousBeam = true
    weapon.appearance = WeaponAppearance.Tesla
    weapon.name = "Tesla Gun /* Weapon Name*/"%_t
    weapon.prefix = "Tesla /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/tesla-gun.png" -- previously lightning-frequency.png
    weapon.sound = "lightning"
    weapon.accuracy = 0.99 - rand:getFloat(0, 0.06)

    local hue = rand:getFloat(0, 360)

    weapon.damage = damage
    weapon.damageType = DamageType.Energy
    weapon.impactParticles = ImpactParticles.Energy
    weapon.shieldDamageMultiplicator = 5 + rand:getFloat(0, 0.4) + rarity.value * 0.4
    weapon.stoneDamageMultiplicator = 0
    weapon.blength = weapon.reach

    weapon.bouterColor = ColorHSV(hue, 1, rand:getFloat(0.1, 0.3))
    weapon.binnerColor = ColorHSV(hue + rand:getFloat(-120, 120), 0.3, rand:getFloat(0.7, 0.8))
    weapon.bwidth = 0.5
    weapon.bauraWidth = 1
    weapon.banimationSpeed = 4
    weapon.bshape = BeamShape.Lightning
    weapon.bshapeSize = 5

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    return weapon
end

function WeaponGenerator.generatePointDefenseLaser(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setBeam()

    local fireDelay = 0.2 -- always the same with beams, does not really matter
    local reach = rand:getFloat(400, 500)
    local damage = (1.5 + (rarity.value * 0.25)) * 0.1

    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.continuousBeam = true
    weapon.appearance = WeaponAppearance.Laser
    weapon.name = "Point Defense Laser /* Weapon Name*/"%_t
    weapon.prefix = "Point Defense Laser /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/laser-gun.png" -- previously laser-blast.png
    weapon.sound = "laser"

    local hue = rand:getFloat(0, 360)

    weapon.damage = damage
    weapon.damageType = DamageType.Fragments
    weapon.blength = weapon.reach

    weapon.bouterColor = ColorHSV(hue, 1, rand:getFloat(0.1, 0.3))
    weapon.binnerColor = ColorHSV(hue + rand:getFloat(-120, 120), 0.3, rand:getFloat(0.7, 0.8))
    weapon.bshape = BeamShape.Straight
    weapon.bwidth = 0.5
    weapon.bauraWidth = 1
    weapon.banimationSpeed = 4

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    return weapon
end

function WeaponGenerator.generateLaser(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setBeam()

    local fireDelay = 0.2 -- always the same with beams, does not really matter
    local reach = rand:getFloat(450, 750)
    local damage = dps * fireDelay

    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.continuousBeam = true
    weapon.appearance = WeaponAppearance.Laser
    weapon.name = "Laser /* Weapon Name*/"%_t
    weapon.prefix = "Laser /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/laser-gun.png" -- previously laser-blast.png
    weapon.sound = "laser"

    local hue = rand:getFloat(0, 360)

    weapon.damage = damage
    weapon.damageType = DamageType.Energy
    weapon.blength = weapon.reach

    weapon.bouterColor = ColorHSV(hue, 1, rand:getFloat(0.1, 0.3))
    weapon.binnerColor = ColorHSV(hue + rand:getFloat(-120, 120), 0.3, rand:getFloat(0.7, 0.8))
    weapon.bshape = BeamShape.Straight
    weapon.bwidth = 0.5
    weapon.bauraWidth = 1
    weapon.banimationSpeed = 4

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    return weapon
end

function WeaponGenerator.generateRepairBeamEmitter(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setBeam()

    local fireDelay = 0.2 -- always the same with beams, does not really matter
    local reach = rand:getFloat(200, 300)

    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.continuousBeam = true
    weapon.appearance = WeaponAppearance.Repair
    weapon.name = "Repair Beam /* Weapon Name*/"%_t
    weapon.prefix = "Repair /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/repair-beam.png" -- previously laser-heal.png
    weapon.sound = "repair"

    weapon.damageType = DamageType.Energy
    weapon.impactParticles = ImpactParticles.Energy
    if rand:test(0.5) then
        weapon.shieldRepair = dps * fireDelay * rand:getFloat(0.9, 1.1)
        weapon.bouterColor = ColorRGB(0.1, 0.2, 0.4)
        weapon.binnerColor = ColorRGB(0.2, 0.4, 0.9)
    else
        weapon.hullRepair = dps * fireDelay * rand:getFloat(0.9, 1.1)
        weapon.bouterColor = ColorARGB(0.5, 0, 0.5, 0)
        weapon.binnerColor = ColorRGB(1, 1, 1)

        weapon.shieldPenetration = 1
    end

    weapon.blength = weapon.reach
    weapon.bwidth = 0.5
    weapon.bauraWidth = 1
    weapon.banimationSpeed = 4
    weapon.bshapeSize = 2
    weapon.bshape = BeamShape.Swirly

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    return weapon
end

function WeaponGenerator.generateRailGun(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setBeam()

    local fireDelay = rand:getFloat(1, 2.5)
    local reach = rand:getFloat(950, 1400)
    local damage = dps * fireDelay

    weapon.fireDelay = fireDelay
    weapon.appearanceSeed = rand:getInt()
    weapon.reach = reach
    weapon.continuousBeam = false
    weapon.appearance = WeaponAppearance.RailGun
    weapon.name = "Railgun /* Weapon Name*/"%_t
    weapon.prefix = "Railgun /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/rail-gun.png" -- previously beam.png
    weapon.sound = "railgun"
    weapon.accuracy = 0.999 - rand:getFloat(0, 0.01)

    weapon.damage = damage
    weapon.damageType = DamageType.Physical
    weapon.hullDamageMultiplicator = 1.3 + rand:getFloat(0, 0.2) + rarity.value * 0.3
    weapon.impactParticles = ImpactParticles.Physical
    weapon.impactSound = 1
    weapon.blockPenetration = rand:getInt(1, 3 + rarity.value * 2)

    weapon.blength = weapon.reach
    weapon.bshape = BeamShape.Straight
    weapon.bwidth = 0.5
    weapon.bauraWidth = 3
    weapon.banimationSpeed = 1
    weapon.banimationAcceleration = -2

    if rand:getBool() then
        -- shades of red
        weapon.bouterColor = ColorHSV(rand:getFloat(10, 60), rand:getFloat(0.5, 1), rand:getFloat(0.1, 0.5))
        weapon.binnerColor = ColorHSV(rand:getFloat(10, 60), rand:getFloat(0.1, 0.5), 1)
    else
        -- shades of blue
        weapon.bouterColor = ColorHSV(rand:getFloat(180, 260), rand:getFloat(0.5, 1), rand:getFloat(0.1, 0.5))
        weapon.binnerColor = ColorHSV(rand:getFloat(180, 260), rand:getFloat(0.1, 0.5), 1)
    end

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    weapon.recoil = weapon.damage * 20

    return weapon
end

function WeaponGenerator.generateForceGun(rand, force, tech, material, rarity)
    local weapon = Weapon()
    weapon:setBeam()

    local fireDelay = 0.2 -- always the same with beams, does not really matter
    local reach = rand:getFloat(150, 200)

    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.continuousBeam = true
    weapon.appearance = WeaponAppearance.Tesla
    weapon.name = "Force Gun /* Weapon Name*/"%_t
    weapon.prefix = "Force /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/force-gun.png" -- previously echo-ripples.png
    weapon.sound = "beam"
    weapon.material = material
    weapon.rarity = rarity
    weapon.tech = tech

    local forceFactor = (1 + rand:getFloat(0.5, 1) + rarity.value) * material.strengthFactor * material.strengthFactor

    weapon.impactParticles = ImpactParticles.Energy
    weapon.blength = weapon.reach

    local hue = rand:getFloat(0, 360)
    local saturation = 0.3
    local value = 0.1
    local forceType = rand:getInt(1, 6)
    if forceType == 1 then -- ForceType::OtherPush
        weapon.otherForce = force * forceFactor
        weapon.banimationSpeed = 1
        hue = 0
        value = 0.4
        saturation = 0.05
    elseif forceType == 2 then -- ForceType::OtherPull
        weapon.otherForce = -force * forceFactor
        weapon.banimationSpeed = -1
        hue = 240
        value = 0.5
        saturation = 0.2
    elseif forceType == 3 then -- ForceType::SelfPush
        weapon.selfForce = force * forceFactor
        weapon.banimationSpeed = 1
        hue = 60
        value = 0.4
    elseif forceType == 4 then -- ForceType::SelfPull
        weapon.selfForce = -force * forceFactor
        weapon.banimationSpeed = -1
        hue = 180
        value = 0.4
        saturation = 0.1
    elseif forceType == 5 then -- ForceType::BothPush
        weapon.otherForce = force * forceFactor
        weapon.selfForce = force * forceFactor
        weapon.banimationSpeed = 1
        hue = 30
        value = 0.4
    elseif forceType == 6 then -- ForceType::BothPull
        weapon.otherForce = -force * forceFactor
        weapon.selfForce = -force * forceFactor
        weapon.banimationSpeed = -1
        hue = 210
        value = 0.5
        saturation = 0.2
    end

    weapon.bouterColor = ColorHSV(hue, 1, value * 0.25)
    weapon.binnerColor = ColorHSV(hue, saturation, value)
    weapon.bwidth = 0.5
    weapon.bauraWidth = 1
    weapon.banimationSpeed = weapon.banimationSpeed * 4
    weapon.bshape = BeamShape.Straight

    return weapon
end

function WeaponGenerator.generatePulseCannon(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setProjectile()

    -- weaken dps to balance shield penetration
    dps = dps * 0.5

    local fireDelay = rand:getFloat(0.05, 0.2)
    local reach = rand:getFloat(450, 750)
    local damage = dps * fireDelay
    local speed = rand:getFloat(300, 400)
    local existingTime = reach / speed

    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.appearance = WeaponAppearance.PulseCannon
    weapon.name = "Pulse Cannon /* Weapon Name*/"%_t
    weapon.prefix = "Pulse Cannon /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/pulsecannon.png"
    weapon.sound = "pulsecannon"
    weapon.accuracy = 0.99 - rand:getFloat(0, 0.03)

    weapon.damage = damage
    weapon.damageType = DamageType.Physical
    weapon.impactParticles = ImpactParticles.Energy
    weapon.impactSound = 1

    weapon.psize = rand:getFloat(0.08, 0.3)
    weapon.pmaximumTime = existingTime
    weapon.pvelocity = speed
    weapon.pcolor = ColorHSV(rand:getFloat(180, 290), 0.7, 1)

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    weapon.recoil = weapon.damage * 10

    return weapon
end

function WeaponGenerator.generateAntiFighterGun(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setProjectile()

    dps = dps * 0.1

    local fireDelay = rand:getFloat(2, 2.5)
    local reach = rand:getFloat(150, 250)
    local damage = dps * fireDelay
    local speed = rand:getFloat(300, 400)
    local existingTime = reach / speed

    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.appearance = WeaponAppearance.AntiFighter
    weapon.name = "Anti-Fighter Gun /* Weapon Name */"%_t
    weapon.prefix = "Anti-Fighter /* Weapon Prefix */"%_t
    weapon.icon = "data/textures/icons/anti-fighter-gun.png" -- previously flak.png
    weapon.sound = "bolter"
    weapon.accuracy = 0.99 - rand:getFloat(0, 0.03)

    weapon.damage = damage
    weapon.damageType = DamageType.Fragments
    weapon.impactParticles = ImpactParticles.DustExplosion
    weapon.impactSound = 1
    weapon.deathExplosion = true
    weapon.timedDeath = true
    weapon.explosionRadius = 35

    weapon.psize = rand:getFloat(0.3, 0.3)
    weapon.pmaximumTime = existingTime
    weapon.pvelocity = speed
    weapon.pcolor = ColorHSV(rand:getFloat(10, 60), 0.7, 1)

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    -- these have to be assigned after the weapon was adjusted since the damage might be changed
    weapon.recoil = weapon.damage * 75 -- x75 to make up for the reduction to default damage above

    return weapon
end

function WeaponGenerator.generateChaingun(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setProjectile()

    local fireDelay = rand:getFloat(0.04, 0.2)
    local reach = rand:getFloat(300, 450)
    local damage = dps * fireDelay
    local speed = rand:getFloat(300, 400)
    local existingTime = reach / speed

    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.appearance = WeaponAppearance.ChainGun
    weapon.name = "Chaingun /* Weapon Name*/"%_t
    weapon.prefix = "Chaingun /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/chaingun.png" -- previously minigun.png
    weapon.sound = "chaingun"
    weapon.accuracy = 0.99 - rand:getFloat(0, 0.06)

    weapon.damage = damage
    weapon.damageType = DamageType.Physical
    weapon.hullDamageMultiplicator = 1.1 + rand:getFloat(0, 0.2) + rarity.value * 0.1
    weapon.impactParticles = ImpactParticles.Physical
    weapon.impactSound = 1

    weapon.psize = rand:getFloat(0.05, 0.2)
    weapon.pmaximumTime = existingTime
    weapon.pvelocity = speed
    weapon.pcolor = ColorHSV(rand:getFloat(10, 60), 0.7, 1)

    if rand:test(0.05) then
        local shots = {2, 2, 2, 2, 2, 3, 4}
        weapon.shotsFired = shots[rand:getInt(1, #shots)]
        weapon.damage = (weapon.damage * 1.5) / weapon.shotsFired
    end

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    weapon.recoil = weapon.damage * 20

    return weapon
end

function WeaponGenerator.generatePointDefenseChaingun(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setProjectile()

    local fireDelay = rand:getFloat(0.075, 0.1)
    local reach = rand:getFloat(700, 750)
    local damage = (1.5 + (rarity.value * 0.25)) * 0.1
    local speed = rand:getFloat(1000, 1100)
    local existingTime = reach / speed

    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.appearance = WeaponAppearance.ChainGun
    weapon.name = "Point Defense Chaingun /* Weapon Name*/"%_t
    weapon.prefix = "Point Defense Chaingun /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/point-defense-chaingun.png" -- previously minigun.png
    weapon.sound = "chaingun"
    weapon.accuracy = 0.995

    weapon.damage = damage
    weapon.damageType = DamageType.Fragments
    weapon.impactParticles = ImpactParticles.Physical
    weapon.impactSound = 1

    weapon.psize = rand:getFloat(0.05, 0.2)
    weapon.pmaximumTime = existingTime
    weapon.pvelocity = speed
    weapon.pcolor = ColorHSV(rand:getFloat(10, 60), 0.7, 1)

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    weapon.recoil = weapon.damage * 10

    return weapon
end

function WeaponGenerator.generatePlasmaGun(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setProjectile()

    local fireDelay = rand:getFloat(0.15, 0.2)
    local reach = rand:getFloat(550, 800)
    local damage = dps * fireDelay
    local speed = rand:getFloat(400, 600)
    local existingTime = reach / speed

    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.appearance = WeaponAppearance.PlasmaGun
    weapon.name = "Plasma Gun /* Weapon Name*/"%_t
    weapon.prefix = "Plasma /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/plasma-gun.png" -- previously tesla-turret.png
    weapon.sound = "plasma"
    weapon.accuracy = 0.99 - rand:getFloat(0, 0.03)

    weapon.damage = damage
    weapon.damageType = DamageType.Energy
    weapon.impactParticles = ImpactParticles.Energy
    weapon.impactSound = 1
    weapon.shieldDamageMultiplicator = 3 + rand:getFloat(0, 0.4) + rarity.value * 0.4
    weapon.pshape = ProjectileShape.Plasma

    weapon.psize = rand:getFloat(0.4, 0.8)
    weapon.pmaximumTime = existingTime
    weapon.pvelocity = speed
    weapon.pcolor = ColorHSV(rand:getFloat(0, 360), 0.7, 1)

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    weapon.recoil = weapon.damage * 4

    return weapon
end

function WeaponGenerator.generateRocketLauncher(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setProjectile()

    local fireDelay = rand:getFloat(0.5, 1.5)
    local reach = rand:getFloat(1300, 1800)
    local damage = dps * fireDelay
    local speed = rand:getFloat(50, 80)
    local existingTime = reach / speed

    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.seeker = rand:test(1 / 8)
    weapon.appearance = WeaponAppearance.RocketLauncher
    weapon.name = "Rocket Launcher /* Weapon Name*/"%_t
    weapon.prefix = "Launcher /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/rocket-launcher.png" -- previously missile-swarm.png
    weapon.sound = "launcher"
    weapon.accuracy = 0.99 - rand:getFloat(0, 0.02)

    weapon.damage = damage
    weapon.damageType = DamageType.Physical
    weapon.impactParticles = ImpactParticles.Explosion
    weapon.impactSound = 1
    weapon.impactExplosion = true

    weapon.psize = rand:getFloat(0.2, 0.4)
    weapon.pmaximumTime = existingTime
    weapon.pvelocity = speed
    weapon.pcolor = ColorHSV(rand:getFloat(10, 60), 0.7, 1)
    weapon.pshape = ProjectileShape.Rocket

    if rand:test(0.05) then
        local shots = {2, 2, 2, 2, 2, 3, 4}
        weapon.shotsFired = shots[rand:getInt(1, #shots)]
        weapon.damage = (weapon.damage * 1.5) / weapon.shotsFired
    end

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    -- these have to be assigned after the weapon was adjusted since the damage might be changed
    weapon.recoil = weapon.damage * 2
    weapon.explosionRadius = math.sqrt(weapon.damage * 5)

    return weapon
end

function WeaponGenerator.generateCannon(rand, dps, tech, material, rarity)
    local weapon = Weapon()
    weapon:setProjectile()

    local fireDelay = rand:getFloat(1.5, 2.5)
    local reach = rand:getFloat(1100, 1500)
    local damage = dps * fireDelay
    local speed = rand:getFloat(300, 400)
    local existingTime = reach / speed

    weapon.fireDelay = fireDelay
    weapon.reach = reach
    weapon.appearanceSeed = rand:getInt()
    weapon.appearance = WeaponAppearance.Cannon
    weapon.name = "Cannon /* Weapon Name*/"%_t
    weapon.prefix = "Cannon /* Weapon Prefix*/"%_t
    weapon.icon = "data/textures/icons/cannon.png" -- previously hypersonic-bolt.png
    weapon.sound = "cannon"
    weapon.accuracy = 0.99 - rand:getFloat(0, 0.01)

    weapon.damage = damage
    weapon.damageType = DamageType.Physical
    weapon.impactParticles = ImpactParticles.Explosion
    weapon.impactSound = 1
    weapon.impactExplosion = true

    weapon.psize = rand:getFloat(0.2, 0.5)
    weapon.pmaximumTime = existingTime
    weapon.pvelocity = speed
    weapon.pcolor = ColorHSV(rand:getFloat(10, 60), 0.7, 1)

    WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)

    -- these have to be assigned after the weapon was adjusted since the damage might be changed
    weapon.recoil = weapon.damage * 20
    weapon.explosionRadius = math.sqrt(weapon.damage * 5)

    return weapon
end

local generatorFunction = {}
generatorFunction[WeaponType.ChainGun            ] = WeaponGenerator.generateChaingun
generatorFunction[WeaponType.PointDefenseChainGun] = WeaponGenerator.generatePointDefenseChaingun
generatorFunction[WeaponType.PointDefenseLaser   ] = WeaponGenerator.generatePointDefenseLaser
generatorFunction[WeaponType.Laser               ] = WeaponGenerator.generateLaser
generatorFunction[WeaponType.MiningLaser         ] = WeaponGenerator.generateMiningLaser
generatorFunction[WeaponType.RawMiningLaser      ] = WeaponGenerator.generateRawMiningLaser
generatorFunction[WeaponType.SalvagingLaser      ] = WeaponGenerator.generateSalvagingLaser
generatorFunction[WeaponType.RawSalvagingLaser   ] = WeaponGenerator.generateRawSalvagingLaser
generatorFunction[WeaponType.PlasmaGun           ] = WeaponGenerator.generatePlasmaGun
generatorFunction[WeaponType.RocketLauncher      ] = WeaponGenerator.generateRocketLauncher
generatorFunction[WeaponType.Cannon              ] = WeaponGenerator.generateCannon
generatorFunction[WeaponType.RailGun             ] = WeaponGenerator.generateRailGun
generatorFunction[WeaponType.RepairBeam          ] = WeaponGenerator.generateRepairBeamEmitter
generatorFunction[WeaponType.Bolter              ] = WeaponGenerator.generateBolter
generatorFunction[WeaponType.LightningGun        ] = WeaponGenerator.generateLightningGun
generatorFunction[WeaponType.TeslaGun            ] = WeaponGenerator.generateTeslaGun
generatorFunction[WeaponType.ForceGun            ] = WeaponGenerator.generateForceGun
generatorFunction[WeaponType.PulseCannon         ] = WeaponGenerator.generatePulseCannon
generatorFunction[WeaponType.AntiFighter         ] = WeaponGenerator.generateAntiFighterGun

function WeaponGenerator.generateWeapon(rand, type, dps, tech, material, rarity)
    return generatorFunction[type](rand, dps, tech, material, rarity)
end

function WeaponGenerator.adaptWeapon(rand, weapon, tech, material, rarity)
    local variation = rand:getFloat(WEAPON_STRENGTHMINVARIATION, WEAPON_STRENGTHMAXVARIATION)
    local dpsFactor = 1 + rarity.value * 0.5

    weapon.tech = tech
    weapon.material = material
    weapon.rarity = rarity

    if weapon.damage ~= 0 then weapon.damage = weapon.damage * dpsFactor * variation end
    if weapon.shieldRepair ~= 0 then weapon.shieldRepair = weapon.shieldRepair * dpsFactor * variation end
    if weapon.hullRepair ~= 0 then weapon.hullRepair = weapon.hullRepair * dpsFactor * variation end
end

function WeaponGenerator.adaptMiningLaser(rand, weapon, tech, material, rarity)
    local variation = rand:getFloat(WEAPON_STRENGTHMINVARIATION, WEAPON_STRENGTHMAXVARIATION)
    local dpsFactor = 1 + rarity.value * 0.05

    weapon.tech = tech
    weapon.material = material
    weapon.rarity = rarity

    if weapon.damage ~= 0 then weapon.damage = weapon.damage * dpsFactor * variation end
end

function WeaponGenerator.getStoneDamageMultiplicator()
    return 200
end

return WeaponGenerator
