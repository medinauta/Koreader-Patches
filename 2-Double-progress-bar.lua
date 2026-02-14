--[[
ReadMe below. Scroll for settings.
]]--

local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Size = require("ui/size")
local Screen = Device.screen
local ReaderView = require("apps/reader/modules/readerview")
local _ReaderView_paintTo_orig = ReaderView.paintTo
local screen_width = Screen:getWidth()
local screen_height = Screen:getHeight()
local ProgressWidget = require("ui/widget/progresswidget")
local UIManager = require("ui/uimanager")

ReaderView.paintTo = function(self, bb, x, y)
    _ReaderView_paintTo_orig(self, bb, x, y)
--  book info
local pageno = self.state.page or 1 -- Current page
local pages = self.ui.doc_settings.data.doc_pages or 1
local pages_left_book  = pages - pageno
-- chapter info
local toc = self.ui.toc
if not toc then return end -- Skip when ToC module missing
toc:fillToc()
local toc_items = toc.toc
if not toc_items or #toc_items == 0 then return end -- Skip when chapter data is unavailable or empty
local doc = self.ui.document
local pages_chapter
local pages_left
local pages_done

if toc then
    pages_chapter = toc:getChapterPageCount(pageno) or pages
    pages_left = toc:getChapterPagesLeft(pageno) or (doc and doc.getTotalPagesLeft and doc:getTotalPagesLeft(pageno)) or (pages - pageno)
    pages_done = toc:getChapterPagesDone(pageno) or 0
else
    pages_chapter = pages
    pages_left = (doc and doc.getTotalPagesLeft and doc:getTotalPagesLeft(pageno)) or (pages - pageno)
    pages_done = pageno - 1
end

pages_done = pages_done + 1 -- This +1 is to include the page you're looking at.
local page_margins = (self.document and self.document.getPageMargins and self.document:getPageMargins()) or {left = 0}
local BOOK_MARGIN = page_margins.left or 0
local CHAPTER = 0
local BOOK = 1
local ON = true
local OFF = false 
--  colour definitions
local black  = Blitbuffer.COLOR_BLACK
local dark   = Blitbuffer.COLOR_GRAY_4
local light  = Blitbuffer.COLOR_GRAY
local white  = Blitbuffer.COLOR_WHITE

-------------------------------------------
     -- -- --  SETTINGS  -- -- --
-------------------------------------------
local top_bar_type = BOOK -- set as CHAPTER or BOOK
local bottom_bar_type = CHAPTER -- set as CHAPTER or BOOK
local stacked = OFF -- stacks the top bar on the bottom bar
local margin = BOOK_MARGIN -- use BOOK_MARGIN or any numeric value. Margin from sides. Def 20
local gap = 0 -- gap between progress bars.
local radius = 10 -- make the ends a little round.
local prog_bar_thickness = 5 -- progress bar height.
local top_padding = 1 -- for stacked=OFF. negative tucks it in to the device edge. Def was -1
local bottom_padding = 1 -- space between progress bars and bottom edge
--"colour" settings     -- you can change the definitions above
local top_bar_seen_color     = dark
local top_bar_unread_color       = light
local bottom_bar_seen_color  = black
local bottom_bar_unread_color    = light

------------------------------------------------------
-- you don't have to change anything below this line.
------------------------------------------------------
screen_width = Screen:getWidth()
screen_height = Screen:getHeight()

local chapter_percentage = pages_done/pages_chapter
local book_percentage = pageno/pages

local top_bar_percentage
local bottom_bar_percentage

local prog_bar_width =  screen_width - gap - margin*2
local prog_bar_y = screen_height - prog_bar_thickness - bottom_padding

--  compute percentages 
if top_bar_type == CHAPTER then
    top_bar_percentage = chapter_percentage
else
    top_bar_percentage = book_percentage
end

if bottom_bar_type == CHAPTER then
    bottom_bar_percentage = chapter_percentage
else 
    bottom_bar_percentage = book_percentage
end

--  geometry for the bars
local bottom_bar_y    = screen_height - prog_bar_thickness - bottom_padding    
    
if stacked then
    top_bar_y    = bottom_bar_y - prog_bar_thickness - gap   
else
    top_bar_y    = top_padding
end
        
--  create the two widgets
local top_bar = ProgressWidget:new{
    width = prog_bar_width,
    height = prog_bar_thickness,
    percentage = top_bar_percentage,
    margin_v = 0,
    margin_h = 0,
    radius = radius,
    bordersize = 0,
    fillcolor = top_bar_seen_color,
    bgcolor = top_bar_unread_color,
}

local bottom_bar = ProgressWidget:new{
    width = prog_bar_width,
    height = prog_bar_thickness,
    percentage = bottom_bar_percentage,
    margin_v = 0,
    margin_h = 0,
    radius = radius,
    bordersize = 0,
    fillcolor = bottom_bar_seen_color,
    bgcolor = bottom_bar_unread_color,
}
local bottom_bar_x = Screen:getWidth()/ 2 + gap / 2

top_bar:paintTo(bb, margin, top_bar_y)   
bottom_bar:paintTo(bb, margin, bottom_bar_y)   

end


--[[
By default this is for a status bar above and below, with a setting to stack them.
Colour, thicnkess, and margin should be clear, padding is used to 
make one smaller than the other by tucking it away into the device edge,
and can be used to hide one of the bars entirely.


Btw, all settings can be edited within KOReader, under Tools // More tools
// patch management // After setup // [long press the patch name]

It also draws on top of the regular ui, so it doesnt clash with the normal
progress bar. But disable auto-refresh, as any refresh causes it to 
temporarily draw above the new bars. I just make them the same height and 
progress type so that the occasional overlaps aren't confusing, as even a
status bar with no progress bar will overlap occasionally. (Ideally
me or someone can fix this z-fighting eventually)


As of Koreader 25.10 works on Android. Previously tested on Kobo, 
and original fork was confirmed to work on Kindle.
Only supports reflowable documents (not PDF)

Works on PDF now! Cheers Omer-Faruq. If it doesn't render on some PDF
then enable custom TOC and make a chapter.

Note: only grays seem to work for colour definitions.

hugely indebted to zenixlabs for absolutely everything, from  currently removed
patch  (https://github.com/zenixlabs/koreader-frankenpatches-public)

Zenixlan's CREDITS: some outline code for this was borrowed from a user patch made by 
joshua cantara. (https://github.com/joshuacant/KOReader.patches)
]]--
