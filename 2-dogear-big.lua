-- ============================================================
-- ReaderDogear Patch (2-dogear-big.lua)
-- https://github.com/medinauta/Koreader-Patches/
-- Customizes the bookmark dogear: size, icon, and Y position.
-- Also repaints the dogear AFTER ReaderView.paintTo so it always
-- appears on top of other patches (e.g. reader-header-print-edition).
--
-- SETTINGS -- edit these values to your liking:
-- ============================================================

local DOGEAR_SIZE_MULTIPLIER = 1.8   -- Scale factor for max size (e.g. 1.8 = 80% bigger)
local DOGEAR_MIN_MULTIPLIER  = 1.8   -- Scale factor for min size (keep in sync with max)
local DOGEAR_Y_OFFSET        = 0     -- Extra pixels to push dogear DOWN from top (0 = default).
                                     -- Increase this if a header/status bar overlaps the dogear.

-- Icon to use for the dogear. Use nil to keep the default ("dogear.alpha").
-- To use a custom image, place your file in /koreader/icons folder
-- and enter the bare name without extension (e.g. if your file is "dogear2.svg" enter "dogear2").

local DOGEAR_ICON            = "dogear3"   -- nil = default | example: "dogear2"
local DOGEAR_ALPHA           = true -- false = default | true = enable transparency

-- ============================================================
-- Patch code -- no need to edit below this line
-- ============================================================

local ReaderDogear = require("apps/reader/modules/readerdogear")

-- Preserve originals
ReaderDogear.init_orig               = ReaderDogear.init
ReaderDogear.setupDogear_orig        = ReaderDogear.setupDogear
ReaderDogear.updateDogearOffset_orig = ReaderDogear.updateDogearOffset

-- Override init: rescale min/max sizes and store y offset
ReaderDogear.init = function(self)
    self:init_orig()

    -- Apply size multipliers to the values computed in the original init
    self.dogear_max_size = math.floor(DOGEAR_SIZE_MULTIPLIER * self.dogear_max_size)
    self.dogear_min_size = math.floor(DOGEAR_MIN_MULTIPLIER  * self.dogear_min_size)

    -- Store our custom y offset so other functions can read it
    self.custom_y_offset = DOGEAR_Y_OFFSET

    -- Re-run setup now that sizes have changed
    self.dogear_size = nil  -- force setupDogear to rebuild
    self:setupDogear()
    self:resetLayout()
end

-- Override setupDogear: inject custom icon and/or alpha setting
ReaderDogear.setupDogear = function(self, new_dogear_size)
    -- If no custom icon, use original logic but patch alpha afterwards if needed
    if not DOGEAR_ICON then
        self:setupDogear_orig(new_dogear_size)
        -- The original hardcodes alpha=false; override it if the user wants alpha
        if DOGEAR_ALPHA and self.icon then
            self.icon.alpha = true
        end
        return
    end

    -- Custom icon path: duplicate the original logic with our icon substituted
    local BD             = require("ui/bidi")
    local Geom           = require("ui/geometry")
    local IconWidget     = require("ui/widget/iconwidget")
    local RightContainer = require("ui/widget/container/rightcontainer")
    local VerticalGroup  = require("ui/widget/verticalgroup")
    local VerticalSpan   = require("ui/widget/verticalspan")
    local Screen         = require("device").screen

    if not new_dogear_size then
        new_dogear_size = self.dogear_max_size
    end

    if new_dogear_size ~= self.dogear_size then
        self.dogear_size = new_dogear_size
        if self[1] then
            self[1]:free()
        end
        self.icon = IconWidget:new{
            icon           = DOGEAR_ICON,
            rotation_angle = BD.mirroredUILayout() and 90 or 0,
            width          = self.dogear_size,
            height         = self.dogear_size,
            alpha          = DOGEAR_ALPHA,
        }
        self.top_pad = VerticalSpan:new{ width = self.dogear_y_offset }
        self.vgroup  = VerticalGroup:new{
            self.top_pad,
            self.icon,
        }
        self[1] = RightContainer:new{
            dimen = Geom:new{
                w = Screen:getWidth(),
                h = self.dogear_y_offset + self.dogear_size,
            },
            self.vgroup,
        }
    end
end

-- Override updateDogearOffset: add our extra DOGEAR_Y_OFFSET on top of
-- whatever the original function computes (header height, etc.)
ReaderDogear.updateDogearOffset = function(self)
    if not self.ui.rolling then
        return
    end

    self.dogear_y_offset = 0
    if self.view.view_mode == "page" then
        self.dogear_y_offset = self.ui.document:getHeaderHeight()
    end

    -- Add the custom extra offset from settings on top of the native offset
    self.dogear_y_offset = self.dogear_y_offset + (self.custom_y_offset or DOGEAR_Y_OFFSET)

    -- Update component heights and positioning
    if self[1] then
        self[1].dimen.h    = self.dogear_y_offset + self.dogear_size
        self.top_pad.width = self.dogear_y_offset
        self.vgroup:resetLayout()
    end
end

-- ============================================================
-- Repaint dogear on top of ReaderView.paintTo so it always
-- appears above other patches that draw into the framebuffer
-- (e.g. reader-header-print-edition).
-- ============================================================

local ReaderView = require("apps/reader/modules/readerview")
local _ReaderView_paintTo_orig = ReaderView.paintTo

ReaderView.paintTo = function(self, bb, x, y)
    _ReaderView_paintTo_orig(self, bb, x, y)
    -- Repaint dogear last so it is never covered by header patches
    if self.dogear_visible and self.dogear then
        self.dogear:paintTo(bb, x, y)
    end
end

