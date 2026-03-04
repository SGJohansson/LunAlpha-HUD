log("[LunaHUD] [DATA] Point of No Return & Tracker Logic")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunaHUD: No Return & Status V2.1.1 (Hotfix) ]]
Hooks:PostHook(HUDManager, "update", "LunaNoReturn_Loop", function(self, t, dt)
    local main_hud = managers.hud and managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
    if not main_hud then return end
    
    -- SÄKERSTÄLL variablerna, även om _G.LunaStatus levt kvar i minnet från förra rundan
    _G.LunaStatus = _G.LunaStatus or {}
    _G.LunaStatus._setup_done = _G.LunaStatus._setup_done or false
    _G.LunaStatus._last_stat_update = _G.LunaStatus._last_stat_update or 0

    -- [SÄKERHETSVENTIL] Bygg om om Mask On raderar elementen
    if _G.LunaStatus._setup_done and (_G.LunaStatus._noreturn == nil or not alive(_G.LunaStatus._noreturn)) then
        _G.LunaStatus._setup_done = false
    end

    -- 1. SETUP
    if not _G.LunaStatus._setup_done then
        -- Vi använder huvudpanelen så att ingenting klipps av
        local root = main_hud.panel
        local font = "fonts/font_medium_shadow_mf"

        _G.LunaStatus._noreturn = root:text({ name = "l_nr", font = font, font_size = 28, color = Color.red, align = "right", layer = 100, alpha = 0 })
        _G.LunaStatus._hostages = root:text({ name = "l_os", font = font, font_size = 22, color = Color.white, align = "right", layer = 100, alpha = 0 })
        _G.LunaStatus._jokers = root:text({ name = "l_jk", font = font, font_size = 22, color = Color(1, 0.84, 0), align = "right", layer = 100, alpha = 0 })
        
        -- Vår nya Tracker (Pagers / Hostiles)
        _G.LunaStatus._tracker = root:text({ name = "l_tr", font = font, font_size = 22, color = Color.white, align = "right", layer = 100, alpha = 1 })

        _G.LunaStatus._setup_done = true
    end

    -- 2. UPDATE LOOP
    if _G.LunaStatus._setup_done and alive(_G.LunaStatus._noreturn) then
        local w = _G.LunaStatus._noreturn:parent():w()
        
        -- Hämta data
        local h_count = 0
        local j_count = 0
        local nr_timer = 0
        local is_whisper = false
        local is_assault = false
        local pagers_used = 0
        local hostiles_count = 0

        if managers.groupai and managers.groupai:state() then
            local state = managers.groupai:state()
            
            -- Hostages & No Return
            if state.hostage_count then h_count = state:hostage_count() or 0 end
            if state.get_point_of_no_return_timer then nr_timer = state:get_point_of_no_return_timer() or 0 end

            -- Jokers
            if state._converted_enemies then
                for _ in pairs(state._converted_enemies) do j_count = j_count + 1 end
            end

            -- Tracker Data
            is_whisper = state:whisper_mode()
            is_assault = state:get_assault_mode()
            
            if is_whisper then
                pagers_used = state:get_nr_successful_alarm_pager_bluffs() or 0
            else
                -- Strypt uträkning av hostiles för prestanda
                if t - _G.LunaStatus._last_stat_update > 1 then
                    _G.LunaStatus._last_stat_update = t
                    local count = 0
                    if managers.enemy and managers.enemy:all_enemies() then
                        for _, u_data in pairs(managers.enemy:all_enemies()) do
                            if not (u_data.unit.brain and u_data.unit:brain()._logic_data and u_data.unit:brain()._logic_data.is_converted) then
                                count = count + 1
                            end
                        end
                    end
                    _G.LunaStatus._cached_hostiles = count
                end
                hostiles_count = _G.LunaStatus._cached_hostiles or 0
            end
        end

        -- Uppdatera Texter
        _G.LunaStatus._hostages:set_text(h_count .. " Hostages")
        _G.LunaStatus._hostages:set_alpha(h_count > 0 and 1 or 0)

        _G.LunaStatus._jokers:set_text(j_count .. " Jokers")
        _G.LunaStatus._jokers:set_alpha(j_count > 0 and 1 or 0)

        if is_whisper then
            _G.LunaStatus._tracker:set_text(pagers_used .. "/4 Pagers")
            _G.LunaStatus._tracker:set_color(Color.white)
        else
            if is_assault then
                _G.LunaStatus._tracker:set_text(hostiles_count .. " Active Hostiles")
                _G.LunaStatus._tracker:set_color(Color(1, 0.84, 0))
            else
                _G.LunaStatus._tracker:set_text(hostiles_count .. " Hostiles")
                _G.LunaStatus._tracker:set_color(Color.white)
            end
        end

        -- 3. Positionerings-logik (Staplar allt sömlöst)
        local base_y = 54 -- Start-höjd under klockan
        
        if nr_timer > 0 then
            _G.LunaStatus._noreturn:set_text(string.format("ESCAPE: %02d:%02d", math.floor(nr_timer/60), math.floor(nr_timer%60)))
            _G.LunaStatus._noreturn:set_alpha(1)
            
            _G.LunaStatus._noreturn:set_right(w - 20) 
            _G.LunaStatus._noreturn:set_top(base_y)
            base_y = base_y + 30
        else
            _G.LunaStatus._noreturn:set_alpha(0)
        end

        if h_count > 0 then
            _G.LunaStatus._hostages:set_right(w - 20) 
            _G.LunaStatus._hostages:set_top(base_y)
            base_y = base_y + 25
        end

        if j_count > 0 then
            _G.LunaStatus._jokers:set_right(w - 20) 
            _G.LunaStatus._jokers:set_top(base_y)
            base_y = base_y + 25
        end

        -- Trackern läggs alltid in sist i kön, fäst vid nuvarande "base_y"
        _G.LunaStatus._tracker:set_right(w - 20)
        _G.LunaStatus._tracker:set_top(base_y)
    end
end)