log("[LunaHUD] [CORE] System Kernel Active")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Environment Setup ]]
-- ModPath är en inbyggd SuperBLT-global som pekar på din mod-mapp
LunaHUD.mod_path = ModPath
LunaHUD.logs_path = LunaHUD.mod_path .. "logs/"
LunaHUD.blacklist_path = LunaHUD.mod_path .. "luna_blacklist.json"

-- Ensure Directory Structure
-- Vi använder Application:nice_path för att konvertera till rätt OS-format (Windows/Linux)
function LunaHUD:setup_filesystem()
    -- Kontrollera och skapa logs-mappen
    local nice_logs = Application:nice_path(self.logs_path, true)
    if not SystemFS:exists(nice_logs) then
        SystemFS:make_dir(nice_logs)
        log("[LunaHUD] [CORE] Created missing logs directory at: " .. nice_logs)
    end

    -- Kontrollera och skapa en tom blacklist.json
    local nice_blacklist = Application:nice_path(self.blacklist_path, false)
    if not io.file_is_readable(nice_blacklist) then
        local file = io.open(nice_blacklist, "w")
        if file then
            file:write("{}") -- Viktigt: En tom JSON-tabell för att Investigator inte ska krascha
            file:close()
            log("[LunaHUD] [CORE] Initialized empty luna_blacklist.json")
        else
            log("[LunaHUD] [ERROR] Could not create blacklist file!")
        end
    end
end

-- Exekvera setup omedelbart vid laddning
LunaHUD:setup_filesystem()

-- [[ LunAlpha HUD: Core Firewall V8.0 - Safe House Shield ]]
