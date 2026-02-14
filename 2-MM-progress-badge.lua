--[[
User patch for Cover Browser plugin to add progress percentage badges in top right corner
]]--

--========================== [[Edit your preferences here]] ================================

local text_size = 0.27   -- Base font size ratio
local move_on_x = 5      -- Push badge left from right edge
local move_on_y = -1     -- Push badge down/up from top edge
local badge_w = 55        -- Badge width 55
local badge_h = 30        -- Badge height 30

--========================================================================================

local userpatch = require("userpatch")
local TextWidget = require("ui/widget/textwidget")
local Font = require("ui/font")
local Screen = require("device").screen
local Blitbuffer = require("ffi/blitbuffer")
local IconWidget = require("ui/widget/iconwidget")

local percent_badge = IconWidget:new{ icon = "percent.badge", alpha = true }

local function patchCoverBrowserProgressPercent(plugin)

    local MosaicMenu = require("mosaicmenu")
    local MosaicMenuItem = userpatch.getUpValue(MosaicMenu._updateItemsBuildUI, "MosaicMenuItem")

    local origMosaicMenuItemPaintTo = MosaicMenuItem.paintTo

    function MosaicMenuItem:paintTo(bb, x, y)
        -- Draw original cover
        origMosaicMenuItemPaintTo(self, bb, x, y)

        local target = self[1][1][1]
        if not target or not target.dimen then return end

        local corner_mark_size = Screen:scaleBySize(20)

        if self.do_hint_opened and self.been_opened and self.percent_finished
           and self.status ~= "complete" and not self.is_directory then

            local percent = math.floor(self.percent_finished * 100)
            local percent_num = string.format("%d", percent)
            local percent_sign = "%"

            local font_size = math.floor(corner_mark_size * text_size)
            local pct_size  = math.floor(font_size * 0.65)

            -- Number widget
            local num_widget = TextWidget:new{
                text = percent_num,
                font_size = font_size,
                face = Font:getFace("cfont", font_size),
                fgcolor = Blitbuffer.COLOR_BLACK,
                bold = true,
            }

            -- Percent sign widget
            local pct_widget = TextWidget:new{
                text = percent_sign,
                font_size = pct_size,
                face = Font:getFace("cfont", pct_size),
                fgcolor = Blitbuffer.COLOR_BLACK,
                bold = true,
            }

            -- Badge geometry
            local BADGE_W  = Screen:scaleBySize(badge_w)
            local BADGE_H  = Screen:scaleBySize(badge_h)
            local INSET_X  = Screen:scaleBySize(move_on_x)
            local INSET_Y  = Screen:scaleBySize(move_on_y)

            local fx = x + math.floor((self.width  - target.dimen.w) / 2)
            local fy = y + math.floor((self.height - target.dimen.h) / 2)
            local fw = target.dimen.w

            percent_badge.width  = BADGE_W
            percent_badge.height = BADGE_H

            local bx = math.floor(fx + fw - BADGE_W - INSET_X)
            local by = math.floor(fy + INSET_Y)

            -- Draw SVG badge
            percent_badge:paintTo(bb, bx, by)

            -- Measure text
            local ns = num_widget:getSize()
            local ps = pct_widget:getSize()

            local total_w = ns.w + ps.w
            local base_x = bx + math.floor((BADGE_W - total_w) / 2)
            local base_y = by + math.floor((BADGE_H - ns.h) / 2)

            -- Visual baseline correction
            base_y = base_y - Screen:scaleBySize(2)

            -- Draw number
            num_widget:paintTo(bb, base_x, base_y)

            -- Draw %
            pct_widget:paintTo(
                bb,
                base_x + ns.w + Screen:scaleBySize(1),
                base_y + math.floor((ns.h - ps.h) / 2)
            )
        end
    end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowserProgressPercent)
