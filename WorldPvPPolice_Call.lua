-- WorldPvPPolice_Call.lua — l'appel qui part : l'ouvrir, le mettre à jour, compter les morts, écrire
-- dans le fil Discord et à la guilde (spec docs/specs/appel-a-l-aide.md, « Ce qu'on veut » 2, 4 et 5,
-- D3, D4, D9, D11, D13 ; critère 4).
--
-- Logique pure + des sondes (Call.probe) qui seules touchent au jeu, comme _Death.lua : les tests
-- remplacent les sondes et l'horloge.
--
-- TROIS RÈGLES DURES :
--   - C_Club.SendMessage exige un geste du joueur (clic, touche) : hors geste, c'est
--     ADDON_ACTION_BLOCKED, que pcall ne voit PAS. Le chemin sans geste (libération automatique, D13)
--     n'écrit qu'à la guilde, jamais sur Discord.
--   - Une ligne Discord n'est PARTIE que quand elle revient en jeu (CHAT_MSG_GUILD_DISCORD, notre
--     texte, notre GUID ; mesuré sur Forever le 2026-10-10) dans les ECHO_WAIT secondes : un envoi
--     bloqué ne lève rien. D'ici là elle est « en cours » ; sans retour, rien n'est compté (ni délai
--     de 2 minutes, ni « déjà envoyée ») et le geste suivant la renvoie (décision du user, 2026-10-27,
--     après la revue api-gotcha-reviewer).
--   - On envoie la capture faite MORT (Death.last), jamais une capture refaite à l'envoi : le clic sur
--     « Libérer » et la libération automatique arrivent quand on devient fantôme, et le fantôme est
--     chez la gardienne des âmes, peut-être sur une autre carte.
local _, NS = ...
local Line = NS.Line

local Call = {}
NS.Call = Call

Call.EXPIRY = 30 * 60       -- s après la dernière mise à jour partie (D11, 30 min depuis le 2026-10-28)
Call.DISCORD_EVERY = 120    -- s entre deux lignes Discord d'un même appel (morts répétées, critère 4)
Call.ECHO_WAIT = 10         -- s laissées à la ligne Discord pour revenir en jeu (délai jamais mesuré)

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
-- { { key = GUID, name, class }, … }, msg, sentAt, guildSig, discordAt, discordSig, pending, enRoute =
-- { { sender, name }, … } }.
-- D17 (user, 2026-10-28) : il survit à un /reload et à une déco-reco. C'est la MÊME table que
-- db.calls[GUID du perso] : tout changement est gardé, un reroll n'en hérite pas. Les heures sont donc
-- en secondes réelles (time(), probe.now), pas en GetTime(). Au retour, on le reprend s'il a moins de
-- EXPIRY ; sa ligne Discord « en cours » est oubliée (son attente du retour est morte avec le
-- /reload : le geste suivant la renverra).

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
        a.pending = nil
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
             killers = a.killers, msg = a.msg }
end

-- ===== Les deux sorties =====

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

-- La ligne du fil Discord : seulement sur un GESTE, au plus une toutes les DISCORD_EVERY secondes pour
-- un même appel ; une mise à jour retenue part avec le geste suivant (critère 4). Rend (état, attente) ;
-- « pending » = partie sans retour encore : OnEcho la confirme, CheckEcho la déclare perdue.
function Call:ToDiscord(a, c, gesture)
    local p = self.probe
    local club, stream = call(p.stream)
    if not club then return "none" end
    local line = Line.BuildSOS(c)
    if not line then return "failed" end
    if a.discordSig == line then return "same" end
    if a.pending then
        if now(p) - a.pending.at < Call.ECHO_WAIT then return "pending" end
        a.pending = nil   -- jamais revenue (CheckEcho n'est pas encore passé) : comme refusée
    end
    if not gesture then return "nogesture" end
    local wait = self:DiscordWait(a)
    if wait > 0 then return "later", wait end
    if not pcall(p.sendDiscord, club, stream, line) then return "failed" end
    a.pending = { line = line, at = now(p) }
    call(p.after, Call.ECHO_WAIT + 1, function() self:CheckEcho() end)
    return "pending"
end

-- Secondes avant que la ligne suivante de cet appel puisse partir sur Discord (0 = dès le geste).
function Call:DiscordWait(a)
    if not a.discordAt then return 0 end
    return math.max(0, math.ceil(Call.DISCORD_EVERY - (now(self.probe) - a.discordAt)))
end

-- La ligne Discord de l'appel tel qu'il est (nil sans position) : « Ton appel » la compare à la
-- dernière revenue en jeu pour dire si Discord est à jour.
function Call:CurrentLine(a)
    if not (a and a.snap and a.snap.map) then return nil end
    return Line.BuildSOS(fields(a, text((call(self.probe.me)))))
end

-- L'appel tel qu'il est, à la guilde puis, sur un geste, au fil Discord. Rend (compte rendu, parti ?) :
-- parti = la guilde l'a pris ou une ligne Discord attend son retour.
function Call:Deliver(a, gesture)
    local c = fields(a, text((call(self.probe.me))))
    local payload, why = Line.EncodeSOS(c)
    if not payload then return { err = why }, false end
    local report = { n = a.n, deaths = c.deaths }
    report.guild = self:ToGuild(a, payload)
    report.discord, report.wait = self:ToDiscord(a, c, gesture)
    return report, report.guild == "sent" or report.discord == "pending"
end

-- L'appel a changé (envoi, retour de la ligne, quelqu'un en route, réglé) : la fenêtre « Ton appel »
-- (_CallerFrame.lua) suit.
function Call:Changed()
    if type(self.onChange) == "function" then pcall(self.onChange) end
end

function Call:Notify(state)
    if type(self.onDiscord) == "function" then pcall(self.onDiscord, state) end
    self:Changed()
end

local function squash(s) return (s:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")) end

-- La ligne est revenue en jeu (CHAT_MSG_GUILD_DISCORD : texte en 1er, GUID de l'auteur en 12e,
-- peut-être secrets) : elle est partie. Notre ligne et pas une autre : le même texte, blancs regroupés
-- (au cas où le serveur y toucherait) ; une ligne plus ancienne du même appel (même numéro, autre
-- message) ne confirme pas la nouvelle. Un GUID lisible qui n'est pas le nôtre = la ligne d'un autre.
-- Rend true si elle confirme l'envoi.
function Call:OnEcho(line, guid)
    local a = self.active
    local pending = a and a.pending
    if not (pending and readable(line) and type(line) == "string") then return false end
    local mine = text((call(self.probe.guid)))
    if readable(guid) and type(guid) == "string" and guid ~= "" and guid ~= mine then return false end
    if line ~= pending.line and squash(line) ~= squash(pending.line) then return false end
    a.discordAt, a.discordSig, a.pending = pending.at, pending.line, nil
    self:Notify("sent")
    return true
end

-- ECHO_WAIT secondes sans retour : la ligne n'est pas partie (bloquée, sans erreur). Rien n'est compté,
-- le geste suivant la renverra.
function Call:CheckEcho()
    local a = self.active
    local pending = a and a.pending
    if not pending or now(self.probe) - pending.at < Call.ECHO_WAIT then return end
    a.pending = nil
    self:Notify("noecho")
end

-- ===== Le geste =====

-- `origin` : "button", "enter", "release" (un clic ou une touche), ou "auto" (la libération
-- automatique, sans geste : la guilde seulement, D13). `state` = la capture faite mort (Death.last),
-- `serial` = la mort en cours. Rend nil si rien n'est à envoyer (libérer sans message, D3), sinon un
-- compte rendu : { n, deaths, guild = "sent"|"same"|"failed", discord = "pending"|"same"|"later"|"none"|
-- "nogesture"|"failed", wait } ou { err = "pos"|"num"|… } quand l'appel ne peut pas se construire.
-- « pending » devient « sent » ou « noecho » plus tard, par Call.onDiscord(état).
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
    -- Une ligne Discord en cours compte : sans appel ouvert, son retour n'aurait rien à confirmer.
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
-- fantôme, après une déco-reco). Un clic ou Entrée = un geste : la guilde et le fil Discord, comme une
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

-- « C'est réglé » (un geste) : la guilde (« 1 END <n> »), et le fil Discord si une ligne de cet appel
-- y est partie ou en cours (« END <moi> #SOS<n> », D12 ; sans suivi de son retour : rien n'en dépend).
-- L'appel est clos tout de suite chez nous, qu'importe ce qui part. Rend { guild, discord } ou nil.
function Call:Settle()
    if not self:IsActive() then return nil end
    local a, p = self.active, self.probe
    self.active = nil
    keep(self, nil)
    local report = { guild = "failed", discord = "none" }
    local payload = Line.EncodeEND(a.n)
    local result = payload and call(p.sendGuild, payload)
    if readable(result) and (result == 0 or result == true) then report.guild = "sent" end
    local club, stream = call(p.stream)
    local line = (a.discordSig or a.pending) and club and Line.BuildEND(call(p.me), a.n)
    if line then report.discord = pcall(p.sendDiscord, club, stream, line) and "sent" or "failed" end
    self:Changed()
    return report
end

-- ===== Sondes du jeu (remplacées par les tests) =====

Call.probe = {
    now         = function() return time() end,   -- secondes réelles : l'appel survit au /reload (D17)
    me          = function() return UnitName("player") end,
    guid        = function() return UnitGUID("player") end,
    db          = function() return NS.db end,
    stream      = function() return NS.Discord.Stream() end,
    sendDiscord = function(club, stream, line) C_Club.SendMessage(club, stream, line) end,
    sendGuild   = function(payload) return C_ChatInfo.SendAddonMessage(Line.PREFIX, payload, "GUILD") end,
    after       = function(seconds, fn) C_Timer.After(seconds, fn) end,
}
