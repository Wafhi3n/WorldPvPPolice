-- WorldPvPPolice_AlertFrame.lua — les alertes à l'écran quand un guildien appelle à l'aide, et
-- l'écoute des messages d'addon de guilde (spec docs/specs/appel-a-l-aide.md, « Ce qu'on veut » 3 ;
-- critères 7, 11, 13 ; la logique vit dans _Alert.lua).
--
-- Une fenêtre par appel, trois au plus, empilées sous la fenêtre « Ton appel » (_CallerFrame.lua)
-- quand elle est là. Le tout pend à une PILE qu'on déplace en tirant une fenêtre (position gardée
-- pour le compte) : par défaut en haut, DÉCALÉE à droite du centre. La fenêtre de mort de Blizzard
-- (StaticPopup, TOP -135, 320 de large, strate DIALOG au-dessus de la nôtre) cachait sinon « Ton
-- appel » et les alertes, « J'arrive » compris, quand on est mort (relecture api-gotcha-reviewer du
-- 2026-10-28). Jamais de ligne de chat (skill chat-output). En instance (D6), rien à l'écran.
local _, NS = ...
local L = NS.L
local Alert = NS.Alert

local AlertFrame = {}
NS.AlertFrame = AlertFrame

AlertFrame.WIDTH = 340
local HEIGHT, GAP = 136, 4
local DEFAULT_POS = { "TOP", "TOP", 350, -20 }   -- 350 = moitié de la fenêtre de mort + moitié de la nôtre + marge
local TICK = 1   -- s entre deux passages : expiration des alertes, entrée en instance, appel en cours

local function inInstance()
    local ok, inst = pcall(IsInInstance)
    return ok and NS.Line.Readable(inst) and inst == true
end
AlertFrame.InInstance = inInstance   -- « Ton appel » se cache aussi en instance (_CallerFrame.lua, D6)

-- ===== La pile, déplaçable =====

local function savePosition(pile)
    local point, _, relPoint, x, y = pile:GetPoint(1)
    if NS.db and point then NS.db.pile = { point, relPoint, x, y } end
end

function AlertFrame:Pile()
    if self.pile then return self.pile end
    local pile = CreateFrame("Frame", "WorldPvPPolicePile", UIParent)
    pile:SetSize(AlertFrame.WIDTH, 10)
    pile:SetMovable(true)
    pile:SetClampedToScreen(true)
    local pos = NS.db and type(NS.db.pile) == "table" and NS.db.pile or DEFAULT_POS
    pile:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    self.pile = pile
    return pile
end

-- Une fenêtre de la pile se tire à la souris : c'est la pile qui bouge.
function AlertFrame:Draggable(f)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() self:Pile():StartMoving() end)
    f:SetScript("OnDragStop", function()
        local pile = self:Pile()
        pile:StopMovingOrSizing()
        savePosition(pile)
    end)
end

-- Un cadre de la pile : fond de dialogue de Blizzard, au-dessus du jeu, déplaçable.
function AlertFrame:Window(height)
    local f = CreateFrame("Frame", nil, self:Pile(), "BackdropTemplate")
    f:SetSize(AlertFrame.WIDTH, height)
    f:SetFrameStrata("HIGH")
    if _G.BACKDROP_DIALOG_32_32 then f:SetBackdrop(_G.BACKDROP_DIALOG_32_32) end
    self:Draggable(f)
    f:Hide()
    return f
end

-- Une ligne de texte, sous `rel` (ou en haut du cadre), sur une seule ligne : la hauteur est fixe.
function AlertFrame.Text(parent, template, rel, y, width)
    local fs = parent:CreateFontString(nil, "ARTWORK", template)
    if rel then
        fs:SetPoint("TOPLEFT", rel, "BOTTOMLEFT", 0, y)
    else
        fs:SetPoint("TOPLEFT", 20, y)
    end
    fs:SetWidth(width or (AlertFrame.WIDTH - 40))
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    return fs
end

-- ===== Une alerte =====

local function build()
    local f = AlertFrame:Window(HEIGHT)
    local text = AlertFrame.Text
    f.title = text(f, "GameFontNormal", nil, -18)
    f.where = text(f, "GameFontHighlightSmall", f.title, -4)
    f.killers = text(f, "GameFontHighlightSmall", f.where, -2)
    f.msg = text(f, "GameFontHighlightSmall", f.killers, -2)
    f.enRoute = text(f, "GameFontDisableSmall", f.msg, -2)
    f.go = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.go:SetSize(110, 22)
    f.go:SetPoint("BOTTOMRIGHT", -18, 14)
    f.go:SetScript("OnClick", function() Alert:Respond(f.key) end)
    -- « J'arrive » remplace le point de route du joueur et la cible suivie : on le dit au survol.
    f.go:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Prévient la guilde et pose ton point de route sur lui (il remplace le tien)."], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    f.go:SetScript("OnLeave", function() GameTooltip:Hide() end)
    -- « Voir sur la carte » : regarder avant de s'engager, sans rien envoyer (_MapPins.lua).
    f.map = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.map:SetSize(130, 22)
    f.map:SetPoint("RIGHT", f.go, "LEFT", -6, 0)
    f.map:SetText(L["Voir sur la carte"])
    f.map:SetScript("OnClick", function() NS.MapPins:Show(Alert.list[f.key]) end)
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -6, -6)
    f.close:SetScript("OnClick", function() Alert:Dismiss(f.key) end)
    return f
end

local function names(list)
    local out = {}
    for i, r in ipairs(list or {}) do out[i] = r.name end
    return table.concat(out, ", ")
end

-- Les tueurs reçus portent un jeton de classe (ROGUE) : le nom de classe dans MA langue vient du jeu
-- (LOCALIZED_CLASS_NAMES_MALE), pour « Tueur : Xyz (Voleur) ».
local function killersText(killers)
    if #killers == 0 then return "" end
    local names = type(_G.LOCALIZED_CLASS_NAMES_MALE) == "table" and _G.LOCALIZED_CLASS_NAMES_MALE or {}
    local players = {}
    for i, k in ipairs(killers) do
        players[i] = { name = k.name, className = k.class and names[k.class] }
    end
    return NS.Death.KillerText({ status = "player", players = players }, L) or ""
end
AlertFrame.KillersText = killersText   -- l'infobulle des repères de la carte (_MapPins.lua)

local function fill(f, a)
    f.key = a.key
    f.title:SetText(string.format(L["%s appelle à l'aide !"], a.name))
    local where = NS.Death.WhereText({ zone = a.zone, x = a.x, y = a.y }, L)
    f.where:SetText(where .. " · " .. string.format(L["Morts : %d"], a.deaths))
    f.killers:SetText(killersText(a.killers))
    f.msg:SetText(a.msg ~= "" and string.format(L["« %s »"], a.msg) or "")
    local going = names(a.enRoute)
    f.enRoute:SetText(going ~= "" and string.format(L["En route : %s"], going) or "")
    f.go:SetText(a.responded and L["En route"] or L["J'arrive"])
    f.go:SetEnabled(not a.responded)
end

-- Place les alertes visibles sous « Ton appel » (s'il est là) ou en haut de la pile.
function AlertFrame:Layout()
    self.frames = self.frames or {}
    local shown = inInstance() and {} or Alert:Visible()
    local above = NS.CallerFrame and NS.CallerFrame:Shown()
    for i = 1, Alert.MAX_SHOWN do
        local a, f = shown[i], self.frames[i]
        if a then
            f = f or build()
            self.frames[i] = f
            fill(f, a)
            f:ClearAllPoints()
            local rel = self.frames[i - 1] or above
            if rel then f:SetPoint("TOP", rel, "BOTTOM", 0, -GAP) else f:SetPoint("TOP", self:Pile(), "TOP") end
            f:Show()
        elseif f then
            f:Hide()
        end
    end
end

Alert.onChange = function()
    AlertFrame:Layout()
    NS.MapPins:Plot()   -- les repères de la carte suivent les appels reçus
end

-- ===== L'écoute =====
-- Le préfixe s'inscrit pour RECEVOIR (pas pour envoyer). CHAT_MSG_ADDON : préfixe, texte, canal,
-- émetteur. GUILD_ROSTER_UPDATE : la liste de guilde, relue pendant MON appel (D19, _Roster.lua). Un
-- passage par seconde : alertes expirées, entrée ou sortie d'instance, appel en cours, liste de guilde.

if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    pcall(C_ChatInfo.RegisterAddonMessagePrefix, NS.Line.PREFIX)
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("CHAT_MSG_ADDON")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("GUILD_ROSTER_UPDATE")
driver:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_ADDON" then
        Alert:OnMessage(...)
    elseif event == "GUILD_ROSTER_UPDATE" then
        NS.Roster:OnRoster(...)
    else
        NS.MapPins:Init()   -- la carte du monde est là : les repères s'y accrochent
        AlertFrame:Layout()
    end
end)
local since, wasInInstance = 0, nil
driver:SetScript("OnUpdate", function(_, elapsed)
    since = since + elapsed
    if since < TICK then return end
    since = 0
    Alert:Prune()
    NS.Roster:Tick(TICK)
    if NS.CallerFrame then NS.CallerFrame:Update() end
    local inst = inInstance()
    if inst ~= wasInInstance then
        wasInInstance = inst
        AlertFrame:Layout()
    end
end)
