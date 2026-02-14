-- Confirm before opening a book for the first time

local FileManager = require("apps/filemanager/filemanager")
local ConfirmBox = require("ui/widget/confirmbox")
local UIManager = require("ui/uimanager")
local DocSettings = require("docsettings")
local logger = require("logger")

local unpack = unpack or table.unpack

if not FileManager._confirm_first_open_patched then
    FileManager._confirm_first_open_patched = true
    logger.dbg("[ConfirmFirstOpen] Patching FileManager.openFile")

    local orig_openFile = FileManager.openFile

    FileManager.openFile = function(self, path, ...)
        local args = { ... }

        logger.dbg("[ConfirmFirstOpen] openFile called: " .. tostring(path))

        local ok, has_sidecar = pcall(function()
            return DocSettings:hasSidecarFile(path)
        end)

        if ok and has_sidecar then
            logger.dbg("[ConfirmFirstOpen] Sidecar exists, opening normally")
            return orig_openFile(self, path, unpack(args))
        end

        logger.dbg("[ConfirmFirstOpen] First open detected, showing dialog")

        local dialog
        dialog = ConfirmBox:new{
            title = "First Time Opening This Book",
            text =
                "This book has never been opened on this device.\n\n"
                .. "Opening it now will create reading metadata and start "
                .. "tracking your progress from the beginning.\n\n"
                .. "Do you want to open this book now?",
            ok_text = "Open Book",
            cancel_text = "Cancel",
            ok_callback = function()
                logger.dbg("[ConfirmFirstOpen] User confirmed open")
                UIManager:close(dialog)
                orig_openFile(self, path, unpack(args))
            end,
            cancel_callback = function()
                logger.dbg("[ConfirmFirstOpen] User cancelled open")
                UIManager:close(dialog)
            end,
        }

        UIManager:show(dialog)
        return true
    end
end
