log("[LunaHUD] [COMBAT] Health & Shield Feedback")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunaHUD: Player Damage Logic - Status Link & Stability ]]

-- 1. HUD FEEDBACK (Lägg till dessa rader)
Hooks:PostHook(PlayerDamage, "restore_health", "LunaHUD_HP_Feedback", function(self, health_restored)
    if _G.LunaStatus and health_restored and health_restored > 0 then
        LunaStatus:ShowStatus(health_restored * 10, "health")
    end
end)

Hooks:PostHook(PlayerDamage, "restore_armor", "LunaHUD_Armor_Feedback", function(self, armor_restored)
    if _G.LunaStatus and armor_restored and armor_restored > 0 then
        LunaStatus:ShowStatus(armor_restored * 10, "armor")
    end
end)

-- 2. STABILITETS-FIXAR (Behåll dessa från din gamla fil)
PlayerDamage.shake_player = function() return nil end
function PlayerDamage:_apply_damage_to_camera(data) return end

