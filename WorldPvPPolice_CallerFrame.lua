-- WorldPvPPolice_CallerFrame.lua — « Ton appel » : ce que voit celui qui a appelé, tant que son appel
-- est en cours (spec docs/specs/appel-a-l-aide.md, « Ce qu'on veut » 3 et 6 ; critères 11 et 13).
--
-- Le numéro, les morts, où en est la ligne Discord (envoyée seulement quand elle est revenue en jeu,
-- D16), qui est en route, et le bouton « C'est réglé ». Elle reste après « Libérer l'esprit », quand
-- l'encart de la mort a disparu : c'est là que l'appelant voit si son appel est parti. Elle se ferme
-- d'elle-même quand l'appel expire (D11). En tête de la pile de _AlertFrame.lua, déplaçable comme elle.
-- Sa case de message (D18) met l'appel à jour sans mourir : en fantôme, après une déco-reco. Mort,
-- l'encart a la sienne : une seule case à l'écran, « Ton appel » rétrécit (user, 2026-10-28).
local _, NS = ...
local L = NS.L

local CallerFrame = {}
NS.CallerFrame = CallerFrame

local HEIGHT, COMPACT = 128, 100
local MAX_MESSAGE_BYTES = 120   -- comme la case de l'encart (_Panel.lua)

local function buildMessageBox(f)
    local box = CreateFrame("EditBox", "WorldPvPPoliceCallerMessage", f, "InputBoxInstructionsTemplate")
    box:SetSize(NS.AlertFrame.WIDTH - 170, 22)
    box:SetPoint("BOTTOMLEFT", 28, 42)
    box:SetAutoFocus(false)
    box:SetMaxBytes(MAX_MESSAGE_BYTES)
    box.Instructions:SetText(L["Message (facultatif)"])
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        CallerFrame:Send()
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

function CallerFrame:Build()
    if self.frame then return self.frame end
    local AF = NS.AlertFrame
    local f = AF:Window(HEIGHT)
    f:SetPoint("TOP", AF:Pile(), "TOP")
    f.title = AF.Text(f, "GameFontNormal", nil, -18)
    f.status = AF.Text(f, "GameFontHighlightSmall", f.title, -4)
    f.enRoute = AF.Text(f, "GameFontHighlightSmall", f.status, -2)
    f.box = buildMessageBox(f)
    f.update = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.update:SetSize(110, 22)
    f.update:SetPoint("LEFT", f.box, "RIGHT", 8, 0)
    f.update:SetText(L["Mettre à jour"])
    f.update:SetScript("OnClick", function() CallerFrame:Send() end)
    f.settle = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.settle:SetSize(120, 22)
    f.settle:SetPoint("BOTTOMRIGHT", -18, 14)
    f.settle:SetText(L["C'est réglé"])
    f.settle:SetScript("OnClick", function() CallerFrame:Settle() end)
    self.frame = f
    return f
end

local function count(set)
    local n = 0
    for _ in pairs(set or {}) do n = n + 1 end
    return n
end

-- « Envoyé » seulement si la dernière ligne revenue en jeu (D16) est celle de l'appel tel qu'il est :
-- une mort notée ou un message changé depuis, et Discord n'est plus à jour. Le délai de 2 minutes
-- entre deux lignes se compte devant le joueur ; passé, il faut un geste (« Mettre à jour »).
local function discordState(a)
    if a.pending then return L["Discord : envoi en cours"] end
    local line = NS.Call:CurrentLine(a)
    if a.discordSig and (not line or a.discordSig == line) then return L["Discord : envoyé"] end
    if not NS.Discord.Stream() then return L["Discord : non relié"] end
    local wait = NS.Call:DiscordWait(a)
    if wait > 0 then return string.format(L["Discord : dans %d s"], wait) end
    return a.discordSig and L["Discord : pas à jour"] or L["Discord : pas envoyé"]
end

-- La case suit le message de l'appel quand il change (envoyé d'ici ou de l'encart, repris après un
-- /reload), sans écraser ce que le joueur est en train d'écrire.
local function fillBox(f, a)
    if a.msg == f.msgShown or f.box:HasFocus() then return end
    f.box:SetText(a.msg or "")
    f.msgShown = a.msg
end

local function fill(f, a)
    f.title:SetText(string.format(L["Ton appel n°%d"], a.n))
    f.status:SetText(string.format(L["Morts : %d"], count(a.deaths)) .. " · " .. discordState(a))
    local names = {}
    for i, r in ipairs(a.enRoute or {}) do names[i] = r.name end
    if #names > 0 then
        f.enRoute:SetText(string.format(L["En route : %s"], table.concat(names, ", ")))
    else
        f.enRoute:SetText(L["Personne en route pour l'instant"])
    end
    fillBox(f, a)
end

-- Mort, l'encart (_Panel.lua) est sous la fenêtre de mort avec SA case : la nôtre se cache, et la
-- fenêtre rétrécit (les alertes, accrochées à son bas, remontent d'elles-mêmes).
local function encartShown()
    local P = NS.Panel
    return (P and P.frame and P.frame:IsShown()) and true or false
end

local function setCompact(f, compact)
    if f.compact == compact then return end
    f.compact = compact
    f:SetHeight(compact and COMPACT or HEIGHT)
    if compact then
        f.box:ClearFocus()
        f.box:Hide()
        f.update:Hide()
    else
        f.box:Show()
        f.update:Show()
    end
end

-- Montre, met à jour ou cache la fenêtre selon l'appel en cours ; la pile des alertes se replace
-- quand elle apparaît ou disparaît.
function CallerFrame:Update()
    local a = NS.Call:IsActive() and NS.Call.active
    local was = self:Shown()
    if a then
        local f = self:Build()
        fill(f, a)
        setCompact(f, encartShown())
        f:Show()
    elseif self.frame then
        self.frame:Hide()
    end
    if was ~= self:Shown() then NS.AlertFrame:Layout() end
end

function CallerFrame:Shown()
    return self.frame and self.frame:IsShown() and self.frame or nil
end

-- « Mettre à jour » ou Entrée (un geste) : le message de la case part avec l'appel (NS.Call:UpdateMessage).
-- Mort, l'encart est là aussi : sa case suit, sinon « Libérer » renverrait l'ancien message.
function CallerFrame:Send()
    if not self.frame then return end
    NS.Call:UpdateMessage(self.frame.box:GetText() or "")
    if NS.Panel and NS.Panel.frame and NS.Panel.frame:IsShown() then NS.Panel:SyncBox(true) end
    self:Update()
end

-- « C'est réglé » (un geste) : END à la guilde et sur Discord, l'appel est clos (NS.Call:Settle).
function CallerFrame:Settle()
    NS.Call:Settle()
    self:Update()
end

-- Un « J'arrive » reçu pour mon appel, un envoi qui part : la fenêtre suit sans attendre le passage
-- suivant de la pile.
NS.Call.onChange = function() CallerFrame:Update() end
