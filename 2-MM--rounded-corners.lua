--[[
User patch for Cover Browser plugin to add rounded corners to book covers
]]--

local userpatch = require("userpatch")
local logger = require("logger")
local IconWidget = require("ui/widget/iconwidget")

local function patchCoverBrowserRoundedCorners(plugin)
    -- Grab Cover Grid mode and the individual Cover Grid items
    local MosaicMenu = require("mosaicmenu")
    local MosaicMenuItem = userpatch.getUpValue(MosaicMenu._updateItemsBuildUI, "MosaicMenuItem")    

    if not MosaicMenuItem then
        logger.err("MosaicMenuItem not found - rounded corners patch may not work correctly")
        return
    end


    -- Load as IconWidget
    local function svg_widget(icon)
        return IconWidget:new{ icon = icon, alpha  = true }
    end


    local icons = {
        tl = "rounded.corner.tl",
        tr = "rounded.corner.tr",
        bl = "rounded.corner.bl",
        br = "rounded.corner.br",
    }

    -- Load corner images as widgets
    local corners = {}
    for k, p in pairs(icons) do
        corners[k] = svg_widget(p)
        if not corners[k] then
            logger.warn("Failed to load SVG: " .. tostring(p))
        end
    end


    local _corner_w, _corner_h
    if corners.tl then
        local sz = corners.tl:getSize() --assume all four SVGs are same size; grab once
        _corner_w, _corner_h = sz.w, sz.h
    end

    -- Store original MosaicMenuItem paintTo method
    local originalMosaicMenuItemPaintTo = MosaicMenuItem.paintTo
    
    -- Override paintTo method to add rounded corners
    function MosaicMenuItem:paintTo(bb, x, y)
        -- First, call the original paintTo method to draw the cover normally
        originalMosaicMenuItemPaintTo(self, bb, x, y)
        
        -- Get the cover image widget (target) and dimensions
        local target = self[1][1][1]
        
        -- ==== NEW: ADD round corners to all books ====
        -- =============================================
        
        -- Paint SVG rounded corners over the OUTER frame (covers the rectangular border)
        if target and target.dimen and corners and corners.tl and not self.is_directory then
            -- OUTER frame rect (includes the frame border)
            local fx = x + math.floor((self.width  - target.dimen.w) / 2)
            local fy = y + math.floor((self.height - target.dimen.h) / 2)
            local fw, fh = target.dimen.w, target.dimen.h

            -- Pick widgets
            local TL, TR, BL, BR = corners.tl, corners.tr, corners.bl, corners.br
            
            -- Helper to get size for IconWidget (getSize)
            local function _sz(w)
                if w.getSize then local s = w:getSize(); return s.w, s.h end
                if w.getWidth then return w:getWidth(), w:getHeight() end
                return 0, 0
            end
            local tlw, tlh = _sz(TL)
            local trw, trh = _sz(TR)
            local blw, blh = _sz(BL)
            local brw, brh = _sz(BR)

            -- Top-left
            --if TL.paintTo then TL:paintTo(bb, fx, fy) else bb:blitFrom(TL, fx, fy) end
            -- Top-right
            if TR.paintTo then TR:paintTo(bb, fx + fw - trw, fy) else bb:blitFrom(TR, fx + fw - trw, fy) end
            -- Bottom-left
            --if BL.paintTo then BL:paintTo(bb, fx, fy + fh - blh) else bb:blitFrom(BL, fx, fy + fh - blh) end
            -- Bottom-right
            if BR.paintTo then BR:paintTo(bb, fx + fw - brw, fy + fh - brh) else bb:blitFrom(BR, fx + fw - brw, fy + fh - rh) end
        end
    end

    logger.info("Cover Browser rounded corners patch applied successfully")
end

userpatch.registerPatchPluginFunc("coverbrowser", patchCoverBrowserRoundedCorners)