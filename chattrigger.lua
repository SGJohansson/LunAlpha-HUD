log("[LunaHUD] [SYSTEM] Command Trigger Module")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Chat Trigger V11.2 - Dynamic Version ]]
-- Role: Hanterar ENDAST publika info-kommandon (!version, !about, !help).
-- Fix: Hämtar nu versionsnumret dynamiskt från _G.LunaHUD.version (init.lua).


local function local_msg(txt)
    -- feed_system_message är säkert att använda lokalt
    managers.chat:feed_system_message(ChatManager.GAME, "[LunaHUD] " .. txt)
end

Hooks:PostHook(ChatManager, "send_message", "Luna_Chat_Command", function(self, channel_id, sender, message)
    if not message then return end
    
    local msg_lower = message:lower()
    
    -- =================================================================
    -- 1. QUIET MODE CHECK
    -- =================================================================
    local quiet = _G.LunaHUD and _G.LunaHUD.settings and _G.LunaHUD.settings.quiet_mode

    -- =================================================================
    -- 2. PUBLIKA KOMMANDON (!version / !about)
    -- =================================================================
    if msg_lower == "!version" or msg_lower == "!about" or msg_lower == "!lunalpha" then
        if not quiet then
            -- DYNAMISK HÄMTNING:
            -- Vi hämtar versionen från init.lua. Fallback till "Unknown" om globalen saknas.
            local ver = (_G.LunaHUD and _G.LunaHUD.version) and _G.LunaHUD.version or "Unknown"

            managers.chat:send_message(ChatManager.GAME, "LunaHUD", "LunAlpha HUD v" .. ver)
            managers.chat:send_message(ChatManager.GAME, "LunaHUD", "Dev: S.G.Johansson, https://lunalpha-hud.netlify.app ")
        else
            -- Annars bara lokalt meddelande
            local_msg("Quiet Mode is ON. Version info suppressed.")
        end
        return
    end

    -- =================================================================
    -- 3. HJÄLP (!help / !commands)
    -- =================================================================
    if msg_lower == "!help" or msg_lower == "!commands" then
        local_msg("--- LunAlpha Commands ---")
        local_msg("!ghost      - Find hidden HUD elements")
        local_msg("!stats      - Toggle HUD Statistics")
        local_msg("!list       - List Peers & IDs")
        local_msg("!kickcheck  - Scan for Blacklisted players")
        local_msg("!ssl        - Deep Integrity Scan")
        local_msg("!log        - Save Lobby Snapshot to logs/")
        local_msg("Use Menu for: CleanCooker, Quiet Mode & Blacklist Wipe.")
        return
    end
end)
