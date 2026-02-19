--[[ 
Patch: Kobo-style Sleep Screen Banner + Avoid Night Mode toggle + Smart Title 
Original patch: https://github.com/zenixlabs/koreader-frankenpatches-public/blob/main/2-kobo-style-sleepscreen-banner.lua
This mod was done before the author added the "Highlight" feature to the patch, so this does not include it.
--]]

local Blitbuffer = require("ffi/blitbuffer")
local BookInfo = require("apps/filemanager/filemanagerbookinfo")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local LeftContainer = require("ui/widget/container/leftcontainer")
local Screen = Device.screen
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local logger = require("logger")
local _ = require("gettext")

local screen_w = Screen:getWidth()

-- ===================== SMART TITLE CASE =====================
local function smartTitleCase(str)
    if not str then return str end

    local small_words = {
        ["a"]=true, ["an"]=true, ["and"]=true, ["as"]=true, ["at"]=true,
        ["but"]=true, ["by"]=true, ["for"]=true, ["from"]=true, ["in"]=true, ["into"]=true,
        ["nor"]=true, ["of"]=true, ["on"]=true, ["or"]=true, ["over"]=true, ["the"]=true,
        ["to"]=true, ["with"]=true
    }

    local words = {}
    for w in str:gmatch("%S+") do table.insert(words, w) end

    local capitalize_next = true  -- start with first word capitalized
    for i, w in ipairs(words) do
        local lower = w:lower()
        if capitalize_next or i == 1 or i == #words or not small_words[lower] then
            words[i] = lower:gsub("^%l", string.upper)
        else
            words[i] = lower
        end
        -- If word ends with colon, next word should be capitalized
        capitalize_next = w:match(":$") ~= nil
    end

    return table.concat(words, " ")
end

-- ===================== PATCH SETTINGS =====================
local banner_settings = {
    title_text = "%C",
    background = 0, -- 0=white, 1=black
    margin = 10,
    title_fontFace = "cfont",
    title_fontSize = 30,
    stats_fontFace = "cfont",
    stats_fontSize = 17,
    border_size = 1,
    border_color = 1,
    padding = 15,
}

-- Default toggle initialization
if G_reader_settings:hasNot("screensaver_kobo_style_banner") then
    G_reader_settings:saveSetting("screensaver_kobo_style_banner", false)
end
if G_reader_settings:hasNot("screensaver_force_day_banner") then
    G_reader_settings:saveSetting("screensaver_force_day_banner", false)
end

-- ===================== SCREENSAVER UI PATCH =====================
local og_uiMan_show = UIManager.show

function UIManager:show(widget, ...)
    -- START CONDITION: If main toggle is OFF, exit and use original code
    if not G_reader_settings:isTrue("screensaver_kobo_style_banner") then
        return og_uiMan_show(self, widget, ...)
    end

    if widget.name ~= "ScreenSaver" then
        return og_uiMan_show(self, widget, ...)
    end

    local screensaver_type = G_reader_settings:readSetting("screensaver_type")
    local message_enabled = G_reader_settings:isTrue("screensaver_show_message")
    local message_type = G_reader_settings:readSetting("screensaver_message_container")

    if not message_enabled or message_type ~= "banner" then
        return og_uiMan_show(self, widget, ...)
    end
    if screensaver_type ~= "cover" and screensaver_type ~= "random_image" and screensaver_type ~= "document_cover" then
        return og_uiMan_show(self, widget, ...)
    end

    if not (widget and widget[1] and widget[1][1] and widget[1][1][2] and widget[1][1][2].widget) then
        return og_uiMan_show(self, widget, ...)
    end

    local cus_pos_container = widget[1][1][2]
    local stats_widget = cus_pos_container.widget
    local stats_text = stats_widget.text
    stats_widget:free()

    local last_file = G_reader_settings:readSetting("lastfile")
    self.ui = require("apps/reader/readerui").instance or require("apps/filemanager/filemanager").instance

    local title_text
    if self.ui and self.ui.bookinfo then
        title_text = self.ui.bookinfo:expandString(banner_settings.title_text, last_file) or "N/A"
    else
        title_text = BookInfo:expandString(banner_settings.title_text, last_file) or "N/A"
    end

    -- Title Case
    title_text = smartTitleCase(title_text)

    -- ===== Night Mode + Avoid Night Mode Logic =====
    local night_mode = G_reader_settings:isTrue("night_mode")
    local avoid_night = G_reader_settings:isTrue("screensaver_force_day_banner")

    -- Base colors from settings
    local base_bg = banner_settings.background == 1 and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_WHITE
    local base_fg = banner_settings.background == 1 and Blitbuffer.COLOR_WHITE or Blitbuffer.COLOR_BLACK
    local base_border = banner_settings.border_color == 1 and Blitbuffer.COLOR_WHITE or Blitbuffer.COLOR_BLACK

    local fg_color, bg_color, border_color

    if night_mode then
       if avoid_night then
           -- Force light banner even in night mode pre-reverse colors
           fg_color = base_bg
           bg_color = base_fg
           border_color = base_fg
       else
           -- Leave colors as normal; device night mode will reverse them
           fg_color = base_fg
           bg_color = base_bg
           border_color = base_border
       end
    else -- night mode off so normal colors
       fg_color = base_fg
       bg_color = base_bg
       border_color = base_border
    end

    local max_wid = screen_w * 0.4

    local function makeTextWidget(text, fontFace, fontSize)
        local w = TextWidget:new{
            text = text,
            face = Font:getFace(fontFace, fontSize),
            alignment = "left",
            fgcolor = fg_color,
            bgcolor = bg_color,
        }
        if w:getSize().w > max_wid then
            w:free()
            return TextBoxWidget:new{
                text = text,
                face = Font:getFace(fontFace, fontSize),
                width = max_wid,
                alignment = "left",
                fgcolor = fg_color,
                bgcolor = bg_color,
            }
        end
        return w
    end

    local title_widget = makeTextWidget(title_text, banner_settings.title_fontFace, banner_settings.title_fontSize)
    local stats_widget_new = makeTextWidget(stats_text, banner_settings.stats_fontFace, banner_settings.stats_fontSize)

    local title_dimen = title_widget:getSize()
    local stats_dimen = stats_widget_new:getSize()
    local wid = math.max(title_dimen.w, stats_dimen.w)

    local content_widget = VerticalGroup:new{
        LeftContainer:new{ dimen = {w = wid, h = title_dimen.h}, title_widget },
        LeftContainer:new{ dimen = {w = wid, h = stats_dimen.h}, stats_widget_new },
    }

    content_widget = FrameContainer:new{
        background = bg_color,
        color = fg_color,
        margin = Screen:scaleBySize(banner_settings.margin),
        bordersize = Screen:scaleBySize(banner_settings.border_size),
        padding = Screen:scaleBySize(banner_settings.padding),
        content_widget,
    }

    cus_pos_container.horizontal_position = 0
    cus_pos_container.widget = content_widget

    return og_uiMan_show(self, widget, ...)
end

-- ===================== MENU HELPERS =====================

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

local function add_options_in(menu)
    local items = menu.sub_item_table
    if #items > 0 then items[#items].separator = true end

    -- Toggle 1: Kobo Style
    table.insert(items, {
        text = _("Kobo style sleep banner"),
        help_text = _("Enabled when Message container is set to Banner."),
        enabled_func = function()
            return G_reader_settings:readSetting("screensaver_message_container") == "banner"
        end,
        checked_func = function()
            return G_reader_settings:isTrue("screensaver_kobo_style_banner")
        end,
        callback = function(touchmenu_instance)
            G_reader_settings:flipNilOrFalse("screensaver_kobo_style_banner")
            touchmenu_instance:updateItems()
        end,
    })

    -- Toggle 2: Avoid Night Mode
    table.insert(items, {
        text = _("Avoid night mode"),
        help_text = _("Keep white banner and black text even when night mode is enabled."),
        enabled_func = function()
            return G_reader_settings:isTrue("screensaver_kobo_style_banner") and 
                   G_reader_settings:readSetting("screensaver_message_container") == "banner"
        end,
        checked_func = function()
            return G_reader_settings:isTrue("screensaver_force_day_banner")
        end,
        callback = function(touchmenu_instance)
            G_reader_settings:flipNilOrFalse("screensaver_force_day_banner")
            touchmenu_instance:updateItems()
        end,
    })
end

local function add_options_in_screensaver(order, menu, menu_name)
    local buttons = order["KOMenu:menu_buttons"]
    for i, button in ipairs(buttons) do
        if button == "setting" then
            local setting_menu = menu.tab_item_table[i]
            if setting_menu then
                local sub_menu = find_item_from_path(setting_menu, _("Screen"), _("Sleep screen"), _("Sleep screen message"))
                if sub_menu then
                    add_options_in(sub_menu)
                    logger.info("Added Kobo style toggles in", menu_name)
                end
            end
        end
    end
end

-- ===================== HOOK INTO MENUS =====================
local FileManagerMenu = require("apps/filemanager/filemanagermenu")
local FileManagerMenuOrder = require("ui/elements/filemanager_menu_order")
local orig_FileManagerMenu_setUpdateItemTable = FileManagerMenu.setUpdateItemTable

FileManagerMenu.setUpdateItemTable = function(self)
    orig_FileManagerMenu_setUpdateItemTable(self)
    add_options_in_screensaver(FileManagerMenuOrder, self, "file manager")
end

local ReaderMenu = require("apps/reader/modules/readermenu")
local ReaderMenuOrder = require("ui/elements/reader_menu_order")
local orig_ReaderMenu_setUpdateItemTable = ReaderMenu.setUpdateItemTable

ReaderMenu.setUpdateItemTable = function(self)
    orig_ReaderMenu_setUpdateItemTable(self)
    add_options_in_screensaver(ReaderMenuOrder, self, "reader")

end
