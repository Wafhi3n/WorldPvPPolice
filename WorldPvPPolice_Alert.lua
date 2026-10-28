-- WorldPvPPolice_Alert.lua — ce qu'on REÇOIT : les appels des guildiens, « J'arrive », « C'est réglé »
-- (spec docs/specs/appel-a-l-aide.md, « Ce qu'on veut » 3 et 6, D6, D11, D12, D14 ; critères 7, 11, 13).
--
-- Logique pure + des sondes (Alert.probe), comme _Death.lua et _Call.lua : les tests remplacent les
-- sondes et l'horloge. Les fenêtres et l'écoute de CHAT_MSG_ADDON vivent dans _AlertFrame.lua.
--
-- QUI EST « MOI » : CHAT_MSG_ADDON ne porte pas de GUID, seulement le nom COMPLET de l'émetteur,
-- « Prénom Nom » sur Forever, « Nom-Royaume » sur Retail (Line). On le compare à nos propres noms
-- complets, jamais au prénom seul (plusieurs joueurs partagent un prénom), et on apprend le nom exact
-- que le serveur nous donne quand notre propre SOS nous revient (un message de guilde revient à son
-- émetteur, mesuré en groupe le 2026-10-05).
local _, NS = ...
local Line = NS.Line

local Alert = {}
NS.Alert = Alert

Alert.EXPIRY = 15 * 60   -- s après la dernière mise à jour reçue (D11, comme l'appelant)
Alert.MAX_SHOWN = 3      -- alertes à l'écran au plus (spec, « Deux appels en même temps »)

Alert.list = {}          -- [émetteur .. "#" .. n] = alerte

local function readable(v) return Line.Readable(v) end
local function isText(v) return readable(v) and type(v) == "string" and v ~= "" end
local function is(v, want) return readable(v) and v == want end   -- jamais `==` sur une secrète

local function returns(ok, ...)
    if not ok then return nil end
    return ...
end

local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    return returns(pcall(fn, ...))
end

local function now(p) return call(p.now) or 0 end

-- Le nom à montrer d'un émetteur : sans royaume ; sur Forever, « Prénom Nom » entier (il n'a pas de
-- royaume, et le nom de famille distingue deux prénoms pareils).
local function displayName(full)
    return full:match("^([^%-]+)") or full
end
Alert.DisplayName = displayName

-- ===== Moi =====

local function addName(set, s)
    if isText(s) then set[s] = true end
end

-- Mes noms complets possibles : GetUnitName("player", true) et UnitFullName("player"), tels quels
-- (« Prénom Nom » sur Forever) et suivis de « -Royaume » (la forme Retail de CHAT_MSG_ADDON).
local function myNames(p)
    local set = {}
    local full = call(p.fullName)
    local name, realm = call(p.unitFull)
    local normalized = call(p.realm)
    for _, base in ipairs({ full, name }) do
        if isText(base) then
            addName(set, base)
            if not base:find("-", 1, true) then
                if isText(realm) then addName(set, base .. "-" .. realm) end
                if isText(normalized) then addName(set, base .. "-" .. normalized) end
            end
        end
    end
    return set
end

function Alert:IsMe(name)
    if not isText(name) then return false end
    if self.selfName == name then return true end
    return myNames(self.probe)[name] == true
end

-- Notre propre message, revenu : reconnu à notre nom, ou à défaut au SOS que l'appel en cours vient
-- d'envoyer (même texte, même numéro) ; dans ce cas le nom de l'émetteur est le nôtre : on l'apprend.
function Alert:IsOwn(m, payload, sender)
    if self:IsMe(sender) then return true end
    local a = NS.Call and NS.Call.active
    if m.kind == "SOS" and a and a.guildSig == payload and a.n == m.n then
        self.selfName = sender
        return true
    end
    return false
end

-- ===== Gardées au /reload (D17) =====
-- Les alertes reçues survivent à un /reload et à une déco-reco, comme l'appel de l'appelant (choix du
-- user, 2026-10-28) : Alert.list est la table même de db.received[GUID du perso], ses heures en
-- secondes réelles (time()). Au retour, celles de plus de EXPIRY tombent au premier Prune.

local function ident(p)
    local db, key = call(p.db), call(p.guid)
    if type(db) == "table" and isText(key) then return db, key end
    return nil
end

local function isAlert(a)
    return type(a) == "table" and isText(a.sender) and type(a.n) == "number" and type(a.map) == "number"
        and type(a.updatedAt) == "number" and type(a.deaths) == "number" and type(a.enRoute) == "table"
end

-- Reprend les alertes gardées, une fois (dès que la base et le GUID sont là). Une alerte reçue avant
-- (tout début de session) s'ajoute à celles gardées ; une entrée abîmée est jetée.
function Alert:Restore()
    if self.restored then return end
    local db, key = ident(self.probe)
    if not db then return end
    self.restored = true
    if type(db.received) ~= "table" then db.received = {} end
    local saved = type(db.received[key]) == "table" and db.received[key] or {}
    for k, a in pairs(saved) do
        if not isAlert(a) or a.key ~= k then saved[k] = nil end
    end
    for k, a in pairs(self.list) do
        if not saved[k] then saved[k] = a end
    end
    self.list = saved
    db.received[key] = saved
end

-- La liste repart à vide (/wpp off) : la base suit.
local function reset(self)
    self.list = {}
    local db, key = ident(self.probe)
    if db and self.restored and type(db.received) == "table" then db.received[key] = self.list end
end

-- ===== Réception =====

local function changed(self, what)
    if type(self.onChange) == "function" then pcall(self.onChange, what) end
end

-- Les alertes plus vieilles que EXPIRY (depuis leur dernière mise à jour) disparaissent.
function Alert:Prune()
    self:Restore()
    local t, gone = now(self.probe), false
    for key, a in pairs(self.list) do
        if t - a.updatedAt >= Alert.EXPIRY then
            self.list[key] = nil
            gone = true
        end
    end
    if gone then changed(self, "expire") end
end

local function zoneOf(p, map)
    local zone = call(p.mapName, map)
    if isText(zone) then return zone end
    return nil
end

-- Un SOS d'un guildien : une alerte, ou la mise à jour de la sienne. Pas en instance (D6), pas si le
-- joueur a coupé les alertes (/wpp off). Un nouveau numéro du même appelant remplace son ancien appel.
function Alert:OnSOS(m, sender)
    local p = self.probe
    if is(call(p.inInstance), true) or is(call(p.alertsOn), false) then return nil end
    local key = sender .. "#" .. m.n
    local a = self.list[key]
    if not a then
        for other, old in pairs(self.list) do
            if old.sender == sender then self.list[other] = nil end
        end
        a = { key = key, sender = sender, name = displayName(sender), n = m.n, enRoute = {} }
        self.list[key] = a
    elseif m.deaths > a.deaths then
        a.dismissed = nil   -- une mort de plus : l'alerte écartée revient
    end
    a.map, a.x, a.y, a.zone = m.map, m.x, m.y, zoneOf(p, m.map)
    a.deaths, a.killers, a.msg = m.deaths, m.killers or {}, m.msg
    a.updatedAt = now(p)
    return a
end

local function addEnRoute(list, sender)
    for _, r in ipairs(list) do
        if r.sender == sender then return false end
    end
    list[#list + 1] = { sender = sender, name = displayName(sender) }
    return true
end
Alert.AddEnRoute = addEnRoute

-- Un « J'arrive » : pour MON appel, la liste « en route » de l'appelant (_Call) ; pour celui d'un
-- autre guildien, la liste de son alerte (on voit qui y va déjà).
function Alert:OnOMW(m, sender)
    if self:IsMe(m.caller) then
        return NS.Call and NS.Call:AddResponder(m.n, sender) and "responder" or nil
    end
    local a = self.list[m.caller .. "#" .. m.n]
    if a and addEnRoute(a.enRoute, sender) then return "enroute" end
    return nil
end

-- Un message d'addon de guilde (CHAT_MSG_ADDON : préfixe, texte, canal, émetteur). Rend ce qui a
-- changé ("new", "update", "enroute", "responder", "end", "self") ou nil. Jamais de ligne de chat.
function Alert:OnMessage(prefix, payload, channel, sender)
    if not (isText(prefix) and prefix == Line.PREFIX and isText(channel) and channel == "GUILD") then
        return nil
    end
    if not (isText(payload) and isText(sender)) then return nil end
    local m = Line.Decode(payload)
    if not m then return nil end
    if self:IsOwn(m, payload, sender) then return "self" end
    self:Prune()
    local what
    if m.kind == "SOS" then
        local had = self.list[sender .. "#" .. m.n] ~= nil
        if self:OnSOS(m, sender) then what = had and "update" or "new" end
    elseif m.kind == "OMW" then
        what = self:OnOMW(m, sender)
    elseif self.list[sender .. "#" .. m.n] then
        self.list[sender .. "#" .. m.n] = nil
        what = "end"
    end
    if what then changed(self, what) end
    return what
end

-- ===== Ce qu'on montre =====

-- Les alertes à l'écran : non écartées, les plus récentes d'abord, MAX_SHOWN au plus.
function Alert:Visible()
    self:Restore()
    local out = {}
    for _, a in pairs(self.list) do
        if not a.dismissed then out[#out + 1] = a end
    end
    table.sort(out, function(x, y) return x.updatedAt > y.updatedAt end)
    for i = #out, Alert.MAX_SHOWN + 1, -1 do out[i] = nil end
    return out
end

function Alert:Dismiss(key)
    local a = self.list[key]
    if a then
        a.dismissed = true
        changed(self, "dismiss")
    end
end

-- /wpp off : plus rien à l'écran.
function Alert:Clear()
    reset(self)
    changed(self, "clear")
end

-- ===== « J'arrive » (un geste) =====

-- Prévient la guilde (l'appelant reconnaît son nom complet) et le fil Discord (D12, la ligne
-- « OMW <moi> > <appelant> #SOS<n> », sans suivi de son retour : rien n'en dépend), pose un point de
-- route sur le cadavre s'il a des coordonnées (pas en zone seule, D14). Rend { guild, discord,
-- waypoint } ou nil si l'alerte n'existe plus.
function Alert:Respond(key)
    local a = self.list[key]
    if not a then return nil end
    local p = self.probe
    local report = { guild = "failed", discord = "none", waypoint = false }
    local payload = Line.EncodeOMW(a.n, a.sender)
    local result = payload and call(p.sendGuild, payload)
    if is(result, 0) or is(result, true) then report.guild = "sent" end
    local club, stream = call(p.stream)
    local line = club and Line.BuildOMW(call(p.me), a.sender, a.n)
    if line then report.discord = pcall(p.sendDiscord, club, stream, line) and "sent" or "failed" end
    if a.x and a.y then report.waypoint = is(call(p.setWaypoint, a.map, a.x, a.y), true) end
    a.responded = true
    changed(self, "respond")
    return report
end

-- ===== Sondes du jeu (remplacées par les tests) =====

local function setWaypoint(map, x, y)
    if not C_Map.CanSetUserWaypointOnMap(map) then return false end
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x, y))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
    return true
end

Alert.probe = {
    now         = function() return time() end,   -- secondes réelles : les alertes survivent au /reload (D17)
    guid        = function() return UnitGUID("player") end,
    db          = function() return NS.db end,
    me          = function() return UnitName("player") end,
    fullName    = function() return GetUnitName("player", true) end,
    unitFull    = function() return UnitFullName("player") end,
    realm       = function() return GetNormalizedRealmName() end,
    inInstance  = function() return (IsInInstance()) end,
    alertsOn    = function() return not (NS.db and NS.db.alerts == false) end,
    mapName     = function(map) local info = C_Map.GetMapInfo(map); return info and info.name end,
    stream      = function() return NS.Discord.Stream() end,
    sendDiscord = function(club, stream, line) C_Club.SendMessage(club, stream, line) end,
    sendGuild   = function(payload) return C_ChatInfo.SendAddonMessage(Line.PREFIX, payload, "GUILD") end,
    setWaypoint = setWaypoint,
}
