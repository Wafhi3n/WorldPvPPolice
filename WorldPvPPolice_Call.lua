-- WorldPvPPolice_Call.lua — l'appel qui part : l'ouvrir, le mettre à jour, compter les morts, écrire
-- dans le fil Discord et à la guilde (spec docs/specs/appel-a-l-aide.md, « Ce qu'on veut » 2, 4 et 5,
-- D3, D4, D9, D11, D13 ; critère 4).
--
-- Logique pure + des sondes (Call.probe) qui seules touchent au jeu, comme _Death.lua : les tests
-- remplacent les sondes et l'horloge.
--
-- DEUX RÈGLES DURES :
--   - C_Club.SendMessage exige un geste du joueur (clic, touche) : hors geste, c'est
--     ADDON_ACTION_BLOCKED, que pcall ne voit PAS. Le chemin sans geste (libération automatique, D13)
--     n'écrit qu'à la guilde, jamais sur Discord.
--   - On envoie la capture faite MORT (Death.last), jamais une capture refaite à l'envoi : le clic sur
--     « Libérer » et la libération automatique arrivent quand on devient fantôme, et le fantôme est
--     chez la gardienne des âmes, peut-être sur une autre carte.
local _, NS = ...
local Line = NS.Line

local Call = {}
NS.Call = Call

Call.EXPIRY = 15 * 60       -- s après la dernière mise à jour partie (D11)
Call.DISCORD_EVERY = 120    -- s entre deux lignes Discord d'un même appel (morts répétées, critère 4)

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
-- Call.active = { n, serial (la mort qui l'a ouvert), deaths = { [mort] = true }, snap, killer,
-- class, msg, sentAt, guildSig, discordAt, discordSig }. Jamais sauvegardé (spec, « Données
-- sauvegardées ») : un /reload l'oublie.

function Call:IsActive()
    local a = self.active
    if not a then return false end
    if now(self.probe) - a.sentAt < Call.EXPIRY then return true end
    self.active = nil
    return false
end

-- Une mort par un joueur (l'encart s'est ouvert) pendant un appel en cours : le compteur monte (D9).
-- Rien ne part ici : la mise à jour part avec le geste suivant.
function Call:NoteDeath(serial)
    if serial and self:IsActive() then self.active.deaths[serial] = true end
end

-- Le récap relu après coup dit « monstre » : cette mort ne compte plus, sauf celle qui a ouvert l'appel.
function Call:ForgetDeath(serial)
    local a = self.active
    if a and serial and serial ~= a.serial then a.deaths[serial] = nil end
end

-- Le prochain numéro d'appel de CE perso (clé = son GUID), et de quoi le consommer une fois l'appel
-- parti. Il vit dans les SavedVariables du poste : un autre poste repart de 1 (le bot ne reconnaît un
-- numéro que dans la fenêtre de 15 minutes).
local function nextNumber(p)
    local db, key = call(p.db), text((call(p.guid)))
    if type(db) ~= "table" or not key then return nil end
    if type(db.nextCall) ~= "table" then db.nextCall = {} end
    local n = db.nextCall[key]
    if type(n) ~= "number" or n < 1 or n ~= math.floor(n) then n = 1 end
    return n, function() db.nextCall[key] = n + 1 end
end

-- Ce que l'appel retient de cette mort : sa position et son tueur ; à défaut, ceux d'avant (une mort
-- de plus sans position lisible ne fait pas perdre celle de l'appel).
local function absorb(a, state, serial, msg)
    local snap = state.snap
    if snap and snap.x and snap.y then a.snap = snap end
    local k = state.killer
    if k and k.status == "player" and k.name then a.killer, a.class = k.name, k.class end
    a.deaths[serial] = true
    a.msg = Line.Clean(msg)
end

local function fields(a, me)
    local s = a.snap
    return { who = me, n = a.n, map = s.map, zone = s.zone, x = s.x, y = s.y, deaths = count(a.deaths),
             killer = a.killer, class = a.class, msg = a.msg }
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
-- un même appel ; une mise à jour retenue part avec le geste suivant (critère 4). Rend (état, attente).
function Call:ToDiscord(a, c, gesture)
    local p = self.probe
    local line = Line.BuildSOS(c)
    if not line then return "failed" end
    if a.discordSig == line then return "same" end
    local club, stream = call(p.stream)
    if not club then return "none" end
    if not gesture then return "nogesture" end
    if a.discordAt then
        local wait = Call.DISCORD_EVERY - (now(p) - a.discordAt)
        if wait > 0 then return "later", math.ceil(wait) end
    end
    if not pcall(p.sendDiscord, club, stream, line) then return "failed" end
    a.discordAt, a.discordSig = now(p), line
    return "sent"
end

-- ===== Le geste =====

-- `origin` : "button", "enter", "release" (un clic ou une touche), ou "auto" (la libération
-- automatique, sans geste : la guilde seulement, D13). `state` = la capture faite mort (Death.last),
-- `serial` = la mort en cours. Rend nil si rien n'est à envoyer (libérer sans message, D3), sinon un
-- compte rendu : { n, deaths, guild = "sent"|"same"|"failed", discord = "sent"|"same"|"later"|"none"|
-- "nogesture"|"failed", wait } ou { err = "pos"|"num"|… } quand l'appel ne peut pas se construire.
function Call:Send(msg, origin, state, serial)
    if (origin == "release" or origin == "auto") and Line.Clean(msg) == "" then return nil end
    if not (state and serial) then return { err = "state" } end
    local p = self.probe
    local opening = not self:IsActive()
    local a = opening and { deaths = {}, serial = serial } or self.active
    absorb(a, state, serial, msg)
    -- Pas d'appel sans coordonnées : OUVERT dans la spec (« Position illisible »).
    if not a.snap then return { err = "pos" } end
    local consume
    if opening then
        a.n, consume = nextNumber(p)
        if not a.n then return { err = "num" } end
    end
    local c = fields(a, text((call(p.me))))
    local payload, why = Line.EncodeSOS(c)
    if not payload then return { err = why } end
    local report = { n = a.n, deaths = c.deaths }
    report.guild = self:ToGuild(a, payload)
    report.discord, report.wait = self:ToDiscord(a, c, origin ~= "auto")
    -- L'appel dure 15 minutes après la dernière mise à jour PARTIE (D11) : un double clic qui n'envoie
    -- rien ne le prolonge pas. Un appel dont rien n'est parti n'est pas ouvert, et garde son numéro.
    local sent = report.guild == "sent" or report.discord == "sent"
    if opening and not sent then return report end
    if opening then
        consume()
        self.active = a
    end
    if sent then a.sentAt = now(p) end
    return report
end

-- ===== Sondes du jeu (remplacées par les tests) =====

Call.probe = {
    now         = function() return GetTime() end,
    me          = function() return UnitName("player") end,
    guid        = function() return UnitGUID("player") end,
    db          = function() return NS.db end,
    stream      = function() return NS.Discord.Stream() end,
    sendDiscord = function(club, stream, line) C_Club.SendMessage(club, stream, line) end,
    sendGuild   = function(payload) return C_ChatInfo.SendAddonMessage(Line.PREFIX, payload, "GUILD") end,
}
