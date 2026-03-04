log("[LunaHUD] [UI] Layout & Panel Orchestrator")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Personal Dashboard Manager V5.4 ]]

Hooks:PostHook(HUDManager, "_setup_player_info_hud_pd2", "Luna_PersonalHUD", function(self)
    local player_panel = self._teammate_panels[HUDManager.PLAYER_PANEL]
    if not player_panel then return end
    local root = player_panel._panel

    -- Skapa textobjekt med shadow-font för läsbarhet
    player_panel._luna_ar = player_panel._luna_ar or root:text({
        name = "luna_ar", font = "fonts/font_medium_shadow_mf", font_size = 32, -- Massive Armor
        color = Color(0, 0.5, 1), layer = 100
    })
    player_panel._luna_hp = player_panel._luna_hp or root:text({
        name = "luna_hp", font = "fonts/font_medium_shadow_mf", font_size = 18, -- Subtle Health
        color = Color(0, 1, 0.2), layer = 100
    })
end)

Hooks:PostHook(HUDManager, "update", "Luna_StatusUpdate", function(self, t, dt)
    local player_panel = self._teammate_panels[HUDManager.PLAYER_PANEL]
    if not player_panel or not player_panel._panel:visible() then return end
    
    local hp_data = player_panel._health_data or { current = 1, total = 1 }
    local ar_data = player_panel._armor_data or { current = 1, total = 1 }
    local root = player_panel._panel

    -- Uppdatera din HP/AR Dashboard
    if player_panel._luna_ar then
        player_panel._luna_ar:set_text(string.format("%03d AR", math.floor(ar_data.current * 10)))
        player_panel._luna_ar:set_right(root:w() - 145)
        player_panel._luna_ar:set_bottom(root:h() - 25)
    end
    if player_panel._luna_hp then
        player_panel._luna_hp:set_text(string.format("%03d HP", math.floor(hp_data.current * 10)))
        player_panel._luna_hp:set_right(root:w() - 145)
        player_panel._luna_hp:set_bottom(root:h() - 5)
    end

    -- Flytta Times Downed (3x) till vänster om dashboarden
    local revive = player_panel._player_panel:child("revive_panel")
    if revive then
        revive:set_visible(true)
        revive:set_right(root:w() - 280)
        revive:set_bottom(root:h() - 5)
    end
end)

