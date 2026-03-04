log("[LunaHUD] [UI] Global HUD Manager Override")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Master Manager V50.0 - Stable 7-Line UI ]]

-- 1. GLOBALA DEFINITIONER (Tvingar rymliga rader)
if _G.HUDChat then
    HUDChat.LINE_HEIGHT = 16 
    HUDChat.WIDTH = 400 -- Minskad bredd för att stabilisera höjden
    HUDChat.MAX_OUTPUT_LINES = 7 -- Återställt till sju rader
end

-- 2. DEN AGGRESSIVA BOXEN (Update-hook för absolut kontroll)
Hooks:PostHook(HUDManager, "update", "Luna_Chat_Force_Update_V50", function(self, t, dt)
    local chat = managers.hud._hud_chat
    if chat and chat._panel and chat._panel:parent() then
        local p = chat._panel
        local parent = p:parent()
        
        -- Vi sätter höjden för 10 rader (16 * 10) för att rymma 7 rader + prompt + padding
        -- Detta förhindrar att Diesel klipper toppen eller fötterna
        local row_h = 16
        local target_h = row_h * 10
        local target_w = 400
        local target_y = parent:h() - target_h - 2
        local target_x = 10
        
        if math.abs(p:y() - target_y) > 1 or p:h() ~= target_h or p:w() ~= target_w then
            p:set_shape(target_x, target_y, target_w, target_h)
        end
    end
end)

Hooks:PostHook(HUDManager, "setup_player_info_hud_pd2", "Luna_QuakeChat_Final_V50", function(self)
    local chat_obj = managers.hud._hud_chat
    if not chat_obj then return end

    local org_layout = chat_obj._layout_input_panel
    chat_obj._layout_input_panel = function(self)
        org_layout(self)
        
        local font_name = "fonts/font_medium_shadow_mf"
        local font_size = 14
        
        local input = self._input_panel
        local say = input:child("say") or input:child("input_prompt")
        if say then
            say:set_font(Idstring(font_name))
            say:set_font_size(font_size)
            say:set_text("> ")
            local _, _, w, _ = say:text_rect()
            say:set_w(w)
        end

        local itext = input:child("input_text")
        if itext then
            itext:set_font(Idstring(font_name))
            itext:set_font_size(font_size)
            itext:set_w(self._panel:w() - (say and say:w() or 0) - 10)
            if say then itext:set_left(say:right() + 2) end
        end

        -- DÖDA GRADIENTER OCH POSITIONERA LOGGEN
        local out = self._panel:child("output_panel")
        if out then 
            if out:child("output_bg") then out:child("output_bg"):set_alpha(0) end
            if input:child("input_bg") then input:child("input_bg"):set_alpha(0) end
            self.line_height = 16
            out:set_bottom(input:top())
        end
    end

    -- TVINGA LOGG-FONT VID MOTTAGNING
    local org_receive = chat_obj.receive_message
    chat_obj.receive_message = function(self, name, message, color, icon)
        org_receive(self, name, message, color, icon)
        local out = self._panel:child("output_panel")
        local scroll = out and out:child("scroll_panel")
        if scroll then
            for _, child in ipairs(scroll:children()) do
                if child.set_font then 
                    child:set_font(Idstring("fonts/font_medium_shadow_mf"))
                    child:set_font_size(14) 
                end
                if child.name and (child:name() == "bg" or child:name() == "output_bg") then 
                    child:set_alpha(0) 
                end
            end
        end
    end

    chat_obj:_layout_input_panel()
end)

-- (Waypoint och Gage-logik bevarad)
local original_add_waypoint = HUDManager.add_waypoint
function HUDManager:add_waypoint(id, data)
    if id == "interact" or (data and data.type == "interact") then return end
    return original_add_waypoint(self, id, data)
end

-- Intressant som faen
local old_present = HUDPresenter.present
function HUDPresenter:present(params, ...)
    if params and params.title and (params.title:find("GAGE") or params.title:find("PACKAGE")) then
        if managers.chat then
            managers.chat:_receive_message(ChatManager.GAME, "[LOG]", params.text, Color(0.7, 0.7, 0.7))
        end
        return 
    end
    return old_present(self, params, ...)
end
