log("[LunaHUD] [UI] Ghost Chat Interface (Minimalist Decay)")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Ghost Chat V2.0 ]]
-- Tar bort bakgrunden och hanterar fade-out.

if _G.HUDChat then
    -- 1. Konfiguration
    HUDChat.LINE_HEIGHT = 16
    HUDChat.FADE_WAIT = 4 -- Sekunder innan texten försvinner
    HUDChat.FADE_SPEED = 2 -- Hur snabbt den tonar ut

    -- 2. Initiering (Dölj bakgrunder)
    Hooks:PostHook(HUDChat, "init", "Luna_Ghost_Init", function(self, ws, hud)
        self._panel:child("output_panel"):set_bottom(self._panel:child("input_panel"):top())
        
        -- Dölj den svarta bakgrunden
        local output_bg = self._panel:child("output_panel"):child("output_bg")
        if output_bg then output_bg:set_visible(false) end
        
        local input_bg = self._panel:child("input_panel"):child("input_bg")
        if input_bg then input_bg:set_visible(false) end
    end)

    -- 3. Input (Visa bakgrund när du skriver)
    Hooks:PostHook(HUDChat, "_on_focus", "Luna_Ghost_Focus", function(self)
        local input_bg = self._panel:child("input_panel"):child("input_bg")
        if input_bg then input_bg:set_visible(true) input_bg:set_alpha(0.3) end
    end)

    Hooks:PostHook(HUDChat, "_on_loose_focus", "Luna_Ghost_Unfocus", function(self)
        local input_bg = self._panel:child("input_panel"):child("input_bg")
        if input_bg then input_bg:set_visible(false) end
    end)

    -- 4. Fade Logic (Update loop)
    Hooks:PostHook(HUDChat, "update", "Luna_Ghost_Update", function(self, t, dt)
        if self._lines then
            local current_time = TimerManager:game():time()
            for _, line in ipairs(self._lines) do
                if line.panel and alive(line.panel) then
                    -- Om raden är gammal, tona ut den
                    if (current_time - (line.timestamp or 0)) > HUDChat.FADE_WAIT then
                        local new_alpha = line.panel:alpha() - (dt * HUDChat.FADE_SPEED)
                        line.panel:set_alpha(math.max(0, new_alpha))
                        if new_alpha <= 0 then line.panel:set_visible(false) end
                    else
                        line.panel:set_alpha(1)
                        line.panel:set_visible(true)
                    end
                end
            end
        end
    end)

    -- 5. Mottagning (Sätt tidsstämpel)
    Hooks:PostHook(HUDChat, "receive_message", "Luna_Ghost_Receive", function(self, name, message, color, icon)
        if self._lines then
            local last_line = self._lines[#self._lines]
            if last_line then
                last_line.timestamp = TimerManager:game():time()
                if last_line.panel then 
                    last_line.panel:set_alpha(1) 
                    last_line.panel:set_visible(true)
                end
            end
        end
    end)
end
