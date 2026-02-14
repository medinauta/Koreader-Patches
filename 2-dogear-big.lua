--Make Bookmark (Readerdogear) bigger. (Folded page corner image.)
local ReaderDogear = require("apps/reader/modules/readerdogear")
ReaderDogear.init_orig = ReaderDogear.init
ReaderDogear.init = function(self)
    self:init_orig()
    self.dogear_max_size = math.floor(1.8 * self.dogear_max_size)
end
