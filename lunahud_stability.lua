log("[LunaHUD] [CORE] Engine Stability & POV Fixes (V5 - Rigid ViewModel Sync)")
if not _G.LunaHUD then _G.LunaHUD = {} end

--[[
    LunAlpha HUD - Stability & Camera Overrides
    V5: Perfect Rigid Sync. Zero sway, zero roll, zero combat shakes.
]]


--------------------------------------------------------------------------------
-- 1. VIEW MODEL GLUE (TweakData)
-- Dödar amplitud för andning/bobbing men behåller systemet aktivt för synk.
-- Dödar även 'vel_overshoot' som är det som skapar släp/rullning.
--------------------------------------------------------------------------------
Hooks:PostHook(PlayerTweakData, "init", "LunaHUD_TweakData_Stability", function(self)
    if self.stances then
        for _, stance in pairs(self.stances) do
            for _, state in ipairs({"steelsight", "standard", "crouched"}) do
                if stance[state] then
                    -- Eliminera all rörelseamplitud
                    if stance[state].shakers then
                        if stance[state].shakers.breathing then
                            stance[state].shakers.breathing.amplitude = 0
                        end
                        if stance[state].shakers.bobbing then
                            stance[state].shakers.bobbing.amplitude = 0
                        end
                    end
                    -- Lås vapnet stenhårt i mitten (inget gummibands-rull vid rörelse)
                    if stance[state].vel_overshoot then
                        stance[state].vel_overshoot.yaw_limit = 0
                        stance[state].vel_overshoot.pitch_limit = 0
                        stance[state].vel_overshoot.yaw_neg_limit = 0
                        stance[state].vel_overshoot.pitch_neg_limit = 0
                    end
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- 2. KIRURGISK SHAKER-NUKING (PlayerCamera)
-- Blockerar rekyl, skada och explosioner, men släpper igenom synk-shakers.
--------------------------------------------------------------------------------
if _G.PlayerCamera and not _G.PlayerCamera._luna_orig_play_shaker then
    _G.PlayerCamera._luna_orig_play_shaker = _G.PlayerCamera.play_shaker
    
    function PlayerCamera:play_shaker(name, amplitude, frequency, offset)
        -- För att View Model (vapnet) inte ska börja rulla fritt ur synk
        -- MÅSTE motorn få ett giltigt Shaker-ID för andning och bobbing.
        -- Vi släpper igenom dessa (deras rörelse är redan satt till 0 ovan).
        if name == "breathing" or name == "headbob" then
            return self:_luna_orig_play_shaker(name, amplitude, frequency, offset)
        end
        
        -- Allt annat (recoil, weapon_fire, explosion, damage) blockeras stenhårt.
        return nil
    end
end

--------------------------------------------------------------------------------
-- 3. HÅRD BLOCKERING AV HIT-FLINCH (PlayerDamage)
--------------------------------------------------------------------------------
if PlayerDamage and PlayerDamage.init then
   Hooks:PostHook(PlayerDamage, "init", "LunaHUD_NukeDamageShake", function(self)	 
    self.shake_player = function() return nil end
    self._apply_damage_to_camera = function(data) return end
    end)
end

--------------------------------------------------------------------------------
-- 4. INTERAKTION FOV-FIX (Från LunaHUD Original)
--------------------------------------------------------------------------------
if not _G.LunaHUD_Stability then 
    _G.LunaHUD_Stability = { mod = 1, speed = 8 } 
end

Hooks:PostHook(PlayerCamera, "update", "LunaHUD_MasterCameraUpdate", function(self, unit, t, dt)
    local target = 1
    local pm = managers.player
    if pm and pm:player_unit() then
        local state = pm:current_state()
        if (pm.is_interaction_in_progress and pm:is_interaction_in_progress()) or state == "climb" then
            target = 1.30
        end
    end
    
    LunaHUD_Stability.mod = math.lerp(LunaHUD_Stability.mod, target, dt * LunaHUD_Stability.speed)
    if self._camera_object then 
        self._camera_object:set_fov(self._camera_object:fov() * LunaHUD_Stability.mod) 
    end
end)
