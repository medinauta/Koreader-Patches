local ReaderHighlight = require("apps/reader/modules/readerhighlight")
local Translator = require("ui/translator")
local _ = require("gettext")
local ffiUtil  = require("ffi/util")
local T = ffiUtil.template

ReaderHighlight.onTranslateText = function (self, text, index)
    Translator:showTranslation(text, true, nil,self.ui.doc_settings:readSetting("translator_to_language",G_reader_settings:readSetting("translator_to_language")) , true, index)
end

ReaderHighlight.onTranslateCurrentPage = function (self)
    local x0, y0, x1, y1, page, is_reflow
    if self.ui.rolling then
        x0 = 0
        y0 = 0
        x1 = self.screen_w
        y1 = self.screen_h
    else
        page = self.ui:getCurrentPage()
        is_reflow = self.ui.document.configurable.text_wrap
        self.ui.document.configurable.text_wrap = 0
        local page_boxes = self.ui.document:getTextBoxes(page)
        if page_boxes and page_boxes[1][1].word then
            x0 = page_boxes[1][1].x0
            y0 = page_boxes[1][1].y0
            x1 = page_boxes[#page_boxes][#page_boxes[#page_boxes]].x1
            y1 = page_boxes[#page_boxes][#page_boxes[#page_boxes]].y1
        end
    end
    local res = x0 and self.ui.document:getTextFromPositions({x = x0, y = y0, page = page}, {x = x1, y = y1}, true)
    if self.ui.paging then
        self.ui.document.configurable.text_wrap = is_reflow
    end
    if res and res.text then
        Translator:showTranslation(res.text, false, self.ui.doc_props.language,self.ui.doc_settings:readSetting("translator_to_language",G_reader_settings:readSetting("translator_to_language")))
    end
end

local SUPPORTED_LANGUAGES = {
    -- @translators Many of the names for languages can be conveniently found pre-translated in the relevant language of this Wikipedia article: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
    af = _("Afrikaans"),
    sq = _("Albanian"),
    am = _("Amharic"),
    ar = _("Arabic"),
    hy = _("Armenian"),
    as = _("Assamese"),
    ay = _("Aymara"),
    az = _("Azerbaijani"),
    bm = _("Bambara"),
    eu = _("Basque"),
    be = _("Belarusian"),
    bn = _("Bengali"),
    bho = _("Bhojpuri"),
    bs = _("Bosnian"),
    bg = _("Bulgarian"),
    ca = _("Catalan"),
    ceb = _("Cebuano"),
    zh = _("Chinese (Simplified)"), -- "Simplified Chinese may be specified either by zh-CN or zh"
    zh_TW = _("Chinese (Traditional)"), -- converted to "zh-TW" below
    co = _("Corsican"),
    hr = _("Croatian"),
    cs = _("Czech"),
    da = _("Danish"),
    dv = _("Dhivehi"),
    doi = _("Dogri"),
    nl = _("Dutch"),
    en = _("English"),
    eo = _("Esperanto"),
    et = _("Estonian"),
    ee = _("Ewe"),
    fil = _("Filipino (Tagalog)"),
    fi = _("Finnish"),
    fr = _("French"),
    fy = _("Frisian"),
    gl = _("Galician"),
    ka = _("Georgian"),
    de = _("German"),
    el = _("Greek"),
    gn = _("Guarani"),
    -- @translators Many of the names for languages can be conveniently found pre-translated in the relevant language of this Wikipedia article: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
    gu = _("Gujarati"),
    ht = _("Haitian Creole"),
    ha = _("Hausa"),
    haw = _("Hawaiian"),
    he = _("Hebrew"), -- "Hebrew may be specified either by he or iw"
    hi = _("Hindi"),
    hmn = _("Hmong"),
    hu = _("Hungarian"),
    is = _("Icelandic"),
    ig = _("Igbo"),
    ilo = _("Ilocano"),
    id = _("Indonesian"),
    ga = _("Irish"),
    it = _("Italian"),
    ja = _("Japanese"),
    jw = _("Javanese"),
    -- @translators Many of the names for languages can be conveniently found pre-translated in the relevant language of this Wikipedia article: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
    kn = _("Kannada"),
    kk = _("Kazakh"),
    km = _("Khmer"),
    rw = _("Kinyarwanda"),
    gom = _("Konkani"),
    ko = _("Korean"),
    kri = _("Krio"),
    ku = _("Kurdish"),
    ckb = _("Kurdish (Sorani)"),
    ky = _("Kyrgyz"),
    lo = _("Lao"),
    la = _("Latin"),
    lv = _("Latvian"),
    ln = _("Lingala"),
    lt = _("Lithuanian"),
    lg = _("Luganda"),
    lb = _("Luxembourgish"),
    mk = _("Macedonian"),
    mai = _("Maithili"),
    mg = _("Malagasy"),
    ms = _("Malay"),
    ml = _("Malayalam"),
    mt = _("Maltese"),
    mi = _("Maori"),
    mr = _("Marathi"),
    lus = _("Mizo"),
    mn = _("Mongolian"),
    my = _("Myanmar (Burmese)"),
    ne = _("Nepali"),
    no = _("Norwegian"),
    ny = _("Nyanja (Chichewa)"),
    ["or"] = _("Odia (Oriya)"),
    om = _("Oromo"),
    ps = _("Pashto"),
    fa = _("Persian"),
    pl = _("Polish"),
    pt = _("Portuguese"),
    pa = _("Punjabi"),
    qu = _("Quechua"),
    ro = _("Romanian"),
    ru = _("Russian"),
    sm = _("Samoan"),
    sa = _("Sanskrit"),
    gd = _("Scots Gaelic"),
    nso = _("Sepedi"),
    sr = _("Serbian"),
    st = _("Sesotho"),
    sn = _("Shona"),
    sd = _("Sindhi"),
    si = _("Sinhala (Sinhalese)"),
    sk = _("Slovak"),
    sl = _("Slovenian"),
    so = _("Somali"),
    es = _("Spanish"),
    su = _("Sundanese"),
    sw = _("Swahili"),
    sv = _("Swedish"),
    tl = _("Tagalog (Filipino)"),
    tg = _("Tajik"),
    ta = _("Tamil"),
    tt = _("Tatar"),
    te = _("Telugu"),
    th = _("Thai"),
    ti = _("Tigrinya"),
    ts = _("Tsonga"),
    tr = _("Turkish"),
    tk = _("Turkmen"),
    ak = _("Twi (Akan)"),
    uk = _("Ukrainian"),
    ur = _("Urdu"),
    ug = _("Uyghur"),
    uz = _("Uzbek"),
    vi = _("Vietnamese"),
    cy = _("Welsh"),
    -- @translators Many of the names for languages can be conveniently found pre-translated in the relevant language of this Wikipedia article: https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
    xh = _("Xhosa"),
    yi = _("Yiddish"),
    yo = _("Yoruba"),
    zu = _("Zulu"),
}
-- Fix zh_TW => zh-TW:
SUPPORTED_LANGUAGES["zh-TW"] = SUPPORTED_LANGUAGES["zh_TW"]
SUPPORTED_LANGUAGES["zh_TW"] = nil

TranslatorAddToMainMenuOrig = Translator.genSettingsMenu

local getTargetLanguageForDocument = function()
    local ui = require("apps/reader/readerui").instance


    local lang = ui and ui.doc_settings and ui.doc_settings:readSetting("translator_to_language",G_reader_settings:readSetting("translator_to_language"))

    if not lang then
        -- Fallback to the UI language the user has selected
        lang = G_reader_settings:readSetting("language")
        if lang and lang ~= "" then
            -- convert "zh-CN" and "zh-TW" to "zh"
            lang = lang:match("(.*)-") or lang
            if lang == "C" then
                lang="en"
            end
            lang = lang:lower()

        end
    end
    return lang or "en"
end


Translator.genSettingsMenu = function (self)
    local menu = TranslatorAddToMainMenuOrig(self)

    local ui = require("apps/reader/readerui").instance

    local function genLanguagesItems(setting_name, default_checked_item)
        local items_table = {}
        for lang_key, lang_name in ffiUtil.orderedPairs(SUPPORTED_LANGUAGES) do
            table.insert(items_table, {
                text_func = function()
                    return T("%1 (%2)", lang_name, lang_key)
                end,
                checked_func = function()
                    return lang_key == (ui.doc_settings:readSetting(setting_name) or default_checked_item)
                end,
                callback = function()
                    ui.doc_settings:saveSetting(setting_name, lang_key)
                end,
            })
        end
        return items_table
    end

    if ui.view then
        table.insert(menu.sub_item_table, {
            text_func = function()
                local lang = getTargetLanguageForDocument()

                return T(_("Translate to for this Document: %1"), self:getLanguageName(lang, ""))
            end,
            sub_item_table = genLanguagesItems("translator_to_language", getTargetLanguageForDocument()),
        })
    end

    return menu
end

