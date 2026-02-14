-- koreader/patches
-- sdothum - 2016 (c) wtfpl
--
-- plugins/vocabbuilder.koplugin
-- frontend/ui/widget/dictquicklookup.lua
--
-- close dictionary popup on add to vocabulary builder -- all to save one tap! :)

local DataStorage = require("datastorage")
local G_reader_settings = require("luasettings"):open(DataStorage:getDataDir() .. "/settings.reader.lua")
local settings = G_reader_settings:readSetting("vocabulary_builder", {enabled = false, with_context = true})

local UIManager = require("ui/uimanager")
local Event = require("ui/event")
local _ = require("gettext")

local userpatch = require("userpatch")
-- local util = require("util")
userpatch.registerPatchPluginFunc("vocabbuilder", function(plugin)
	-- local onDictButtonsReady = plugin.onDictButtonsReady
	plugin.onDictButtonsReady = function(self, dict_popup, buttons)
		-- onDictButtonsReady(self)

		if settings.enabled then
			-- words are added automatically, no need to add the button
			return
		end
		if dict_popup.is_wiki_fullpage then
			return
		end
		table.insert(buttons, 1, {{
			id = "vocabulary",
			-- text = _("Add to vocabulary builder"),
			text = _("➥ Vocabulary builder"),
			font_bold = false,
			callback = function()
				local book_title = (dict_popup.ui.doc_props and dict_popup.ui.doc_props.display_title) or _("Dictionary lookup")
				dict_popup.ui:handleEvent(Event:new("WordLookedUp", dict_popup.lookupword, book_title, true)) -- is_manual: true
				local button = dict_popup.button_table.button_by_id["vocabulary"]

				if button then
					-- button:disable()
					-- UIManager:setDirty(dict_popup, function()
					-- 	return "ui", button.dimen
					-- end)

					-- close dictionary widget to save the "close" button press!
					UIManager:close(dict_popup)                 -- explicit widget close
					dict_popup:onClose()                        -- trigger scheduled highlight removal
					-- UIManager:sendEvent(Event:new("Close"))  -- more expensive than above 2 calls but feels more future proof :)
				end
			end
		}})
	end
end)

