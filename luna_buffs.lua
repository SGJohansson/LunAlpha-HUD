log("[LunaHUD] [UI] Buff & Skill Timers (Live Tracking - V13 Aesthetic Update)")
if not _G.LunaHUD then _G.LunaHUD = {} end

LunaHUD.Buffs = LunaHUD.Buffs or { _setup_done = false, CustomTimers = {}, stand_still_timer = 0, lnl_kills = 0, current_melee_mult = 1 }

-- =======================================================
-- 1. DE BUFFAR VI VILL SPÅRA
-- =======================================================
LunaHUD.Buffs.Tracked = {
    -- [ SKADA & OMLADDNING ]
    { id = "overkill", category = "temporary", upgrade = "overkill_damage_multiplier", title = "OVERKILL" },
    { id = "aggressive_reload", category = "temporary", upgrade = "single_shot_fast_reload", title = "AGGRESSIVE RELOAD" },
    { id = "unseen_strike", category = "temporary", upgrade = "unseen_strike", title = "UNSEEN STRIKE" },
    { id = "trigger_happy", category = "temporary", upgrade = "trigger_happy", title = "TRIGGER HAPPY" },
    
    -- [ ÖVERLEVNAD & RÖRELSE ]
    { id = "second_wind", category = "temporary", upgrade = "damage_speed_multiplier", title = "SECOND WIND" },
    { id = "swan_song", category = "temporary", upgrade = "berserker_damage_multiplier", title = "SWAN SONG" },
    { id = "underdog", category = "temporary", upgrade = "dmg_multiplier_outnumbered", title = "UNDERDOG" },
    { id = "running_from_death", category = "temporary", upgrade = "increased_movement_speed", title = "RUNNING FROM DEATH" },
    { id = "up_you_go", category = "temporary", upgrade = "revived_damage_resist", title = "UP YOU GO" },
    
    -- [ PERK DECKS ]
    { id = "pocket_ecm", category = "temporary", upgrade = "pocket_ecm_kill_dodge", title = "HACKER DODGE" },
    { id = "kingpin", category = "temporary", upgrade = "chico_injector", title = "INJECTOR" },
    
    -- [ SUPPORT & TEAM ]
    { id = "bullet_storm", category = "temporary", upgrade = "bullet_storm", title = "BULLET STORM" },
    { id = "quick_fix", category = "temporary", upgrade = "first_aid_damage_reduction", title = "QUICK FIX" },
    { id = "combat_medic", category = "temporary", upgrade = "revive_damage_reduction", title = "COMBAT MEDIC" },
    
    -- [ CUSTOM HOOKS ]
    { id = "bloodthirst_timer", is_custom = true, title = "BLOODTHIRST" },
    { id = "bloodthirst_stack", is_custom = true, title = "BLOODTHIRST" }, -- Titel fixad för estetik
    { id = "lock_n_load", is_custom = true, title = "LOCK N LOAD" },
    { id = "sixth_sense", is_custom = true, title = "SIXTH SENSE" }
}

-- ==========================================
-- [ CUSTOM HOOKS ]: Säkrad Kill & Stack Logik
-- ==========================================
Hooks:PostHook(PlayerManager, "set_melee_dmg_multiplier", "LunaBuffs_GetBloodthirst", function(self, multiplier)
    LunaHUD.Buffs.current_melee_mult = multiplier
end)

Hooks:PostHook(PlayerManager, "reset_melee_dmg_multiplier", "LunaBuffs_ResetBloodthirst", function(self)
    LunaHUD.Buffs.current_melee_mult = 1
end)

Hooks:PostHook(PlayerManager, "on_killshot", "LunaBuffs_CustomKillTriggers", function(self, killed_unit, variant, headshot, weapon_id)
    if variant == "melee" then
        if self:has_category_upgrade("player", "melee_kill_increase_reload_speed") then
            LunaHUD.Buffs.CustomTimers["bloodthirst_timer"] = self:player_timer():time() + 10.0
        end
    else
        if self:has_category_upgrade("smg", "fire_mode_kill_reload_speed_multiplier") or self:has_category_upgrade("assault_rifle", "fire_mode_kill_reload_speed_multiplier") or self:has_category_upgrade("lmg", "fire_mode_kill_reload_speed_multiplier") then
            LunaHUD.Buffs.lnl_kills = math.min((LunaHUD.Buffs.lnl_kills or 0) + 1, 2)
        end
    end
end)

-- ==========================================
-- 2. SETUP & LIVE TRACKING ENGINE
-- ==========================================
Hooks:PostHook(HUDManager, "update", "LunaBuffs_LiveUpdate", function(self, t, dt)
	-- DÖRRVAKTEN: Kolla om buffarna är avstängda i menyn
    if _G.LunaHUD and _G.LunaHUD.settings and _G.LunaHUD.settings.show_buffs == false then
        -- Göm panelen om den är framme, och avbryt sedan funktionen!
        if LunaHUD.Buffs and LunaHUD.Buffs.panel and alive(LunaHUD.Buffs.panel) then
            LunaHUD.Buffs.panel:set_visible(false)
        end
        return 
    elseif LunaHUD.Buffs and LunaHUD.Buffs.panel and alive(LunaHUD.Buffs.panel) then
        -- Se till att den är synlig om vi slår PÅ den igen
        LunaHUD.Buffs.panel:set_visible(true)
    end
    local main_hud = managers.hud and managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
    if not main_hud then return end
    if not managers.player then return end

    if LunaHUD.Buffs._setup_done and (LunaHUD.Buffs.panel == nil or not alive(LunaHUD.Buffs.panel)) then
        LunaHUD.Buffs._setup_done = false
    end

    if not LunaHUD.Buffs._setup_done then
        local root = main_hud.panel
        if root:child("luna_buffs_panel") then root:remove(root:child("luna_buffs_panel")) end

        LunaHUD.Buffs.panel = root:panel({ name = "luna_buffs_panel", w = 300, h = 400, layer = 10 })
        LunaHUD.Buffs.panel:set_left(root:w() / 2 + 100)
        LunaHUD.Buffs.panel:set_center_y(root:h() / 2 + 50)

        LunaHUD.Buffs.UI_Elements = {}
        local font = "fonts/font_medium_shadow_mf"
        
        for _, buff in ipairs(LunaHUD.Buffs.Tracked) do
            local text_element = LunaHUD.Buffs.panel:text({
                name = buff.id, text = "", font = font, font_size = 21, color = Color.white, alpha = 0, layer = 1
            })
            LunaHUD.Buffs.UI_Elements[buff.id] = text_element
        end
        LunaHUD.Buffs._setup_done = true
    end

    local player_unit = managers.player:player_unit()
    local current_state = alive(player_unit) and player_unit:movement() and player_unit:movement():current_state()

    if current_state and type(current_state._is_reloading) == "function" and current_state:_is_reloading() then
        LunaHUD.Buffs.lnl_kills = 0
    end

    local is_stealth = managers.groupai and managers.groupai:state():whisper_mode()
    local has_sixth_sense = managers.player:has_category_upgrade("player", "stand_still_casing_sec")
    
    if is_stealth and has_sixth_sense and alive(player_unit) then
        local speed = player_unit:movement():m_velocity():length()
        if speed < 1.0 then
            LunaHUD.Buffs.stand_still_timer = LunaHUD.Buffs.stand_still_timer + dt
        else
            LunaHUD.Buffs.stand_still_timer = 0
        end
    else
        LunaHUD.Buffs.stand_still_timer = 0
    end

    -- ==========================================
    -- 3. UPDATE LOOP
    -- ==========================================
    if LunaHUD.Buffs._setup_done and alive(LunaHUD.Buffs.panel) then
        local current_y = 0

        for _, buff in ipairs(LunaHUD.Buffs.Tracked) do
            local ui_text = LunaHUD.Buffs.UI_Elements[buff.id]
            if alive(ui_text) then
                
                local is_active = false
                local time_left = 0
                local custom_text = nil
                local alpha_val = 1

                if buff.id == "sixth_sense" then
                    if LunaHUD.Buffs.stand_still_timer > 0 then
                        is_active = true
                        local required_time = managers.player:upgrade_value("player", "stand_still_casing_sec", 3.5)
                        time_left = required_time - LunaHUD.Buffs.stand_still_timer
                        if time_left <= 0 then custom_text = "[" .. buff.title .. "] ACTIVE" end
                    end

                elseif buff.id == "bloodthirst_stack" then
                    if LunaHUD.Buffs.current_melee_mult and LunaHUD.Buffs.current_melee_mult >= 16 then
                        is_active = true
                        custom_text = "[BLOODTHIRST] x1600"
                    end

                elseif buff.id == "lock_n_load" then
                    if LunaHUD.Buffs.lnl_kills and LunaHUD.Buffs.lnl_kills >= 2 then
                        is_active = true
                        custom_text = "[LOCK N LOAD] READY"
                    end

                elseif buff.is_custom then
                    local expire_time = LunaHUD.Buffs.CustomTimers[buff.id]
                    if expire_time and expire_time > managers.player:player_timer():time() then
                        is_active = true
                        time_left = expire_time - managers.player:player_timer():time()
                    end

                else
                    if managers.player:has_activate_temporary_upgrade(buff.category, buff.upgrade) then
                        is_active = true
                        local expire_time = managers.player:get_activate_temporary_expire_time(buff.category, buff.upgrade)
                        time_left = expire_time - managers.player:player_timer():time()
                    end
                end

                if is_active and (time_left > 0 or custom_text) then
                    local full_text = custom_text or string.format("[%s] %.1fs", buff.title, time_left)
                    ui_text:set_text(full_text)
                    
                    local name_len = string.len("[" .. buff.title .. "] ")
                    
                    -- Färglogik för estetisk enhetlighet
                    ui_text:set_range_color(0, name_len, Color(1, 0.84, 0)) -- [BUFFNAMN] i guld
                    
                    if custom_text then
                        if buff.id == "bloodthirst_stack" then
                            -- x1600 i vitt
                            ui_text:set_range_color(name_len, string.len(full_text), Color.white)
                        else
                            -- ACTIVE / READY i grönt	
                            ui_text:set_range_color(name_len, string.len(full_text), Color(0.1, 0.9, 0.1))
                        end
                    else
                        -- Sekundtimers i vitt
                        ui_text:set_range_color(name_len, string.len(full_text), Color.white)
                    end

                    if not custom_text and time_left < 2.0 then
                        alpha_val = math.max(0.2, time_left / 2.0)
                    end

                    ui_text:set_alpha(alpha_val)
                    ui_text:set_top(current_y)
                    current_y = current_y + 24
                else
                    ui_text:set_alpha(0)
                end
            end
        end
    end
end)