local ReaderMenu = require("apps/reader/modules/readermenu")

local _getTabIndexFromLocation_orig = ReaderMenu._getTabIndexFromLocation
ReaderMenu._getTabIndexFromLocation = function(self, ges) return self.last_tab_index end

local FileManagerMenu = require("apps/filemanager/filemanagermenu")

local _getTabIndexFromLocation_orig = FileManagerMenu._getTabIndexFromLocation
FileManagerMenu._getTabIndexFromLocation = function(self, ges) return self.last_tab_index end