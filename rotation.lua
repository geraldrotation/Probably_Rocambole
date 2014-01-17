-- ProbablyEngine Rotation Packager
-- Custom Restoration Druid Rotation
-- Created on Jan 17th 2014 2:35 pm

ProbablyEngine.raid = {
  roster = {}
}

local GetSpellInfo = GetSpellInfo
local GetNumGroupMembers = GetNumGroupMembers
local IsInRaid = IsInRaid
local UnitCanAssist = UnitCanAssist
local UnitDebuff = UnitDebuff
local UnitExists = UnitExists
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetTotalHealAbsorbs = UnitGetTotalHealAbsorbs
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitInParty = UnitInParty
local UnitInRange = UnitInRange
local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsFriend = UnitIsFriend
local UnitUsingVehicle = UnitUsingVehicle

local function canHeal(unit)
  if UnitExists(unit)
     and UnitCanAssist('player', unit)
     and UnitIsFriend('player', unit)
     and UnitIsConnected(unit)
     and not UnitIsDeadOrGhost(unit)
     and not UnitUsingVehicle(unit) then

     if UnitInParty(unit) and not UnitInRange(unit) then
       return false
     end

     return true
  end

  return false
end

local ancientBarrierDebuffs = { GetSpellInfo(142861), GetSpellInfo(142863), GetSpellInfo(142864), GetSpellInfo(142865) }
local function ancientBarrier(unit)
  if not UnitDebuff(unit, ancientBarrierDebuffs[1]) then
    return false
  end

	local amount
	for i= 2, 4 do
		amount = select(15, UnitDebuff('player', ancientBarrierDebuffs[i]))
		if amount then
      return amount
		end
	end

	return false
end

local function updateHealth(index)
  if not ProbablyEngine.raid.roster[index] then
    return
  end

  local unit = ProbablyEngine.raid.roster[index].unit

  local incomingHeals = UnitGetIncomingHeals(unit) or 0
  local absorbs = UnitGetTotalHealAbsorbs(unit) or 0

  local health = UnitHealth(unit) + incomingHeals - absorbs
  local maxHealth = UnitHealthMax(unit)

  local ancientBarrierShield = ancientBarrier(unit)
  if ancientBarrierShield then
    health = ancientBarrierShield
  end

  ProbablyEngine.raid.roster[index].health = health / maxHealth * 100
  ProbablyEngine.raid.roster[index].healthMissing = maxHealth - health
  ProbablyEngine.raid.roster[index].maxHealth = maxHealth  
end

ProbablyEngine.raid.updateHealth = function (unit)
  if type(unit) == 'number' then
    return updateHealth(unit)
  end

  if unit == 'focus' then return updateHealth(-2) end
  if unit == 'target' then return updateHealth(-1) end
  if unit == 'player' then return updateHealth(0) end


  local prefix = (IsInRaid() and 'raid') or 'party'
  if unit:find(prefix) then
    return updateHealth(tonumber(unit:sub(#prefix + 1)))
  end
end

ProbablyEngine.raid.build = function()
  local groupMembers = GetNumGroupMembers()
  local rosterLength = #ProbablyEngine.raid.roster
  local prefix = (IsInRaid() and 'raid') or 'party'

  local i, unit
  for i = -2, groupMembers -1 do
    unit = (i == -2 and 'focus') or (i == -1 and 'target') or (i == 0 and 'player') or prefix .. i

    if not ProbablyEngine.raid.roster[i] then ProbablyEngine.raid.roster[i] = {} end

    ProbablyEngine.raid.roster[i].unit = unit
    if UnitExists(unit) and not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit) then
      ProbablyEngine.raid.roster[i].role = UnitGroupRolesAssigned(unit)
      updateHealth(i)
    end
  end

  if groupMembers > rosterLength then
    return
  end

  for i = groupMembers + 1, rosterLength do
    ProbablyEngine.raid.roster[i] = nil
  end
end

ProbablyEngine.raid.lowestHP = function()
  local lowestUnit = 'player'
  if canHeal('focus') then lowestUnit = 'focus' end

  local lowest = 100

  for _, unit in pairs(ProbablyEngine.raid.roster) do
    if canHeal(unit.unit) and unit.health and unit.health < lowest then
      lowest = unit.health
      lowestUnit = unit.unit
    end
  end

  return lowestUnit
end

ProbablyEngine.raid.raidPercent = function()
  local groupMembers = GetNumGroupMembers()
  local rosterLength = #ProbablyEngine.raid.roster

  if groupMembers == 0 then
    return 100
  end

  local total = 0
  for i = 0, rosterLength do
    total = total + ProbablyEngine.raid.roster[i].health
  end

  return total / groupMembers
end

ProbablyEngine.raid.needsHealing = function(threshold)
  if not threshold then threshold = 80 end

  local needsHealing = 0
  for i = 0, #ProbablyEngine.raid.roster do
    if ProbablyEngine.raid.roster[i].health <= threshold then
      needsHealing = needsHealing + 1
    end
  end

  return needsHealing
end

ProbablyEngine.raid.tank = function()
  if canHeal('focus') then
    return 'focus'
  end

  local tank = 'player'
  local highestUnit

  local lowest, highest = 100, 0
  for _, unit in pairs(ProbablyEngine.raid.roster) do
    if canHeal(unit.unit) then
      if unit.role == 'TANK' then
        if unit.health and unit.health < lowest then
          lowest = unit.health
          tank = unit.unit
        end
      else
        if unit.maxHealth and unit.maxHealth > highest then
          highest = unit.maxHealth
          highestUnit = unit.unit
        end
      end
    end
  end

  if GetNumGroupMembers() > 0 and tank == 'player' then
    tank = highestUnit
  end

  return tank
end
ProbablyEngine.library.register('coreHealing', {
   needsHealing = function(percent, count)
    return ProbablyEngine.raid.needsHealing(tonumber(percent)) >= count
  end,
  needsDispelled = function(spell)
    for unit,_ in pairs(ProbablyEngine.raid.roster) do
      if UnitDebuff(unit, spell) then
        ProbablyEngine.dsl.parsedTarget = unit
        return true
      end
    end
  end,
})

ProbablyEngine.rotation.register_custom(105, "Rocambole's Resto Druid", {

-----------------------
--Special Binds
-----------------------
--Incarnation Modifier
 { "Incarnation: Tree of Life", "modifier.rshift" },
 
--Tranquility Modifier
 { "Tranquility", "modifier.rcontrol" },
 
--Shrooms
 { "Wild Mushroom", "modifier.lalt", "ground" },
 { "Wild Mushroom: Bloom", "modifier.lcontrol" },

-----------------------
--Self Shit
-----------------------
--Innervate
 { "Innervate", "player.mana <= 77", "player" },

--Cancel Druid Forms
 { "!/cancelaura Cat Form", "!player.buff(137452)" },

--MotW
 { "Mark of the Wild", { 
   "!player.buff(Mark of the Wild).any",
   "!player.buff(Blessing of Kings).any",
   "!player.buff(Legacy of the Emperor).any" }},

--Symbiosis NEED WORK
-- { "symbosis.castOn("Monk", "Shaman", "Mage")" },

--Ima Troll
 { "Berserking", "player.buff(Bloodlust)" },

-----------------------
--Incarnation Talent
-----------------------
--Regrowth
 { "Regrowth", {
   "player.buff(33891)",
   "!lowest.buff(Regrowth)",
   "lowest.health <= 80",
   "!lowest.range > 40"
 }, "lowest" },

--Wildgrowth
 { "48438", {
   "player.buff(33891)",
   "@coreHealing.needsHealing(100, 1)",
   "!tank.range > 40"
 }, "lowest" },
 
--Lifebloom Spam
 { "33763", {
   "player.buff(33891)",
   "lowest.health < 99",
   "lowest.buff(33763).count < 3",
   "!lowest.range > 40"
 }, "lowest" },
 
 { "33763", {
   "player.buff(33891)",
   "lowest.buff(33763).duration <= 2",
   "!lowest.range > 40"
 }, "lowest" },
 
-----------------------
--SoO Dispells
-----------------------
 { "88423", "@coreHealing.needsDispelled(Aqua Bomb)" },
 { "88423", "@coreHealing.needsDispelled(Aqua Bomb)" },
 { "88423", "@coreHealing.needsDispelled(Shadow Word: Bane)" }, 
 { "88423", "@coreHealing.needsDispelled(Lingering Corruption)" },
 { "88423", { "player.buff(144359)", "@coreHealing.needsDispelled(Mark of Arrogance)" }},
 { "88423", "@coreHealing.needsDispelled(Corrosive Blood)" }, 
 { "8936", { "lowest.health < 100", "!lowest.buff(8936)" }, "target.id(71604)" },
 { "5185", { "lowest.health < 100", "lowest.buff(8936)", }, "target.id(71604)" },

-----------------------
--TANK REBIRTH
-----------------------
 { "Rebirth", {
  "player.buff(132158)",
  "tank.Health = 0",
  "!tank.range > 40"
 }, "tank" },

 { "Nature's Swiftness", {
   "tank.Health = 0",
   "!tank.range > 40"
 }, "tank" },

 { "Rebirth", {
   "!player.buff(Nature's Swiftness)",
   "tank.Health = 0",
   "!tank.range > 40"
 }, "tank" },

-----------------------
--Don't step on the fire!
-----------------------
--SELF!
 { "Barkskin", "player.health <= 40" },
 { "Might of Ursoc", "player.health < 30" },
 { "!/cancelaura Bear Form", "!player.buff(Might of Ursoc)" },
 
--Iron Bark for Tank
 { "Ironbark", {
   "tank.health < 15",
   "!tank.range > 40"
 }, "tank" },

-----------------------
--Let the Healz Begin
-----------------------
--Tank Rejuvenation
 { "Rejuvenation", {
   "tank.health <= 100",
   "!tank.buff(Rejuvenation)",
   "!tank.range > 40"
 }, "tank" },
 
--Life Bloom Tank
 { "33763", {
   "tank.buff(33763).count < 3",
   "!tank.range > 40"
 }, "tank" },
 
 { "33763", {
   "tank.buff(33763).duration < 2",
   "!tank.range > 40"
 }, "tank" },
   
--Raid Rejuvenation
 { "Rejuvenation", {
   "lowest.health <= 78",
   "!lowest.buff(Rejuvenation)",
   "!lowest.range > 40"
 }, "lowest" },
 
--Raid Swiftmend
 { "Swiftmend", {
   "lowest.buff(Rejuvenation)",
   "lowest.health <= 75",
   "!lowest.range > 40"
 }, "lowest" },
 
--Tank Swiftmend
 { "Swiftmend", {
   "lowest.buff(Rejuvenation)",
   "lowest.health <= 95",
   "!tank.range > 40"
 }, "lowest" },
 
--Regrowth
 { "Regrowth", {
   "lowest.health <= 55",
   "!lowest.buff(Regrowth)",
   "!lowest.range > 40"
 }, "lowest" },
 
--Regrowth Clearcasting
 { "Regrowth", { 
   "player.buff(16870)", 
   "!lowest.buff(Regrowth)",
   "lowest.health < 60",
   "!lowest.range > 40"
 }, "lowest" },
 
--SoTF WildGrowth
 { "Wild Growth", {
   "modifier.last(Swiftmend)",
   "player.spell(Soul of the Forest).exists"
 }, "lowest" },

--Wildgrowth
 { "48438", {
   "@coreHealing.needsHealing(95, 3)",
   "lowest.range < 38"
 }, "lowest" },
 
--Healing Touch
 { "Healing Touch", {
   "lowest.health < 60",
   "!lowest.range > 40"
 }, "lowest" },

--Healing Touch (Sage Mender)
 { "Healing Touch", {
   "player.buff(Sage Mender).count = 5",
   "lowest.health <= 80",
   "lowest.range < 38"
 }, "lowest" },

--Healing Touch (Clearcasting)
 { "Healing Touch", {
   "player.buff(16870)",
   "lowest.health <= 70",
   "!lowest.range > 40"
 }, "lowest" },
 }, {

-----------------------
--OoC Healing/Buffing
-----------------------
--MOTW
 { "Mark of the Wild", { 
   "!player.buff(Mark of the Wild).any",
   "!player.buff(Blessing of Kings).any",
   "!player.buff(Legacy of the Emperor).any" }},

--Shrooms
 { "Wild Mushroom", "modifier.lalt", "ground" },
 { "Wild Mushroom: Bloom", "modifier.lcontrol" },
 
 } )