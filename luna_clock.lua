log("[LunaHUD] [UI] Mission Clock & HUD Timer")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunaHUD: Clock V8.0 - Static Core ]]
-- Ansvar: Visar Logga, Klocka och Interaction-text.
-- Helt frikopplad från spellogik för maximal stabilitet.

Hooks:PostHook(HUDManager, "update", "LunaClock_Static_Loop", function(self, t, dt)
    if not managers.hud or not managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2) then return end
    
    _G.LunaClock = _G.LunaClock or { _setup_done = false }
    local heist_timer = managers.hud._hud_heist_timer

    -- 1. SETUP (Körs en gång)
    if not LunaClock._setup_done and heist_timer and heist_timer._hud_panel then
        local root = heist_timer._hud_panel
        local w = root:w()
        local font = "fonts/font_medium_shadow_mf"

        -- Logga (Guld)
        LunaClock._logo = root:text({ 
            name = "l_l", 
            font = font, 
            font_size = 26, 
            color = Color(1, 0.84, 0), 
            text = "LUNALPHA HUD", 
            align = "right", 
            layer = 1
        })

        -- Tid (Vit | Grå | Blå)
        LunaClock._combined_time = root:text({ 
            name = "l_ct", 
            font = font, 
            font_size = 22, 
            color = Color.white, 
            align = "right", 
            layer = 1 
        })

        LunaClock._logo:set_right(w - 20) 
        LunaClock._logo:set_top(5)
        
        LunaClock._combined_time:set_right(w - 20) 
        LunaClock._combined_time:set_top(28)

        LunaClock._setup_done = true
    end

    -- 2. UPDATE LOOP
    if LunaClock._setup_done and alive(LunaClock._combined_time) then
        -- Tidräkning
        local time_now = os.date("%H:%M")
        local heist_str = "00:00"
        
        if managers.game_play_central then
            local t = managers.game_play_central:get_heist_timer()
            local h = math.floor(t / 3600)
            local m = math.floor((t % 3600) / 60)
            local s = math.floor(t % 60)
            if h > 0 then
                heist_str = string.format("%dh %02d:%02d", h, m, s)
            else
                heist_str = string.format("%02d:%02d", m, s)
            end
        end

        -- Sätt text
        LunaClock._combined_time:set_text(time_now .. " | " .. heist_str)
        
        -- Färglägg pipe "|"
        local full_text = LunaClock._combined_time:text()
        local pipe_pos = string.find(full_text, "|")
        if pipe_pos then
            LunaClock._combined_time:set_range_color(0, pipe_pos - 1, Color.white)
            LunaClock._combined_time:set_range_color(pipe_pos - 1, pipe_pos, Color(0.5, 0.5, 0.5))
            LunaClock._combined_time:set_range_color(pipe_pos, string.len(full_text), Color(0.4, 0.7, 1.0))
        end

        -- Göm vanilla timer panel
        if heist_timer._heist_timer_panel then 
            heist_timer._heist_timer_panel:set_alpha(0)
            heist_timer._heist_timer_panel:set_visible(false)
        end
    end
end)

-- (Interaction Text Fix - Bevarad här)
Hooks:PostHook(HUDInteraction, "prepare_interaction", "LunaMinimal_SmallerInteractionText", function(self)
    if self._interact_panel and self._interact_panel:child("interact_text") then
        local text = self._interact_panel:child("interact_text")
        text:set_font_size(22)
        local _, _, w, h = text:text_rect()
        text:set_h(h)
        text:set_center_y(self._interact_panel:h() / 2 + 50)
    end
end)



