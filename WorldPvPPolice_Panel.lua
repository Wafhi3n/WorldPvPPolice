-- WorldPvPPolice_Panel.lua — l'encart d'appel sous la fenêtre de mort (spec
-- docs/specs/appel-a-l-aide.md, « Ce qu'on veut » 1 et 2, D2, D4).
--
-- La fenêtre de mort est un StaticPopup de Blizzard (« DEATH » ; « HARDCORE_DEATH » en mode hardcore,
-- où la mort est définitive : pas d'encart). On ne l'écrit JAMAIS : on s'accroche à StaticPopup_Show
-- (hooksecurefunc, après Blizzard) et notre cadre, à nous, s'ancre sous elle. Un champ posé sur la
-- fenêtre ou un script remplacé pourrait gâter « Libérer l'esprit » (mesure M7 au banc).
--
-- L'envoi (bouton Appeler, Entrée, et le clic de « Libérer l'esprit ») est la tâche T3 : ici, le
-- bouton et Entrée passent la main à NS.Call quand il existe. Aucune ligne de chat (skill chat-output).
local _, NS = ...
local L = NS.L

local Panel = {}
NS.Panel = Panel

local WHICH = "DEATH"
local WIDTH, HEIGHT = 330, 128
local MAX_MESSAGE_BYTES = 120   -- la ligne Discord entière tient en 255 octets (NS.Line coupe de toute façon)
local CHECK_EVERY = 0.25        -- s entre deux vérifications « la fenêtre de mort est-elle encore là ? »
local RECAP_RETRY = 1           -- s : le récap peut arriver après la fenêtre ; on le relit une fois

local function deathDialog()
    if not _G.StaticPopup_FindVisible then return nil end
    local ok, dialog = pcall(_G.StaticPopup_FindVisible, WHICH)
    if ok then return dialog end
    return nil
end

local function text(parent, template, anchor, rel, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", template)
    fs:SetPoint("TOP", rel or parent, anchor, 0, y)
    fs:SetWidth(WIDTH - 40)
    return fs
end

local function buildMessageBox(f)
    local box = CreateFrame("EditBox", "WorldPvPPolicePanelMessage", f, "InputBoxInstructionsTemplate")
    box:SetSize(WIDTH - 140, 22)
    box:SetPoint("BOTTOMLEFT", 28, 30)
    box:SetAutoFocus(false)
    box:SetMaxBytes(MAX_MESSAGE_BYTES)
    box.Instructions:SetText(L["Message (facultatif)"])
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        Panel:Call("enter")
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

function Panel:Build()
    if self.frame then return self.frame end
    local f = CreateFrame("Frame", "WorldPvPPolicePanel", UIParent, "BackdropTemplate")
    f:SetSize(WIDTH, HEIGHT)
    f:SetFrameStrata("DIALOG")
    if _G.BACKDROP_DIALOG_32_32 then f:SetBackdrop(_G.BACKDROP_DIALOG_32_32) end
    f:Hide()
    f.title = text(f, "GameFontNormal", "TOP", nil, -18)
    f.title:SetText(L["Appeler la guilde à l'aide ?"])
    f.killer = text(f, "GameFontHighlightSmall", "BOTTOM", f.title, -6)
    f.where = text(f, "GameFontHighlightSmall", "BOTTOM", f.killer, -3)
    f.box = buildMessageBox(f)
    f.call = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.call:SetSize(90, 22)
    f.call:SetPoint("LEFT", f.box, "RIGHT", 8, 0)
    f.call:SetText(L["Appeler"])
    f.call:SetScript("OnClick", function() Panel:Call("button") end)
    f.discord = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    f.discord:SetPoint("BOTTOM", 0, 14)
    local since = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        since = since + elapsed
        if since < CHECK_EVERY then return end
        since = 0
        if not deathDialog() then self:Hide() end
    end)
    self.frame = f
    return f
end

function Panel:Refresh(state)
    local f = self.frame
    if not (f and state) then return end
    f.killer:SetText(NS.Death.KillerText(state.killer, L) or "")
    f.where:SetText(NS.Death.WhereText(state.snap, L))
    if NS.Discord.Stream() then
        f.discord:SetText(L["Discord : relié"])
    else
        f.discord:SetText(L["Discord : non relié (appel en jeu seulement)"])
    end
end

function Panel:ShowUnder(dialog, state)
    local f = self:Build()
    f:ClearAllPoints()
    f:SetPoint("TOP", dialog, "BOTTOM", 0, -2)
    self:Refresh(state)
    f:Show()
end

function Panel:Hide()
    if self.frame then
        self.frame.box:ClearFocus()
        self.frame:Hide()
    end
end

-- Le bouton Appeler et Entrée. L'envoi lui-même est T3 (NS.Call) ; le message est relu ici, au geste.
function Panel:Call(origin)
    if not (self.frame and NS.Call and NS.Call.FromPanel) then return end
    NS.Call:FromPanel(self.frame.box:GetText() or "", origin)
end

-- Le récap a pu arriver après la fenêtre : un tueur devenu « monstre » ferme l'encart, un joueur
-- trouvé s'affiche.
function Panel:Recheck()
    if not (self.frame and self.frame:IsShown()) then return end
    NS.Death:RereadKiller()
    if NS.Death:Offer(NS.Death.last) then
        self:Refresh(NS.Death.last)
    else
        self:Hide()
    end
end

local function onPopupShow(which)
    if which ~= WHICH then return end
    local state = NS.Death:Current()
    local dialog = deathDialog()
    if not (dialog and NS.Death:Offer(state)) then
        Panel:Hide()
        return
    end
    Panel:ShowUnder(dialog, state)
    if state.killer.status == "unknown" and _G.C_Timer then
        _G.C_Timer.After(RECAP_RETRY, function() Panel:Recheck() end)
    end
end

if hooksecurefunc and _G.StaticPopup_Show then
    hooksecurefunc("StaticPopup_Show", onPopupShow)
end

-- PLAYER_DEAD capture la mort (la fenêtre s'ouvre sur le même événement, chez Blizzard) ; libérer ou
-- être ressuscité referme l'encart.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_DEAD")
events:RegisterEvent("PLAYER_ALIVE")
events:RegisterEvent("PLAYER_UNGHOST")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_DEAD" then
        NS.Death:Capture()
    else
        Panel:Hide()
    end
end)
