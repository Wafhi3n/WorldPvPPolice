-- WorldPvPPolice_Call.lua — l'appel qui part : l'ouvrir, le mettre à jour, compter les morts, prévenir
-- la guilde (spec docs/specs/appel-a-l-aide.md, « Ce qu'on veut » 2, 4 et 5, D3, D4, D9, D11, D13 ;
-- critère 4). Discord, c'est le module WorldPvPPoliceDiscord, branché sur la prise (_Bridge.lua, S7).
--
-- Logique pure + des sondes (Call.probe) qui seules touchent au jeu, comme _Death.lua : les tests
-- remplacent les sondes et l'horloge.
--
-- DEUX RÈGLES DURES :
--   - Le module est appelé DANS la pile du geste, avec `gesture` : la libération automatique (D13)
--     n'en a pas, et C_Club.SendMessage hors geste, c'est ADDON_ACTION_BLOCKED, que pcall ne voit pas.
--   - On envoie la capture faite MORT (Death.last), jamais une capture refaite à l'envoi : le clic sur
--     « Libérer » et la libération automatique arrivent quand on devient fantôme, et le fantôme est
--     chez la gardienne des âmes, peut-être sur une autre carte.
local _, NS = ...
local Line = NS.Line

local Call = {}
NS.Call = Call

Call.EXPIRY = 30 * 60       -- s après la dernière mise à jour partie (D11, 30 min depuis le 2026-10-28)

local function readable(v) return Line.Readable(v) end

local function returns(ok, ...)
    if not ok then return nil end
    return ...
end

local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    return returns(pcall(fn, ...))
end

local function text(v)
    if readable(v) and type(v) == "string" and v ~= "" then return v end
    return nil
end

local function count(set)
    local n = 0
    for _ in pairs(set) do n = n + 1 end
    return n
end

local function now(p) return call(p.now) or 0 end

-- ===== L'appel en cours =====
-- Call.active = { n, serial (la mort qui l'a ouvert), deaths = { [mort] = true }, snap, killers =
-- { { key = GUID, name, class }, … }, msg, sentAt, guildSig, fusion, enRoute = { { sender, name }, … } },
-- plus les champs que le module y pose (discordAt, discordSig, viaChat).
-- D17 (user, 2026-10-28) : il survit à un /reload et à une déco-reco. C'est la MÊME table que
-- db.calls[GUID du perso] : tout changement est gardé, un reroll n'en hérite pas. Les heures sont donc
-- en secondes réelles (time(), probe.now), pas en GetTime(). Au retour, on le reprend s'il a moins de
-- EXPIRY.

local function ident(p)
    local db, key = call(p.db), text((call(p.guid)))
    if type(db) == "table" and key then return db, key end
    return nil
end

local function keep(self, a)
    local db, key = ident(self.probe)
    if not db then return end
    if type(db.calls) ~= "table" then db.calls = {} end
    db.calls[key] = a
end

local function isCall(a)
    return type(a) == "table" and type(a.n) == "number" and type(a.sentAt) == "number"
        and type(a.deaths) == "table" and type(a.snap) == "table" and type(a.snap.map) == "number"
end

-- Reprend l'appel gardé, une fois (dès que la base et le GUID sont là).
function Call:Restore()
    if self.restored then return end
    local db, key = ident(self.probe)
    if not db then return end
    self.restored = true
    local a = type(db.calls) == "table" and db.calls[key]
    if not a then return end
    if isCall(a) and now(self.probe) - a.sentAt < Call.EXPIRY then
        self.active = a
    else
        db.calls[key] = nil
    end
end

function Call:IsActive()
    self:Restore()
    local a = self.active
    if not a then return false end
    if now(self.probe) - a.sentAt < Call.EXPIRY then return true end
    self.active = nil
    keep(self, nil)
    return false
end

-- Une mort par un joueur (l'encart s'est ouvert) pendant un appel en cours : le compteur monte (D9) et
-- « Ton appel » le montre tout de suite. Rien ne part ici : la mise à jour part avec le geste suivant.
function Call:NoteDeath(serial)
    if not (serial and self:IsActive()) or self.active.deaths[serial] then return end
    self.active.deaths[serial] = true
    self:Changed()
end

-- Le récap relu après coup dit « monstre » : cette mort ne compte plus, sauf celle qui a ouvert l'appel.
function Call:ForgetDeath(serial)
    local a = self.active
    if not (a and serial and serial ~= a.serial and a.deaths[serial]) then return end
    a.deaths[serial] = nil
    self:Changed()
end

-- Le prochain numéro d'appel de CE perso (clé = son GUID), et de quoi le consommer une fois l'appel
-- parti. Il vit dans les SavedVariables du poste : un autre poste repart de 1 (le bot ne reconnaît un
-- numéro que dans la fenêtre de 30 minutes).
local function nextNumber(p)
    local db, key = call(p.db), text((call(p.guid)))
    if type(db) ~= "table" or not key then return nil end
    if type(db.nextCall) ~= "table" then db.nextCall = {} end
    local n = db.nextCall[key]
    if type(n) ~= "number" or n < 1 or n ~= math.floor(n) then n = 1 end
    return n, function() db.nextCall[key] = n + 1 end
end

-- La position de l'appel : celle de cette mort. Sans coordonnées, elle part en zone seule (D14), sauf
-- sur la MÊME carte qu'un point déjà connu de l'appel, qu'on garde : un point dans la bonne zone vaut
-- mieux que la zone seule, mais un point dans la mauvaise zone est pire. Sans carte du tout (rien de
-- lisible), on garde ce qu'on avait.
local function placeOf(a, snap)
    if not (snap and snap.map) then return end
    if snap.x and snap.y then
        a.snap = snap
    elseif not (a.snap and a.snap.x and a.snap.map == snap.map) then
        a.snap = snap
    end
end

-- Les tueurs de l'appel (D15) : ceux de cette mort d'abord, puis ceux des morts d'avant, une fois
-- chacun (par GUID, qui ne part jamais sur le fil), MAX_KILLERS au plus : une équipe qui campe s'y
-- retrouve, les plus récents devant.
local function mergeKillers(a, players)
    local list, seen = {}, {}
    local function add(p)
        local key = p.key or p.name
        if p.name and not seen[key] and #list < Line.MAX_KILLERS then
            seen[key] = true
            list[#list + 1] = { key = p.key, name = p.name, class = p.class }
        end
    end
    for _, p in ipairs(players) do add(p) end
    for _, p in ipairs(a.killers or {}) do add(p) end
    a.killers = list
end

-- Ce que l'appel retient de cette mort : sa position, ses tueurs, son message.
local function absorb(a, state, serial, msg)
    placeOf(a, state.snap)
    local k = state.killer
    mergeKillers(a, k and k.status == "player" and k.players or {})
    a.deaths[serial] = true
    a.msg = Line.Clean(msg)
end

local function fields(a, me)
    local s = a.snap
    return { who = me, n = a.n, map = s.map, zone = s.zone, x = s.x, y = s.y, deaths = count(a.deaths),
             killers = a.killers, msg = a.msg, fusion = a.fusion }
end

-- Les champs de l'appel tel qu'il est (nil sans position) : le module en refait sa ligne, pour dire
-- si ce qu'il a envoyé est encore à jour.
function Call:Fields(a)
    if not (a and a.snap and a.snap.map) then return nil end
    return fields(a, text((call(self.probe.me))))
end

-- ===== La sortie =====

-- Le message d'addon de guilde : pas de geste demandé (D13). Rien si rien n'a changé depuis le
-- dernier (un double clic n'envoie pas deux fois). SendAddonMessage rend 0 quand le message part
-- (Enum.SendAddonMessageResult.Success) ; tout autre retour = pas parti.
function Call:ToGuild(a, payload)
    if a.guildSig == payload then return "same" end
    local result = call(self.probe.sendGuild, payload)
    if not (readable(result) and (result == 0 or result == true)) then return "failed" end
    a.guildSig = payload
    return "sent"
end

-- L'appel tel qu'il est, à la guilde, puis au module s'il y en a un (le geste avec). Rend (compte rendu,
-- parti ?) : parti = la guilde l'a pris, ou quelque chose est sorti chez le module. Le champ F (S5) se
-- décide AVANT le message : c'est lui qui le porte.
function Call:Deliver(a, gesture)
    a.fusion = NS.Bridged("Fusion") == true or nil
    local c = fields(a, text((call(self.probe.me))))
    local payload, why = Line.EncodeSOS(c)
    if not payload then return { err = why }, false end
    local report = { n = a.n, deaths = c.deaths }
    report.guild = self:ToGuild(a, payload)
    local out
    report.discord, report.wait, out = NS.Bridged("Deliver", a, c, gesture)
    return report, report.guild == "sent" or out == true
end

-- L'appel a changé (envoi, quelqu'un en route, réglé) : la fenêtre « Ton appel » (_CallerFrame.lua) suit.
function Call:Changed()
    if type(self.onChange) == "function" then pcall(self.onChange) end
end

-- Le module a la suite d'un envoi « pending » (sa ligne est revenue, ou pas) : l'encart complète son
-- compte rendu (Call.onBridge, _Panel.lua), « Ton appel » suit.
function Call:Notify(state)
    if type(self.onBridge) == "function" then pcall(self.onBridge, state) end
    self:Changed()
end

-- ===== Le geste =====

-- `origin` : "button", "enter", "release" (un clic ou une touche), ou "auto" (la libération
-- automatique, sans geste : la guilde seulement, D13). `state` = la capture faite mort (Death.last),
-- `serial` = la mort en cours. Rend nil si rien n'est à envoyer (libérer sans message, D3), sinon un
-- compte rendu : { n, deaths, guild = "sent"|"same"|"failed", discord, wait } ou { err = "pos"|"num"|… }
-- quand l'appel ne peut pas se construire. `discord`, `wait` = ce que rend le module (nil sans module) ;
-- « pending » se complète plus tard, par Call:Notify(état).
function Call:Send(msg, origin, state, serial)
    if (origin == "release" or origin == "auto") and Line.Clean(msg) == "" then return nil end
    if not (state and serial) then return { err = "state" } end
    local p = self.probe
    local opening = not self:IsActive()
    local a = opening and { deaths = {}, serial = serial } or self.active
    absorb(a, state, serial, msg)
    -- Sans coordonnées, la zone seule part (D14) ; sans carte du tout, il n'y a rien à envoyer.
    if not a.snap then return { err = "pos" } end
    local consume
    if opening then
        a.n, consume = nextNumber(p)
        if not a.n then return { err = "num" } end
    end
    local report, sent = self:Deliver(a, origin ~= "auto")
    if report.err then return report end
    -- L'appel dure 30 minutes après la dernière mise à jour PARTIE (D11) : un double clic qui n'envoie
    -- rien ne le prolonge pas. Un appel dont rien n'est parti n'est pas ouvert, et garde son numéro.
    -- Ce qui sort chez le module compte (une ligne en cours) : sans appel ouvert, sa suite n'aurait rien
    -- à compléter.
    if opening and not sent then return report end
    if opening then
        consume()
        self.active = a
        keep(self, a)
    end
    if sent then a.sentAt = now(p) end
    self:Changed()
    return report
end

-- « Ton appel » (D18) : un nouveau message pour l'appel en cours, sans nouvelle mort (vivant, en
-- fantôme, après une déco-reco). Un clic ou Entrée = un geste : la guilde et le module, comme une
-- mise à jour après une mort ; morts, position et tueurs ne bougent pas. Le même message deux fois
-- n'envoie rien et ne prolonge pas l'appel (D11). Rend nil sans appel en cours, sinon le compte rendu.
function Call:UpdateMessage(msg)
    if not self:IsActive() then return nil end
    local a = self.active
    a.msg = Line.Clean(msg)
    local report, sent = self:Deliver(a, true)
    if sent then a.sentAt = now(self.probe) end
    self:Changed()
    return report
end

-- ===== Ceux qui arrivent, « C'est réglé » =====

-- Un guildien répond « J'arrive » à MON appel numéro `n` (NS.Alert a reconnu mon nom complet) : il entre
-- dans la liste « en route », une fois. Rend true s'il y entre.
function Call:AddResponder(n, sender)
    if not (self:IsActive() and self.active.n == n) then return false end
    local a = self.active
    a.enRoute = a.enRoute or {}
    if not NS.Alert.AddEnRoute(a.enRoute, sender) then return false end
    self:Changed()
    return true
end

-- « C'est réglé » (un geste) : la guilde (« 1 END <n> »), puis le module avec l'appel (il sait si une
-- ligne de cet appel est partie chez lui). L'appel est clos tout de suite chez nous, qu'importe ce qui
-- part. Rend { guild, discord } ou nil.
function Call:Settle()
    if not self:IsActive() then return nil end
    local a, p = self.active, self.probe
    self.active = nil
    keep(self, nil)
    local report = { guild = "failed" }
    local payload = Line.EncodeEND(a.n)
    local result = payload and call(p.sendGuild, payload)
    if readable(result) and (result == 0 or result == true) then report.guild = "sent" end
    report.discord = NS.Bridged("Settle", a)
    self:Changed()
    return report
end

-- ===== Sondes du jeu (remplacées par les tests) =====

Call.probe = {
    now         = function() return time() end,   -- secondes réelles : l'appel survit au /reload (D17)
    me          = function() return UnitName("player") end,
    guid        = function() return UnitGUID("player") end,
    db          = function() return NS.db end,
    sendGuild   = function(payload) return C_ChatInfo.SendAddonMessage(Line.PREFIX, payload, "GUILD") end,
}
