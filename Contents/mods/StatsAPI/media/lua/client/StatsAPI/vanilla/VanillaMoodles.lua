local StatsAPI = require "StatsAPI/StatsAPI"

local VanillaMoodles = {}

VanillaMoodles.addMoodles = function()
    -- there should be a toggle to turn these off, but currently the entire thing will explode if they're missing
    local hungerIcon = getTexture("media/ui/Moodles/Moodle_Icon_Hungry.png")
    StatsAPI.addMoodle("hungry", hungerIcon)
    StatsAPI.addMoodle("foodeaten", hungerIcon, 4, true)
    StatsAPI.addMoodle("thirst", "media/ui/Moodles/Moodle_Icon_Thirsty.png")
    StatsAPI.addMoodle("bored", "media/ui/Moodles/Moodle_Icon_Bored.png")
    StatsAPI.addMoodle("stress", "media/ui/Moodles/Moodle_Icon_Stressed.png")
    StatsAPI.addMoodle("endurance", "media/ui/Moodles/Moodle_Icon_Endurance.png")
    StatsAPI.addMoodle("tired", "media/ui/Moodles/Moodle_Icon_Tired.png")
    StatsAPI.addMoodle("panic", "media/ui/Moodles/Moodle_Icon_Panic.png")
    StatsAPI.addMoodle("sick", "media/ui/Moodles/Moodle_Icon_Sick.png")
    StatsAPI.addMoodle("unhappy", "media/ui/Moodles/Moodle_Icon_Unhappy.png")
    StatsAPI.addMoodle("bleeding", "media/ui/Moodles/Moodle_Icon_Bleeding.png", 4, false, nil, "bleed")
    StatsAPI.addMoodle("wet", "media/ui/Moodles/Moodle_Icon_Wet.png")
    StatsAPI.addMoodle("hasacold", "media/ui/Moodles/Moodle_Icon_Cold.png", 4, false, "hascold", "hasacold")
    StatsAPI.addMoodle("injured", "media/ui/Moodles/Moodle_Icon_Injured.png")
    StatsAPI.addMoodle("pain", "media/ui/Moodles/Moodle_Icon_Pain.png")
    StatsAPI.addMoodle("heavyload", "media/ui/Moodles/Moodle_Icon_HeavyLoad.png")
    StatsAPI.addMoodle("drunk", "media/ui/Moodles/Moodle_Icon_Drunk.png")
    StatsAPI.addMoodle("hyperthermia", "media/ui/weather/Moodle_Icon_TempHot.png")
    StatsAPI.addMoodle("hypothermia", "media/ui/weather/Moodle_Icon_TempCold.png")
    StatsAPI.addMoodle("windchill", "media/ui/Moodle_Icon_Windchill.png")
    StatsAPI.addMoodle("CantSprint", "media/ui/Moodle_Icon_CantSprint.png", 1)
end

Events.OnGameBoot.Add(VanillaMoodles.addMoodles)

---@param attacker IsoGameCharacter
---@param weapon HandWeapon
---@param target IsoMovingObject
---@param damage number
VanillaMoodles.onWeaponHit = function(attacker, weapon, target, damage)
    if not attacker:isLocal() then return end
    local parts
    if attacker:isAimAtFloor() and attacker:isDoShove() then
        parts = {BodyPartType.UpperLeg_L, BodyPartType.LowerLeg_L, BodyPartType.Foot_L,
                 BodyPartType.UpperLeg_R, BodyPartType.LowerLeg_R, BodyPartType.Foot_R}
    else
        parts = {BodyPartType.UpperArm_L, BodyPartType.ForeArm_L, BodyPartType.Hand_L,
                 BodyPartType.UpperArm_R, BodyPartType.ForeArm_R, BodyPartType.Hand_R}
    end
    
    local bodyDamage = attacker:getBodyDamage()
    local pain = 0
    for i = 1, #parts do
        pain = pain + bodyDamage:getBodyPart(parts[i]):getPain()
    end
    if pain > 10 then
        StatsAPI.wiggleMoodle(attacker, StatsAPI.MoodleType.Panic)
        StatsAPI.wiggleMoodle(attacker, StatsAPI.MoodleType.Injured)
    end
    
    local panicLevel = StatsAPI.getMoodleLevel(attacker, StatsAPI.MoodleType.Panic)
    
    if weapon:isRanged() then
        if attacker:getPerkLevel(Perks.Aiming) < 6 and panicLevel > 2 then
            StatsAPI.wiggleMoodle(attacker, StatsAPI.MoodleType.Panic)
        end
    else
        if panicLevel > 1 then
            StatsAPI.wiggleMoodle(attacker, StatsAPI.MoodleType.Panic)
        end
        if StatsAPI.getMoodleLevel(attacker, StatsAPI.MoodleType.Endurance) > 0 then
            StatsAPI.wiggleMoodle(attacker, StatsAPI.MoodleType.Endurance)
        end
        if StatsAPI.getMoodleLevel(attacker, StatsAPI.MoodleType.Tired) > 0 then
            StatsAPI.wiggleMoodle(attacker, StatsAPI.MoodleType.Tired)
        end
    end
    
    if StatsAPI.getMoodleLevel(attacker, StatsAPI.MoodleType.Stress) > 1 then
        StatsAPI.wiggleMoodle(attacker, StatsAPI.MoodleType.Stress)
    end
end

Events.OnWeaponHitXp.Add(VanillaMoodles.onWeaponHit)

return VanillaMoodles