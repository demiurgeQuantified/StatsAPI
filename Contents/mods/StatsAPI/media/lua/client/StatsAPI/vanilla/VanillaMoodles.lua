local StatsAPI = require "StatsAPI/StatsAPI"
-- there should be a toggle to turn these off, but currently the entire thing will explode if they're missing

StatsAPI.addMoodle("thirst", "media/ui/Moodles/Moodle_Icon_Thirsty.png")

local hungerIcon = getTexture("media/ui/Moodles/Moodle_Icon_Hungry.png")
StatsAPI.addMoodle("hungry", hungerIcon)
StatsAPI.addMoodle("foodeaten", hungerIcon, 4, true)

StatsAPI.addMoodle("bored", "media/ui/Moodles/Moodle_Icon_Bored.png")
StatsAPI.addMoodle("stress", "media/ui/Moodles/Moodle_Icon_Stressed.png")
StatsAPI.addMoodle("endurance", "media/ui/Moodles/Moodle_Icon_Endurance.png")
StatsAPI.addMoodle("tired", "media/ui/Moodles/Moodle_Icon_Tired.png")
StatsAPI.addMoodle("panic", "media/ui/Moodles/Moodle_Icon_Panic.png")
StatsAPI.addMoodle("sick", "media/ui/Moodles/Moodle_Icon_Sick.png")
StatsAPI.addMoodle("unhappy", "media/ui/Moodles/Moodle_Icon_Unhappy.png")
StatsAPI.addMoodle("bleeding", "media/ui/Moodles/Moodle_Icon_Bleeding.png")
StatsAPI.addMoodle("wet", "media/ui/Moodles/Moodle_Icon_Wet.png")
StatsAPI.addMoodle("hasacold", "media/ui/Moodles/Moodle_Icon_Cold.png")
StatsAPI.addMoodle("injured", "media/ui/Moodles/Moodle_Icon_Injured.png")
StatsAPI.addMoodle("pain", "media/ui/Moodles/Moodle_Icon_Pain.png")
StatsAPI.addMoodle("heavyload", "media/ui/Moodles/Moodle_Icon_HeavyLoad.png")
StatsAPI.addMoodle("drunk", "media/ui/Moodles/Moodle_Icon_Drunk.png")
StatsAPI.addMoodle("hyperthermia", "media/ui/weather/Moodle_Icon_TempHot.png")
StatsAPI.addMoodle("hypothermia", "media/ui/weather/Moodle_Icon_TempCold.png")
StatsAPI.addMoodle("windchill", "media/ui/Moodle_Icon_Windchill.png")
StatsAPI.addMoodle("CantSprint", "media/ui/Moodle_Icon_CantSprint.png", 1)