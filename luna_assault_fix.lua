log("[LunaHUD] [DATA] Assault Logic & Handshake Provider")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Assault Fix - The Provider V2.5 ]]

-- Säkerställ att tabellen finns direkt vid laddning
_G.LunaHUD = _G.LunaHUD or { current_hostages = 0, current_jokers = 0, nr_timer = 0 }

local old_init = HUDAssaultCorner.init
function HUDAssaultCorner:init(hud, ...)
    old_init(self, hud, ...)
    local panels = {"assault_panel", "casing_panel", "point_of_no_return_panel", "hostages_panel"}
    for _, name in ipairs(panels) do
        local p = self._hud_panel:child(name)
        if p then p:set_alpha(0) p:set_x(-5000) end
    end
end

-- Hooka gisslan-räknaren mer aggressivt
local old_set_hostages = HUDAssaultCorner.set_hostage_count
function HUDAssaultCorner:set_hostage_count(count, ...)
    _G.LunaHUD.current_hostages = count
    return old_set_hostages(self, count, ...)
end

