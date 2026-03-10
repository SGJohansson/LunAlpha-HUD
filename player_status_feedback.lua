log("[LunaHUD] [COMBAT] Ability & Buff Status (V2.4 - Strict Filter)")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunaHUD: Player Status Feedback V2.4 - Ghost Filter Edition ]]

_G.LunaStatus = _G.LunaStatus or {
    _workspace = nil,
    _panel = nil,
    _recent_x = {},
    _last_event = { health = {val = 0, t = 0}, armor = {val = 0, t = 0} } -- Eko-filter
}

function LunaStatus:CheckHUD()
    if not alive(self._workspace) then
        self._workspace = managers.gui_data:create_fullscreen_workspace()
        self._panel = self._workspace:panel()
    end
end

function LunaStatus:GetSmartX(base_x)
    local new_x = base_x + math.random(-25, 25)
    local max_attempts = 10
    local min_gap = 45 

    for i = 1, max_attempts do
        local too_close = false
        for _, old_x in ipairs(self._recent_x) do
            if math.abs(new_x - old_x) < min_gap then
                too_close = true
                break
            end
        end
        if not too_close then break end
        new_x = base_x + math.random(-85, 85)
    end

    table.insert(self._recent_x, 1, new_x)
    if #self._recent_x > 5 then table.remove(self._recent_x) end
    return new_x
end

-- CENTRAL RIT-FUNKTION
function LunaStatus:ShowStatus(amount, type)
    -- DÖRRVAKTEN: Döda funktionen direkt om Damage Popups är AV i menyn.
    -- Detta fångar alla anrop oavsett vilken fil som skickar dem.
    if _G.LunaHUD and _G.LunaHUD.settings and _G.LunaHUD.settings.show_dmgpop == false then 
        return 
    end

    if not amount or amount <= 0 then return end
    
    local now = TimerManager:game():time()
    local amt = math.floor(amount)
    
    -- EKO-FILTER: Om exakt samma värde skickas igen inom 0.02s, ignorera det.
    -- Detta stoppar dubbla instanser utan att stoppa äkta snabba gains.
    local last = self._last_event[type]
    if amt == last.val and (now - last.t) < 0.02 then
        return
    end
    
    -- Uppdatera filtret med det senaste värdet
    self._last_event[type].val = amt
    self._last_event[type].t = now

    self:CheckHUD()
    local is_hp = type == "health"
    local color = is_hp and Color(0.2, 1, 0.2) or Color(0.4, 0.8, 1)
    local font_size = is_hp and 38 or 38 

    local pop_text = self._panel:text({
        text = "+" .. amt,
        font = "fonts/font_medium_shadow_mf",
        font_size = font_size,
        color = color,
        align = "center", vertical = "center", layer = 2000
    })
    
    local cx, cy = self._panel:w() / 2, self._panel:h() / 2
    local base_x = -70 
    local offset_y = -140 
    
    if is_hp then 
        offset_y = offset_y - 55 
    end
    
    local final_x = self:GetSmartX(base_x)
    pop_text:set_center(cx + final_x, cy + offset_y)
    
    pop_text:animate(function(o)
        local duration = 1.4
        local t = 0
        local start_y = o:y()
        while t < duration do
            local dt = coroutine.yield()
            t = t + dt
            if not alive(o) then break end
            o:set_y(start_y - (t * 35))
            if t > 0.9 then o:set_alpha(1 - ((t - 0.9) / 0.5)) end
        end
        if alive(o) then o:parent():remove(o) end
    end)
end

-- HOOKS
if _G.PlayerDamage then
    Hooks:PostHook(PlayerDamage, "restore_health", "LunaStatus_Health", function(self, amount)
        LunaStatus:ShowStatus(amount * 10, "health")
    end)
    Hooks:PostHook(PlayerDamage, "restore_armor", "LunaStatus_Armor", function(self, amount)
        LunaStatus:ShowStatus(amount * 10, "armor")
    end)
end