-- WorldPvPPolice_Options.lua — la page de l'addon dans Options → AddOns (S6 et S7 de
-- docs/specs/appel-sans-pont-discord.md) : les mêmes réglages que les commandes /wpp.
--
-- Méthode de LeyLines (LeyLines_OptionsPanel.lua, vue en jeu le 2026-10-08, build 70245) : une page
-- « canevas », nos cases faites du modèle du jeu, AUCUN menu déroulant (sur Forever, ouvrir un menu
-- déroulant créé par un addon a fait planter le client, constat C17), pas de `frame.OnDefault` (le
-- « tout par défaut » du jeu ne remet pas nos réglages en silence). Les cases se construisent au
-- premier affichage. Chaque case écrit par NS:SetOption, le chemin des commandes.
local _, NS = ...
local L = NS.L

local Options = {}
NS.OptionsPanel = Options

local ROW = 30

-- Les cases, dans l'ordre. Un module y ajoute les siennes au chargement de ses fichiers, avant le
-- premier affichage, avec `get` et `set` (ses réglages vivent dans SA base).
Options.LIST = {
    { key = "alerts", label = L["Recevoir les appels des guildiens"],
      tip = L["Une fenêtre s'ouvre quand un guildien tué par un joueur appelle à l'aide. Comme /wpp on | off."] },
}

-- Accroché, pas remplacé : le modèle de case peut avoir ses propres scripts de survol.
local function tip(region, title, text)
    region:HookScript("OnEnter", function(owner)
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        GameTooltip:AddLine(text, 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    region:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

function Options:Check(parent, e, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 16, y)
    cb:SetSize(26, 26)
    cb.Text:SetFontObject("GameFontHighlight")
    cb.Text:SetJustifyH("LEFT")
    cb.Text:SetText(e.label)
    cb:SetHitRectInsets(0, -300, 0, 0)   -- le libellé fait partie de la case : survol et clic
    cb:SetScript("OnClick", function(box)
        local on = box:GetChecked() and true or false
        if type(e.set) == "function" then pcall(e.set, on) else NS:SetOption(e.key, on) end
    end)
    tip(cb, e.label, e.tip)
    cb.Load = function(box)
        local v
        if type(e.get) == "function" then v = select(2, pcall(e.get)) else v = NS.db[e.key] end
        box:SetChecked(v == true)
    end
    return cb
end

function Options:Build(f)
    self.controls = {}
    local title = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(NS.TITLE)
    local sub = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetText(L["Réglages communs à tous les personnages du compte."])
    local y = -70
    for _, e in ipairs(self.LIST) do
        self.controls[#self.controls + 1] = self:Check(f, e, y)
        y = y - ROW
    end
    local foot = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    foot:SetPoint("BOTTOMLEFT", 16, 16)
    foot:SetWidth(620)
    foot:SetJustifyH("LEFT")
    foot:SetText(L["Toutes les commandes : /wpp help."])
end

function Options:Refresh()
    for _, c in ipairs(self.controls or {}) do c:Load() end
end

-- `/wpp options`. Hors combat seulement : `Settings.OpenToCategory` passe par une fonction marquée
-- HasRestrictions, et LeyLines ne l'a mesurée que hors combat (2026-10-08).
function Options:Open()
    if InCombatLockdown and InCombatLockdown() then
        NS:Print(L["Les options s'ouvrent hors combat."])
    elseif self.category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(self.category:GetID())
    else
        NS:Print(L["La page d'options n'existe pas sur ce client."])
    end
end

-- Au PLAYER_LOGIN. Sans l'API (autre client), la page n'existe pas et `/wpp options` le dit.
function Options:Register()
    if self.frame or not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end
    local f = CreateFrame("Frame")
    f:Hide()
    f:SetScript("OnShow", function(frame)
        if not Options.controls then Options:Build(frame) end
        Options:Refresh()
    end)
    local category = Settings.RegisterCanvasLayoutCategory(f, NS.TITLE)
    Settings.RegisterAddOnCategory(category)
    self.category, self.frame = category, f
    NS.onOptionChange = function() if f:IsShown() then Options:Refresh() end end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function() Options:Register() end)
