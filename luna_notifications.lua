log("[LunaHUD] [UI] Tactical Notification System")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Notifications & Presenter Override V4.1 ]]
-- Fix: Delar upp logiken i 'show' för att skilja på Objectives och Varningar.

_G.LunaHUD = _G.LunaHUD or {}
LunaHUD.Notifs = LunaHUD.Notifs or { active = false, queue = {} }

--------------------------------------------------------------------------------
-- SYSTEM 1: THE GHOST OVERLAY (Center Prompts)
--------------------------------------------------------------------------------
if not _G.LunaPresenter then
    _G.LunaPresenter = {
        _panel = nil,
        _text = nil,
        gold = Color(1, 0.84, 0)
    }
end

function LunaPresenter:setup()
    local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
    if not hud or not hud.panel then return end

    if not self._panel or not alive(self._panel) then
        self._panel = hud.panel:panel({ name = "luna_presenter_overlay", layer = 10 })
        self._text = self._panel:text({
            name = "text",
            text = "",
            font = "fonts/font_medium_shadow_mf",
            font_size = 22, -- Placeholder startvärde
            color = self.gold,
            align = "center",
            vertical = "center",
            alpha = 0
        })
    end
end

function LunaPresenter:show(text)
    self:setup()
    if not alive(self._text) then return end
    
    self._text:stop()
    
    local clean_text = utf8.to_upper(text or "")
    
    -- --- HÄR ÄR LOGIKEN FÖR ATT SKILJA PÅ DEM ---
    local is_objective = clean_text:find("OBJECTIVE") or clean_text:find("ACTIVATED")
    
    if is_objective then
        -- OBJECTIVE: Stor (32) och Guld
        self._text:set_font_size(32)
        self._text:set_color(self.gold)
        self._text:set_center(self._panel:w() / 2, self._panel:h() / 2 - 200)
    else
        -- VARNINGAR: Liten (18) och Vit (Detta fixar din prompt)
        self._text:set_font_size(18)
        self._text:set_color(Color.white)
        self._text:set_center(self._panel:w() / 2, self._panel:h() / 2 - 260) -- Högre upp
    end
    -- ---------------------------------------------

    self._text:set_text(clean_text)
    
    self._text:animate(function(o)
        over(0.15, function(p) o:set_alpha(p) end)
        wait(is_objective and 3.5 or 2.5)
        over(0.5, function(p) o:set_alpha(1 - p) end)
        o:set_alpha(0)
    end)
end

-- HOOK: HUDPresenter (Center Prompts)
if HUDPresenter then
    -- Override: Vi visar vår text men kör INTE vanilla-visningen
    function HUDPresenter:present(params)
        if params and params.text then
            LunaPresenter:show(params.text)
        end
    end
    
    -- Init: Här döljer vi ENDAST presenter-delarna, inte hela panelen!
    Hooks:PostHook(HUDPresenter, "init", "Luna_Kill_Presenter_Elements", function(self)
        -- Dölj bakgrunden (den svarta toningen)
        if self._bg then 
            self._bg:set_alpha(0)
            self._bg:set_visible(false)
        end
        
        -- Dölj text-panelen inuti presentern (så vi slipper dubbeltext)
        if self._hud_panel then
            local p_panel = self._hud_panel:child("presenter_panel")
            if p_panel then
                p_panel:set_visible(false)
                p_panel:set_alpha(0)
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- SYSTEM 2: NOTIFICATION CENTER (Side/Hint Manager)
--------------------------------------------------------------------------------
if HUDManager then
    function HUDManager:luna_show_notification(title, text)
    	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
    	if not hud or not hud.panel then return end
    
    	if not self._luna_notif_panel then
        -- ÄNDRAT: layer från 2000 till 10
        self._luna_notif_panel = hud.panel:panel({
            name = "luna_notif_panel",
            layer = 10,
            w = 800, h = 100 
        })
        self._luna_notif_panel:set_center_x(hud.panel:center_x())
        self._luna_notif_panel:set_y(hud.panel:h() * 0.15)
    end


        self._luna_notif_panel:clear()
        local display_text = (title ~= "" and title .. ": " or "") .. text
        
        local t_obj = self._luna_notif_panel:text({
            name = "msg",
            text = display_text,
            font = tweak_data.menu.pd2_medium_font,
            font_size = 28,
            color = Color.white,
            align = "center",
            vertical = "center",
            layer = 1
        })
        
        t_obj:animate(function(o)
            over(0.5, function(p) o:set_alpha(p) end)
            wait(3)
            over(0.5, function(p) o:set_alpha(1-p) end)
            o:set_visible(false)
        end)
    end
    
    function HUDManager:show_hint(params)
        if not params or not params.text then return end
        self:luna_show_notification("", params.text)
    end
end

