log("[LunaHUD] [UI] Tactical Jumbotron Overlay")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Jumbotron V27.1 - Error Handler Edition ]]
-- Fix: Implementerat "Sanitizer" som fångar 'ERROR'-strängar från saknade DLC-texter.
-- Fix: Fallback-system som gör om interna ID:n (t.ex. ranc_weapon) till läsbar text.
_G.LunaHUD = _G.LunaHUD or {}
LunaHUD.Jumbotron = LunaHUD.Jumbotron or { active_text = "", timer = 0 }

-- Utökad manuell lista för kända problem-objekt
local MAP = {
    ["money_wrap_single_bundle"] = "CASH", 
    ["gold_pile"] = "GOLD", 
    ["person"] = "BODY",
    ["painting_carry_drop"] = "PAINTING", 
    ["coke_pure"] = "COKE", 
    ["weapon_case"] = "WEAPON",
    ["goat_carry_drop"] = "GOAT", 
    ["safe_carry_drop"] = "SAFE",
    ["corpse_dispose"] = "BODY BAG", 
    ["gen_pku_crowbar"] = "CROWBAR", 
    ["pickup_keycard"] = "KEYCARD",
    -- Specifika fixar för buggiga/saknade DLC-strängar
    ["ranc_weapon"] = "WEAPON CASE", -- Fix för Rancho-vapnet på din bild
    ["gligen"] = "GLIGEN",
    ["drk_bomb_part"] = "BOMB PART"
}

-- Hjälpfunktion: Tvättar smutsiga ID:n om localization fallerar
local function GetSafeCarryLabel(carry_id)
    if not carry_id then return "" end

    -- 1. Kolla manuell lista först (Snabbast och snyggast)
    if MAP[carry_id] then 
        return MAP[carry_id] 
    end

    -- 2. Försök hämta officiell text
    local key = "hud_carry_" .. carry_id
    local text = managers.localization:text(key)
    
    -- 3. Analysera om vi fick skräp tillbaka
    -- Diesel returnerar ofta "ERROR: HUD_CARRY_..." om nyckeln saknas
    local is_error = text:find("ERROR") or text:find("HUD_CARRY")

    if is_error then
        -- Fallback: Gör om "ranc_weapon" till "RANC WEAPON"
        local clean = carry_id:gsub("_", " "):upper()
        return clean
    end

    return text:upper()
end

-- ---------------------------------------------------------
-- DEL 1: RENDERING & CARRYING LOGIK (Kopplat till HUDManager)
-- ---------------------------------------------------------
if RequiredScript == "lib/managers/hudmanager" then
    Hooks:PostHook(HUDManager, "update", "Luna_Jumbo_RenderLoop", function(self, t, dt)
        local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
        if not hud or not hud.panel then return end

        -- 1. Skapa objektet om det saknas (Lazy Load)
        if not alive(LunaHUD.Jumbotron.obj) then
            LunaHUD.Jumbotron.obj = hud.panel:text({
                name = "luna_jumbo_text",
                font = tweak_data.menu.pd2_massive_font,
                font_size = 24, -- Diskret och snygg storlek
                color = Color(1, 0.84, 0), -- Luna Guld
                align = "center", 
                vertical = "top",
                layer = 2000 -- Ligger alltid överst
            })
            -- Placering: Centrerad, 12% från toppen (under objectives)
            LunaHUD.Jumbotron.obj:set_center_x(hud.panel:w()/2)
            LunaHUD.Jumbotron.obj:set_y(hud.panel:h() * 0.12) 
        end
        local txt = LunaHUD.Jumbotron.obj

        -- 2. HÄMTA DATA SÄKERT
        local carry_data = managers.player:get_my_carry_data()
        
        -- Kontrollera att carry_data är en tabell
        local is_carrying_valid = (carry_data and type(carry_data) == "table" and carry_data.carry_id)
        
        if is_carrying_valid then
            -- STATE: CARRYING (Permanent text)
            -- Använd vår nya säkra funktion här
            local label = GetSafeCarryLabel(carry_data.carry_id)
            
            txt:set_text("CARRYING: " .. label)
            txt:set_visible(true)
            txt:set_alpha(1)
            txt:stop() -- Stoppa ev. fade-out animationer
        
        elseif LunaHUD.Jumbotron.timer > 0 then
            -- STATE: ACQUIRED (Popup text)
            LunaHUD.Jumbotron.timer = LunaHUD.Jumbotron.timer - dt
            txt:set_text("ACQUIRED: " .. LunaHUD.Jumbotron.active_text)
            txt:set_visible(true)
            
            -- Snygg fade-out sista halva sekunden
            if LunaHUD.Jumbotron.timer < 0.5 then
                txt:set_alpha(LunaHUD.Jumbotron.timer * 2)
            else
                txt:set_alpha(1)
            end
        else
            -- STATE: IDLE (Dölj)
            txt:set_visible(false)
        end

        -- 3. DÖLJ VANILLA-RUTAN (Städar bort originalet)
        if self._hud_temp then
            if alive(self._hud_temp._bg_box) then self._hud_temp._bg_box:set_visible(false) end
            if alive(self._hud_temp._temp_panel) then self._hud_temp._temp_panel:set_visible(false) end
        end
    end)

-- ---------------------------------------------------------
-- DEL 2: INTERAKTIONS-LYSSNARE (Kopplat till InteractionExt)
-- ---------------------------------------------------------
elseif RequiredScript == "lib/units/interactions/interactionext" then
    Hooks:PostHook(BaseInteractionExt, "interact", "Luna_Jumbo_Trigger", function(self, player)
        local id = self.tweak_data
        local text = MAP[id] -- Kolla om interaktionen finns i vår lista (t.ex. keycard pickup)
        
        -- Fallback om objektet inte finns i vår MAP, försök läsa carry_data från enheten
        if not text and self._unit and self._unit:carry_data() then
             local c_id = self._unit:carry_data():carry_id()
             if c_id then
                 text = GetSafeCarryLabel(c_id)
             end
        end

        -- Trigga "ACQUIRED" popup i 3 sekunder om vi hittade en text
        if text then
            LunaHUD.Jumbotron.active_text = text
            LunaHUD.Jumbotron.timer = 3.0 
        end
    end)
end
