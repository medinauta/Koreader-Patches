--[[ User patch for Cover Browser plugin: Rounded corners with persistent left/right toggle ]]
--

local IconWidget = require("ui/widget/iconwidget")
local logger = require("logger")
local userpatch = require("userpatch")

local function patchCoverBrowserRoundedCorners(plugin)
    -- Prevent patch running twice
    if plugin._rounded_corner_patch_loaded then return end
    plugin._rounded_corner_patch_loaded = true

    local MosaicMenu = require("mosaicmenu")
    local MosaicMenuItem = userpatch.getUpValue(MosaicMenu._updateItemsBuildUI, "MosaicMenuItem")
    if not MosaicMenuItem then return end

    local BookInfoManager = userpatch.getUpValue(MosaicMenuItem.update, "BookInfoManager")
    if not BookInfoManager then return end

    -----------------------------------------------------------------------
    -- BooleanSetting EXACTLY like Page Count patch
    -----------------------------------------------------------------------
    local function BooleanSetting(text, name, default)
        local s = { text = text }
        s.get = function()
            local setting = BookInfoManager:getSetting(name)
            if default then return not setting end
            return setting
        end
        s.toggle = function()
            return BookInfoManager:toggleSetting(name)
        end
        return s
    end

    -----------------------------------------------------------------------
    -- Register settings
    -----------------------------------------------------------------------
    BookInfoManager._userpatch_settings = BookInfoManager._userpatch_settings or {}
    local settings = BookInfoManager._userpatch_settings

    settings.round_left  = BooleanSetting("Round left corners",  "folder_round_left",  true)
    settings.round_right = BooleanSetting("Round right corners", "folder_round_right", true)

    -----------------------------------------------------------------------
    -- Add menu toggles ONCE (global guard)
    -----------------------------------------------------------------------
    local orig_addToMainMenu = plugin.addToMainMenu
    function plugin:addToMainMenu(menu_items)
        orig_addToMainMenu(self, menu_items)
        if self._rounded_corner_menu_added then return end
        self._rounded_corner_menu_added = true

        if not menu_items.filebrowser_settings then return end

        local function getMenuItem(menu, text)
            for _, item in ipairs(menu.sub_item_table or {}) do
                if item.text == text then return item end
            end
        end

        local mosaic = getMenuItem(menu_items.filebrowser_settings, "Mosaic and detailed list settings")
        if not mosaic then return end

        -- Separator before our items
        if #mosaic.sub_item_table > 0 then
            mosaic.sub_item_table[#mosaic.sub_item_table].separator = true
        end

        local function addSetting(setting)
            table.insert(mosaic.sub_item_table, {
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

        addSetting(settings.round_left)
        addSetting(settings.round_right)
    end

    -----------------------------------------------------------------------
    -- Load corner SVG widgets
    -----------------------------------------------------------------------
    local function svg_widget(icon)
        return IconWidget:new({ icon = icon, alpha = true })
    end

    local icons = {
        tl = "rounded.corner.tl",
        tr = "rounded.corner.tr",
        bl = "rounded.corner.bl",
        br = "rounded.corner.br",
    }

    local corners = {}
    for k, name in pairs(icons) do
        corners[k] = svg_widget(name)
        if not corners[k] then
            logger.warn("Failed to load SVG icon: " .. tostring(name))
        end
    end

    local function _sz(w)
        if not w then return 0,0 end
        if w.getSize then local s = w:getSize(); return s.w, s.h end
        if w.getWidth then return w:getWidth(), w:getHeight() end
        return 0,0
    end

    -----------------------------------------------------------------------
    -- Paint rounded corners
    -----------------------------------------------------------------------
    local orig_paintTo = MosaicMenuItem.paintTo
    function MosaicMenuItem:paintTo(bb, x, y)
        orig_paintTo(self, bb, x, y)

        if self.is_directory then return end
        local target = self[1] and self[1][1] and self[1][1][1]
        if not target or not target.dimen then return end

        local fx = x + math.floor((self.width  - target.dimen.w) / 2)
        local fy = y + math.floor((self.height - target.dimen.h) / 2)
        local fw, fh = target.dimen.w, target.dimen.h

        local left_enabled  = settings.round_left.get()
        local right_enabled = settings.round_right.get()

        local TL, TR, BL, BR = corners.tl, corners.tr, corners.bl, corners.br
        local tlw, tlh = _sz(TL)
        local trw, trh = _sz(TR)
        local blw, blh = _sz(BL)
        local brw, brh = _sz(BR)

        if left_enabled then
            if TL then TL:paintTo(bb, fx, fy) end
            if BL then BL:paintTo(bb, fx, fy + fh - blh) end
        end

        if right_enabled then
            if TR then TR:paintTo(bb, fx + fw - trw, fy) end
            if BR then BR:paintTo(bb, fx + fw - brw, fy + fh - brh) end
        end
    end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowserRoundedCorners)