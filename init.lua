log("[LunaHUD] [CORE] Global Initialization (V11.0 - Release Candidate)")
if not _G.LunaHUD then _G.LunaHUD = {} end

--------------------------------------------------------------------
-- [LunaHUD] MODUL LADDAD: init.lua (V10.0)
--------------------------------------------------------------------
if _G.LunaHUD and _G.LunaHUD._init_done then return end

_G.LunaHUD = _G.LunaHUD or {}
_G.LunaHUD._init_done = true
_G.LunaHUD_ModPath = ModPath
if not _G.LunaHUD then _G.LunaHUD = {} end
-- [ DYNAMISK VERSIONSKONTROLL ]
local function LoadModVersion()
    local file = io.open(ModPath .. "mod.txt", "r")
    if file then
        local file_content = file:read("*a")
        file:close()
        
        -- Översätt JSON-texten till en Lua-tabell och hämta versionen
        local success, mod_data = pcall(function() return json.decode(file_content) end)
        if success and mod_data and mod_data.version then
            return mod_data.version
        end
    end
    return "UNKNOWN" -- Fallback om något går snett
end
_G.LunaHUD.version = LoadModVersion()
log("[LunaHUD] Laddade version: " .. tostring(_G.LunaHUD.version))
_G.LunaHUD_SavePath = SavePath
_G.LunaHUD.player_stats = { hp = 1, ar = 1 } 

-- Inställnings-motor
_G.LunaHUD.settings_path = _G.LunaHUD_SavePath .. "lunahud_settings.json"

-- DEFAULT VALUES
_G.LunaHUD.settings = {
    show_stats = true,      -- Quake Stats
    show_crosshair = true,  -- Custom Crosshair
    cooker_mode = 3,        -- 1=Off, 2=Local, 3=Public (Default)
    quiet_mode = false      -- False = Svara på commands. True = Tyst.
}

function LunaHUD:LoadSettings()
    local file = io.open(self.settings_path, "r")
    if file then
        local data = json.decode(file:read("*all"))
        file:close()
        if type(data) == "table" then
            for k, v in pairs(data) do 
                self.settings[k] = v 
            end
        end
    end
end

function LunaHUD:SaveSettings()
    local file = io.open(self.settings_path, "w+")
    if file then
        file:write(json.encode(self.settings))
        file:close()
    end
end

LunaHUD:LoadSettings()

function LunaHUD:clean_text(text_id)
    if not text_id then return "" end
    local text = managers.localization:text(text_id)
    local clean = text:gsub("hud_int_", ""):gsub("HUD_INT_", ""):gsub("_", " ")
    return clean:upper()
end

