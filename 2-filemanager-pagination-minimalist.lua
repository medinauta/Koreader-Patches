local userpatch = require("userpatch")
local _ = require("gettext")
local T = require("ffi/util").template
local Font = require("ui/font")
local Size = require("ui/size")

-- ============================================================
--  USER SETTINGS
-- ============================================================

-- Arrows style for pagination chevron buttons
--   "remove"  → hide the buttons entirely
--   "minimal" → replace icons with dot characters (• and ••)
--   "default" → leave the original chevron icons unchanged
local ARROWS = "minimal"

-- Pagination text format
--   "minimal" → "1 / 50"
--   "default" → "Page 1 of 50"  (original KOReader text)
local PAGINATION = "minimal"

-- Footer height
--   "minimal" → smaller font on the page-info button → shorter footer
--   "default" → leave original size unchanged
local FOOTER_HEIGHT = "minimal"

-- Font size for the page-info button when FOOTER_HEIGHT = "minimal"
-- Button default is 20. Lower = shorter footer bar. Tweak to taste.
local FOOTER_FONT_SIZE = 11

-- ============================================================
--  HELPERS
-- ============================================================

local function hideChevrons(self)
    if self.page_info_left_chev  then self.page_info_left_chev:hide()  end
    if self.page_info_right_chev then self.page_info_right_chev:hide() end
    if self.page_info_first_chev then self.page_info_first_chev:hide() end
    if self.page_info_last_chev  then self.page_info_last_chev:hide()  end
end

local function setMinimalChevrons(self)
    if self.page_info_left_chev then
        self.page_info_left_chev.icon = nil
        self.page_info_left_chev:setText("•")
    end
    if self.page_info_right_chev then
        self.page_info_right_chev.icon = nil
        self.page_info_right_chev:setText("•")
    end
    if self.page_info_first_chev then
        self.page_info_first_chev.icon = nil
        self.page_info_first_chev:setText("••")
    end
    if self.page_info_last_chev then
        self.page_info_last_chev.icon = nil
        self.page_info_last_chev:setText("••")
    end
end

-- Apply smaller font to page_info_text and force Button:init() to rerun.
-- From button.lua: Button:init() reads self.text_font_size and
-- self.text_font_face directly. Button:setText() calls self:init() whenever
-- self.width is nil or the geometry changes — so we set the font fields,
-- clear width, then call setText() to trigger the full reinit.
local function applyFooterFont(btn)
    if not btn then return end
    btn.text_font_size = FOOTER_FONT_SIZE
    btn.text_font_face = "cfont"
    btn.text_font_bold = false
    btn.width = nil  -- ensures setText takes the init() branch, not the fast path
    btn:setText(btn.text or "")
end

-- ============================================================
--  PATCH
-- ============================================================

local function patchMenu(Menu)

    -- --------------------------------------------------------
    -- 1. Intercept init
    --    Run orig first (creates page_info_text at default size 20),
    --    then resize it and recalculate layout so available_height
    --    and item_dimen.h reflect the smaller footer.
    -- --------------------------------------------------------
    local orig_init = Menu.init
    function Menu:init()
        orig_init(self)

        -- ---- FOOTER HEIGHT ---------------------------------
        if FOOTER_HEIGHT == "minimal" and self.page_info_text then
            applyFooterFont(self.page_info_text)
            -- Re-run layout calculation now that getSize().h is smaller.
            -- Pass true to skip the perpage/font_size staleness check
            -- (we only want to redo the height math).
            self:_recalculateDimen()
        end

        -- ---- ARROWS ----------------------------------------
        if ARROWS == "remove" then
            hideChevrons(self)
        elseif ARROWS == "minimal" then
            setMinimalChevrons(self)
        end
    end

    -- --------------------------------------------------------
    -- 2. Intercept updatePageInfo
    --    Re-apply ARROWS (orig re-shows chevrons on every call)
    --    and rewrite pagination text.
    -- --------------------------------------------------------
    local orig_updatePageInfo = Menu.updatePageInfo
    function Menu:updatePageInfo(select_number)
        orig_updatePageInfo(self, select_number)

        -- orig calls :show() on all chevrons — re-hide if needed
        if ARROWS == "remove" then
            hideChevrons(self)
        end
        -- "minimal" chevron dot text persists because updatePageInfo
        -- only calls enableDisable/show/hide, never setText on chevrons.

        -- Rewrite pagination text
        if PAGINATION == "minimal" and self.page_info_text then
            if self.page_num and self.page_num > 0 then
                -- Pass current width to take the fast path in setText
                -- (avoids a full Button:init() reinit on every page turn)
                self.page_info_text:setText(
                    string.format("%d / %d", self.page, self.page_num),
                    self.page_info_text.width
                )
            end
        end
    end

end

-- Apply the patch to the Menu base class
local Menu = require("ui/widget/menu")
patchMenu(Menu)