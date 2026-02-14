--[[ 
User patch: Screensaver Utilities
Version: 6.1 (Shared Context Fix)
]]

local logger = require("logger")
local UIManager = require("ui/uimanager")
local Device = require("device")
local Screen = Device.screen
local ffiUtil = require("ffi/util")
local Screensaver = require("ui/screensaver")
local CenterContainer = require("ui/widget/container/centercontainer")
local _ = require("gettext")

-- SHARED STATE VARIABLE
-- This tracks if we are in the file browser (random image) vs reader (book cover)
-- Updated automatically by the Screensaver hook below.
local is_screensaver_browser_context = false

-- 1. INITIALIZE SETTINGS
local settings_map = {
    ["screensaver_close_widgets"] = true,
    ["screensaver_refresh"] = true,
    ["screensaver_center_shrink"] = true,
    ["screensaver_force_no_fill_random"] = true,
}

for setting, default in pairs(settings_map) do
    if G_reader_settings:hasNot(setting) then
        G_reader_settings:saveSetting(setting, default)
    end
end

-- 2. MENU HELPERS
local function find_item_from_path(menu, ...)
    local function find_sub_item(sub_items, text)
        for _, item in ipairs(sub_items) do
            local item_text = item.text or (item.text_func and item.text_func())
            if item_text and item_text == text then return item end
        end
    end
    local sub_items, item
    for _, text in ipairs { ... } do
        sub_items = item and item.sub_item_table or menu
        if not sub_items then return end
        item = find_sub_item(sub_items, text)
        if not item then return end
    end
    return item
end

local function add_screensaver_options(sleep_menu)
    local items = sleep_menu.sub_item_table
    if not items then return end
    if #items > 0 then items[#items].separator = true end
    
    table.insert(items, {
        text = _("Close dialogs before screensaver"),
        checked_func = function() return G_reader_settings:isTrue("screensaver_close_widgets") end,
        callback = function(touchmenu)
            G_reader_settings:flipNilOrFalse("screensaver_close_widgets")
            touchmenu:updateItems()
        end,
    })

    table.insert(items, {
        text = _("Refresh screen before screensaver"),
        enabled_func = function()
            local ss_type = G_reader_settings:readSetting("screensaver_type")
            return Device:hasEinkScreen() and (ss_type == "cover" or ss_type == "random_image")
        end,
        checked_func = function() return G_reader_settings:isTrue("screensaver_refresh") end,
        callback = function(touchmenu)
            G_reader_settings:toggle("screensaver_refresh")
            touchmenu:updateItems()
        end,
    })

    table.insert(items, {
        text = _("Center and shrink book cover"),
        checked_func = function() return G_reader_settings:isTrue("screensaver_center_shrink") end,
        callback = function(touchmenu)
            G_reader_settings:flipNilOrFalse("screensaver_center_shrink")
            touchmenu:updateItems()
        end,
    })

    table.insert(items, {
        text = _("Force no fill in file browser"),
        help_text = _("Transparent screensaver when in file browser."),
        checked_func = function() return G_reader_settings:isTrue("screensaver_force_no_fill_random") end,
        callback = function(touchmenu)
            G_reader_settings:toggle("screensaver_force_no_fill_random")
            touchmenu:updateItems()
        end,
    })
end

local function inject_menu(order, menu)
    local buttons = order["KOMenu:menu_buttons"]
    for i, button in ipairs(buttons) do
        if button == "setting" then
            local setting_menu = menu.tab_item_table[i]
            if setting_menu then
                local sleep_menu = find_item_from_path(setting_menu, _("Screen"), _("Sleep screen"))
                if sleep_menu then add_screensaver_options(sleep_menu) end
            end
        end
    end
end

local FileManagerMenu = require("apps/filemanager/filemanagermenu")
local FileManagerMenuOrder = require("ui/elements/filemanager_menu_order")
local orig_FM_setUpdate = FileManagerMenu.setUpdateItemTable
FileManagerMenu.setUpdateItemTable = function(self)
    orig_FM_setUpdate(self)
    inject_menu(FileManagerMenuOrder, self)
end

local ReaderMenu = require("apps/reader/modules/readermenu")
local ReaderMenuOrder = require("ui/elements/reader_menu_order")
local orig_RM_setUpdate = ReaderMenu.setUpdateItemTable
ReaderMenu.setUpdateItemTable = function(self)
    orig_RM_setUpdate(self)
    inject_menu(ReaderMenuOrder, self)
end

-- 3. SCREENSAVER FLOW HOOK
-- We hook this FIRST to determine the context before the ImageWidget is created
local orig_show = Screensaver.show
Screensaver.show = function(self, ...)
    
    -- DETECT CONTEXT: Are we in the File Browser (Random Image) or Reader (Book)?
    -- We store this in the local variable for ImageWidget to see.
    is_screensaver_browser_context = not (self.ui and self.ui.view and self.ui.view.document)
    
    -- Force No Fill (Transparency) if in Browser
    if is_screensaver_browser_context and G_reader_settings:isTrue("screensaver_force_no_fill_random") then
        self.screensaver_background = "none"
    end

    -- Close widgets logic
    if G_reader_settings:isTrue("screensaver_close_widgets") then
        local added, widgets = {}, {}
        for w in UIManager:topdown_widgets_iter() do
            if not added[w] then table.insert(widgets, w) added[w] = true end
        end
        table.remove(widgets) 
        for _, w in ipairs(widgets) do UIManager:close(w, "fast") end
        UIManager:forceRePaint()
    end

    -- Refresh logic
    if G_reader_settings:isTrue("screensaver_refresh") then
        local ss_type = G_reader_settings:readSetting("screensaver_type")
        if Device:hasEinkScreen() and (ss_type == "cover" or ss_type == "random_image") then
            if self:withBackground() then Screen:clear() end
            Screen:refreshFull(0, 0, Screen:getWidth(), Screen:getHeight())
            if Device:isKobo() and Device:isSunxi() then ffiUtil.usleep(150 * 1000) end
        end
    end

    return orig_show(self, ...)
end

-- 4. THE IMAGEWIDGET CONSTRUCTOR
local ImageWidget = require("ui/widget/imagewidget")
local orig_ImageWidget_new = ImageWidget.new

function ImageWidget:new(args)
    -- GUARD: Only shrink if context is NOT browser (meaning it is a Book Cover)
    if Device.screen_saver_mode and G_reader_settings:isTrue("screensaver_center_shrink") 
       and args and args.width and args.height then
        
        -- Use the variable set by Screensaver.show above
        if not is_screensaver_browser_context then
            local margin = 0.85
            args.width = math.floor(args.width * margin)
            args.height = math.floor(args.height * margin)
            args.scale_factor = 0 
            
            local widget = orig_ImageWidget_new(self, args)
            
            return CenterContainer:new{
                dimen = Screen:getSize(),
                widget
            }
        end
    end
    return orig_ImageWidget_new(self, args)
end
