local ImageWidget = require("ui/widget/imagewidget")
local PluginLoader = require("pluginloader")
local Size = require("ui/size")

-- Max allowable stretch percentage
local STRETCH_LIMIT_PERCENTAGE = 20

-- Hook plugin loading
local patch_plugin_func
local orig_PluginLoader_createPluginInstance = PluginLoader.createPluginInstance

PluginLoader.createPluginInstance = function(self, plugin, attr)
    local ok, plugin_or_err = orig_PluginLoader_createPluginInstance(self, plugin, attr)
    if ok and plugin.name == "coverbrowser" then
        patch_plugin_func(plugin)
    end
    return ok, plugin_or_err
end

-- Patch function
patch_plugin_func = function(plugin)
    local MosaicMenu = require("mosaicmenu")

    -- Find MosaicMenuItem upvalue
    local MosaicMenuItem
    local n = 1
    while true do
        local name, value = debug.getupvalue(MosaicMenu._updateItemsBuildUI, n)
        if not name then break end
        if name == "MosaicMenuItem" then
            MosaicMenuItem = value
            break
        end
        n = n + 1
    end
    if not MosaicMenuItem then return end

    -- Find ImageWidget upvalue inside MosaicMenuItem.update
    local ImageWidgetUp
    n = 1
    while true do
        local name, value = debug.getupvalue(MosaicMenuItem.update, n)
        if not name then break end
        if name == "ImageWidget" then
            ImageWidgetUp = value
            break
        end
        n = n + 1
    end
    if not ImageWidgetUp then return end
    local setupvalue_n = n

    -- Compute max cover size per tile
    local border_size = Size.border.thin
    local underline_h = 1
    local orig_init = MosaicMenuItem.init

    MosaicMenuItem.init = function(self)
        if self.width and self.height then
            self._max_img_w = self.width - 2*border_size
            self._max_img_h = self.height - 2*border_size - underline_h
        end
        orig_init(self)
    end

    -- Stretching ImageWidget subclass
    local StretchingImageWidget = ImageWidget:extend{}

    StretchingImageWidget.init = function(self)
        local parent = self.parent
        if not parent then return end
        if parent.is_directory then
            -- Skip folders
            return
        end
        local max_w = parent._max_img_w
        local max_h = parent._max_img_h
        if not max_w or not max_h then return end

        self.scale_factor = nil
        self.width = max_w
        self.height = max_h
        self.stretch_limit_percentage = STRETCH_LIMIT_PERCENTAGE
    end

    -- Replace MosaicMenu ImageWidget with our subclass
    debug.setupvalue(MosaicMenuItem.update, setupvalue_n, StretchingImageWidget)
end
