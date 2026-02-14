-- a patch for changing ToC title to book title

local Event = require("ui/event")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local ReaderToc = require("apps/reader/modules/readertoc")
local onShowToc_orig = ReaderToc.onShowToc
ReaderToc.onShowToc = function(self)
    -- Run original code
    onShowToc_orig(self)
    -- See if the book has some title
    local doc_info = self.ui.document:getProps()
    if doc_info and doc_info.title ~= "" then
        -- Add some left icon, that will then be used after :init() below
        self.toc_menu.title_bar.left_icon = "info"
        -- Set book title as TOC widget title (or keep the original if it has been disabled)
        local title = _("Table of Contents")
        if not self.ui.doc_settings:isTrue("toc_hide_book_title") then
            title = doc_info.title
        end
        -- Re-init TitleBar
        self.toc_menu.title_bar:clear()
        self.toc_menu.title_bar.title = title
        self.toc_menu.title_bar:init()
        -- Add some handlers for the added left button
        function self.toc_menu:onLeftButtonTap()
            self.ui.doc_settings:toggle("toc_hide_book_title")
            self:onClose()
            UIManager:broadcastEvent(Event:new("ShowToc"))
        end
        function self.toc_menu:onLeftButtonHold()
            UIManager:broadcastEvent(Event:new("ShowBookInfo"))
        end
    end
end
