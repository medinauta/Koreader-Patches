--[[
User patch for Cover Browser plugin to add page count badges for unread books
with menu toggle integrated safely
]]--

local Blitbuffer = require("ffi/blitbuffer")
local userpatch = require("userpatch")
local TextWidget = require("ui/widget/textwidget")
local FrameContainer = require("ui/widget/container/framecontainer")
local Font = require("ui/font")
local Screen = require("device").screen
local Size = require("ui/size")
local BD = require("ui/bidi")

--========================== [[Preferences]] ================================
local page_font_size = 0.5                    -- Adjust from 0 to 1. Default was 0.9
local page_text_color = Blitbuffer.COLOR_WHITE
local border_thickness = 2
local border_corner_radius = 6
local border_color = Blitbuffer.COLOR_DARK_GRAY
local background_color = Blitbuffer.COLOR_GRAY_1
local move_from_border = 5

--========================== [[Patch Function]] =============================
local function patchCoverBrowserPageCount(plugin)
    local MosaicMenu = require("mosaicmenu")
    local MosaicMenuItem = userpatch.getUpValue(MosaicMenu._updateItemsBuildUI, "MosaicMenuItem")
    if not MosaicMenuItem then return end

    local BookInfoManager = userpatch.getUpValue(MosaicMenuItem.update, "BookInfoManager")
    if not BookInfoManager then return end

    -- Utility for menu toggles (boolean settings)
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

    -- Attach setting to BookInfoManager so it can be shared with other patches
    BookInfoManager._userpatch_settings = BookInfoManager._userpatch_settings or {}
    local settings = BookInfoManager._userpatch_settings
    settings.show_page_count = BooleanSetting("Show page count", "folder_show_page_count", true)

    -- Add menu item safely at the end of Mosaic settings menu
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

        -- Separator for clarity
        item.sub_item_table[#item.sub_item_table].separator = true

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

    --================ Page Count Badge =================
    local origMosaicMenuItemPaintTo = MosaicMenuItem.paintTo
    function MosaicMenuItem:paintTo(bb, x, y)
        origMosaicMenuItemPaintTo(self, bb, x, y)

        -- Skip directories, deleted, or complete/seen books
        if self.is_directory or self.file_deleted or self.status == "complete" or self.been_opened then return end
        if not settings.show_page_count.get() then return end

        -- Target image inside the mosaic item
        local target = self[1] and self[1][1] and self[1][1][1]
        if not target or not target.dimen then return end

        local corner_mark_size = Screen:scaleBySize(10)
        local page_count = self.text and self.text:match("%- %[(%d+)%] %-")
        if not page_count then return end

        local page_text = page_count .. "p."
        local font_size = math.floor(corner_mark_size * page_font_size)

        local pages_text = TextWidget:new{
            text = page_text,
            face = Font:getFace("cfont", font_size),
            alignment = "left",
            fgcolor = page_text_color,
            bold = true,
            padding = 0.5,
        }

        local pages_badge = FrameContainer:new{
            linesize = Screen:scaleBySize(2),
            radius = Screen:scaleBySize(border_corner_radius),
            color = border_color,
            bordersize = border_thickness,
            background = background_color,
            padding = Screen:scaleBySize(2),
            margin = 0,
            pages_text,
        }

        local cover_left = x + math.floor((self.width - target.dimen.w) / 2)
        local cover_bottom = y + self.height - math.floor((self.height - target.dimen.h) / 2)
        local badge_w, badge_h = pages_badge:getSize().w, pages_badge:getSize().h

        local pad = Screen:scaleBySize(move_from_border)
        local pos_x_badge = cover_left + pad
        local pos_y_badge = cover_bottom - (pad + badge_h)

        pages_badge:paintTo(bb, pos_x_badge, pos_y_badge)
    end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowserPageCount)
