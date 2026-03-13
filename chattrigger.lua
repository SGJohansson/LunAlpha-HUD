log("[LunaHUD] [SYSTEM] Command Trigger Module")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- ==============================================================================
-- [[ LUNALPHA HUD: KOMMANDOREFERENS (CHAT TRIGGER) ]]
-- ==============================================================================
-- !version   : Skickar moddens version publikt (fungerar som handskakning mellan Luna-användare).
-- !about     : Skickar kort info och GitHub-länk publikt.
-- !help      : Visar en lokal lista över tillgängliga kommandon.
-- !commands  : Alias för !help.
-- ==============================================================================

local function local_msg(txt)
    managers.chat:feed_system_message(ChatManager.GAME, "[LunaHUD] " .. txt)
end

-- 1. HANDSKAKNING (Lyssnar på andras - och dina egna - publika meddelanden)
-- FIX: Använder _receive_message för att garanterat fånga all inkommande nätverkschatt
Hooks:PostHook(ChatManager, "_receive_message", "Luna_Version_Handshake", function(self, channel_id, name, message, color, icon)
    if not message then return end
    
    local msg_lower = message:lower()
    local quiet = _G.LunaHUD and _G.LunaHUD.settings and _G.LunaHUD.settings.quiet_mode

    if msg_lower == "!version" then
        if not quiet then
            local ver = (_G.LunaHUD and _G.LunaHUD.version) and _G.LunaHUD.version or "Unknown"
            -- Fördröjning för att chatten ska hinna rita upp och se naturlig ut. 
            -- Unikt ID förhindrar överskrivning om flera spelare spammar kommandot.
            DelayedCalls:Add("Luna_Version_Reply_" .. tostring(Application:time()), 0.5, function()
                managers.chat:send_message(ChatManager.GAME, "LunaHUD", "LunAlpha HUD v" .. ver)
            end)
        else
            local_msg("Quiet Mode is ON. Ignorerade !version handskakning.")
        end
    end
end)

-- 2. EGNA KOMMANDON & HJÄLPMENY (Fångar innan de skickas)
Hooks:PostHook(ChatManager, "send_message", "Luna_Chat_Command", function(self, channel_id, sender, message)
    if not message then return end
    
    local msg_lower = message:lower()
    local quiet = _G.LunaHUD and _G.LunaHUD.settings and _G.LunaHUD.settings.quiet_mode

    -- PUBLIC: !about
    if msg_lower == "!about" or msg_lower == "!lunalpha" then
        if not quiet then
            local ver = (_G.LunaHUD and _G.LunaHUD.version) and _G.LunaHUD.version or "Unknown"
            managers.chat:send_message(ChatManager.GAME, "LunaHUD", "LunAlpha HUD v" .. ver .. ", https://github.com/SGJohansson/LunAlpha-HUD/")
        else
            local_msg("Quiet Mode is ON. Version info suppressed.")
        end
        return
    end

    -- LOCAL: !help / !commands
    if msg_lower == "!help" or msg_lower == "!commands" then
        local_msg("--- LunAlpha Commands ---")
        local_msg("!info <id>  - Deep Scan in chat (Mods, Stats, Build)")
        local_msg("!stats      - Toggle HUD Statistics")
        local_msg("!list       - List Peers & IDs")
        local_msg("!kickcheck  - Scan for Blacklisted players")
        local_msg("!ssl        - Deep Integrity Scan")
        local_msg("!log        - Save Lobby Snapshot to logs/")
        local_msg("!readme     - Open Local Manual")
        local_msg("!leave      - Return to Main Menu")
        local_msg("!q / !quit  - Exit Game")
        local_msg("!ghost      - Find hidden HUD elements")
        return
    end
end)