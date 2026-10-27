-- WorldPvPPolice_CallerFrame.lua — « Ton appel » : ce que voit celui qui a appelé, tant que son appel
-- est en cours (spec docs/specs/appel-a-l-aide.md, « Ce qu'on veut » 3 et 6 ; critères 11 et 13).
--
-- Le numéro, les morts, où en est la ligne Discord (envoyée seulement quand elle est revenue en jeu,
-- D16), qui est en route, et le bouton « C'est réglé ». Elle reste après « Libérer l'esprit », quand
-- l'encart de la mort a disparu : c'est là que l'appelant voit si son appel est parti. Elle se ferme
-- d'elle-même quand l'appel expire (D11). En tête de la pile de _AlertFrame.lua, déplaçable comme elle.
local _, NS = ...
local L = NS.L

local CallerFrame = {}
NS.CallerFrame = CallerFrame

local HEIGHT = 96

function CallerFrame:Build()
    if self.frame then return self.frame end
    local AF = NS.AlertFrame
    local f = AF:Window(HEIGHT)
    f:SetPoint("TOP", AF:Pile(), "TOP")
    f.title = AF.Text(f, "GameFontNormal", nil, -18)
    f.status = AF.Text(f, "GameFontHighlightSmall", f.title, -4)
    f.enRoute = AF.Text(f, "GameFontHighlightSmall", f.status, -2, AF.WIDTH - 170)
    f.settle = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.settle:SetSize(120, 22)
    f.settle:SetPoint("BOTTOMRIGHT", -18, 16)
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

local function discordState(a)
    if a.discordSig then return L["Discord : envoyé"] end
    if a.pending then return L["Discord : envoi en cours"] end
    if not NS.Discord.Stream() then return L["Discord : non relié"] end
    return L["Discord : pas envoyé"]
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
end

-- Montre, met à jour ou cache la fenêtre selon l'appel en cours ; la pile des alertes se replace
-- quand elle apparaît ou disparaît.
function CallerFrame:Update()
    local a = NS.Call:IsActive() and NS.Call.active
    local was = self:Shown()
    if a then
        local f = self:Build()
        fill(f, a)
        f:Show()
    elseif self.frame then
        self.frame:Hide()
    end
    if was ~= self:Shown() then NS.AlertFrame:Layout() end
end

function CallerFrame:Shown()
    return self.frame and self.frame:IsShown() and self.frame or nil
end

-- « C'est réglé » (un geste) : END à la guilde et sur Discord, l'appel est clos (NS.Call:Settle).
function CallerFrame:Settle()
    NS.Call:Settle()
    self:Update()
end

-- Un « J'arrive » reçu pour mon appel, un envoi qui part : la fenêtre suit sans attendre le passage
-- suivant de la pile.
NS.Call.onChange = function() CallerFrame:Update() end
