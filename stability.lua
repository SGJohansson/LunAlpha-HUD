log("[LunaHUD] [SYSTEM] Engine Stability & Garbage Collection")
if not _G.LunaHUD then _G.LunaHUD = {} end

-- LunAlpha HUD: Camera Stability & Dynamic FOV
if not _G.LunAlphaStability then
    _G.LunAlphaStability = { modifier = 1, lerp_speed = 8 }
end

if _G.PlayerCamera then
    -- 1. DÖDA ALLA EXTERNA SKAK (Explosioner, tunga träffar)
    PlayerCamera.play_shaker = function() return nil end

    -- 2. DÖDA ANDNING & GUNG (Breathing/Bobbing)
    Hooks:PostHook(PlayerCamera, "update", "LunaHUD_CameraFix", function(self, unit, t, dt)
        if self._shakers then
            self._shakers.bobbing = 0
            self._shakers.breathing = 0
        end

        -- 3. DYNAMISK FOV (Ökar siktfältet vid interaktion/downed/climb för bättre överblick)
        local target = 1
        local pm = managers.player
        if pm and pm:player_unit() then
            local state = pm:current_state()
            if (pm.is_interaction_in_progress and pm:is_interaction_in_progress()) or 
               state == "bleed_out" or 
               state == "climb" then
                target = 1.30
            end
        end

        LunAlphaStability.modifier = math.lerp(LunAlphaStability.modifier, target, dt * LunAlphaStability.lerp_speed)

        if self._camera_object then
            self._camera_object:set_fov(self._camera_object:fov() * LunAlphaStability.modifier)
        end
    end)
end


