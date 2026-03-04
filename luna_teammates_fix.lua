log("[LunaHUD] [UI] Teammates & Safe Hooks (V98.0)")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Teammates Fix V98.0 - Safe Hooks ]]
-- V97.2 + Justerade positioner
-- Fix: Tog bort direkta hooks på HUDMissionBriefing/HUDHint för att lösa "Could not hook function" error
-- Använder nu HUDManager för att säkert komma åt dessa objekt när de skapas.


local function hide_obj(obj)
    if obj then
        obj:set_alpha(0)
        obj:set_visible(false)
        if obj.set_size then obj:set_size(0, 0) end
        if obj.set_x then obj:set_x(-5000) end
    end
end

local function strip_background(panel)
    if not panel then return end
    local bg_names = { "bg", "background", "shadow", "bg_rect" }
    for _, child in ipairs(panel:children()) do
        local name = child:name()
        for _, bad_name in ipairs(bg_names) do
            if name == bad_name or name:find("bg") then hide_obj(child) end
        end
    end
end

-- [[ INVENTORY LOGIC ]]
local ID_TO_TEXT = {
    ["bank_manager_key"] = "Keycard", ["keycard"] = "Keycard",
    ["crowbar"] = "Crowbar", ["crowbar_stack"] = "Crowbar",
    ["planks"] = "Planks", ["boards"] = "Planks",
    ["harddrive"] = "HDD", ["files"] = "Files",
    ["muriatic_acid"] = "M-Acid", ["hydrogen_chloride"] = "HCl", ["caustic_soda"] = "C-Soda",
    ["gold"] = "Gold", ["money"] = "Money", ["c4"] = "C4",
    ["thermite"] = "Thermite", ["liquid_nitrogen"] = "L-Nitro"
}

local old_add = HUDTeammate.add_special_equipment
function HUDTeammate:add_special_equipment(data, ...)
    old_add(self, data, ...)
    if not self._main_player then
        if self._special_equipment then
            local panel = self._special_equipment[#self._special_equipment]
            if panel then hide_obj(panel) end
        end
        self._luna_inv_items = self._luna_inv_items or {}
        local raw_id = data.id or "unknown"
        local label = ID_TO_TEXT[raw_id] or raw_id
        if raw_id:find("key") then label = "Keycard"
        elseif raw_id:find("crowbar") then label = "Crowbar"
        elseif raw_id:find("plank") then label = "Planks" end
        table.insert(self._luna_inv_items, { id = raw_id, label = label })
    end
end

local old_remove = HUDTeammate.remove_special_equipment
function HUDTeammate:remove_special_equipment(equipment_id, ...)
    old_remove(self, equipment_id, ...)
    if not self._main_player and self._luna_inv_items then
        for i, item in ipairs(self._luna_inv_items) do
            if item.id == equipment_id then
                table.remove(self._luna_inv_items, i)
                return
            end
        end
    end
end

function HUDTeammate:luna_get_inv_text()
    if not self._luna_inv_items or #self._luna_inv_items == 0 then return nil end
    local labels = {}
    for _, item in ipairs(self._luna_inv_items) do table.insert(labels, item.label) end
    return table.concat(labels, ", ")
end

local function clean_surgical(teammate)
    if not teammate._panel then return end
    local p_panel = teammate._player_panel or teammate._panel:child("player")
    
    if not teammate._main_player then
        local hide_list = {
            "radial_health_panel", "name_bg", "callsign_bg", "callsign", 
            "box_bg", "box_ai_bg", "name", "revive_panel", "carry_panel",
            "weapons_panel", "interact_panel", "condition_icon", "condition_timer",
            "special_equipment_panel", "quest_icons_panel", "equipment_panel", 
            "cable_ties_panel", "grenades_panel", "deployable_equipment_panel"
        }
        for _, name in ipairs(hide_list) do
            hide_obj(teammate._panel:child(name) or (p_panel and p_panel:child(name)))
        end
        local sp_panel = teammate._panel:child("special_equipment_panel")
        if sp_panel then for _, child in ipairs(sp_panel:children()) do hide_obj(child) end end
    else
        hide_obj(teammate._panel:child("radial_health_panel") or (p_panel and p_panel:child("radial_health_panel")))
        local w_panel = teammate._panel:child("weapons_panel") or (p_panel and p_panel:child("weapons_panel"))
        if w_panel then
            local pri = w_panel:child("primary_weapon_panel")
            if pri then strip_background(pri) end
            local sec = w_panel:child("secondary_weapon_panel")
            if sec then strip_background(sec) end
        end
        local panels_to_strip = { "deployable_equipment_panel", "grenades_panel", "cable_ties_panel" }
        for _, p_name in ipairs(panels_to_strip) do
            local p = teammate._panel:child(p_name) or (p_panel and p_panel:child(p_name))
            if p then strip_background(p) end
        end
    end
end

local COLOR_ALIASES = { "BROWN", "BLUE", "BLONDE", "PINK", "WHITE", "ORANGE" }

Hooks:PostHook(HUDTeammate, "init", "Luna_GhostStack_Init", function(self, i)
    clean_surgical(self)
    local hud_panel = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2).panel
    self._luna_world_panel = self._luna_world_panel or hud_panel:panel({ name = "luna_ghost_world_" .. i, layer = 1 })
    local font = "fonts/font_medium_shadow_mf"
    self._luna_cache = { hp = -1, ar = -1, inv = "", name_chk = "" }
    self._luna_inv_items = {}

    if self._main_player then
        self._luna_ar = self._luna_world_panel:text({ name = "l_ar", font = font, font_size = 44, color = Color(0, 0.6, 1), align = "right", vertical = "bottom" })
        self._luna_hp = self._luna_world_panel:text({ name = "l_hp", font = font, font_size = 36, color = Color(0, 1, 0.2), align = "right", vertical = "bottom" })
    else
        local p_color = tweak_data.chat_colors[i] or Color.white
        self._luna_name = self._luna_world_panel:text({ name = "l_name", font = font, font_size = 28, color = p_color, align = "right", vertical = "bottom" })
        self._luna_ghost_info = self._luna_world_panel:text({ name = "l_info", font = font, font_size = 18, color = Color.white, align = "right", vertical = "bottom" })
        local is_ai = self._ai
        local raw_alias = COLOR_ALIASES[i] or "GHOST"
        local final_alias = is_ai and raw_alias .. " (AI)" or raw_alias
        self._luna_stats = self._luna_stats or { hp = 100, ar = 100, alias = final_alias, real_name = final_alias }
    end
end)

Hooks:PostHook(HUDTeammate, "set_health", "Luna_Sync_HP", function(self, data)
    if not self._main_player and self._luna_stats then 
        if data.total > 0 then self._luna_stats.hp = math.clamp(math.floor((data.current / data.total) * 100), 0, 100) else self._luna_stats.hp = 0 end
    end
end)

Hooks:PostHook(HUDTeammate, "set_armor", "Luna_Sync_AR", function(self, data)
    if not self._main_player and self._luna_stats then 
        if data.total > 0 then self._luna_stats.ar = math.clamp(math.floor((data.current / data.total) * 100), 0, 100) else self._luna_stats.ar = 0 end
    end
end)

Hooks:PostHook(HUDTeammate, "set_name", "Luna_Sync_Name", function(self, name)
    if not self._main_player and self._luna_stats then self._luna_stats.real_name = tostring(name):upper() end
end)

Hooks:PostHook(HUDManager, "update", "Luna_GhostStack_Render", function(self, t, dt)
    for i, teammate in ipairs(self._teammate_panels) do
        if teammate and alive(teammate._luna_world_panel) then
            local root = teammate._luna_world_panel:parent()
            local cache = teammate._luna_cache or { hp = -1, ar = -1, inv = "", name_chk = "" }
            if t % 1 < dt then clean_surgical(teammate) end

            if teammate._main_player then
                local hp = teammate._health_data and math.floor(teammate._health_data.current * 10) or 0
                local ar = teammate._armor_data and math.floor(teammate._armor_data.current * 10) or 0
                
		-- SGJ Justering av ammo-storlek playerhud
		-- [[ LUNA CUSTOM RESIZE: NAMN & AMMO ]]
            -- 1. Minska och flytta namnet (Vanilla-element)
            local name_bg = teammate._panel:child("name_bg")
            local name_txt = teammate._panel:child("name")
            if name_txt then
                name_txt:set_font_size(18) -- Sätt önskad storlek (Vanilla är ca 24)
                -- Om du vill flytta namnet, avkommentera nedan:
                -- name_txt:set_bottom(teammate._panel:h() - 70)
            end

            -- 2. Ammo Resize (Current stor, Total liten)
            local w_panel = teammate._panel:child("weapons_panel")
            if w_panel then
                local weapons = { w_panel:child("primary_weapon_panel"), w_panel:child("secondary_weapon_panel") }

                for _, wep in ipairs(weapons) do
                    if wep then
                        local clip = wep:child("ammo_clip")
                        local total = wep:child("ammo_total")

                        if clip and total then
                            -- GÖR CURRENT AMMO STÖRRE (T.ex. 32)
                            clip:set_font_size(28)

                            -- GÖR TOTAL AMMO MINDRE (T.ex. 18)
                            total:set_font_size(14)

                            -- Justera position så "Total" ligger snyggt bredvid/under
                            -- Total brukar ligga under clip i vanilla, vi kan justera det:
                             total:set_top(clip:bottom() - 5)
                        end
                    end
                end
            end
            -- [[ SLUT PÅ RESIZE ]]


                if cache.hp ~= hp then
                    teammate._luna_hp:set_text(string.format("%d HP", hp))
                    local txt = teammate._luna_hp
                    local full = txt:text()
                    local hp_start = string.find(full, "HP")
                    if hp_start then
                        txt:set_range_color(0, hp_start - 1, Color.white)
                        txt:set_range_color(hp_start - 1, string.len(full), Color(0, 1, 0.2))
                    end
                    cache.hp = hp
                end
                
                if cache.ar ~= ar then
                    teammate._luna_ar:set_text(string.format("%d AR", ar))
                    local txt = teammate._luna_ar
                    local full = txt:text()
                    local ar_start = string.find(full, "AR")
                    if ar_start then
                        txt:set_range_color(0, ar_start - 1, Color(1, 0.84, 0))
                        txt:set_range_color(ar_start - 1, string.len(full), Color(0, 0.6, 1))
                    end
                    cache.ar = ar
                end
                
                local right_x = root:world_right() - 140
                local bottom_y = root:world_bottom() - -5
                teammate._luna_hp:set_right(right_x)
                teammate._luna_hp:set_bottom(bottom_y)
                teammate._luna_ar:set_right(right_x)
                teammate._luna_ar:set_bottom(bottom_y - 28)

            elseif teammate._luna_name then
                local right_x = root:world_right() - 30
                local s = teammate._luna_stats
                local inv_text = teammate:luna_get_inv_text()
                local current_inv_str = inv_text or "nil"
                local display_name = (s.real_name ~= "..." and s.real_name) or s.alias
                local needs_update = (cache.hp ~= s.hp) or (cache.ar ~= s.ar) or (cache.inv ~= current_inv_str) or (cache.name_chk ~= display_name)

                if needs_update then
                    teammate._luna_name:set_text(display_name)
                    local info_obj = teammate._luna_ghost_info
                    local base_str = string.format("%d%% HP | %d%% AR", s.hp, s.ar)
                    local full_str = inv_text and (base_str .. " | " .. inv_text) or base_str
                    info_obj:set_text(full_str)
                    
                    local hp_len = string.len(tostring(s.hp)) + 4
                    local ar_start = hp_len + 3
                    local ar_len = string.len(tostring(s.ar)) + 4
                    info_obj:set_range_color(0, hp_len, Color(0, 1, 0.2)) 
                    info_obj:set_range_color(hp_len, hp_len + 3, Color.white)
                    info_obj:set_range_color(ar_start, ar_start + ar_len, Color(0, 0.5, 1))
                    if inv_text then
                        local inv_start = ar_start + ar_len
                        info_obj:set_range_color(inv_start, inv_start + 3, Color.white)
                        info_obj:set_range_color(inv_start + 3, string.len(full_str), Color(1, 0.84, 0))
                    end
                    cache.hp = s.hp
                    cache.ar = s.ar
                    cache.inv = current_inv_str
                    cache.name_chk = display_name
                end
                local base_y = root:world_bottom() - 180
                teammate._luna_name:set_world_right(right_x)
                teammate._luna_name:set_world_bottom(base_y - (i * 55))
                teammate._luna_ghost_info:set_world_right(right_x)
                teammate._luna_ghost_info:set_world_bottom(teammate._luna_name:world_bottom() + 20)
            end
            teammate._luna_cache = cache
        end
    end
end)

-- [[ OBJECTIVE & HINT FIX (SAFE METHOD) ]]
-- Vi hookar HUDManager när den skapar objektiven, vilket är garanterat att fungera.
Hooks:PostHook(HUDManager, "_create_mission_briefing_hud", "Luna_Gold_Briefing", function(self)
    if self._hud_mission_briefing and self._hud_mission_briefing._single_objective_text then
        local obj = self._hud_mission_briefing._single_objective_text
        obj:set_color(Color(1, 0.84, 0)) -- Guld
        obj:set_font_size(obj:font_size() + 2) -- Större
        
        local x, y = obj:position()
        obj:set_position(x, y - 20) -- Flytta upp
    end
end)

Hooks:PostHook(HUDManager, "_create_hint_hud", "Luna_Gold_Hint", function(self)
    if self._hud_hint and self._hud_hint._hint_text then
        local hint = self._hud_hint._hint_text
        hint:set_color(Color(1, 0.84, 0)) -- Guld
        hint:set_font_size(hint:font_size() + 2)
    end
end)
