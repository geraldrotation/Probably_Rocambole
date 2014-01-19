-- ProbablyEngine Rotation Packager
-- Custom Restoration Druid Rotation
-- Created on Jan 17th 2014 2:35 pm

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

ProbablyEngine.rotation.register_custom(105, "Rocambole", {

------------------------------
--Special Binds
------------------------------
--Incarnation Modifier
 { "Incarnation: Tree of Life", "modifier.rshift" },
 
--Tranquility Modifier
 { "Tranquility", "modifier.rcontrol" },
 
--Shrooms
 { "Wild Mushroom", "modifier.lalt", "ground" },
 { "Wild Mushroom: Bloom", "modifier.lcontrol" },

------------------------------
--Self Shit
------------------------------
--Innervate
 { "Innervate", "player.mana <= 77", "player" },

--Ima Troll
 { "Berserking", "player.buff(Bloodlust)" },

------------------------------
--Incarnation Talent
------------------------------
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
 
------------------------------
--SoO Dispells
------------------------------
 { "88423", "@coreHealing.needsDispelled(Aqua Bomb)" },
 { "88423", "@coreHealing.needsDispelled(Aqua Bomb)" },
 { "88423", "@coreHealing.needsDispelled(Shadow Word: Bane)" }, 
 { "88423", "@coreHealing.needsDispelled(Lingering Corruption)" },
 { "88423", { "player.buff(144359)", "@coreHealing.needsDispelled(Mark of Arrogance)" }},
 { "88423", "@coreHealing.needsDispelled(Corrosive Blood)" }, 
 { "8936", { "lowest.health < 100", "!lowest.buff(8936)" }, "target.id(71604)" },
 { "5185", { "lowest.health < 100", "lowest.buff(8936)", }, "target.id(71604)" },

------------------------------
--TANK REBIRTH
------------------------------
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

------------------------------
--Don't step on the fire!
------------------------------
--SELF!
 { "Barkskin", "player.health <= 40" },
 { "Might of Ursoc", "player.health < 30" },
 
-- Healthstone
 {"#5512", "player.health <= 45"}, 

--Iron Bark for Tank
 { "Ironbark", {
   "tank.health < 15",
   "!tank.range > 40"
 }, "tank" },

------------------------------
--Let the Healz Begin
------------------------------
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

-----------------------------------
--OoC Healing/Buffing
-----------------------------------
--MOTW
 { "Mark of the Wild", { 
   "!player.buff(Mark of the Wild).any",
   "!player.buff(Blessing of Kings).any",
   "!player.buff(Legacy of the Emperor).any" }},
 
--Shrooms
 { "Wild Mushroom", "modifier.lalt", "ground" },
 { "Wild Mushroom: Bloom", "modifier.lcontrol" },  
 
 -- Healthstone
 {"#5512", "player.health <= 45"}, 
 
})