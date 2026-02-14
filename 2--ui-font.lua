-- NAME IT "2--ui-font.lua": it NEEDS to be the 1st user patch to be executed

local Font = require("ui/font")
local Version = require("version")
local _ = require("gettext")
local T = require("ffi/util").template
local FontList = require("fontlist")
local UIManager = require("ui/uimanager")
local cre = require("document/credocument"):engineInit()
local logger = require("logger")

if Version:getNormalizedCurrentVersion() < Version:getNormalizedVersion("v2025.04-115") then
    local orig_string_rep = string.rep -- fix https://github.com/koreader/koreader/issues/13925
    getmetatable("").__index.rep = function(self, n)
        if n < math.huge then return orig_string_rep(self, n) end
        return self
    end
end

-- util
local function get_bold_path(path_regular)
    local path_bold, n_repl = path_regular:gsub("%-Regular%.", "-Bold.", 1)
    return n_repl > 0 and path_bold
end

-- UI font
local UIFont = {
    setting = { name = "ui_font_name", default = "Noto Sans" },
    font_type = { regular = "NotoSans-Regular.ttf", bold = "NotoSans-Bold.ttf" },
}

function UIFont:getSetting() return G_reader_settings:readSetting(self.setting.name, self.setting.default) end
function UIFont:setSetting(value) G_reader_settings:saveSetting(self.setting.name, value) end

function UIFont:init()
    local path_exists = {}
    -- stylua: ignore
    for _, font in ipairs(FontList.fontlist) do path_exists[font] = true end

    self.font_list = {}
    self.fonts = {}
    for _, name in ipairs(cre.getFontFaces()) do
        local path_regular = cre.getFontFaceFilenameAndFaceIndex(name)
        local path_bold = get_bold_path(path_regular)
        if path_exists[path_regular] and path_exists[path_bold] then
            table.insert(self.font_list, name)
            self.fonts[name] = { regular = path_regular, bold = path_bold }
        end
    end

    local type_font = {}
    self.to_be_replaced = {}
    -- stylua: ignore start
    for typ, font in pairs(self.font_type) do type_font[font] = typ end
    for name, font in pairs(Font.fontmap) do self.to_be_replaced[name] = type_font[font] end
    -- stylua: ignore end

    self:setFont()
end

function UIFont:setFont(name)
    local current_name = self:getSetting()
    if name ~= current_name then
        name = name or current_name
        if not self.fonts[name] then name = DEFAULT end
        for font, typ in pairs(self.to_be_replaced) do
            Font.fontmap[font] = self.fonts[name][typ]
        end
        self:setSetting(name)
        return true
    end
end

function UIFont:menu()
    return {
        text_func = function() return T(_("UI font: %1"), self:getSetting()) end,
        sub_item_table_func = function()
            local items = {}
            for i, name in ipairs(self.font_list) do
                table.insert(items, {
                    text = name,
                    enabled_func = function() return name ~= self:getSetting() end,
                    font_func = function(size) return Font:getFace(self.fonts[name].regular, size) end,
                    callback = function()
                        if self:setFont(name) then
                            UIManager:askForRestart(_("Restart to apply the UI font change"))
                        end
                    end,
                })
            end
            return items
        end,
    }
end

--singleton
UIFont:init()

-- menu
local FileManagerMenu = require("apps/filemanager/filemanagermenu")
local ReaderMenu = require("apps/reader/modules/readermenu")

local function patch(menu, order)
    table.insert(order.setting, "----------------------------")
    table.insert(order.setting, "ui_font")
    menu.menu_items.ui_font = UIFont:menu()
end

local orig_FileManagerMenu_setUpdateItemTable = FileManagerMenu.setUpdateItemTable
function FileManagerMenu:setUpdateItemTable()
    patch(self, require("ui/elements/filemanager_menu_order"))
    orig_FileManagerMenu_setUpdateItemTable(self)
end

local orig_ReaderMenu_setUpdateItemTable = ReaderMenu.setUpdateItemTable
function ReaderMenu:setUpdateItemTable()
    patch(self, require("ui/elements/reader_menu_order"))
    orig_ReaderMenu_setUpdateItemTable(self)
end