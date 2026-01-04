--[[
    Book Spine Effect (Apple Books style)
    based on: https://github.com/advokatb/KOReader-Patches/blob/main/2-pt-book-spine-effect.lua
]]--

local userpatch = require("userpatch")
local logger = require("logger")
local DataStorage = require("datastorage")
local IconWidget = require("ui/widget/iconwidget")
local util = require("util")
local Screen = require("device").screen

------------------------------------------------------------------
-- Internal tuning values (hardcoded)
------------------------------------------------------------------
local spine_width     = 150    -- multiplier: 100 = cover width, 200 = 2x cover width
local spine_intensity = 0.25   -- opacity (0..1)
local spine_offset    = 0      -- horizontal offset from cover left (pixels)
local spine_lightning = true   -- enable lighting/shadow layer

local function patchBookSpineEffect(plugin)
    local MosaicMenu = require("mosaicmenu")
    local MosaicMenuItem = userpatch.getUpValue(
        MosaicMenu._updateItemsBuildUI,
        "MosaicMenuItem"
    )
    if not MosaicMenuItem then return end
    if MosaicMenuItem._spine_effect_patch_applied then return end
    MosaicMenuItem._spine_effect_patch_applied = true

    ------------------------------------------------------------------
    -- Rendering
    ------------------------------------------------------------------
    local data_dir = DataStorage:getDataDir()
    local spine_icon_path   = data_dir .. "/icons/book.spine.png"
    local shadow_icon_path  = data_dir .. "/icons/book.spine.shadow.png"

    local spine_icon_exists  = util.fileExists(spine_icon_path)
    local shadow_icon_exists = util.fileExists(shadow_icon_path)

    local orig_paintTo = MosaicMenuItem.paintTo
    function MosaicMenuItem:paintTo(bb, x, y)
        -- Draw everything
        orig_paintTo(self, bb, x, y)

        if not spine_icon_exists then return end
        if self.is_directory or not self._has_cover_image then return end

        local target = self[1] and self[1][1] and self[1][1][1]
        if not target or not target.dimen then return end

        -- Center cover inside tile
        local fx = x + math.floor((self.width - target.dimen.w) / 2)
        local fy = y + math.floor((self.height - target.dimen.h) / 2)
        local fh = target.dimen.h
        local cover_w = target.dimen.w

        local draw_x = fx + spine_offset

        -- 1) Optional lighting / shadow layer (always full cover width)
        if spine_lightning and shadow_icon_exists then
            IconWidget:new{
                icon = "book.spine.shadow",
                alpha = true,
                opacity = spine_intensity,
                height = fh,
                width  = cover_w,  -- always 100% of cover width
            }:paintTo(bb, fx, fy)
        end

        -- 2) Main spine image (scaled by multiplier)
        local draw_width = math.floor(cover_w * (spine_width / 100))
        draw_width = math.max(1, draw_width)  -- ensure at least 1px

        IconWidget:new{
            icon = "book.spine",
            alpha = true,
            opacity = spine_intensity,
            height = fh,
            width = draw_width,
        }:paintTo(bb, draw_x, fy)
    end

    logger.info("Book Spine Effect: spine + optional lighting loaded")
end

userpatch.registerPatchPluginFunc(
    "coverbrowser",
    patchBookSpineEffect
)
