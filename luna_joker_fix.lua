log("[LunaHUD] [DATA] Minion & Joker Management")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Joker Tracker ]]
_G.LunaHUD = _G.LunaHUD or {}

Hooks:PostHook(GroupAIStateBase, "set_unit_team", "Luna_Joker_Track", function(self, unit, team_id)
    if not unit or not unit:base() then return end
    
    DelayedCalls:Add("Luna_Joker_Update_" .. tostring(unit:key()), 0.5, function()
        local count = 0
        if managers.groupai and managers.groupai:state() then
            for _, data in pairs(managers.groupai:state():all_char_criminals()) do
                if data.unit and alive(data.unit) and data.unit:base() and data.unit:base().is_convert then
                    count = count + 1
                end
            end
        end
        _G.LunaHUD.current_jokers = count
    end)
end)

