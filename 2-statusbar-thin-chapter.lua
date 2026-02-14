local BD = require("ui/bidi")
local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Geom = require("ui/geometry")
local Math = require("optmath")
local ProgressWidget = require("ui/widget/progresswidget")
local ReaderFooter = require("apps/reader/modules/readerfooter")
local ReaderToc = require("apps/reader/modules/readertoc")
local T = require("ffi/util").template
local _ = require("gettext")

local Screen = Device.screen
local userpatch = require("userpatch")
local initial_marker_height_threshold = userpatch.getUpValue(ProgressWidget.paintTo, "INITIAL_MARKER_HEIGHT_THRESHOLD")

local logger = require("logger")

function ProgressWidget:paintTo(bb, x, y)
    local my_size = self:getSize()

    -- same bar height if thin_ticks, need extra space for the taller markers
    local dy = self.thin_ticks and (Screen:scaleBySize(1) / 2) or 0
    my_size.h = my_size.h + dy * 2

    if not self.dimen then
        self.dimen = Geom:new {
            x = x,
            y = y,
            w = my_size.w,
            h = my_size.h,
        }
    else
        self.dimen.x = x
        self.dimen.y = y
        self.dimen.w = my_size.w
        self.dimen.h = my_size.h
    end
    if self.dimen.w == 0 or self.dimen.h == 0 then return end

    local _mirroredUI = BD.mirroredUILayout()
    -- We'll draw every bar element in order, bottom to top.
    local fill_width = my_size.w - 2 * (self.margin_h + self.bordersize)
    local fill_y = y + self.margin_v + self.bordersize
    local fill_height = my_size.h - 2 * (self.margin_v + self.bordersize)

    if self.radius == 0 then
        -- If we don't have rounded borders, we can start with a simple border colored rectangle.
        bb:paintRect(x, y + dy, my_size.w, my_size.h - dy * 2, self.bordercolor)

        -- And a full background bar inside (i.e., on top) of that.
        bb:paintRect(
            x + self.margin_h + self.bordersize,
            fill_y + dy,
            math.ceil(fill_width),
            math.ceil(fill_height) - dy * 2,
            self.bgcolor
        )
    else
        -- Otherwise, we have to start with the background.
        bb:paintRoundedRect(x, y, my_size.w, my_size.h, self.bgcolor, self.radius)
        -- Then the border around that.
        bb:paintBorder(
            math.floor(x),
            math.floor(y),
            my_size.w,
            my_size.h,
            self.bordersize,
            self.bordercolor,
            self.radius
        )
    end

    -- Then we can just paint the fill rectangle(s) and tick(s) on top of that.
    -- First the fill bar(s)...
    -- Fill bar for alternate pages (e.g. non-linear flows).
    if self.alt and self.alt[1] ~= nil then
        for i = 1, #self.alt do
            local tick_x = fill_width * ((self.alt[i][1] - 1) / self.last)
            local width = fill_width * (self.alt[i][2] / self.last)
            if _mirroredUI then tick_x = fill_width - tick_x - width end
            tick_x = math.floor(tick_x)
            width = math.ceil(width)

            bb:paintRect(
                x + self.margin_h + self.bordersize + tick_x,
                fill_y + dy,
                width,
                math.ceil(fill_height) - dy * 2,
                self.altcolor
            )
        end
    end

    -- Main fill bar for the specified percentage.
    if self.percentage >= 0 and self.percentage <= 1 then
        local fill_x = x + self.margin_h + self.bordersize
        if self.fill_from_right or (_mirroredUI and not self.fill_from_right) then
            fill_x = fill_x + (fill_width * (1 - self.percentage))
            fill_x = math.floor(fill_x)
        end

        bb:paintRect(
            fill_x,
            fill_y + dy,
            math.ceil(fill_width * self.percentage),
            math.ceil(fill_height) - dy * 2,
            self.fillcolor
        )

        -- Overlay the initial position marker on top of that
        if self.initial_pos_marker and self.initial_percentage >= 0 then
            if self.height <= initial_marker_height_threshold then
                self.initial_pos_icon:paintTo(
                    bb,
                    Math.round(fill_x + math.ceil(fill_width * self.initial_percentage) - self.height / 4),
                    y - Math.round(self.height / 6)
                )
            else
                self.initial_pos_icon:paintTo(
                    bb,
                    Math.round(fill_x + math.ceil(fill_width * self.initial_percentage) - self.height / 2),
                    y
                )
            end
        end
    end

    -- ...then the tick(s).
    if self.ticks and self.last and self.last > 0 then
        local filled = math.floor(fill_width * self.percentage)
        for i, tick in ipairs(self.ticks) do
            local tick_x = fill_width * (tick / self.last)
            if _mirroredUI then tick_x = fill_width - tick_x end
            tick_x = math.floor(tick_x)
            -- color depend on the tick placment: white if it's read, black if after
            local color = (self.thin_ticks and (tick_x < filled)) and Blitbuffer.COLOR_WHITE or self.bordercolor
            bb:paintRect(
                x + self.margin_h + self.bordersize + tick_x,
                fill_y,
                self.tick_width,
                math.ceil(fill_height),
                color
            )
        end
    end
end

local orig_ReaderFooter_setTocMarkers = ReaderFooter.setTocMarkers
local orig_ReaderToc_getTocTicks = ReaderToc.getTocTicks
local was_thin_ticks

ReaderFooter.setTocMarkers = function(self, reset)
    self.progress_bar.thin_ticks = self.settings.progress_style_thin and self.settings.toc_markers -- check ProgressWidget.paintTo

    local force_reset = false
    if self.progress_bar.thin_ticks ~= was_thin_ticks then
        self.ui.toc.ticks_flattened = nil
        force_reset = true
    end
    was_thin_ticks = self.progress_bar.thin_ticks

    if self.progress_bar.thin_ticks then -- force TOC to level 1 to avoid cluttering the status bar
        ReaderToc.getTocTicks = function(self, level) return { orig_ReaderToc_getTocTicks(self, 1) } end
    end

    local save_thin_setting = self.settings.progress_style_thin
    self.settings.progress_style_thin = false -- prevent premature exit

    orig_ReaderFooter_setTocMarkers(self, reset or force_reset)

    self.settings.progress_style_thin = save_thin_setting
    ReaderToc.getTocTicks = orig_ReaderToc_getTocTicks
end

local function patch_menu_item(attrib_name, replacement, menu, ...)
    local function find_sub_item(sub_items, text)
        local find_text
        if type(text) == "table" then
            local set = {}
            for _, t in ipairs(text) do
                set[t] = true
            end
            find_text = function(a_text) return set[a_text] end
        else
            find_text = function(a_text) return a_text == text end
        end
        for _, item in ipairs(sub_items) do
            local item_text = item.text or (item.text_func and item.text_func())
            if item_text and find_text(item_text) then
                -- logger.info("Found item", item_text)
                return item
            end
        end
    end

    local function find_item_from_path(menu, path)
        local sub_items, item
        for _, text in ipairs(path) do
            sub_items = (item or menu).sub_item_table
            if not sub_items then return end
            item = find_sub_item(sub_items, text)
            if not item then return end
        end
        return item
    end

    local item = find_item_from_path(menu, { ... })
    if item and item[attrib_name] then
        item[attrib_name] = replacement
        local path = { ... }
        for i, t in ipairs(path) do
            if type(t) == "table" then path[i] = table.concat(t, " | ") end
        end
        logger.info("Patch", attrib_name, "in '", table.concat(path, " > "), "'")
    end
end

local orig_ReaderFooter_addToMainMenu = ReaderFooter.addToMainMenu

ReaderFooter.addToMainMenu = function(self, menu_items)
    orig_ReaderFooter_addToMainMenu(self, menu_items)

    patch_menu_item(
        "callback",
        function()
            self.settings.progress_style_thin = true
            local bar_height = self.settings.progress_style_thin_height
            self.progress_bar:updateStyle(false, bar_height)
            self:setTocMarkers()
            self:refreshFooter(true, true)
        end,
        menu_items.status_bar,
        _("Progress bar"),
        { _("Thickness and height: thin"), _("Thickness and height: thick") },
        _("Thin")
    )

    patch_menu_item(
        "enabled_func",
        function() return not self.settings.chapter_progress_bar and not self.settings.disable_progress_bar end,
        menu_items.status_bar,
        _("Progress bar"),
        _("Show chapter markers")
    )

    patch_menu_item(
        "enabled_func",
        function()
            return not self.settings.chapter_progress_bar
                and self.settings.toc_markers
                and not self.settings.disable_progress_bar
        end,
        menu_items.status_bar,
        _("Progress bar"),
        T(_("Chapter marker width: %1"), self:genProgressBarChapterMarkerWidthMenuItems())
    )
end
