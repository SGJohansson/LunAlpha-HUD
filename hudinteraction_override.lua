log("[LunaHUD] [UI] Interaction & Safety Interface")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- [[ LunAlpha HUD: Interaction V27.1 - Smart Safety Protocol ]]

-- Färgkoder för Cook Off
local SAFETY_COLORS = {
    acid = { color = Color(0, 0.5, 1), text = "MURIATIC ACID", id = "acid" },            -- BLÅ
    caustic = { color = Color(0, 1, 0.2), text = "CAUSTIC SODA", id = "caustic_soda" },  -- GRÖN
    hydrogen = { color = Color(1, 0.2, 0.2), text = "HYDROGEN CHLORIDE", id = "hydrogen_chloride" } -- RÖD
}

local function force_luna_void(self)
    if not self._hud_panel then return end
    pcall(function()
        -- Dölj cirklar och standard-grafik
        local circles = { self._interact_circle, self._circle, self._hud_panel:child("interact_panel") }
        for _, obj in ipairs(circles) do
            if obj then
                obj:set_visible(false)
                obj:set_alpha(0)
                if obj.set_size then obj:set_size(0, 0) end
            end
        end

        -- Flytta standardtexten så den inte är i vägen
        local interact_text = self._hud_panel:child(self._child_name_text)
        local invalid_text = self._hud_panel:child(self._child_ivalid_name_text)
        
        if interact_text then 
            interact_text:set_font_size(16) 
            interact_text:set_center_y(self._hud_panel:h() / 2 + 195) 
        end
        if invalid_text then 
            invalid_text:set_font_size(16) 
            invalid_text:set_center_y(self._hud_panel:h() / 2 + 195) 
        end
    end)
end

local function animate_luna_finish(o)
    local start_font_size = 22
    local end_font_size = 45
    local duration = 0.2
    local t = 0
    while t < duration do
        t = t + coroutine.yield()
        local n = t / duration
        o:set_font_size(math.lerp(start_font_size, end_font_size, n))
        o:set_alpha(1 - n)
    end
    o:set_visible(false)
    o:set_font_size(start_font_size)
    o:set_alpha(0)
end

function HUDInteraction:_animate_interaction_complete(circle, ...)
    if circle then circle:set_size(0, 0) circle:set_alpha(0) end
end

Hooks:PostHook(HUDInteraction, "init", "LunaHUD_V27_Init", function(self, hud)
    self._hud_panel = hud.panel
    local sw, sh = self._hud_panel:w(), self._hud_panel:h()
    self._luna_panel = self._luna_panel or self._hud_panel:panel({ name = "luna_panel", layer = 2 })
    
    -- Procent-räknaren
    self._luna_progress = self._luna_progress or self._luna_panel:text({
        name = "luna_progress", visible = false, font = "fonts/font_medium_mf", 
        font_size = 22, color = Color.white, align = "center", vertical = "center"
    })
    self._luna_progress:set_center(sw / 2, sh / 2 + 115)

    -- SAFETY LABEL (Cook Off)
    self._luna_safety_label = self._luna_panel:text({
        name = "luna_safety_label",
        visible = false,
        text = "",
        font = tweak_data.menu.pd2_massive_font, -- Fet font för tydlighet
        font_size = 24, -- [LUNA UPDATE] Minskad fontstorlek (var 32)
        align = "center",
        vertical = "center",
        layer = 1
    })
    -- Placera den högre upp för att undvika krock med pick-ups
    self._luna_safety_label:set_center_x(sw / 2)
    self._luna_safety_label:set_center_y(sh / 2 + 120) -- [LUNA UPDATE] Flyttad upp (var 160)

    -- Lägg till detta precis innan force_luna_void(self)
    if self._hud_panel:child("interact_panel") then
        self._hud_panel:child("interact_panel"):set_layer(2) -- Tvingar ner vanilla-interaktionen 
    end

    if self._interact_circle then
        self._interact_circle:set_layer(2) -- Tvingar ner den faktiska mätar-cirkeln     
    end

    force_luna_void(self)
end)

Hooks:PreHook(HUDInteraction, "show_interact", "LunaHUD_V27_PreShow", function(self, data)
    -- Återställ UI
    if self._luna_progress then 
        self._luna_progress:stop() 
        self._luna_progress:set_visible(false)
        self._luna_progress:set_alpha(0)
        self._luna_progress:set_font_size(22)
    end
    self._luna_finishing = false 
    force_luna_void(self)

    -- COOK OFF SÄKERHETSKONTROLL
    if self._luna_safety_label and data and data.text then
      local text_id = tostring(data.text):lower()
      -- Filtrera så vi bara kollar på labb-inputs (add/place/insert)
      local is_lab_input = text_id:find("add") or text_id:find("place") or text_id:find("insert")
      
      local match_data = nil

      if is_lab_input then
        if text_id:find("acid") or text_id:find("muriatic") then
            match_data = SAFETY_COLORS.acid
        elseif text_id:find("caustic") or text_id:find("soda") then
            match_data = SAFETY_COLORS.caustic
        elseif text_id:find("hydrogen") or text_id:find("chloride") then
            match_data = SAFETY_COLORS.hydrogen
        end
      end

      -- [LUNA UPDATE] Logik: Visa BARA om vi har rätt ingrediens i inventoryt
      local can_interact = false
      if match_data then
          -- Kolla inventoryt efter den specifika ingrediensen
          if managers.player:has_special_equipment(match_data.id) then
              can_interact = true
              self._luna_safety_label:set_text(match_data.text)
              self._luna_safety_label:set_color(match_data.color)
          end
      end

      -- Visa bara om vi hittade en match OCH har ingrediensen
      self._luna_safety_label:set_visible(can_interact)
      self._luna_safety_label:set_alpha(can_interact and 1 or 0)
   end
end)

Hooks:PostHook(HUDInteraction, "set_interaction_bar_width", "LunaHUD_V27_Progress", function(self, current, total)
    force_luna_void(self)
    if self._luna_progress and total > 0 then
        local pct = math.clamp(current / total, 0, 1)
        self._luna_progress:set_text(string.format("%d%%", math.floor(pct * 100)))
        
        if pct >= 1 and not self._luna_finishing then
            self._luna_finishing = true
            self._luna_progress:animate(animate_luna_finish)
            -- Göm säkerhetstexten direkt när klart
            if self._luna_safety_label then self._luna_safety_label:set_visible(false) end
        elseif pct < 1 then
            self._luna_finishing = false
            self._luna_progress:set_visible(true)
            self._luna_progress:set_alpha(1)
        end
        
        pcall(function()
            local valid = self._interact_circle and self._interact_circle:color() ~= Color.red
            self._luna_progress:set_color(valid and Color.white or Color.red)
        end)
    end
end)

-- Watchdog
Hooks:PostHook(HUDInteraction, "update", "LunaHUD_V27_Watchdog", function(self)
    force_luna_void(self)
    if not managers.interaction:active_unit() then
        if self._luna_progress then
            self._luna_progress:set_visible(false)
            self._luna_progress:set_alpha(0)
            self._luna_finishing = false
        end
        if self._luna_safety_label then
            self._luna_safety_label:set_visible(false)
        end
    end
end)

local original_hide = HUDInteraction.hide_interaction_bar
function HUDInteraction:hide_interaction_bar(complete, ...)
    force_luna_void(self)
    
    if self._luna_progress then 
        if not complete then
            self._luna_progress:stop()
            self._luna_progress:set_visible(false)
            self._luna_progress:set_alpha(0)
            self._luna_finishing = false
        end
    end
    
    -- Göm alltid säkerhetstexten när interaktionen bryts/avslutas
    if self._luna_safety_label then
        self._luna_safety_label:set_visible(false)
    end

    return original_hide(self, false, ...)
end
