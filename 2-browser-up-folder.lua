local BD = require("ui/bidi")
local FileChooser = require("ui/widget/filechooser")
local logger = require("logger")
local FileManagerMenu = require("apps/filemanager/filemanagermenu")
local FileManagerMenuOrder = require("ui/elements/filemanager_menu_order")
local _ = require("gettext")

-- 1. Icons
local Icon = {
    home = "home",
    up = BD.mirroredUILayout() and "back.top.rtl" or "back.top",
}

-- 2. Persistent Settings
local function Setting(name, default)
    local obj = {}
    obj.get = function() return G_reader_settings:readSetting(name, default) end
    obj.toggle = function() G_reader_settings:toggle(name) end
    return obj
end

local HideEmpty = Setting("filemanager_hide_empty_folder", false)
local HideUp = Setting("filemanager_hide_up_folder", true)

-- 3. FileChooser UI Logic
local orig_FileChooser_genItemTable = FileChooser.genItemTable
function FileChooser:genItemTable(dirs, files, path)
    local item_table = orig_FileChooser_genItemTable(self, dirs, files, path)
    if self._dummy or self.name ~= "filemanager" then return item_table end

    local items = {}
    local is_sub_folder = false

    for _, item in ipairs(item_table) do
        local is_up = item.is_go_up or item.text == ".." or item.path:match("/%.%.$")
        if is_up then
            if not HideUp.get() then table.insert(items, item) end
            is_sub_folder = true 
        elseif item.attr and item.attr.mode == "directory" then
            local sub_dirs, dir_files = self:getList(item.path, {})
            if not (HideEmpty.get() and #dir_files == 0) then
                table.insert(items, item)
            end
        else
            table.insert(items, item)
        end
    end

    if self.title_bar then
        local icon = is_sub_folder and Icon.up or Icon.home
        self.title_bar.left_icon = icon
        if self.title_bar.left_button then
            self.title_bar.left_button:setIcon(icon)
        end
    end
    
    return items
end

-- 4. Menu Patching logic
local orig_FileManagerMenu_setUpdateItemTable = FileManagerMenu.setUpdateItemTable

function FileManagerMenu:setUpdateItemTable()
    -- We define our items BEFORE calling the original function
    self.menu_items["hide_empty_folder"] = {
        text = _("Hide empty folders"),
        checked_func = function() return HideEmpty.get() end,
        callback = function()
            HideEmpty.toggle()
            self.ui.file_chooser:refreshPath()
        end,
    }

    self.menu_items["hide_up_folder"] = {
        text = _("Hide up folders"),
        checked_func = function() return HideUp.get() end,
        callback = function()
            HideUp.toggle()
            self.ui.file_chooser:refreshPath()
        end,
        separator = true, -- 🔥 Separator AFTER this item
    }

    -- Apply the order injection
    local order = FileManagerMenuOrder.filemanager_settings
    local patched = false
    for _, v in ipairs(order) do
        if v == "hide_empty_folder" then patched = true break end
    end

    if not patched then
        local anchor_idx = #order
        for i, v in ipairs(order) do
            if v == "advanced_settings" then
                anchor_idx = i
                break
            end
        end

        -- Add separator to the item immediately before our first item
        local prev_item_key = order[anchor_idx - 1]
        if prev_item_key and self.menu_items[prev_item_key] then
            self.menu_items[prev_item_key].separator = true -- 🔥 Separator BEFORE our group
        end

        table.insert(order, anchor_idx, "hide_empty_folder")
        table.insert(order, anchor_idx + 1, "hide_up_folder")
    end

    -- Now call the original function to build the UI
    orig_FileManagerMenu_setUpdateItemTable(self)
end