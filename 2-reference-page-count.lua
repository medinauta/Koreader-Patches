-- fallback if there's no source for reference pages
-- gives the actual number of pages in the status bar page_progress & page_left_book instead of a label

local ReaderFooter = require("apps/reader/modules/readerfooter")
local ReaderPageMap = require("apps/reader/modules/readerpagemap")
local userpatch = require("userpatch")

local footerTextGeneratorMap = userpatch.getUpValue(ReaderFooter.applyFooterMode, "footerTextGeneratorMap")
local orig_ReaderPageMap_getLastPageLabel = ReaderPageMap.getLastPageLabel
local orig_ReaderPageMap_postInit = ReaderPageMap._postInit
local orig_ReaderPageMap_init = ReaderPageMap.init

-- build pagemap with CHAR_PER_PAGE if none available
local CHAR_PER_PAGE = 1818

ReaderPageMap._postInit = function(self)
    self.ui.document:buildSyntheticPageMapIfNoneDocumentProvided(CHAR_PER_PAGE)
    orig_ReaderPageMap_postInit(self)
end

-- real page number instead of last page label
function ReaderPageMap:init() -- reset for a new book
    self._last_page_number = nil
    orig_ReaderPageMap_init(self)
end

function ReaderPageMap:_getLastPageNumber() -- cached
    self._last_page_number = self._last_page_number or #self.ui.document:getPageMap()
    return self._last_page_number
end

for _, item in ipairs { "page_progress", "pages_left_book" } do -- patch getLastPageLabel
    local orig = footerTextGeneratorMap[item]
    footerTextGeneratorMap[item] = function(...)
        ReaderPageMap.getLastPageLabel = ReaderPageMap._getLastPageNumber
        local ret = orig(...)
        ReaderPageMap.getLastPageLabel = orig_ReaderPageMap_getLastPageLabel
        return ret
    end
end
