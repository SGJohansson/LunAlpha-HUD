log("[LunaHUD] [COMBAT] Damage Indicator System (V11.1 Stable)")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunaHUD: Damage Pop V11.1 - Crash Fix ]]
-- Fix: Återinförde _last_x och lade till nil-checks för att förhindra krasch vid explosioner.
-- Status: Stabiliserad. Värmeskalan och Object Pooling är intakt.


-- Tvinga in saknade värden om tabellen redan finns i minnet
_G.LunaDamage = _G.LunaDamage or {}
_G.LunaDamage._last_x = _G.LunaDamage._last_x or 0
_G.LunaDamage._last_t = _G.LunaDamage._last_t or 0
_G.LunaDamage._cluster_count = _G.LunaDamage._cluster_count or 0
_G.LunaDamage._pool = _G.LunaDamage._pool or {}
_G.LunaDamage._active_pops = _G.LunaDamage._active_pops or {}
_G.LunaDamage._pool_size = 50

function LunaDamage:Init()
    if self._workspace and alive(self._workspace) then return end
    
    self._workspace = managers.gui_data:create_fullscreen_workspace()
    self._panel = self._workspace:panel()
    
    -- Töm ev. gammal pool för att undvika dubbletter vid reload
    self._pool = {} 
    
    for i = 1, self._pool_size do
        local text_obj = self._panel:text({
            name = "luna_dmg_" .. i,
            text = "",
            font = "fonts/font_medium_shadow_mf",
            font_size = 20,
            color = Color.white,
            align = "center", 
            vertical = "center", 
            layer = 2000,
            visible = false
        })
        table.insert(self._pool, text_obj)
    end
end

function LunaDamage:GetFromPool()
    if not self._pool or #self._pool == 0 then self:Init() end
    for _, obj in ipairs(self._pool) do
        if alive(obj) and not obj:visible() then return obj end
    end
    return nil
end

function LunaDamage:CreateDamagePopup(damage_info)
    if not damage_info then return end
    
    local attacker = damage_info.attacker_unit
    local unit = damage_info.unit
    if not alive(unit) then return end

    local is_sentry = alive(attacker) and attacker:base() and attacker:base().sentry_gun
    if attacker ~= managers.player:local_player() and not is_sentry then return end

    if not self._workspace then self:Init() end

    -- 1. OVERKILL LOGIK
    local raw_damage = damage_info.damage or 0
    local is_kill = (damage_info.result and damage_info.result.type == "death") or (unit:character_damage() and unit:character_damage():dead())
    
    if is_kill and damage_info.attack_data and damage_info.attack_data.damage then
        if damage_info.attack_data.damage > raw_damage then
            raw_damage = damage_info.attack_data.damage
        end
    end
    
    if raw_damage <= 0 then return end
    local damage_val = math.floor(raw_damage * 10)
    
    -- 2. STATUS
    local is_crit = damage_info.critical_hit or false
    local is_headshot = damage_info.col_ray and damage_info.col_ray.body and damage_info.col_ray.body:name() == Idstring("head")
    local u_key = unit:key()
    local now = TimerManager:game():time()

    -- 3. VÄRMESKALA (Vit -> Gul -> Röd -> Orange -> Guld)
    local color = Color(0.8, 0.8, 0.8)
    local f_size = 20
    local suffix = ""

    if damage_val >= 1500 then 
        color = Color(1, 0.84, 0) -- Guld
        f_size = 48 
        suffix = "!"
    elseif is_kill and (is_crit or is_headshot) then
        color = Color(1, 0.4, 0) -- Orange
        f_size = 38
        suffix = "!"
    elseif is_kill then
        color = Color(1, 0.1, 0.1) -- Röd
        f_size = 34
    else
        if is_headshot then 
            color = Color(1, 1, 0.2) -- Gul
            f_size = 28
            suffix = "!"
        elseif is_crit then
            color = Color(1, 0.7, 0.2) -- Ljusorange
            f_size = 28
            suffix = "!"
        else
            color = Color(0.9, 0.9, 0.9) -- Vit
            f_size = 20
        end
    end

    -- 4. STACKING
    if not (is_kill or damage_val >= 1500) and self._active_pops[u_key] then
        local data = self._active_pops[u_key]
        if data.obj and alive(data.obj) and data.obj:visible() and data.val == damage_val and (now - data.t) < 0.6 then
            data.count = data.count + 1
            data.t = now
            local growth = math.min(12, data.count * 2)
            data.obj:set_font_size(data.base_size + growth)
            data.obj:set_text(tostring(data.val) .. " x" .. data.count .. suffix)
            data.obj:set_alpha(1)
            data.shake_t = 0.12 
            return 
        end
    end

    -- 5. HÄMTA OBJEKT
    local pop_text = self:GetFromPool()
    if not pop_text then return end

    pop_text:set_font_size(f_size)
    pop_text:set_color(color)
    pop_text:set_text(tostring(damage_val) .. suffix)
    pop_text:set_alpha(1)
    pop_text:set_visible(true)

    -- 6. POSITIONERING (Safety Fix)
    local pos = unit:position()
    local cam = managers.viewport:get_current_camera()
    if not cam then return end
    
    local screen_pos = cam:world_to_screen(pos + Vector3(0, 0, 180))
    
    -- Crash Fix: Initiera _last_t om den saknas
    self._last_t = self._last_t or 0
    
    if math.abs(now - self._last_t) < 0.05 then
        self._cluster_count = (self._cluster_count or 0) + 1
    else
        self._cluster_count = 0
    end
    self._last_t = now

    local spread_x = 0
    local spread_y = 0
    
    if self._cluster_count > 0 then
        local spread_mult = math.min(self._cluster_count, 5) * 40
        spread_x = math.random(-spread_mult, spread_mult)
        spread_y = math.random(-spread_mult/2, spread_mult/2)
    else
        spread_x = math.random(-30, 30)
    end

    local start_pos_x = (screen_pos.x + 1) * self._panel:w() / 2 + spread_x
    local start_pos_y = (screen_pos.y + 1) * self._panel:h() / 2 + spread_y
    
    pop_text:set_center(start_pos_x, start_pos_y)

    -- 7. ANIMATION
    local pop_data = { 
        obj = pop_text, val = damage_val, count = 1, t = now, 
        base_size = f_size, shake_t = 0
    }
    self._active_pops[u_key] = pop_data

    pop_text:stop()
    pop_text:animate(function(o)
        local duration = 1.5
        local t = 0
        local cur_y = start_pos_y
        local cur_x = start_pos_x
        local drift_x = (spread_x * 0.5)
        
        while t < duration do
            local dt = coroutine.yield()
            t = t + dt
            if not alive(o) or not o:visible() then break end

            local sx, sy = 0, 0
            if pop_data.shake_t > 0 then
                pop_data.shake_t = pop_data.shake_t - dt
                sx = math.random(-1.5, 1.5)
                sy = math.random(-1.5, 1.5)
            end
            
            local speed = (is_kill or damage_val >= 1500) and 55 or 30
            cur_y = cur_y - (dt * speed)
            cur_x = cur_x + (drift_x * dt)
            
            o:set_center(cur_x + sx, cur_y + sy)
            
            if t > (duration - 0.4) then 
                o:set_alpha(1 - ((t - (duration - 0.4)) / 0.4)) 
            end
        end
        
        if alive(o) then
            o:set_visible(false) 
            if self._active_pops[u_key] and self._active_pops[u_key].obj == o then 
                self._active_pops[u_key] = nil 
            end
        end
    end)
end

-- Hooks
if _G.CopDamage then
    Hooks:PostHook(CopDamage, "_on_damage_received", "LunaDamage_Final", function(self, data)
        -- DÖRRVAKTEN: Är DamagePop avstängt i menyn? Vänd i dörren!
        if _G.LunaHUD and _G.LunaHUD.settings and _G.LunaHUD.settings.show_dmgpop == false then 
            return 
        end
        
        data.unit = self._unit
        LunaDamage:CreateDamagePopup(data)
    end)
end

if _G.SentryGunDamage then
    Hooks:PostHook(SentryGunDamage, "_on_damage_received", "LunaDamage_SentryFinal", function(self, data)
        -- DÖRRVAKTEN: Måste ligga här också så vi inte får skadesiffror på Sentry Guns när modden är avstängd
        if _G.LunaHUD and _G.LunaHUD.settings and _G.LunaHUD.settings.show_dmgpop == false then 
            return 
        end
        
        data.unit = self._unit
        LunaDamage:CreateDamagePopup(data)
    end)
end