log("[LunaHUD] [CORE] HUD Manager Patch & Consistency Fix")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Master Manager V63.0 - Objective Restoration ]]
function HUDManager:luna_ghost_trigger(text)
    local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
    if not hud or not hud.panel then return end

    if alive(_G.LunaHUD._ghost_obj) then 
        _G.LunaHUD._ghost_obj:stop()
        _G.LunaHUD._ghost_obj:parent():remove(_G.LunaHUD._ghost_obj) 
    end

    _G.LunaHUD._ghost_obj = hud.panel:text({
        name = "luna_ghost_text",
        text = "- " .. text:upper(),
        font = "fonts/font_medium_shadow_mf",
        font_size = 30, 
        color = Color.white,
        x = 100, y = 120, 
        layer = 1,
        blend_mode = "add",
        alpha = 0 
    })

    _G.LunaHUD._ghost_obj:animate(function(o)
        over(0.5, function(p) o:set_alpha(p) end)
        wait(120)
        over(2, function(p) 
            o:set_alpha(1 - p)
            o:set_x(100 - (p * 20)) 
        end)
        if alive(o) then o:parent():remove(o) end
    end)
end

