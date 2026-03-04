log("[LunaHUD] [UI] Combat Statistics Feed")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Combat Stats Feed V2.1 - Color Fix ]]
_G.LunaStats = _G.LunaStats or { alpha_t = 0, last_update = 0 }

-- DEL 1: Fånga "Kills" för att trigga Alpha-spiken
if RequiredScript == "lib/managers/statisticsmanager" then
    Hooks:PostHook(StatisticsManager, "killed", "Luna_StatsFeed_Spike", function(self)
        _G.LunaStats.alpha_t = 10.0 
    end)

-- DEL 2: Rendera och uppdatera texten på skärmen
elseif RequiredScript == "lib/managers/hudmanagerpd2" then
    Hooks:PostHook(HUDManager, "update", "Luna_StatsFeed_Update", function(self, t, dt)
        local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
        if not hud or not hud.panel then return end

        -- 1. SETUP (Lazy Load - Garanterar att den ritas)
        if not self._luna_stats_text then
            local font = tweak_data.menu.pd2_small_font
            self._luna_stats_text = hud.panel:text({
                name = "luna_stats_feed_text",
                text = "",
                font = font,
                font_size = 18,
                color = Color.white,
                align = "center",
                vertical = "top",
                layer = 1,
                x = 0,
                y = 5 -- 5px från toppen
            })
            self._luna_stats_text:set_center_x(hud.panel:w() / 2)
        end

        local text_obj = self._luna_stats_text

        -- 2. TOGGLE CHECK
        if not _G.LunaHUD.settings.show_stats then
            text_obj:set_visible(false)
            return
        end
        text_obj:set_visible(true)

        -- 3. THROTTLING LOGIC (Prestandaoptimering: Körs bara 4 ggr/sekund)
        if t - _G.LunaStats.last_update > 0.25 then
            _G.LunaStats.last_update = t
            
            if managers.statistics then
                local kills = managers.statistics:session_total_kills()
                local specs = managers.statistics:session_total_specials_kills()
                local acc = managers.statistics:session_hit_accuracy()
                
                -- Färg-säker stränguppbyggnad (Låter motorn sköta teckenlängden)
                local lbl_k = "KILLS: "
                local val_k = tostring(kills)
                local lbl_s = "  |  SPEC: "
                local val_s = tostring(specs)
                local lbl_a = "  |  ACC: "
                local val_a = tostring(acc) .. "%"
                
                text_obj:set_text(lbl_k .. val_k .. lbl_s .. val_s .. lbl_a .. val_a)
                
                -- Nollställ allt till vitt först för en ren canvas
                text_obj:set_color(Color.white) 
                
                -- KILLS (Guld)
                local pos1 = #lbl_k
                local pos2 = pos1 + #val_k
                text_obj:set_range_color(pos1, pos2, Color(1, 0.84, 0))
                
                -- SPEC (Blå)
                local pos3 = pos2 + #lbl_s
                local pos4 = pos3 + #val_s
                text_obj:set_range_color(pos3, pos4, Color(0, 0.5, 1))
                
                -- ACC (Guld)
                local pos5 = pos4 + #lbl_a
                local pos6 = pos5 + #val_a
                text_obj:set_range_color(pos5, pos6, Color(1, 0.84, 0))
            end
        end

        -- 4. ALPHA FADE (Animation - körs varje frame)
        if _G.LunaStats.alpha_t > 0 then
            _G.LunaStats.alpha_t = _G.LunaStats.alpha_t - dt
            text_obj:set_alpha(0.5 + (0.5 * math.min(1, _G.LunaStats.alpha_t)))
        else
            text_obj:set_alpha(0.5)
        end
    end)
end
 --- EOF: luna_stats_feed.lua ---
