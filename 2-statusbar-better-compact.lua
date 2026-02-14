-- enhance compact items:
-- use the better frontlight icons, and add the battery percentage
-- better separator for title/chapter/author in compact mode with no separator

local ReaderFooter = require("apps/reader/modules/readerfooter")
local userpatch = require("userpatch")

local footerTextGeneratorMap = userpatch.getUpValue(ReaderFooter.applyFooterMode, "footerTextGeneratorMap")
local symbol_prefix = userpatch.getUpValue(footerTextGeneratorMap.frontlight, "symbol_prefix")

-- use the better icons for compact items
for _, item in ipairs { "frontlight", "frontlight_warmth" } do
    symbol_prefix.compact_items[item] = symbol_prefix.icons[item]
end

-- use the battery percent for compact items
for _, item in ipairs { "battery" } do
    local orig = footerTextGeneratorMap[item]
    footerTextGeneratorMap[item] = function(footer, ...)
        local item_prefix_save = footer.settings.item_prefix
        if footer.settings.item_prefix == "compact_items" then footer.settings.item_prefix = "icons" end
        local text = orig(footer, ...)
        footer.settings.item_prefix = item_prefix_save -- restore
        return text
    end
end

-- add a separator for title/chapter/author
local BEGIN, END = string.char(0x1E), string.char(0x1F)

for _, item in ipairs { "book_author", "book_title", "book_chapter" } do
    local orig = footerTextGeneratorMap[item]
    footerTextGeneratorMap[item] = function(...) return BEGIN .. orig(...) .. END end
end

local separator_next = symbol_prefix.compact_items.pages_left

local subs = { -- order is important
    { pattern = END .. " " .. BEGIN, replace = " " .. separator_next .. " " }, -- sequence of title/chapter/author
    
    { pattern = "^" .. BEGIN, replace = "" }, -- @beginning of string
    { pattern = END .. "$", replace = "" }, -- @end of string
    { pattern = BEGIN, replace = separator_next .. " " }, --@beginning of title/chapter/author
    { pattern = END, replace = "" }, --@end of title/chapter/author
}

local orig_ReaderFooter_genAllFooterText = ReaderFooter.genAllFooterText

function ReaderFooter:genAllFooterText(...)
    local text, is_filler_inside = orig_ReaderFooter_genAllFooterText(self, ...)
    if self.settings.item_prefix == "compact_items" and self.settings.items_separator == "none" then
        -- stylua: ignore
        for _, sub in ipairs(subs) do text = text:gsub(sub.pattern, sub.replace) end
    end
    return text, is_filler_inside
end