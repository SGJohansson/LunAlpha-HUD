log("[LunaHUD] [UI] Mission Presenter & Event Graphics")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Presenter Override (Ghost Overlay) ]]
-- Ersätter vanilla "Civilian Mode" / "Cant perform action" svarta lådor.
-- Design: Guldtext, ingen bakgrund, mindre font, högre placering.

if not _G.LunaPresenter then
    _G.LunaPresenter = {
        _panel = nil,
        _text = nil,
        -- LunaHUD Guld
        color = Color(1, 0.84, 0)
    }
end

function LunaPresenter:setup()
    -- Hämta HUD-managern
    local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
    if not hud or not hud.panel then return end

    -- Skapa panelen om den inte finns
    if not self._panel or not alive(self._panel) then
        self._panel = hud.panel:panel({ 
            name = "luna_presenter_overlay", 
            layer = 2000 -- Ligger över allt annat
        })
        
        self._text = self._panel:text({
            name = "luna_presenter_text",
            text = "",
            font = "fonts/font_medium_shadow_mf", -- Skuggad, tydlig font
            font_size = 22,                       -- Mindre storlek (enligt önskemål)
            color = self.color,
            align = "center",
            vertical = "center",
            alpha = 0
        })
        
        -- POSITIONERING
        -- Center X, men flyttad 220 pixlar UPPÅT från mitten för att rensa siktet
        self._text:set_center(self._panel:w() / 2, self._panel:h() / 2 - 220)
    end
end

function LunaPresenter:show(text)
    self:setup()
    if not alive(self._text) then return end

    -- Stoppa pågående animationer direkt (förhindrar spam-blinkande)
    self._text:stop()
    
    -- Sätt text och gör den uppercase för renare look
    self._text:set_text(utf8.to_upper(text))
    
    -- Animation: Snabb fade in, stå still, fade ut
    self._text:animate(function(o)
        local t = 0
        local in_time = 0.15
        local stay_time = 2.5
        local out_time = 0.5
        
        -- Fade In
        while t < in_time do
            t = t + coroutine.yield()
            o:set_alpha(math.clamp(t / in_time, 0, 1))
        end
        o:set_alpha(1)
        
        -- Vänta
        wait(stay_time)
        
        -- Fade Out
        t = 0
        while t < out_time do
            t = t + coroutine.yield()
            o:set_alpha(1 - math.clamp(t / out_time, 0, 1))
        end
        o:set_alpha(0)
    end)
end

------------------------------------------------------------------------
-- THE OVERRIDE
-- Vi kapar signalen innan spelet hinner rita den fula svarta rutan.
------------------------------------------------------------------------

if HUDPresenter then
    -- 1. Ersätt 'present'-funktionen helt.
    -- Vi sparar INTE undan originalet eftersom vi vill döda det.
    function HUDPresenter:present(params)
        if params and params.text then
            LunaPresenter:show(params.text)
        end
        -- Här tar det stopp. Spelets vanilla-kod körs aldrig.
    end
    
    -- 2. Init-Hook: Försäkra att vanilla-elementen är osynliga/borta vid start
    Hooks:PostHook(HUDPresenter, "init", "Luna_Kill_Vanilla_Presenter", function(self)
        if self._bg then 
            self._bg:set_visible(false) 
            self._bg:set_alpha(0) 
        end
        
        -- Flytta originalpanelen till Sibirien (utanför skärmen)
        if self._hud_panel then 
            self._hud_panel:set_x(-5000) 
            self._hud_panel:set_visible(false) 
        end
    end)
end

