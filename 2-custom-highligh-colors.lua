local BlitBuffer = require("ffi/blitbuffer")
local ReaderHighlight = require("apps/reader/modules/readerhighlight")
local _ = require("gettext")

ReaderHighlight_orig_colors = ReaderHighlight.highlight_colors
ReaderHighlight.highlight_colors = {
    {_("Red"), "red"},
    {_("Orange"), "orange"},
    {_("Yellow"), "yellow"},
    {_("Green"), "green"},
    {_("Olive"), "olive"},
    {_("Cyan"), "cyan"},
    {_("Blue"), "blue"},
    {_("Purple"), "purple"},
    {_("Pink"), "pink"},  -- Added pink color
    {_("Gray"), "gray"},
}

BlitBuffer_orig_highlight_colors = BlitBuffer.HIGHLIGHT_COLORS
BlitBuffer.HIGHLIGHT_COLORS = {
    ["red"]    = "#FF0000",   -- Updated color from #FF3300
    ["orange"] = "#FFA947",   -- Updated color from #FF8800
    ["yellow"] = "#FFFF00",   -- Updated color from #FFFF33
    ["green"]  = "#00AA66",   -- Unchanged
    ["olive"]  = "#88FF77",   -- Unchanged
    ["cyan"]   = "#00FFEE",   -- Unchanged
    ["blue"]   = "#56A1FC",   -- Updated color from #0066FF
    ["purple"] = "#9500FF",   -- Updated color from #EE00FF
    ["pink"]   = "#FF00E6",   -- Added new color
}