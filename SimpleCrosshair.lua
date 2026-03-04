log("[LunaHUD] [UI] Crosshair Provider (V11.8 - Smart Category ADS, Blacklist & Optic Override)")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Simple Dynamic Crosshair V11.8 - State Anchor & Smart ADS ]]
-- Path: mods/LunAlpha_MinimalHUD/SimpleCrosshair.lua
-- Update: Kategori-baserad ADS-detektering + Optisk sikt-detektor för Maelstrom/Prototype.


-- Tvinga reset vid reload för att rensa gamla låsta värden
_G.LunaCrosshair = nil

_G.LunaCrosshair = {
    -- FÄRGER
    gold = Color(1, 0.84, 0),
    red = Color(1, 0.2, 0.2),
    white = Color.white,
    
    -- GEOMETRI
    dot_size = 4,
    line_len = 6,
    
    -- DYNAMIK
    gap_crouch = 5,
    gap_stand = 9,
    gap_move = 14,
    
    -- REKYL
    recoil_max = 20,
    recoil_add = 5,
    recoil_decay = 40,
    
    -- INTERNA
    current_gap = 9,
    recoil_val = 0,
    hit_timer = 0,
    
    -- CACHE (Prestanda)
    ads_cache = {}
}

-- SVARTLISTA: Vapen som är LMGs/Specials men som HAR ett faktiskt sikte (standard).
local EXCLUDED_FROM_ADS = {
    ["hk51b"] = true,     -- SG Versteckt 51D Light Machine Gun
    ["hailstorm"] = true, -- Hailstorm Mk 5
    ["ray"] = true        -- Commando 101 Rocket Launcher
}

-- VITLISTA: Specialvapen utan rimlig kategori i tweak_data men som saknar sikte
local ALWAYS_VISIBLE_SPECIALS = {
    ["rpg7"] = true, ["m32"] = true, 
    ["flamethrower_mk2"] = true, ["hunter"] = true, ["ecp"] = true       
}

-- O(1) Cache för att undvika tweak_data-iterationer varje frame
local function requires_ads(w_id)
    if not w_id or w_id == "" then return false end
    
    -- 1. Läs från cache
    if _G.LunaCrosshair.ads_cache[w_id] ~= nil then
        return _G.LunaCrosshair.ads_cache[w_id]
    end

    -- 2. Kolla svartlista direkt (Överrider allt annat)
    if EXCLUDED_FROM_ADS[w_id] then
        _G.LunaCrosshair.ads_cache[w_id] = false
        return false
    end
    
    -- 3. Hårdkodad vitlista (Specials)
    if ALWAYS_VISIBLE_SPECIALS[w_id] then
        _G.LunaCrosshair.ads_cache[w_id] = true
        return true
    end
    
    -- 4. Dynamisk sökning i tweak_data (Fångar ALLA varianter automatiskt)
    local td = tweak_data.weapon[w_id]
    if td then
        local cat = td.category or ""
        local cats = td.categories or {}
        
        local is_lmg = (cat == "lmg") or table.contains(cats, "lmg")
        local is_minigun = (cat == "minigun") or table.contains(cats, "minigun")
        local is_akimbo = (cat == "akimbo") or table.contains(cats, "akimbo")
        local is_bow = (cat == "bow" or td.sub_category == "bow") and (td.sub_category ~= "crossbow")
        
        if is_lmg or is_minigun or is_akimbo or is_bow then
            _G.LunaCrosshair.ads_cache[w_id] = true
            return true
        end
    end
    
    -- Spara negativt resultat för att slippa söka igen
    _G.LunaCrosshair.ads_cache[w_id] = false
    return false
end

-- Kollar dynamiskt om vapnet har ett faktiskt optiskt sikte monterat (t.ex. Maelstrom, Holo, Specter)
-- Cachas direkt på vapen-basen för noll prestandapåverkan efter första framen
local function check_has_optic(w_base)
    if w_base._luna_has_optic ~= nil then
        return w_base._luna_has_optic
    end
    
    local optic_found = false
    if w_base._parts then
        for part_id, _ in pairs(w_base._parts) do
            -- 'upg_o_' är Paydays standard-prefix för optiska sikten.
            -- Fångar även upp custom-sikten som är döpta till maelstrom/prototype explicit.
            if string.find(part_id, "upg_o_") or string.find(part_id, "maelstrom") or string.find(part_id, "prototype") then
                optic_found = true
                break
            end
        end
    end
    w_base._luna_has_optic = optic_found
    return optic_found
end

-- Använder RaycastWeaponBase för att inkludera ALLA skjutvapen (även äldre/custom)
if _G.RaycastWeaponBase then
    Hooks:PostHook(RaycastWeaponBase, "fire", "LunaXH_Fire", function(self, ...)
        if not _G.LunaHUD.settings.show_crosshair then return end
        local unit = self._setup and self._setup.user_unit
        if unit == managers.player:player_unit() then
            _G.LunaCrosshair.recoil_val = math.min(_G.LunaCrosshair.recoil_max, _G.LunaCrosshair.recoil_val + _G.LunaCrosshair.recoil_add)
        end
    end)
end

Hooks:PostHook(HUDHitConfirm, "on_hit_confirmed", "LunaXH_Hit", function(self)
    if not _G.LunaHUD.settings.show_crosshair then return end
    _G.LunaCrosshair.hit_timer = 0.15
    _G.LunaCrosshair.recoil_val = math.min(_G.LunaCrosshair.recoil_max, _G.LunaCrosshair.recoil_val + 2)
end)

local function create_crosshair(hud_manager)
    local root = hud_manager:script(PlayerBase.PLAYER_INFO_HUD_PD2).panel
    if not root then return end
    
    if hud_manager._luna_xh_panel and alive(hud_manager._luna_xh_panel) then
        root:remove(hud_manager._luna_xh_panel)
    end

    hud_manager._luna_xh_panel = root:panel({ name = "luna_xh_panel", layer = 2000 })
    
    local cx, cy = root:w() / 2, root:h() / 2
    hud_manager._xh_cx, hud_manager._xh_cy = cx, cy
    
    hud_manager._xh_dot = hud_manager._luna_xh_panel:bitmap({
        name = "xh_dot", w = _G.LunaCrosshair.dot_size, h = _G.LunaCrosshair.dot_size, 
        color = _G.LunaCrosshair.gold, layer = 2
    })
    hud_manager._xh_dot:set_center(cx, cy)

    local function draw_line(name, w, h)
        return hud_manager._luna_xh_panel:bitmap({ name = name, w = w, h = h, color = _G.LunaCrosshair.white, layer = 1 })
    end
    hud_manager._xh_left   = draw_line("l", _G.LunaCrosshair.line_len, 2)
    hud_manager._xh_right  = draw_line("r", _G.LunaCrosshair.line_len, 2)
    hud_manager._xh_top    = draw_line("t", 2, _G.LunaCrosshair.line_len)
    hud_manager._xh_bottom = draw_line("b", 2, _G.LunaCrosshair.line_len)
end

Hooks:PostHook(HUDManager, "update", "LunaXH_Update", function(self, t, dt)
    if not self._luna_xh_panel or not alive(self._luna_xh_panel) then
        if self:script(PlayerBase.PLAYER_INFO_HUD_PD2) then create_crosshair(self) end
        return
    end
    
    if not _G.LunaHUD.settings.show_crosshair then
        self._luna_xh_panel:set_visible(false)
        return
    end

    local player = managers.player:local_player()
    if not alive(player) then
        self._luna_xh_panel:set_visible(false)
        return
    end

    local movement = player:movement()
    if not movement then 
        self._luna_xh_panel:set_visible(false)
        return 
    end

    local state_name = movement:current_state_name()
    local state = movement:current_state()
    
    -- Filter för icke-stridande tillstånd
    local invalid_states = { 
        ["mask_off"] = true, 
        ["clean"] = true, 
        ["civilian"] = true, 
        ["ingame_waiting_for_players"] = true 
    }
    
    if invalid_states[state_name] then
        self._luna_xh_panel:set_visible(false)
        return
    end

    -- DEFAULT TILL PÅ. Siktet förutsätts vara synligt om inget annat sägs.
    local should_show = true
    local is_moving = false
    local is_crouching = false
    
    local inventory = player:inventory()
    local weapon = inventory and inventory:equipped_unit()
    local w_base = weapon and weapon:base()
    
    if w_base then
        local w_id = w_base._name_id or (w_base.get_name_id and w_base:get_name_id()) or ""
        local force_show_ads = requires_ads(w_id)
        local has_optic = check_has_optic(w_base) -- <--- NY KONTROLL HÄR

        if state then
            if state.in_steelsight and state:in_steelsight() then
                -- Dölj alltid om ett faktiskt sikte (Maelstrom, etc) är monterat
                if has_optic then
                    should_show = false
                -- Annars, dölj om vapnet inte är i vår vitlista (LMG/Akimbo/Minigun)
                elseif not force_show_ads then
                    should_show = false
                end
            end
        end
    end

    if state then
        -- Identifiera rörelse (Används för dynamisk storlek)
        is_moving = state._moving
        is_crouching = state._state_data and state._state_data.ducking
        
        -- Dölj under melee-attacker
        if (state._state_data and state._state_data.meleeing) or state_name == "melee" then
            should_show = false
        end
    end

    -- Dölj om vi interagerar med något (t.ex. borrar, lyfter bags)
    if managers.interaction and alive(managers.interaction:active_unit()) then
        should_show = false
    end
    
    -- Dölj i menyer och chatt
    if managers.menu and managers.menu:is_active() then should_show = false end
    if managers.hud and managers.hud._chat_focus then should_show = false end

    self._luna_xh_panel:set_visible(should_show)
    if not should_show then return end

    -- BERÄKNA GAP (Siktets spridning)
    local target_gap = _G.LunaCrosshair.gap_stand 
    if is_crouching then target_gap = _G.LunaCrosshair.gap_crouch 
    elseif is_moving then target_gap = _G.LunaCrosshair.gap_move end

    target_gap = target_gap + _G.LunaCrosshair.recoil_val
    local diff = target_gap - _G.LunaCrosshair.current_gap
    _G.LunaCrosshair.current_gap = _G.LunaCrosshair.current_gap + (diff * dt * 15)

    -- REKYL ÅTERHÄMTNING
    if _G.LunaCrosshair.recoil_val > 0 then
        _G.LunaCrosshair.recoil_val = math.max(0, _G.LunaCrosshair.recoil_val - (dt * _G.LunaCrosshair.recoil_decay))
    end

    -- FÄRG (Hit Confirm)
    if _G.LunaCrosshair.hit_timer > 0 then
        _G.LunaCrosshair.hit_timer = math.max(0, _G.LunaCrosshair.hit_timer - dt)
        self._xh_dot:set_color(_G.LunaCrosshair.red)
    else
        self._xh_dot:set_color(_G.LunaCrosshair.gold)
    end

    -- RITA UPPDATERADE POSITIONER
    local cx, cy = self._luna_xh_panel:w()/2, self._luna_xh_panel:h()/2
    local final_gap = _G.LunaCrosshair.current_gap
    
    self._xh_dot:set_center(cx, cy)
    self._xh_left:set_center(cx - final_gap - 3, cy)
    self._xh_right:set_center(cx + final_gap + 3, cy)
    self._xh_top:set_center(cx, cy - final_gap - 3)
    self._xh_bottom:set_center(cx, cy + final_gap + 3)
end)
