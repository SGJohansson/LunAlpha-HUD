log("[LunaHUD] [UI] Configuration Menu Loaded (V12 - Tactical Toggles)")
if not _G.LunaHUD then _G.LunaHUD = {} end

_G.LunaMenu = _G.LunaMenu or {}
LunaHUD_ModPath = ModPath

-- 1. DEFINIERA TEXTER
Hooks:Add("LocalizationManagerPostInit", "LunaMenu_Loc", function(loc)
    local SPACER = "\n\n\n\n\n\n\n\n\n\n\n\n" 

    loc:add_localized_strings({
        ["luna_main_title"] = "LunAlpha HUD",
        ["luna_main_desc"] = "Configuration, Security Info and Credits.",
        
        -- Nya Toggles!
        ["luna_toggle_buffs_title"] = "Tactical Buff Timers",
        ["luna_toggle_buffs_desc"] = "Toggles the central list showing active buffs, skills, and max stacks.",
        
        ["luna_toggle_dmgpop_title"] = "Damage Popups",
        ["luna_toggle_dmgpop_desc"] = "Toggles floating damage numbers above enemies.",
        
        ["luna_toggle_auto_inv_title"] = "Auto-Investigate (Security)",
        ["luna_toggle_auto_inv_desc"] = "Automatically scans joining players for hidden skills and cheats.",

        -- Gamla
        ["luna_toggle_stats_title"] = "Combat Stats Feed",
        ["luna_toggle_stats_desc"] = "Toggles the Quake-style combat statistics (Kills, Specials, Accuracy).",

        ["luna_toggle_cross_title"] = "Dynamic Crosshair",
        ["luna_toggle_cross_desc"] = "Toggles the minimalist CS-style crosshair. Replaces vanilla hit markers.",

        ["luna_cooker_title"] = "COOK OFF HELPER",
        ["luna_cooker_desc"] = "Classic Bain Assistant. Announces correct ingredients in chat (Blue Text).",

        ["luna_quiet_title"] = "Quiet Mode",
        ["luna_quiet_desc"] = "Stealth mode. The mod will NOT respond to !version or !about commands.",

        ["luna_wipe_title"] = "Wipe Blacklist",
        ["luna_wipe_desc"] = "Permanently deletes all entries in the blacklist database. Requires confirmation.",
        ["luna_wipe_confirm_title"] = "CONFIRM DELETION",
        ["luna_wipe_confirm_msg"] = "Are you sure you want to wipe the blacklist?\nThis action cannot be undone.",
        ["luna_wipe_btn_yes"] = "YES, WIPE IT",
        ["luna_wipe_btn_no"] = "CANCEL",

        -- INFO BUTTONS
        ["luna_sec_title"] = "COMMAND LIST (CLI)",
        ["luna_sec_desc"] = SPACER ..
                            "--- COMMAND REFERENCE ---\n" ..
                            "!stats        : Toggle Stats Feed\n" ..
                            "!ssl          : Deep Scan & Integrity Check\n" ..
                            "!kickcheck    : Auto-Kick Blacklisted (Host)\n" ..
                            "!ban <id>     : Ban User & Save URL (Host)\n" ..
                            "!unban <id>   : Remove User from DB\n" ..
                            "!log          : Save Lobby Snapshot\n" ..
                            "!debug <id>   : Technical Scan (Build/Mods)\n" ..
                            "!ghost        : Find hidden HUD elements\n" ..
                            "!list         : List active Peer IDs",

        ["luna_cred_title"] = "CREDITS",
        ["luna_cred_desc"] = SPACER ..
                             "--- DEVELOPMENT ---\n" ..
                             "AUTHOR  : S.G.Johansson\n" ..
                             "ARCH    : LunAlpha Architecture\n" ..
                             "VERSION : 96.0 (Strict Auto-Coder)\n" ..
                             "LICENSE : GPLv3 (2025-2026)\n\n" ..
                             "\"Trust no one but the code.\""
    })
end)

-- 2. SETUP
Hooks:Add("MenuManagerSetupCustomMenus", "LunaMenu_Setup", function(menu_manager, nodes)
    MenuHelper:NewMenu("luna_hud_menu")
end)

Hooks:Add("MenuManagerPopulateCustomMenus", "LunaMenu_Populate", function(menu_manager, nodes)
    MenuCallbackHandler.Luna_EmptyCallback = function(self, item) end
    
    -- SAVE CALLBACKS (NYA)
    MenuCallbackHandler.Luna_SaveBuffs = function(self, item)
        _G.LunaHUD.settings.show_buffs = (item:value() == "on")
        _G.LunaHUD:SaveSettings()
    end

    MenuCallbackHandler.Luna_SaveDmgPop = function(self, item)
        _G.LunaHUD.settings.show_dmgpop = (item:value() == "on")
        _G.LunaHUD:SaveSettings()
    end

    MenuCallbackHandler.Luna_SaveAutoInv = function(self, item)
        _G.LunaHUD.settings.auto_investigate = (item:value() == "on")
        _G.LunaHUD:SaveSettings()
    end

    -- SAVE CALLBACKS (GAMLA)
    MenuCallbackHandler.Luna_SaveStats = function(self, item)
        _G.LunaHUD.settings.show_stats = (item:value() == "on")
        _G.LunaHUD:SaveSettings()
    end

    MenuCallbackHandler.Luna_SaveCross = function(self, item)
        _G.LunaHUD.settings.show_crosshair = (item:value() == "on")
        _G.LunaHUD:SaveSettings()
    end

    MenuCallbackHandler.Luna_SaveQuiet = function(self, item)
        _G.LunaHUD.settings.quiet_mode = (item:value() == "on")
        _G.LunaHUD:SaveSettings()
    end

    MenuCallbackHandler.Luna_SaveCooker = function(self, item)
        local val = (item:value() == "on") and 2 or 1
        _G.LunaHUD.settings.cooker_mode = val
        _G.LunaHUD:SaveSettings()
    end

    MenuCallbackHandler.Luna_WipeBlacklist = function(self, item)
        local function wipe_now()
            local path = SavePath .. "luna_blacklist.json"
            local file = io.open(path, "w+")
            if file then
                file:write("{}")
                file:close()
                managers.chat:feed_system_message(ChatManager.GAME, "[LunaHUD] Blacklist wiped successfully.")
            else
                managers.chat:feed_system_message(ChatManager.GAME, "[LunaHUD] Error: Could not write to file.")
            end
        end

        local opts = {
            [1] = { text = managers.localization:text("luna_wipe_btn_yes"), callback = wipe_now },
            [2] = { text = managers.localization:text("luna_wipe_btn_no"), is_cancel_button = true }
        }
        local menu = QuickMenu:new(
            managers.localization:text("luna_wipe_confirm_title"),
            managers.localization:text("luna_wipe_confirm_msg"),
            opts
        )
        menu:show()
    end

    -- --- MENY ELEMENT ---

    -- 1. Buff Timers
    MenuHelper:AddToggle({
        id = "luna_buffs", title = "luna_toggle_buffs_title", desc = "luna_toggle_buffs_desc",
        callback = "Luna_SaveBuffs",
        value = _G.LunaHUD.settings.show_buffs, 
        menu_id = "luna_hud_menu", priority = 13
    })

    -- 2. Damage Popups
    MenuHelper:AddToggle({
        id = "luna_dmgpop", title = "luna_toggle_dmgpop_title", desc = "luna_toggle_dmgpop_desc",
        callback = "Luna_SaveDmgPop",
        value = _G.LunaHUD.settings.show_dmgpop, 
        menu_id = "luna_hud_menu", priority = 12
    })

    -- 3. Crosshair
    MenuHelper:AddToggle({
        id = "luna_cross", title = "luna_toggle_cross_title", desc = "luna_toggle_cross_desc",
        callback = "Luna_SaveCross",
        value = _G.LunaHUD.settings.show_crosshair,
        menu_id = "luna_hud_menu", priority = 11
    })

    -- 4. Stats
    MenuHelper:AddToggle({
        id = "luna_stats", title = "luna_toggle_stats_title", desc = "luna_toggle_stats_desc",
        callback = "Luna_SaveStats",
        value = _G.LunaHUD.settings.show_stats,
        menu_id = "luna_hud_menu", priority = 10
    })

    -- 5. Auto-Investigate
    MenuHelper:AddToggle({
        id = "luna_auto_inv", title = "luna_toggle_auto_inv_title", desc = "luna_toggle_auto_inv_desc",
        callback = "Luna_SaveAutoInv",
        value = _G.LunaHUD.settings.auto_investigate, 
        menu_id = "luna_hud_menu", priority = 9
    })

    -- 6. CleanCooker 
    local cooker_is_on = (_G.LunaHUD.settings.cooker_mode and _G.LunaHUD.settings.cooker_mode > 1) or false
    MenuHelper:AddToggle({
        id = "luna_cooker", title = "luna_cooker_title", desc = "luna_cooker_desc",
        callback = "Luna_SaveCooker",
        value = cooker_is_on, 
        menu_id = "luna_hud_menu", priority = 8
    })

    -- 7. Quiet Mode
    MenuHelper:AddToggle({
        id = "luna_quiet", title = "luna_quiet_title", desc = "luna_quiet_desc",
        callback = "Luna_SaveQuiet",
        value = _G.LunaHUD.settings.quiet_mode or false,
        menu_id = "luna_hud_menu", priority = 7
    })

    -- 8. Wipe Blacklist
    MenuHelper:AddButton({
        id = "luna_wipe", title = "luna_wipe_title", desc = "luna_wipe_desc",
        callback = "Luna_WipeBlacklist",
        menu_id = "luna_hud_menu", priority = 6
    })

    -- 9. CLI Command List
    MenuHelper:AddButton({
        id = "luna_sec", title = "luna_sec_title", desc = "luna_sec_desc",
        callback = "Luna_EmptyCallback",
        menu_id = "luna_hud_menu", priority = 2
    })

    -- 10. Credits
    MenuHelper:AddButton({
        id = "luna_cred", title = "luna_cred_title", desc = "luna_cred_desc",
        callback = "Luna_EmptyCallback",
        menu_id = "luna_hud_menu", priority = 1
    })
end)

Hooks:Add("MenuManagerBuildCustomMenus", "LunaMenu_Build", function(menu_manager, nodes)
    nodes["luna_hud_menu"] = MenuHelper:BuildMenu("luna_hud_menu")
    MenuHelper:AddMenuItem(nodes["blt_options"], "luna_hud_menu", "luna_main_title", "luna_main_desc")
end)