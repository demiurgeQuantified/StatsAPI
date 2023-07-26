local StatsAPI = require "StatsAPI/StatsAPI"

-- there should be a toggle to turn these off, but currently the entire thing will explode if they're missing
StatsAPI.addMoodle("stress", getTexture("media/ui/Moodles/Moodle_Icon_Stressed.png"), 4)
StatsAPI.addMoodle("foodeaten", getTexture("media/ui/Moodles/Moodle_Icon_Hungry.png"), 4, true)