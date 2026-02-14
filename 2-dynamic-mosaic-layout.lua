-- Based on a patch from xiriby but didnt do anything on my Kindle PW SE:
-- https://github.com/xiriby/2-dynamic-mosaic-layout/blob/main/2-dynamic-mosaic-layout.lua

local FileChooser = require("ui/widget/filechooser")
local Device = require("device")

local home_cols_portrait, home_rows_portrait = 4, 3
local home_cols_landscape, home_rows_landscape = 4, 3
local max_cols, max_rows = 4, 3 -- Default: 5x4

local function compute_grid(count)
    local cols, rows
    if count <= 4 then cols, rows = 2, 2
    elseif count <= 6 then cols, rows = 3, 2
    elseif count <= 9 then cols, rows = 3, 3
    elseif count <= 12 then cols, rows = 4, 3
    elseif count <= 16 then cols, rows = 4, 4
    elseif count <= 20 then cols, rows = 5, 4
    else cols, rows = 5, 5 end

    if cols > max_cols then cols = max_cols end
    if rows > max_rows then rows = max_rows end
    return cols, rows
end

local orig_refreshPath = FileChooser.refreshPath
function FileChooser:refreshPath(...)
    -- count items BEFORE building item_table
    local items = self:genItemTableFromPath(self.path or "")
    local count = 0
    for _, item in ipairs(items or {}) do
        if item.text ~= ".." and not item.is_go_up then
            count = count + 1
        end
    end

    local is_home = (self.path == Device.home_dir or self.path == "/" or self.path == "")

    local screen_size = Device.screen:getSize() or {}
    local w, h = screen_size.w or 0, screen_size.h or 0
    local portrait = h >= w

    local cols, rows
    if is_home then
        if portrait then
            cols, rows = home_cols_portrait, home_rows_portrait
        else
            cols, rows = home_cols_landscape, home_rows_landscape
        end
    else
        cols, rows = compute_grid(count)
    end

    -- force the grid BEFORE building widgets
    self.nb_cols = cols
    self.nb_rows = rows
    self.perpage = cols * rows
    self.nb_cols_portrait = cols
    self.nb_rows_portrait = rows
    self.nb_cols_landscape = cols
    self.nb_rows_landscape = rows

    -- now call the original refreshPath (builds the item widgets with new grid)
    orig_refreshPath(self, ...)
    
    print("DYNAMIC GRID:", self.path, count, "items ->", cols, "x", rows)
end
    