log("[LunaHUD] [DATA] CleanCooker Assistant (V11.3)")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: CleanCooker V11.3 - Live Visuals ]]
-- Logic: Blå text [RADIO] BAIN lokalt.
-- Feature: Live Toggle. Reagerar direkt på meny-ändringar utan omstart.

_G.CleanCooker = _G.CleanCooker or {}
CleanCooker.last_t = 0
CleanCooker.COOLDOWN = 5 

-- Bekräftade ID:n (Säkerhetslistan)
CleanCooker.DEFINITIONS = {
    -- Lab Rats / Cook Off Standard
    ["pln_rt1_20"] = "Muriatic Acid",
    ["pln_rt1_22"] = "Caustic Soda",
    ["pln_rt1_24"] = "Hydrogen Chloride",
    
    -- Cook Off (Specifics)
    ["pln_rat_stage1_20"] = "Muriatic Acid",
    ["pln_rat_stage1_22"] = "Caustic Soda",
    ["pln_rat_stage1_24"] = "Hydrogen Chloride",
    ["pln_rat_stage1_26"] = "Hydrogen Chloride", 
    ["pln_rat_stage1_28"] = "Hydrogen Chloride",
    
    -- Locke (Border Crystals etc)
    ["Play_loc_mex_cook_03"] = "Muriatic Acid",
    ["Play_loc_mex_cook_04"] = "Caustic Soda",
    ["Play_loc_mex_cook_05"] = "Hydrogen Chloride"
}

local function ShowBlueText(text)
    if not managers.chat then return end
    -- Den blå färgen du gillar (R:0.4, G:0.8, B:1.0)
    managers.chat:_receive_message(ChatManager.GAME, "[RADIO] BAIN", text, Color(0.4, 0.8, 1))
end

local function BroadcastToTeam(text)
    -- Skicka till laget som vanlig text (om du är host)
    if Network:is_server() and managers.network:session() then
        managers.network:session():send_to_peers_ip_verified("send_chat_message", ChatManager.GAME, "[LunaHUD]: " .. text)
    end
end

Hooks:PostHook(DialogManager, "queue_dialog", "Luna_Cook_Visuals", function(self, id, ...)
    -- 1. LIVE TOGGLE CHECK
    -- Kollar inställningen varje gång Bain pratar.
    -- Om cooker_mode är 1 (eller nil/false), avbryt direkt.
    if not _G.LunaHUD.settings.cooker_mode or _G.LunaHUD.settings.cooker_mode == 1 then
        return
    end

    -- 2. Kolla om IDt är en "Säker Ingrediens"
    local ingredient = CleanCooker.DEFINITIONS[id]
    
    if ingredient then
        -- 3. Anti-Spam Check
        if (Application:time() - CleanCooker.last_t) < CleanCooker.COOLDOWN then
            return
        end
        CleanCooker.last_t = Application:time()

        -- 4. Visa den blå texten (LOKALT)
        ShowBlueText(ingredient .. "!")

        -- 5. Skicka till laget (PUBLIKT)
        BroadcastToTeam(ingredient .. "!")
    end
end)

