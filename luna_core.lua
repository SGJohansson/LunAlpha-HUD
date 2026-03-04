log("[LunaHUD] [CORE] System Kernel Active")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Core Firewall V8.0 - Safe House Shield ]]

--local old_set_unit = UnitNetworkHandler.set_unit
--function UnitNetworkHandler:set_unit(unit, character_name, outfit_string, outlier_id, peer_id, ...)
--    -- Tvinga Dallas i Safe House för att spara minne och slippa asset-krascher
--   local level_id = managers.job:current_level_id()
--    if level_id == "chill_ri" or level_id == "chill" or (outfit_string and #outfit_string > 300) then
--        outfit_string = "dallas"
--    end
--    return old_set_unit(self, unit, character_name, outfit_string, outlier_id, peer_id, ...)
--end
