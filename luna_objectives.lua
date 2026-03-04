log("[LunaHUD] [UI] Tactical Objectives Display")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Objectives V9.2 - Clean Stream ]]

-- DÖLJ ORIGINAL-PANELEN
Hooks:PostHook(HUDObjectives, "init", "Luna_Hide_Vanilla_Obj", function(self)
    if self._objectives_panel then
        self._objectives_panel:set_visible(false)
        self._objectives_panel:set_alpha(0)
        self._objectives_panel:set_x(-5000)
    end
end)

-- SKICKA DATA TILL DIN GULD-HUD
function HUDObjectives:activate_objective(data)
    if managers.hud and managers.hud.luna_ghost_trigger then
        managers.hud:luna_ghost_trigger(data.text)
    end
end

function HUDObjectives:complete_objective(data)
    -- Här kan vi lägga in arkiv-logik senare om vi vill
end

