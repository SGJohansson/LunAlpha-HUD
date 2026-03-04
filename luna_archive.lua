log("[LunaHUD] [DATA] Legacy Stats Archive")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: The Archive - TAB History ]]

_G.LunaHUD = _G.LunaHUD or {}
_G.LunaHUD.archive = _G.LunaHUD.archive or {}

-- 1. SPARA HISTORIK (Händer när ett mål blir klart)
Hooks:PostHook(ObjectivesManager, "complete_objective", "LunaArchive_Record", function(self, id)
    local objective = self._objectives[id]
    if objective and objective.text then
        local t = managers.game_play_central:get_heist_timer()
        local timestamp = string.format("[%02d:%02d]", math.floor(t/60), math.floor(t%60))
        
        table.insert(_G.LunaHUD.archive, {
            text = utf8.to_upper(objective.text),
            time = timestamp
        })
    end
end)

-- 2. RITA ARKIVET I TAB-MENYN (Modifierar HUDStatsScreen)
-- Vi använder källkoden du skickade för att hitta rätt panel
local old_create_stats = HUDStatsScreen._create_stats_screen_objectives
function HUDStatsScreen:_create_stats_screen_objectives(panel)
    panel:clear() -- Rensa originalet
    
    local y = 0
    local x = 10
    local font = tweak_data.menu.pd2_small_font
    local font_size = 18

    -- RITA ARKIVET (avklarade mål)
    for i, data in ipairs(_G.LunaHUD.archive) do
        local log_entry = panel:text({
            text = data.time .. "  " .. data.text,
            font = font,
            font_size = font_size - 2,
            color = Color.white:with_alpha(0.3), -- Stoiskt grå/vit
            x = x, y = y,
            layer = 1
        })
        y = y + log_entry:h() + 2
    end

    -- RITA AKTIVA MÅL (Guld-branding)
    for id, data in pairs(managers.objectives:get_active_objectives()) do
        local active_entry = panel:text({
            text = ">  " .. utf8.to_upper(data.text),
            font = font,
            font_size = font_size,
            color = Color(1, 0.84, 0), -- Luna-guld
            x = x, y = y,
            layer = 1
        })
        y = y + active_entry:h() + 2
    end
end

