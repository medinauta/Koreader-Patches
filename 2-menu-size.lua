local Device = require("device")
local Screen = Device.screen
local Menu = require("ui/widget/menu")
local TouchMenu = require("ui/widget/touchmenu")
local Size = require("ui/size") --new

local dpi = Screen:getDPI()
Screen:clearDPI()
local dpi_default = Screen:getDPI()
Screen:setDPI(dpi)
local size_ratio = math.min(dpi / dpi_default, 1)

TouchMenu.max_per_page_default = math.floor(TouchMenu.max_per_page_default / size_ratio)
TouchMenu.item_height = Size.item.height_big --Space between menu items, default=30, big=40, large=50 
Menu.items_per_page_default = math.floor(Menu.items_per_page_default / size_ratio)