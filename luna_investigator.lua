log("[LunaHUD] [SYSTEM] Security & Crossplay Investigator (V14.7 - Crash Fix & Vanilla Sync)")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [ID: INVESTIGATOR_V14.7_STABLE] --
-- [[ LUNALPHA INVESTIGATOR v14.7 ]]
--
-- [ CHANGELOG V14.7 ]
-- + Crash Fix: Tog bort anrop till obefintlig banned_list-metod i Vanilla Sync.
-- + Blind Fire Unban: Skjuter nu in både ID som string och number mot spelets motor för 100% träff.
-- + Data Unification: process_peers och !ban använder nu ett enhetligt Account ID för båda databaserna.
-- + Quick Unban: !unban utan argument tar nu automatiskt bort den senast bannade spelaren.
-- + Smart Aimbot Filter: Ignorerar nu automatiskt hagelgevär/explosiva vapen.

_G.LunaInvestigator = _G.LunaInvestigator or {
    last_snap_t = 0,
    cooldown = 2,
    last_banned_id = nil, -- Quick Unban memory
    spam_tracker = {}, 
    join_timers = {},  
    blacklist_keywords = {
        "p3dhack", "pirate", "unlocker", "dlc", "mvp", "silent assassin",
        "carry stacker", "extra loot", "selective replenisher", "cook faster",
        "auto cook", "auto open", "instant", "aimbot", "godmode",
        "money generator", "experience booster", "db suppressor unlocker",
        "little friend", "good rpg", "cl menu", "biker perk deck",
        "rngmodifier", "ct mod", "ultimate trainer", "xp increaser",
        "overdrill", "meth helper", "unlock all", "crime spree", 
        "spree adder", "free contracts", "free assets", "free skills", 
        "god mode", "infinite ammo", "interact through walls", "speedhack"
    },
    log_dir = ModPath .. "logs/",
    db_path = ModPath .. "luna_blacklist.json"
}

LunaInvestigator.TREE_NAMES = {
    "MM: Medic", "MM: Controller", "MM: Sharpshooter",
    "ENF: Shotgunner", "ENF: Tank", "ENF: Ammo",
    "TECH: Engineer", "TECH: Breacher", "TECH: Oppressor",
    "GHO: Shinobi", "GHO: Artful", "GHO: Silent",
    "FUG: Gunslinger", "FUG: Revenant", "FUG: Brawler"
}

LunaInvestigator.PERK_DECKS = {
    "Crew Chief", "Muscle", "Armorer", "Rogue", "Hitman", "Burglar",
    "Infiltrator", "Sociopath", "Gambler", "Grinder", "Yakuza", "Ex-President",
    "Maniac", "Anarchist", "Sicario", "Stoic", "Tag Team", "Hacker",
    "Leech", "Copycat"
}

-- [[ CORE UTILS ]]
function LunaInvestigator:is_safe()
    return managers.network and managers.network:session()
end

function LunaInvestigator:local_feedback(msg)
    if managers.chat then
        managers.chat:_receive_message(ChatManager.GAME, "LUNA", msg, Color(1, 0.84, 0))
    end
end

function LunaInvestigator:announce(msg, to_all)
    self:local_feedback(msg)
    if to_all and self:is_safe() and Network:is_server() then
        managers.network:session():send_to_peers_ip_verified("send_chat_message", ChatManager.GAME, "[LUNA] " .. msg)
    end
end

function LunaInvestigator:load_db()
    local file = io.open(self.db_path, "r")
    local db = {}
    if file then
        local content = file:read("*all")
        file:close()
        if content and content ~= "" then
            local success, decoded = pcall(json.decode, content)
            if success and type(decoded) == "table" then 
                db = decoded 
            end
        end
    end
    return db
end

function LunaInvestigator:save_db(db)
    local file = io.open(self.db_path, "w")
    if file then file:write(json.encode(db)) file:close() end
end

-- [[ CROSSPLAY HELPERS ]]
function LunaInvestigator:get_platform_info(user_id)
    local uid_str = tostring(user_id)
    if #uid_str == 17 then
        return "STEAM", "https://steamcommunity.com/profiles/" .. uid_str
    else
        return "EPIC/EOS", "N/A (Crossplay)"
    end
end

-- [[ SPAM PROTECTION ]]
function LunaInvestigator:is_spamming(peer_id)
    if not managers.job or not managers.job:has_active_job() then return false end
    local state = game_state_machine and game_state_machine:current_state_name()
    if state and (state == "menu_main" or state == "ingame_waiting_for_players") then return false end

    local t = Application:time()
    local join_t = self.join_timers[peer_id] or 0
    if (t - join_t) < 15.0 then return false end 

    local tracker = self.spam_tracker[peer_id] or { last_t = 0, count = 0 }
    if t - tracker.last_t < 4.0 then
        tracker.count = tracker.count + 1
        self.spam_tracker[peer_id] = tracker
        if tracker.count > 3 then return true end
        return false
    else
        tracker.last_t = t
        tracker.count = 0
        self.spam_tracker[peer_id] = tracker
        return false
    end
end

function LunaInvestigator:force_kick(peer, id)
    if not Network:is_server() or not managers.network:session() then return end
    managers.network:session():send_to_peers("kick_peer", id, 2)
    managers.network:session():on_peer_kicked(peer, id, 2)
end

-- [[ ANALYTICS TOOLS ]]
function LunaInvestigator:interpret_build(skill_str)
    if not skill_str or skill_str == "" then return "Syncing...", 0 end
    local parts = string.split(skill_str, skill_str:find("_") and "_" or "-")
    local total = 0
    for i = 1, 15 do total = total + (tonumber(parts[i]) or 0) end
    local perk_id = tonumber(parts[16]) or 0
    local perk_name = self.PERK_DECKS[perk_id] or "Unknown"
    return perk_name, total
end

function LunaInvestigator:get_accuracy(peer)
    if not peer or not peer.statistics then return 0, 0 end
    local stats = peer:statistics()
    local shots = stats and stats.session_total_shots or 0
    local hits = stats and stats.session_total_hits or 0
    
    if shots == 0 then return 0, 0 end 
    
    local acc = math.floor((hits / shots) * 100)
    return acc, shots
end

function LunaInvestigator:is_multihit_equipped(peer)
    if not peer or not peer:blackmarket_outfit() then return true end -- Fail safe
    local outfit = peer:blackmarket_outfit()
    
    local function check_weapon(w_data)
        if not w_data or not w_data.factory_id then return false end
        local w_id = managers.weapon_factory:get_weapon_id_by_factory_id(w_data.factory_id)
        if not w_id then return false end
        
        local w_tweak = tweak_data.weapon[w_id]
        if not w_tweak or not w_tweak.categories then return false end
        
        for _, cat in ipairs(w_tweak.categories) do
            if cat == "shotgun" or cat == "grenade_launcher" or cat == "flamethrower" or cat == "bow" or cat == "crossbow" then
                return true
            end
        end
        return false
    end
    
    return check_weapon(outfit.primary) or check_weapon(outfit.secondary)
end

function LunaInvestigator:check_dlc_integrity(peer)
    if not peer or not peer.outfit then return false end
    local outfit = peer:outfit()
    if not outfit or not outfit.primary or not outfit.primary.blueprint then return false end
    
    for _, part_id in ipairs(outfit.primary.blueprint) do
        local part_data = tweak_data.weapon.factory.parts[part_id]
        if part_data and part_data.dlc then
            if not managers.dlc:is_dlc_unlocked(part_data.dlc) and not peer:is_dlc_unlocked(part_data.dlc) then
                return true, part_data.dlc
            end
        end
    end
    return false
end

-- [[ PROCESS PEERS (AUTO-SCAN LOGIC) ]]
function LunaInvestigator:process_peers(mode, target_peer)
    if not self:is_safe() then return end
    local session = managers.network:session()
    local peers = target_peer and { [target_peer:id()] = target_peer } or session:peers()
    local my_id = session:local_peer():id()
    local db = self:load_db()
    local remote_count = 0
    local kick_performed = false

    for id, peer in pairs(peers) do
        if peer and id ~= my_id then
            remote_count = remote_count + 1
            if mode == "silent" and self:is_spamming(id) then 
                -- Drop
            else
                local name = peer:name()
                -- Enhetlig ID identifierare för JSON och Vanilla
                local account_id_raw = peer:account_id() or peer:user_id()
                local acc_id_str = tostring(account_id_raw)

                if db[acc_id_str] then
                    self:announce("ALERT: Banned player detected: " .. name, true)
                    self:force_kick(peer, id)
                    kick_performed = true
                    return
                end

                local dirty_reasons = {}
                local mods = peer:synced_mods() or {}
                for _, mod in ipairs(mods) do
                    local mod_name = tostring(mod.name):lower()
                    for _, kw in ipairs(self.blacklist_keywords) do
                        if mod_name:find(kw) then table.insert(dirty_reasons, "Mod: " .. kw) break end
                    end
                end

                -- SMART AIMBOT FILTER
                local acc, shots = self:get_accuracy(peer)
                if acc and shots > 50 then
                    local is_multi = self:is_multihit_equipped(peer)
                    if not is_multi and acc >= 90 then
                        table.insert(dirty_reasons, "Aimbot (" .. acc .. "% on " .. shots .. " shots)")
                    end
                end

                if peer.skills then
                    local skill_res = peer:skills()
                    if skill_res then
                        local _, total_points = self:interpret_build(skill_res)
                        if total_points > 120 then table.insert(dirty_reasons, "Cheated Skills (" .. total_points .. " pts)") end
                    end
                end

                -- DLC FIX
                local dlc_cheat, item = self:check_dlc_integrity(peer)
                if dlc_cheat then table.insert(dirty_reasons, "DLC Unlocker (" .. tostring(item) .. ")") end

                -- ABSOLUTE BAN LOGIC
                if #dirty_reasons > 0 then
                    local reason_str = table.concat(dirty_reasons, ", ")
                    
                    if mode == "out" then
                        self:announce("FLAGGED: " .. name .. " | " .. reason_str, true)
                    end
                    
                    local plat_name, plat_link = self:get_platform_info(acc_id_str)
                    db[acc_id_str] = { 
                        name = name, 
                        reason = reason_str, 
                        date = os.date("%Y-%m-%d"),
                        url = plat_link
                    }
                    -- SPARA TILL QUICK UNBAN MEMORY
                    self.last_banned_id = acc_id_str
                    self:save_db(db)

                    -- VANILLA SYNC
                    if managers.ban_list and account_id_raw then
                        managers.ban_list:ban(account_id_raw, name)
                        managers.savefile:save_setting(true)
                    end

                    self:announce("KICKING: " .. name .. " (" .. reason_str .. ")", true)
                    self:force_kick(peer, id)
                    kick_performed = true 
                    
                elseif mode == "out" then
                     self:local_feedback("["..id.."] " .. name .. ": Clean.")
                end
            end
        end
    end
    
    if remote_count == 0 and mode ~= "silent" then
        local cmd_name = (mode == "out") and "!ssl" or (mode == "kick" and "!kickcheck" or "Scan")
        self:local_feedback(cmd_name .. ": Executed. No remote peers found.")
    elseif mode == "kick" and not kick_performed and remote_count > 0 then
        self:local_feedback("Kickcheck complete. No bans executed.")
    end
end

-- [[ SNAPSHOT (LOGGING) ]]
function LunaInvestigator:run_snapshot(silent)
    if not self:is_safe() then return end
    
    if _G.LunaHUD and _G.LunaHUD.settings and _G.LunaHUD.settings.quiet_mode then
        if not silent then 
            self:local_feedback("Quiet Mode is active. Log generation skipped.") 
        end
        return
    end

    if not SystemFS:exists(Application:nice_path(self.log_dir, false)) then SystemFS:make_dir(Application:nice_path(self.log_dir, false)) end
    
    local file_path = self.log_dir .. "LunaLog_" .. os.date("%Y-%m-%d") .. ".log"
    local f = io.open(file_path, "a")
    local output = "=== [ ENTRY: " .. os.date("%H:%M:%S") .. " ] ===\n"
    local remote_count = 0
    local session = managers.network:session()
    local my_id = session:local_peer():id()
    
    for id, peer in pairs(session:peers()) do
        if peer and id ~= my_id then
            remote_count = remote_count + 1
            local s_str = peer.skills and peer:skills() or ""
            local perk, pts = self:interpret_build(s_str)
            local acc, shots = self:get_accuracy(peer)
            local user_id = tostring(peer:user_id())
            local plat_name, plat_link = self:get_platform_info(user_id)
            
            output = output .. "PLAYER: " .. peer:name() .. " [ID: " .. user_id .. "]\n"
            output = output .. "PLATFORM: " .. plat_name .. " (" .. plat_link .. ")\n"
            output = output .. "FBI:      https://fbi.paydaythegame.com/suspect/" .. user_id .. "\n"
            output = output .. "BUILD: " .. perk .. " (" .. pts .. " pts) | ACC: " .. acc .. "% (" .. shots .. ")\n"
            local mods = peer:synced_mods() or {}
            output = output .. "MODS: " .. (#mods > 0 and "" or "Hidden/None") .. "\n"
            for _, m in ipairs(mods) do output = output .. " - " .. tostring(m.name) .. "\n" end
            output = output .. "----------------------------------\n"
        end
    end
    
    if remote_count == 0 then
        output = output .. "Command: !log was executed but no peers are currently connected. EOF\n"
    end
    output = output .. "\n"

    if f then f:write(output) f:close() end
    if not silent then self:local_feedback("Lobby snapshot saved to logs/.") end
end

-- [[ AUTO SCAN HOOK ]]
if _G.UnitNetworkHandler then
    Hooks:PostHook(UnitNetworkHandler, "set_unit", "Luna_Auto_Scan_Hook", function(self, unit, char, outfit, out_id, peer_id)
        if _G.LunaHUD and _G.LunaHUD.settings and _G.LunaHUD.settings.auto_investigate == false then 
            return 
        end

        if peer_id and managers.network:session() then
            if not LunaInvestigator.join_timers[peer_id] then LunaInvestigator.join_timers[peer_id] = Application:time() end
            DelayedCalls:Add("Luna_AutoScan_" .. tostring(peer_id), 8.0, function()
                local p = managers.network:session():peer(peer_id)
                if p then LunaInvestigator:process_peers("silent", p) end
            end)
        end
    end)
end

-- [[ COMMAND INTERCEPTOR (THE GATEKEEPER) ]]
if not _G.LunaCommandHooked then
    _G.LunaCommandHooked = true
    local orig_send_message = ChatManager.send_message

    local function GetPeer(id_str)
        local id = tonumber(id_str)
        if not id then return nil end
        return managers.network:session():peer(id)
    end

    local function PrintPeerList()
        LunaInvestigator:local_feedback("--- ACTIVE PEERS ---")
        local found = false
        local session = managers.network:session()
        for id, p in pairs(session:peers()) do
            if id ~= session:local_peer():id() then 
                found = true
                LunaInvestigator:local_feedback(string.format("[%d] %s", id, p:name())) 
            end
        end
        if not found then LunaInvestigator:local_feedback("No remote peers connected.") end
    end

    local luna_commands = {
        ["ghost"] = function(msg)
            local found = 0
            local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
            
            local function scan(panel, p_name)
                if not panel or not panel.children then return end
                for _, child in ipairs(panel:children()) do
                    if child.type_name == "Text" and child:text() == "HELLO" then
                        LunaInvestigator:local_feedback(">>> GHOST FOUND! <<<")
                        child:set_text("BUSTED")
                        child:set_color(Color.red)
                        found = found + 1
                    elseif child.type_name == "Panel" then
                        scan(child, tostring(child:name()))
                    end
                end
            end

            if hud and hud.panel then scan(hud.panel, "HUD_Root") end
        end

        ,["stats"] = function(msg)
            if _G.LunaHUD and _G.LunaHUD.settings then
                _G.LunaHUD.settings.show_stats = not _G.LunaHUD.settings.show_stats
                _G.LunaHUD:SaveSettings()
                local status = _G.LunaHUD.settings.show_stats and "ON" or "OFF"
                LunaInvestigator:local_feedback("Combat Stats Feed: " .. status)
            end
        end

        ,["quit"] = function(msg)
            LunaInvestigator:local_feedback("Exiting game...")
            setup:quit()
        end

        ,["spawn"] = function(msg)
            if not Network:is_server() then LunaInvestigator:local_feedback("Error: Host only.") return end
            managers.network:session():spawn_players()
            LunaInvestigator:local_feedback("Forced spawn on all waiting players.")
        end

        ,["restart"] = function(msg)
            if not Network:is_server() then LunaInvestigator:local_feedback("Error: Host only.") return end
            LunaInvestigator:local_feedback("Restarting game...")
            if managers.game_play_central then
                managers.game_play_central:restart_the_game() 
            end
        end

        ,["list"] = function(msg) PrintPeerList() end

        ,["debug"] = function(msg)
            local target_id = msg:match(" (%d+)")
            if target_id then
                local peer = GetPeer(target_id)
                if peer then
                    LunaInvestigator:local_feedback("--- DEEP SCAN: " .. peer:name() .. " ---")
                    local s_str = peer.skills and peer:skills() or ""
                    local perk, pts = LunaInvestigator:interpret_build(s_str)
                    LunaInvestigator:local_feedback(string.format("Build: %s | Pts: %d%s", perk, pts, pts > 120 and " [!]" or ""))
                    local acc, shots = LunaInvestigator:get_accuracy(peer)
                    LunaInvestigator:local_feedback(string.format("Acc: %d%% (%d shots)", acc, shots))
                    local blt = "N/A"
                    for _, m in ipairs(peer:synced_mods() or {}) do 
                        if m.name == "SuperBLT" then blt = tostring(m.version or "Unknown") end 
                    end
                    LunaInvestigator:local_feedback("SuperBLT: " .. blt)
                else
                    LunaInvestigator:local_feedback("Peer " .. target_id .. " not found.")
                end
            else
                PrintPeerList()
            end
        end

        ,["mods"] = function(msg)
            local target_id = msg:match(" (%d+)")
            if not target_id then LunaInvestigator:local_feedback("Usage: !mods <id>") return end
            local peer = GetPeer(target_id)
            if peer then
                LunaInvestigator:local_feedback("--- MODS: " .. peer:name() .. " ---")
                local mods = peer:synced_mods() or {}
                if #mods == 0 then
                    LunaInvestigator:local_feedback("No mods detected (or hidden).")
                else
                    for _, m in ipairs(mods) do LunaInvestigator:local_feedback("- " .. tostring(m.name)) end
                end
            else
                LunaInvestigator:local_feedback("Peer " .. target_id .. " not found.")
            end
        end

        ,["kick"] = function(msg)
            if not Network:is_server() then LunaInvestigator:local_feedback("Error: Host only.") return end
            local target_id = msg:match(" (%d+)")
            if not target_id then LunaInvestigator:local_feedback("Usage: !kick <id>") return end
            local peer = GetPeer(target_id)
            if peer then
                LunaInvestigator:announce("Kicking " .. peer:name() .. "...", true)
                LunaInvestigator:force_kick(peer, tonumber(target_id))
            else
                LunaInvestigator:local_feedback("Peer " .. target_id .. " not found.")
            end
        end

        ,["ban"] = function(msg)
            if not Network:is_server() then LunaInvestigator:local_feedback("Error: Host only.") return end
            local target_id = msg:match(" (%d+)")
            if not target_id then LunaInvestigator:local_feedback("Usage: !ban <id>") return end
            local peer = GetPeer(target_id)
            if peer then
                local account_id_raw = peer:account_id() or peer:user_id()
                local acc_id_str = tostring(account_id_raw)
                local db = LunaInvestigator:load_db()
                local _, plat_link = LunaInvestigator:get_platform_info(acc_id_str)
                db[acc_id_str] = { 
                    name = peer:name(), 
                    reason = "Manual Ban", 
                    date = os.date("%Y-%m-%d"),
                    url = plat_link
                }
                
                -- SPARA TILL QUICK UNBAN MEMORY
                LunaInvestigator.last_banned_id = acc_id_str
                LunaInvestigator:save_db(db)
                
                -- VANILLA SYNC
                if managers.ban_list and account_id_raw then
                    managers.ban_list:ban(account_id_raw, peer:name())
                    managers.savefile:save_setting(true)
                end

                LunaInvestigator:announce("Banning " .. peer:name() .. "...", true)
                LunaInvestigator:force_kick(peer, tonumber(target_id))
            else
                LunaInvestigator:local_feedback("Peer " .. target_id .. " not found.")
            end
        end

        ,["mark"] = function(msg)
            if not Network:is_server() then LunaInvestigator:local_feedback("Error: Host only.") return end
            local target_id = msg:match(" (%d+)")
            if not target_id then LunaInvestigator:local_feedback("Usage: !mark <id>") return end
            local peer = GetPeer(target_id)
            if peer then
                managers.network:session():mark_peer_as_cheater(tonumber(target_id), "LunaHUD Manual Mark")
                LunaInvestigator:announce("MARKED: " .. peer:name() .. " is now flagged as a Cheater.", true)
            else
                LunaInvestigator:local_feedback("Peer " .. target_id .. " not found.")
            end
        end

        ,["arrest"] = function(msg)
            if not Network:is_server() then LunaInvestigator:local_feedback("Error: Host only.") return end
            local target_id = msg:match(" (%d+)")
            if not target_id then LunaInvestigator:local_feedback("Usage: !arrest <id>") return end
            
            local peer = GetPeer(target_id)
            if peer then
                if alive(peer:unit()) then
                    local unit = peer:unit()
                    managers.network:session():send_to_peers_synched("sync_player_movement_state", unit, "arrested", 0, unit:id())
                    peer:send("sync_player_movement_state", unit, "arrested", 0, unit:id())
                    LunaInvestigator:announce("JAIL: " .. peer:name() .. " has been handcuffed.", true)
                else
                    LunaInvestigator:local_feedback("Error: " .. peer:name() .. " is not fully spawned yet.")
                end
            else
                LunaInvestigator:local_feedback("Peer " .. target_id .. " not found.")
            end
        end

        ,["ssl"] = function(msg)
            LunaInvestigator:announce("Scanning peers...", false)
            LunaInvestigator:process_peers("out")
            LunaInvestigator:run_snapshot(true)
        end

        ,["log"] = function(msg) LunaInvestigator:run_snapshot(false) end

        ,["kickcheck"] = function(msg)
            if Network:is_server() then 
                LunaInvestigator:process_peers("kick") 
            else
                LunaInvestigator:local_feedback("Error: Host only.")
            end
        end

        -- [ KRASCHSÄKER VANILLA UNBAN ]
        ,["unban"] = function(msg)
            local t = string.sub(msg, 8)
            t = t and t:match("^%s*(.-)%s*$") or "" 
            
            local db = LunaInvestigator:load_db()
            local found = false

            if t == "" then
                if LunaInvestigator.last_banned_id and db[LunaInvestigator.last_banned_id] then
                    t = LunaInvestigator.last_banned_id
                else
                    LunaInvestigator:local_feedback("No recent bans in memory. Usage: !unban <name or id>")
                    return
                end
            end
            
            local search_t = t:lower()
            
            for json_account_id, data in pairs(db) do
                if json_account_id:lower() == search_t or (type(data) == "table" and data.name and data.name:lower():find(search_t, 1, true)) then
                    
                    local unbanned_name = type(data) == "table" and data.name or json_account_id
                    db[json_account_id] = nil
                    LunaInvestigator:save_db(db)
                    
                    -- VANILLA SYNC: Skjut blint på både string och number för att undvika PD2-krascher
                    if managers.ban_list then
                        managers.ban_list:unban(json_account_id)
                        
                        local num_id = tonumber(json_account_id)
                        if num_id then
                            managers.ban_list:unban(num_id)
                        end
                        
                        managers.savefile:save_setting(true)
                    end

                    LunaInvestigator:announce("Unbanned: " .. unbanned_name, false)
                    
                    if LunaInvestigator.last_banned_id == json_account_id then
                        LunaInvestigator.last_banned_id = nil
                    end
                    
                    found = true
                    break
                end
            end
            
            if not found then 
                LunaInvestigator:local_feedback("User '".. t .."' not found in ban list.") 
            end
        end

        ,["readyup"] = function(msg)
            if not Network:is_server() then LunaInvestigator:local_feedback("Error: Host only.") return end
            local waiting = {}
            local count = 0
            local session = managers.network:session()
            for id, p in pairs(session:peers()) do
                if id ~= session:local_peer():id() then
                    count = count + 1
                    if not p:waiting_for_player_ready() then table.insert(waiting, p:name()) end
                end
            end
            if count == 0 then
                 LunaInvestigator:local_feedback("All remote peers are ready.")
            elseif #waiting > 0 then
                LunaInvestigator:announce("WAITING FOR: " .. table.concat(waiting, ", ") .. ". Please ready up!", true)
            else
                LunaInvestigator:local_feedback("Everyone is ready.")
            end
        end
    }

    -- Aliases (Mapping synonyms)
    luna_commands["exit"] = luna_commands["quit"]
    luna_commands["unstuck"] = luna_commands["spawn"]
    luna_commands["load"] = luna_commands["spawn"]
    luna_commands["s"] = luna_commands["spawn"]
    
    luna_commands["cheaters"] = luna_commands["kickcheck"]
    
    luna_commands["players"] = luna_commands["list"]
    luna_commands["peers"] = luna_commands["list"]
    
    luna_commands["k"] = luna_commands["kick"]
    luna_commands["b"] = luna_commands["ban"]
    luna_commands["m"] = luna_commands["mods"]
    luna_commands["r"] = luna_commands["restart"]
    luna_commands["cheater"] = luna_commands["mark"]
    
    -- Jailing aliases
    luna_commands["jail"] = luna_commands["arrest"]
    luna_commands["mute"] = luna_commands["arrest"]

    -- The Gatekeeper Function
    function ChatManager:send_message(channel_id, sender, message)
        if not message or type(message) ~= "string" then
            return orig_send_message(self, channel_id, sender, message)
        end

        if message:sub(1, 1) == "!" then
            local parts = string.split(message, " ")
            local command_key = parts[1]:sub(2):lower()

            if luna_commands[command_key] then
                luna_commands[command_key](message)
                return -- Silent execution
            end
        end

        return orig_send_message(self, channel_id, sender, message)
    end
end
-- [END_ID: INVESTIGATOR_V14.7_STABLE] --