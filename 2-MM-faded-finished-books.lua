--[[ User patch for Project: Title plugin to add faded look for finished books in mosaic view with toggle ]]
--

local fading_amount = 0.5 --Set your desired value from 0 to 1.

local logger = require("logger")
local userpatch = require("userpatch")

local function patchCoverBrowserFaded(plugin)
    local MosaicMenu = require("mosaicmenu")
    local MosaicMenuItem = userpatch.getUpValue(MosaicMenu._updateItemsBuildUI, "MosaicMenuItem")
    if not MosaicMenuItem then return end
    if MosaicMenuItem.patched_faded_finished then return end
    MosaicMenuItem.patched_faded_finished = true

    --================= [[Menu toggle]] =================
    local BookInfoManager = userpatch.getUpValue(MosaicMenuItem.update, "BookInfoManager")
    if BookInfoManager then
        BookInfoManager._userpatch_settings = BookInfoManager._userpatch_settings or {}
        local settings = BookInfoManager._userpatch_settings

        local function BooleanSetting(text, name, default)
            local s = { text = text }
            s.get = function()
                local setting = BookInfoManager:getSetting(name)
                if default then return not setting end
                return setting
            end
            s.toggle = function() return BookInfoManager:toggleSetting(name) end
            return s
        end

        settings.show_fade_complete = BooleanSetting("Fade finished books", "folder_fade_complete", true)

        local orig_addToMainMenu = plugin.addToMainMenu
        function plugin:addToMainMenu(menu_items)
            orig_addToMainMenu(self, menu_items)
            if not menu_items.filebrowser_settings then return end

            local function getMenuItem(menu, text)
                for _, item in ipairs(menu.sub_item_table or {}) do
                    if item.text == text then return item end
                end
            end

            local item = getMenuItem(menu_items.filebrowser_settings, "Mosaic and detailed list settings")
            if not item then return end

            -- Add toggle only if not already present
            for _, setting in pairs(settings) do
                if not getMenuItem(item, setting.text) then
                    table.insert(item.sub_item_table, {
                        text = setting.text,
                        checked_func = function() return setting.get() end,
                        callback = function()
                            setting.toggle()
                            if self.ui and self.ui.file_chooser then
                                self.ui.file_chooser:updateItems()
                            end
                        end,
                    })
                end
            end
        end
    end

    --================= [[Fade render]] =================
    local orig_MosaicMenuItem_paint = MosaicMenuItem.paintTo
    function MosaicMenuItem:paintTo(bb, x, y)
        if orig_MosaicMenuItem_paint then
            orig_MosaicMenuItem_paint(self, bb, x, y)
        end

        local settings = BookInfoManager and BookInfoManager._userpatch_settings
        if settings and not settings.show_fade_complete.get() then return end

        if self.status == "complete" then
            local target = self[1] and self[1][1] and self[1][1][1]
            if target and target.dimen then
                local tw = target.dimen.w
                local th = target.dimen.h
                local fx = x + math.floor((self.width - tw) / 2)
                local fy = y + math.floor((self.height - th) / 2)

                bb:lightenRect(fx, fy, tw, th, fading_amount)
            end
        end
    end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowserFaded)