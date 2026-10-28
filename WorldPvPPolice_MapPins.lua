-- WorldPvPPolice_MapPins.lua — les appels reçus sur la grande carte, et « Voir sur la carte » (user,
-- 2026-10-28, sur capture : « deux boutons, un J'arrive et un autre voir localisation, qui ouvre la map
-- et montre là où c'est »).
--
-- « Voir sur la carte » ouvre la carte du monde sur la zone de l'appel (OpenWorldMap de Blizzard :
-- ShowUIPanel, qui ne propage pas le taint, skill wow-forever-api) sans poser de point de route ni
-- prévenir personne : regarder avant de s'engager. Chaque appel reçu avec des coordonnées a son repère
-- sur la carte de SA zone (une tête de mort, plus grande pour celui qu'on vient de demander), aussi
-- quand le joueur ouvre la carte lui-même. Méthode de LeyLines_WorldMap.lua, vue en jeu sur Forever :
-- des cadres enfants du canevas, au-dessus de la bande des points de Blizzard (2000+), taille
-- compensée par l'échelle LUE SUR LE CANEVAS (GetCanvasScale ment), replacés pendant que la carte est
-- ouverte (le zoom n'a pas d'événement).
local _, NS = ...
local L = NS.L

local MapPins = {}
NS.MapPins = MapPins

local SIZE, FOCUS_SIZE = 22, 30
local LEVEL = 2600
local ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"
local EVERY = 0.25

-- Les appels à montrer sur la carte `map` : avec des coordonnées, sur cette carte exactement (pas de
-- report sur la vue du continent, illisible : leçon de LeyLines).
function MapPins.On(map, alerts)
    local out = {}
    for _, a in ipairs(alerts or {}) do
        if a.map == map and a.x and a.y then out[#out + 1] = a end
    end
    return out
end

local function canvas() return _G.WorldMapFrame and _G.WorldMapFrame.GetCanvas and _G.WorldMapFrame:GetCanvas() end

function MapPins:Init()
    if self.ready or not canvas() then return self.ready end
    self.ready, self.pins, self.shown = true, {}, {}
    local map = _G.WorldMapFrame
    map:HookScript("OnShow", function() MapPins:Plot() end)
    if map.OnMapChanged then hooksecurefunc(map, "OnMapChanged", function() MapPins:Plot() end) end
    local driver, since = CreateFrame("Frame"), 0
    driver:SetScript("OnUpdate", function(_, elapsed)
        since = since + elapsed
        if since < EVERY then return end
        since = 0
        if map:IsShown() then MapPins:Place() end
    end)
    return true
end

local function tooltip(pin)
    local a = pin.alert
    if not a then return end
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    GameTooltip:AddLine(string.format(L["%s appelle à l'aide !"], a.name), 1, 0.25, 0.25)
    GameTooltip:AddLine(string.format(L["Morts : %d"], a.deaths), 1, 1, 1)
    local killers = NS.AlertFrame and NS.AlertFrame.KillersText(a.killers or {}) or ""
    if killers ~= "" then GameTooltip:AddLine(killers, 1, 1, 1) end
    if a.msg and a.msg ~= "" then GameTooltip:AddLine(string.format(L["« %s »"], a.msg), 1, 0.82, 0, true) end
    GameTooltip:Show()
end

function MapPins:Acquire(i)
    local pin = self.pins[i]
    if pin then return pin end
    pin = CreateFrame("Frame", nil, canvas())
    pin:SetFrameLevel(LEVEL)
    pin.icon = pin:CreateTexture(nil, "OVERLAY")
    pin.icon:SetAllPoints()
    pin.icon:SetTexture(ICON)
    pin:EnableMouse(true)
    pin:SetScript("OnEnter", tooltip)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.pins[i] = pin
    return pin
end

-- Quels repères pour la carte ouverte (au changement de carte, à l'ouverture, quand les appels changent).
function MapPins:Plot()
    if not self.ready then return end
    local map = _G.WorldMapFrame
    local open = map:IsShown() and map.GetMapID and map:GetMapID()
    self.shown = open and MapPins.On(open, NS.Alert:Visible()) or {}
    self:Place()
end

-- Où les poser (suit le zoom) ; cache les repères en trop.
function MapPins:Place()
    if not self.ready then return end
    local c = canvas()
    local raw = c:GetScale()
    local scale = 1 / ((raw and raw > 0) and raw or 1)
    for i, a in ipairs(self.shown) do
        local pin, size = self:Acquire(i), (a.key == self.focus) and FOCUS_SIZE or SIZE
        pin.alert = a
        pin:SetScale(scale)
        pin:SetSize(size, size)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", c, "TOPLEFT", c:GetWidth() * a.x / scale, -(c:GetHeight() * a.y) / scale)
        pin:Show()
    end
    for i = #self.shown + 1, #self.pins do self.pins[i]:Hide() end
end

-- « Voir sur la carte » (un clic) : la carte de la zone de l'appel, son repère mis en avant. Rend true
-- si la carte a pu s'ouvrir.
function MapPins:Show(a)
    if not (a and a.map) or type(_G.OpenWorldMap) ~= "function" then return false end
    self.focus = a.key
    if not pcall(_G.OpenWorldMap, a.map) then return false end
    self:Init()
    self:Plot()
    return true
end
