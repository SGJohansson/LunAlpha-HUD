log("[LunaHUD] [SYSTEM] Anti-Join Lag Module")
if not _G.LunaHUD then _G.LunaHUD = {} end

local debug = false

if RequiredScript:match("networkpeer$") then

    local _send = NetworkPeer.send
    NetworkPeer._cached = NetworkPeer._cached or {}

    function NetworkPeer:send(func_name, ...)
        -- Denna del är passiv i nuvarande version men förberedd för framtida sändningsfilter
        return _send(self, func_name, ...)
    end

elseif RequiredScript:match("connectionnetworkhandler$") then
    local _sync_outfit = ConnectionNetworkHandler.sync_outfit

    function ConnectionNetworkHandler:sync_outfit(outfit_string, outfit_version, outfit_signature, sender)
        local peer = self._verify_sender(sender)
        if not peer then return end

        -- Om vi är i ett rån och peern inte är fullt synkad än
        if (Utils:IsInHeist() and not peer:synched()) then
            -- Blockera outfit-uppdatering om peern redan har en enhet, inte är i lobbyn, 
            -- eller om outfit-strängen är identisk med den vi redan har.
            if peer:unit() or (not peer:in_lobby()) or (peer:profile("outfit_string") == outfit_string) then
                if debug then
                    managers.mission._fading_debug_output:script().log("blocked from " .. peer:name(), Color.red)
                end
                return
            end
        end

        if debug then
            managers.mission._fading_debug_output:script().log("received from " .. peer:name(), Color.green)
        end

        return _sync_outfit(self, outfit_string, outfit_version, outfit_signature, sender)
    end

elseif RequiredScript:match("basenetworksession$") then
    local _remove_peer = BaseNetworkSession.remove_peer

    -- Rensa cachen när en spelare lämnar så att minnet inte läcker
    function BaseNetworkSession:remove_peer(peer, peer_id, reason)
        local uid = peer:user_id()
        if NetworkPeer._cached and NetworkPeer._cached[uid] then
            NetworkPeer._cached[uid] = nil
            if debug then
                managers.mission._fading_debug_output:script().log("cleared for "..peer:name(), Color.yellow)
            end
        end
        return _remove_peer(self, peer, peer_id, reason)
    end

    local __soft_remove_peer = BaseNetworkSession._soft_remove_peer

    function BaseNetworkSession:_soft_remove_peer(peer)
        local uid = peer:user_id()
        if NetworkPeer._cached and NetworkPeer._cached[uid] then
            NetworkPeer._cached[uid] = nil
            if debug then
                managers.mission._fading_debug_output:script().log("(soft) cleared for "..peer:name(), Color.yellow)
            end
        end
        return __soft_remove_peer(self, peer)
    end
end
