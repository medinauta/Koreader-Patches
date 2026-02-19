--[[
    Book Spine Effect (Apple Books style)
    Original patch: https://github.com/advokatb/KOReader-Patches/blob/main/2-pt-book-spine-effect.lua
    Optimized: pre-scaled cached spine + shadow
    Keeps alpha blending but avoids repeated scaling
]]--

local userpatch = require("userpatch")
local logger = require("logger")
local DataStorage = require("datastorage")
local util = require("util")
local ImageWidget = require("ui/widget/imagewidget")
local Screen = require("device").screen

local spine_width     = 100
local spine_intensity = 0.7
local spine_offset    = 1

local spine_widget  = nil
local cached_height = nil
local cached_width  = nil
local cached_offset = nil

local function patchBookSpineEffect(plugin)
    local MosaicMenu = require("mosaicmenu")
    local MosaicMenuItem = userpatch.getUpValue(MosaicMenu._updateItemsBuildUI, "MosaicMenuItem")
    if not MosaicMenuItem then return end
    if MosaicMenuItem._spine_effect_patch_applied then return end
    MosaicMenuItem._spine_effect_patch_applied = true

    local data_dir = DataStorage:getDataDir()
    local spine_icon_path  = data_dir .. "/icons/book.spine.png"
    local spine_icon_exists  = util.fileExists(spine_icon_path)

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

        settings.show_spine_effect = BooleanSetting("Show spine effect", "folder_show_spine", true)

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

    --================= [[Spine render]] =================
    local orig_paintTo = MosaicMenuItem.paintTo
    function MosaicMenuItem:paintTo(bb, x, y)
        orig_paintTo(self, bb, x, y)

        if not spine_icon_exists then return end
        if self.is_directory or not self._has_cover_image then return end

        local settings = BookInfoManager and BookInfoManager._userpatch_settings
        if settings and not settings.show_spine_effect.get() then return end

        local target = self[1] and self[1][1] and self[1][1][1]
        if not target or not target.dimen then return end

        local fh = target.dimen.h
        local cover_w = target.dimen.w
        local fx = x + math.floor((self.width - cover_w) / 2)
        local fy = y + math.floor((self.height - fh) / 2)

        local offset = Screen:scaleBySize(spine_offset or 0)
        if offset < 0 then offset = 0 end
        if offset > cover_w then offset = cover_w end

        if cached_height ~= fh or cached_width ~= cover_w or cached_offset ~= offset then
            local draw_width = math.floor(cover_w * (spine_width / 100))
            draw_width = math.max(1, draw_width)
            local clipped_width = draw_width - offset
            if clipped_width < 1 then clipped_width = 1 end

            spine_widget = ImageWidget:new{
                file   = spine_icon_path,
                alpha  = true,
                width  = clipped_width,
                height = fh,
            }

            cached_height = fh
            cached_width  = cover_w
            cached_offset = offset
        end

        if spine_widget then
            spine_widget.opacity = spine_intensity
            local draw_x = fx + offset
            spine_widget:paintTo(bb, draw_x, fy)
        end
    end

    logger.info("Book Spine Effect: single spine image loaded (offset-safe)")
end

userpatch.registerPatchPluginFunc("coverbrowser", patchBookSpineEffect)

