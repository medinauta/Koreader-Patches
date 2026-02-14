-- 2-bookmark-list-custom.lua
-- paste this patch into koreader/patches (create one if you do not have this folder)

local ReaderBookmark = require("apps/reader/modules/readerbookmark")
local BD = require("ui/bidi")
local Blitbuffer = require("ffi/blitbuffer")
local ButtonDialog = require("ui/widget/buttondialog")
local CenterContainer = require("ui/widget/container/centercontainer")
local ConfirmBox = require("ui/widget/confirmbox")
local Device = require("device")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local Menu = require("ui/widget/menu")
local Size = require("ui/size")
local UIManager = require("ui/uimanager")
local util = require("util")
local _ = require("gettext")
local N_ = _.ngettext
local Screen = require("device").screen
local T = require("ffi/util").template

function ReaderBookmark:onShowBookmark()
    self.sorting_mode = G_reader_settings:readSetting("bookmarks_items_sorting") or "page"
    self.is_reverse_sorting = G_reader_settings:isTrue("bookmarks_items_reverse_sorting")

    local item_table = {}
    local curr_page_num = self:getCurrentPageNumber()
    local curr_page_string = self:getBookmarkPageString(curr_page_num)
    local curr_page_index = self.ui.annotation:getInsertionIndex({page = curr_page_num})
    local num = #self.ui.annotation.annotations + 1
    curr_page_index = self.is_reverse_sorting and num - curr_page_index or curr_page_index
    local curr_page_index_filtered = curr_page_index

    for i = 1, #self.ui.annotation.annotations do
        local v = self.ui.annotation.annotations[self.is_reverse_sorting and num - i or i]
        local item = util.tableDeepCopy(v)
        item.text_orig = item.text or ""
        item.type = self.getBookmarkType(item)

        if not self.match_table or self:doesBookmarkMatchTable(item) then
            local highlight_text = self:getBookmarkItemText(item)
            local chapter = item.chapter or ""
			
			if item.type == "highlight" or item.type == "note" then
				if chapter ~= "" then
					item.text = string.format("[%s]\u{2003}%s", chapter, highlight_text)
					item.mandatory = self:getBookmarkPageString(item.page)
				else
					item.text = highlight_text
					item.mandatory = self:getBookmarkPageString(item.page)
				end
			else
				item.text = self:getBookmarkItemText(item)
				item.mandatory = self:getBookmarkPageString(item.page)
			end

            if (not self.is_reverse_sorting and i >= curr_page_index) or (self.is_reverse_sorting and i <= curr_page_index) then
                item.after_curr_page = true
                item.mandatory_dim = true
            end
            if item.mandatory == curr_page_string then
                item.bold = true
                item.after_curr_page = nil
                item.mandatory_dim = nil
            end

            table.insert(item_table, item)
        else
            curr_page_index_filtered = curr_page_index_filtered - 1
        end
    end
	local curr_page_datetime
    if self.sorting_mode == "date" and #item_table > 0 then
        local idx = math.max(1, math.min(curr_page_index_filtered, #item_table))
        curr_page_datetime = item_table[idx].datetime
        local sort_func = self.is_reverse_sorting and function(a, b) return a.datetime > b.datetime end
                                                   or function(a, b) return a.datetime < b.datetime end
        table.sort(item_table, sort_func)
    end

    local items_per_page = G_reader_settings:readSetting("bookmarks_items_per_page")
    local items_font_size = G_reader_settings:readSetting("bookmarks_items_font_size", Menu.getItemFontSize(items_per_page))
    local multilines_show_more_text = G_reader_settings:isTrue("bookmarks_items_multilines_show_more_text")
    local show_separator = G_reader_settings:isTrue("bookmarks_items_show_separator")

    self.bookmark_menu = CenterContainer:new{
        dimen = Screen:getSize(),
        covers_fullscreen = true, -- hint for UIManager:_repaint()
    }
    local bm_menu = Menu:new{
        title = T(_("Bookmarks (%1)"), #item_table),
        item_table = item_table,
        is_borderless = true,
        is_popout = false,
        title_bar_fm_style = true,
        items_per_page = items_per_page,
        items_font_size = items_font_size,
        items_max_lines = self.items_max_lines,
        multilines_show_more_text = multilines_show_more_text,
        line_color = show_separator and Blitbuffer.COLOR_DARK_GRAY or Blitbuffer.COLOR_WHITE,
        title_bar_left_icon = "appbar.menu",
        on_close_ges = {
            GestureRange:new{
                ges = "two_finger_swipe",
                range = Geom:new{
                    x = 0, y = 0,
                    w = Screen:getWidth(),
                    h = Screen:getHeight(),
                },
                direction = BD.flipDirectionIfMirroredUILayout("east")
            }
        },
        show_parent = self.bookmark_menu,
    }
    table.insert(self.bookmark_menu, bm_menu)

    local bookmark = self

    function bm_menu:onMenuSelect(item)
        if self.select_count then
            if item.dim then
                item.dim = nil
                if item.after_curr_page then
                    item.mandatory_dim = true
                end
                self.select_count = self.select_count - 1
            else
                item.dim = true
                self.select_count = self.select_count + 1
            end
            bookmark:updateBookmarkList(nil, -1)
        else
            bookmark.ui.link:addCurrentLocationToStack()
            bookmark:gotoBookmark(item.page, item.pos0)
            self.close_callback()
        end
    end

    function bm_menu:onMenuHold(item)
        bookmark:showBookmarkDetails(item)
        return true
    end

    function bm_menu:toggleSelectMode()
        if self.select_count then
            self.select_count = nil
            for _, v in ipairs(item_table) do
                v.dim = nil
                if v.after_curr_page then
                    v.mandatory_dim = true
                end
            end
            self:setTitleBarLeftIcon("appbar.menu")
        else
            self.select_count = 0
            self:setTitleBarLeftIcon("check")
        end
        bookmark:updateBookmarkList(nil, -1)
    end

    function bm_menu:onLeftButtonTap()
        local bm_dialog, dialog_title
        local buttons = {}
        if self.select_count then
            local actions_enabled = self.select_count > 0
            local more_selections_enabled = self.select_count < #item_table
            if actions_enabled then
                dialog_title = T(N_("1 bookmark selected", "%1 bookmarks selected", self.select_count), self.select_count)
            else
                dialog_title = _("No bookmarks selected")
            end
            table.insert(buttons, {
                {
                    text = _("Select all"),
                    enabled = more_selections_enabled,
                    callback = function()
                        UIManager:close(bm_dialog)
                        for _, v in ipairs(item_table) do
                            v.dim = true
                        end
                        self.select_count = #item_table
                        bookmark:updateBookmarkList(nil, -1)
                    end,
                },
                {
                    text = _("Select page"),
                    enabled = more_selections_enabled,
                    callback = function()
                        UIManager:close(bm_dialog)
                        local item_first = (bm_menu.page - 1) * bm_menu.perpage + 1
                        local item_last = math.min(item_first + bm_menu.perpage - 1, #item_table)
                        for i = item_first, item_last do
                            local v = item_table[i]
                            if v.dim == nil then
                                v.dim = true
                                self.select_count = self.select_count + 1
                            end
                        end
                        bookmark:updateBookmarkList(nil, -1)
                    end,
                },
            })
            table.insert(buttons, {
                {
                    text = _("Deselect all"),
                    enabled = actions_enabled,
                    callback = function()
                        UIManager:close(bm_dialog)
                        for _, v in ipairs(item_table) do
                            v.dim = nil
                            if v.after_curr_page then
                                v.mandatory_dim = true
                            end
                        end
                        self.select_count = 0
                        bookmark:updateBookmarkList(nil, -1)
                    end,
                },
                {
                    text = _("Delete note"),
                    enabled = actions_enabled,
                    callback = function()
                        UIManager:show(ConfirmBox:new{
                            text = _("Delete bookmark notes?"),
                            ok_text = _("Delete"),
                            ok_callback = function()
                                UIManager:close(bm_dialog)
                                for _, v in ipairs(item_table) do
                                    if v.dim then
                                        bookmark:deleteItemNote(v)
                                    end
                                end
                                self:onClose()
                                bookmark:onShowBookmark()
                            end,
                        })
                    end,
                },
            })
            table.insert(buttons, {
                {
                    text = _("Exit select mode"),
                    callback = function()
                        UIManager:close(bm_dialog)
                        self:toggleSelectMode()
                    end,
                },
                {
                    text = _("Remove"),
                    enabled = actions_enabled and not bookmark.ui.highlight.select_mode,
                    callback = function()
                        UIManager:show(ConfirmBox:new{
                            text = _("Remove selected bookmarks?"),
                            ok_text = _("Remove"),
                            ok_callback = function()
                                UIManager:close(bm_dialog)
                                for i = #item_table, 1, -1 do
                                    if item_table[i].dim then
                                        bookmark:removeItem(item_table[i])
                                        table.remove(item_table, i)
                                    end
                                end
                                self.select_count = nil
                                self:setTitleBarLeftIcon("appbar.menu")
                                bookmark:updateBookmarkList(item_table, -1)
                            end,
                        })
                    end,
                },
            })
        else -- select mode off
            dialog_title = _("Filter by bookmark type")
            local actions_enabled = #item_table > 0
            local type_count = { highlight = 0, note = 0, bookmark = 0 }
            for _, item in ipairs(bookmark.ui.annotation.annotations) do
                local item_type = bookmark.getBookmarkType(item)
                type_count[item_type] = type_count[item_type] + 1
            end
            local genBookmarkTypeButton = function(item_type)
                return {
                    text = bookmark.display_prefix[item_type] ..
                        T(_("%1 (%2)"), bookmark.display_type[item_type], type_count[item_type]),
                    callback = function()
                        UIManager:close(bm_dialog)
                        self:onClose()
                        bookmark.match_table = { [item_type] = true }
                        bookmark:onShowBookmark()
                    end,
                }
            end
            table.insert(buttons, {
                {
                    text = _("All (reset filters)"),
                    callback = function()
                        UIManager:close(bm_dialog)
                        self:onClose()
                        bookmark:onShowBookmark()
                    end,
                },
                genBookmarkTypeButton("highlight"),
            })
            table.insert(buttons, {
                genBookmarkTypeButton("bookmark"),
                genBookmarkTypeButton("note"),
            })
            table.insert(buttons, {}) -- separator
            table.insert(buttons, {
                {
                    text = _("Filter by edited highlighted text"),
                    callback = function()
                        UIManager:close(bm_dialog)
                        bookmark:filterByEditedText()
                    end,
                },
            })
            table.insert(buttons, {
                {
                    text = _("Filter by highlight style"),
                    callback = function()
                        UIManager:close(bm_dialog)
                        bookmark:filterByHighlightStyle()
                    end,
                },
            })
            table.insert(buttons, {}) -- separator
            table.insert(buttons, {
                {
                    text = _("Export annotations"),
                    callback = function()
                        UIManager:close(bm_dialog)
                        bookmark.ui.annotation:onExportAnnotations()
                    end,
                },
            })
            table.insert(buttons, {}) -- separator
            table.insert(buttons, {
                {
                    text = _("Current page"),
                    callback = function()
                        UIManager:close(bm_dialog)
                        local idx
                        if bookmark.sorting_mode == "date" then
                            for i, v in ipairs(item_table) do
                                if v.datetime == curr_page_datetime then
                                    idx = i
                                    break
                                end
                            end
                        else -- "page"
                            idx = curr_page_index_filtered
                        end
                        bookmark:updateBookmarkList(nil, idx)
                    end,
                },
                {
                    text = _("Latest bookmark"),
                    enabled = actions_enabled
                        and not (bookmark.match_table or bookmark.show_edited_only or bookmark.show_drawer_only),
                    callback = function()
                        UIManager:close(bm_dialog)
                        local idx
                        if bookmark.sorting_mode == "date" then
                            idx = bookmark.is_reverse_sorting and 1 or #item_table
                        else -- "page"
                            idx = select(2, bookmark:getLatestBookmark())
                            idx = bookmark.is_reverse_sorting and #item_table - idx + 1 or idx
                        end
                        bookmark:updateBookmarkList(nil, idx)
                        bookmark:showBookmarkDetails(item_table[idx])
                    end,
                },
            })
            table.insert(buttons, {
                {
                    text = _("Select bookmarks"),
                    enabled = actions_enabled,
                    callback = function()
                        UIManager:close(bm_dialog)
                        self:toggleSelectMode()
                    end,
                },
                {
                    text = _("Search bookmarks"),
                    enabled = actions_enabled,
                    callback = function()
                        UIManager:close(bm_dialog)
                        bookmark:onSearchBookmark()
                    end,
                },
            })
        end
        bm_dialog = ButtonDialog:new{
            title = dialog_title,
            title_align = "center",
            buttons = buttons,
        }
        UIManager:show(bm_dialog)
    end

    function bm_menu:onLeftButtonHold()
        self:toggleSelectMode()
        return true
    end

    bm_menu.close_callback = function()
        UIManager:close(self.bookmark_menu)
        self.bookmark_menu = nil
        self.match_table = nil
        self.show_edited_only = nil
        self.show_drawer_only = nil
    end

    local idx
    if bookmark.sorting_mode == "date" then -- show the most recent bookmark
        idx = bookmark.is_reverse_sorting and 1 or #item_table
    else -- "page", show bookmark in the current book page
        idx = curr_page_index_filtered
    end
    self:updateBookmarkList(nil, idx)
    UIManager:show(self.bookmark_menu)
    return true
end
    