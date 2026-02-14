--[[
Overrides ui/widget/container/underlinecontainer
]]--

local userpatch = require("userpatch")
local logger = require("logger")

local BD = require("ui/bidi")
local Blitbuffer = require("ffi/blitbuffer")
local Geom = require("ui/geometry")
local Size = require("ui/size")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

local UnderlineContainer = WidgetContainer:extend{
    linesize = Size.line.thick,
    padding = 0.8,
    color = Blitbuffer.COLOR_WHITE,
    vertical_align = "top",
    line_width = nil,
}

function UnderlineContainer:getSize()
    local contentSize = self[1]:getSize()
    return Geom:new{
        w = contentSize.w,
        h = contentSize.h + self.linesize + 2 * self.padding
    }
end

function UnderlineContainer:paintTo(bb, x, y)
    local container_size = self:getSize()

    if not self.dimen then
        self.dimen = Geom:new{
            x = x, y = y,
            w = container_size.w,
            h = container_size.h
        }
    else
        self.dimen.x = x
        self.dimen.y = y
    end

    local line_width = self.line_width or self.dimen.w
    local line_x = x
    if BD.mirroredUILayout() then
        line_x = line_x + self.dimen.w - line_width
    end

    local content_size = self[1]:getSize()
    local p_y = y
    if self.vertical_align == "center" then
        p_y = math.floor((container_size.h - content_size.h) / 2) + y
    elseif self.vertical_align == "bottom" then
        p_y = (container_size.h - content_size.h) + y
    end

    self[1]:paintTo(bb, x, p_y)

    bb:hatchRect(
        line_x,
        y + container_size.h - self.linesize,
        line_width,
        self.linesize,
        6,
        self.color
    )
end

-- WRAP new() TO OVERRIDE CALL-SITE VALUES
local _old_new = UnderlineContainer.new
function UnderlineContainer:new(o)
    o = o or {}

    -- Force your padding, ignoring mosaicmenu.lua
    o.padding = 0.8

    return _old_new(self, o)
end

package.loaded["ui/widget/container/underlinecontainer"] = UnderlineContainer
return UnderlineContainer
