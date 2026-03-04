log("[LunaHUD] [UI] Visual Cleanup Module")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [ID: VISUAL_CLEAR_V28.0_THE_DECOY] --
-- [[ LunAlpha HUD: Visual Clear V28.0 - The Decoy ]]
-- 1. DECOY: Skapar en osynlig attrapp för 'player_profile' för att blidka SuperBLT.
-- 2. VOID: Dödar Announcements och Merch helt.
-- 3. LOGIC: Ritar stats och branding i Menu Main.
-- 4. NVG: Rensar Night Vision från brus (0% grain, 75% mjuk färgton).

_G.LunaVisuals = _G.LunaVisuals or { 
    menu_ws = nil, 
    branding_done = false,
    stats_panel = nil 
}

local function GetVersion()
    -- Frågar _G.LunaHUD först (vilket nu läses från mod.txt)
    return _G.LunaHUD and _G.LunaHUD.version or "VER_ERROR"
end

function _G.Luna_KillMenuLogo()
    if _G.LunaVisuals.menu_ws and alive(_G.LunaVisuals.menu_ws) then
        managers.gui_data:destroy_workspace(_G.LunaVisuals.menu_ws)
        _G.LunaVisuals.menu_ws = nil
        _G.LunaVisuals.branding_done = false
        _G.LunaVisuals.stats_panel = nil
    end
end

-- =========================================================================
-- 1. THE DUMMY CLASS (Attrappen)
-- =========================================================================
LunaDummyGui = LunaDummyGui or class()
function LunaDummyGui:init(ws)
    self._panel = ws:panel():panel({ w = 0, h = 0, visible = false, alpha = 0 })
end
function LunaDummyGui:close()
    if self._panel and alive(self._panel) then self._panel:parent():remove(self._panel) end
end
function LunaDummyGui:set_enabled(enabled) end
function LunaDummyGui:update(t, dt) end
function LunaDummyGui:panel() return self._panel end

-- =========================================================================
-- 2. SOURCE CODE OVERRIDES (Surgical Strike + Decoy)
-- =========================================================================
if _G.MenuComponentManager then
    
    function MenuComponentManager:_create_newsfeed_gui() end
    function MenuComponentManager:create_newsfeed_gui() end
    function MenuComponentManager:_create_friends_gui() end
    function MenuComponentManager:create_raid_preorder_menu_gui(node) end
    function MenuComponentManager:create_raid_special_menu_gui(node) end
    function MenuComponentManager:create_raid_menu_gui(node) end
    function MenuComponentManager:_create_content_updates_gui() end
    function MenuComponentManager:create_new_heists_gui(node) end
    function MenuComponentManager:create_socialhub_notification_gui(node) end

    function MenuComponentManager:_create_player_profile_gui()
        if self._player_profile_gui then return end
        self._player_profile_gui = LunaDummyGui:new(self._ws)
    end
    
    function MenuComponentManager:create_player_profile_gui()
        self:_create_player_profile_gui() 
    end

    function MenuComponentManager:refresh_player_profile_gui()
        if not self._player_profile_gui then self:_create_player_profile_gui() end
    end

    function MenuComponentManager:_create_profile_gui() end
    function MenuComponentManager:create_profile_gui() end
end

-- =========================================================================
-- 3. BLT KILLER
-- =========================================================================
if Hooks then
    pcall(function() 
        Hooks:UnregisterHook("MenuComponentManagerPreSetActiveComponents") 
    end)
end

-- =========================================================================
-- 4. MAIN MENU RENDER LOOP
-- =========================================================================
if _G.MenuComponentManager then
    Hooks:PostHook(MenuComponentManager, "update", "Luna_MainMenu_V28_Loop", function(self, t, dt)
        
        if not self._ws or not alive(self._ws) then return end

        if managers.network and managers.network:session() then 
            if _G.LunaVisuals.branding_done then _G.Luna_KillMenuLogo() end
            return 
        end

        if self._newsfeed_gui then self._newsfeed_gui:close() self._newsfeed_gui = nil end
        if self._profile_gui then self._profile_gui:close() self._profile_gui = nil end
        
        if not _G.LunaVisuals.branding_done then
            _G.Luna_KillMenuLogo() 
            _G.LunaVisuals.menu_ws = managers.gui_data:create_fullscreen_workspace()
            local panel = _G.LunaVisuals.menu_ws:panel()
            
            panel:text({
                text = "LUNALPHA HUD v" .. GetVersion(),
                font = "fonts/font_eroded",
                font_size = 28,
                color = Color(1, 0.84, 0),
                align = "left", vertical = "top", layer = 25
            }):set_position(50, 35)

            local credits = panel:text({
                text = "AUTHOR: S.G.JOHANSSON | LICENSE: GPLV3 | TEAM: LUNALPHA",
                font = tweak_data.menu.pd2_medium_font,
                font_size = 12,
                color = Color.white:with_alpha(0.8),
                align = "left", vertical = "bottom", layer = 25
            })
            credits:set_left(40)
            credits:set_bottom(panel:h() - 35)

            _G.LunaVisuals.branding_done = true
        end

        local current_state = game_state_machine and game_state_machine:current_state_name()
        local panel = _G.LunaVisuals.menu_ws and alive(_G.LunaVisuals.menu_ws) and _G.LunaVisuals.menu_ws:panel()

        if panel and alive(panel) then
            if current_state == "menu_main" then
                
                if not _G.LunaVisuals.stats_panel or not alive(_G.LunaVisuals.stats_panel) then
                    local s_panel = panel:panel({ name = "stats_container", layer = 2000 })
                    _G.LunaVisuals.stats_panel = s_panel
                    
                    local font_large = tweak_data.menu.pd2_massive_font 
                    local font_medium = tweak_data.menu.pd2_medium_font
                    local gold = Color(1, 0.84, 0)
                    local white = Color.white

                    s_panel:text({ name = "l_lvl", font = font_large, font_size = 32, color = gold, align = "right" })
                    s_panel:text({ name = "l_cash", font = font_medium, font_size = 20, color = white, align = "right" })
                    s_panel:text({ name = "l_off", font = font_medium, font_size = 20, color = white, align = "right" })
                    s_panel:text({ name = "l_coin", font = font_medium, font_size = 20, color = white, align = "right" })
                end

                local s_panel = _G.LunaVisuals.stats_panel
                if alive(s_panel) then
                    s_panel:set_visible(true)
                    
                    local level = managers.experience:current_level()
                    local rank = managers.experience:current_rank()
                    local c_str = managers.money:total_string()
                    local o_str = managers.experience:cash_string(managers.money:offshore())
                    local cn_str = managers.custom_safehouse and math.floor(managers.custom_safehouse:coins()) or 0
                    
                    local rank_str = (rank > 0) and ("INFAMY " .. tostring(rank) .. " | ") or ""
                    local level_text = rank_str .. "REP " .. tostring(level)

                    local screen_w = panel:w()
                    local screen_h = panel:h()

                    local l_lvl = s_panel:child("l_lvl")
                    l_lvl:set_text(level_text)
                    l_lvl:set_right(screen_w - 50)
                    l_lvl:set_bottom(screen_h - 50)

                    local l_cash = s_panel:child("l_cash")
                    l_cash:set_text("CASH: " .. c_str)
                    l_cash:set_right(screen_w - 50)
                    l_cash:set_bottom(l_lvl:top() - 5)

                    local l_off = s_panel:child("l_off")
                    l_off:set_text("OFFSHORE: " .. o_str)
                    l_off:set_right(screen_w - 50)
                    l_off:set_bottom(l_cash:top() - 5)

                    local l_coin = s_panel:child("l_coin")
                    l_coin:set_text("COINS: " .. managers.experience:cash_string(cn_str, ""))
                    l_coin:set_right(screen_w - 50)
                    l_coin:set_bottom(l_off:top() - 5)
                end
            else
                if _G.LunaVisuals.stats_panel and alive(_G.LunaVisuals.stats_panel) then
                    _G.LunaVisuals.stats_panel:set_visible(false)
                end
            end
        end
    end)
    
    Hooks:PostHook(MenuComponentManager, "set_active_components", "Luna_Hide_In_Lobby", function(self)
        if managers.network and managers.network:session() then _G.Luna_KillMenuLogo() end
    end)
end

-- [[ 5. HUD CLEANUP ]]
local function ForceClean() _G.Luna_KillMenuLogo() end
if _G.HUDManager then Hooks:PostHook(HUDManager, "_setup_player_info_hud_pd2", "Luna_Kill_Brand_Ingame", ForceClean) end
if _G.HUDMissionBriefing then Hooks:PostHook(HUDMissionBriefing, "init", "Luna_Kill_Loadout", ForceClean) end
if _G.HUDLootScreen then Hooks:PostHook(HUDLootScreen, "init", "Luna_Kill_Loot", ForceClean) end

-- [[ 6. VANILLA FIXES ]]
if _G.HUDHitDirection then
    function HUDHitDirection:_get_indicator_color(damage_type, t)
        local player = managers.player:local_player()
        if alive(player) then
            local armor = player:character_damage():get_real_armor()
            if armor > 0 then return Color(0, 0.8, 1) end 
        end
        return Color(1, 0.2, 0.2)
    end
end
-- =========================================================================
-- 7. TACTICAL NIGHT VISION (V5 - The Frame-Perfect Interceptor)
-- Total utrotning av animerat brus och mörka hörn via material-blockering.
-- =========================================================================
if _G.CoreEnvironmentControllerManager then
    
    -- 1. THE INTERCEPTOR (Körs varje gång motorn försöker ändra en visuell effekt)
    local orig_set_material_modifier = CoreEnvironmentControllerManager.set_material_modifier
    if orig_set_material_modifier then
        function CoreEnvironmentControllerManager:set_material_modifier(material, modifier, value)
            
            -- Brutal blockering av white noise/film grain (Gäller globalt)
            if modifier == "noise_multiplier" then
                value = 0
            end
            
            -- Brutal blockering av mörklagda hörn (Vignette)
            if modifier == "vignette_multiplier" then
                value = 0
            end
            
            -- Skicka vidare det "tvättade" värdet till grafikkortet
            orig_set_material_modifier(self, material, modifier, value)
        end
    end

    -- 2. DÄMPA INTENSITETEN ("Alpha"-reducering för Color Grading)
    if PlayerStandard and PlayerStandard.set_night_vision_state then
        Hooks:PostHook(PlayerStandard, "set_night_vision_state", "LunaHUD_DimNVG", function(self, state)
            if state and managers.environment_controller then
                local ecc = managers.environment_controller
                pcall(function()
                    -- Sänker ljusstyrkan (gör den mjuka färgtonen mindre frätande)
                    ecc:set_material_modifier("color_grading_post", "luminance_multiplier", 0.6)
                    
                    -- Sänker kontrasten något så mörka partier inte blir kolsvarta
                    ecc:set_material_modifier("color_grading_post", "contrast_multiplier", 0.8)
                    
                    -- Ta bort kromatisk aberration (färgseparerade kanter runt skärmen)
                    ecc:set_material_modifier("color_grading_post", "chromatic_amount", 0)
                end)
            else
                -- Återställ när nattseendet stängs av
                if managers.environment_controller then
                    local ecc = managers.environment_controller
                    pcall(function()
                        ecc:set_material_modifier("color_grading_post", "luminance_multiplier", 1)
                        ecc:set_material_modifier("color_grading_post", "contrast_multiplier", 1)
                        ecc:set_material_modifier("color_grading_post", "chromatic_amount", 1)
                    end)
                end
            end
        end)
    else
        log("[LunaHUD] [UI] NVG function 'set_night_vision_state' not present in PlayerStandard, skipping hook.")
    end
    
end
-- [END_ID: VISUAL_CLEAR_V28.0_THE_DECOY] --
