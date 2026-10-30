-- WorldPvPPolice_Death.lua — ce qu'on sait à la mort : qui nous a tués, où est le cadavre, et si
-- l'encart d'appel a sa place (spec docs/specs/appel-a-l-aide.md, D1, D6, D10).
--
-- Logique pure + des sondes (Death.probe) qui seules touchent au jeu ; les tests headless remplacent
-- les sondes. Toute lecture passe par pcall et par le test de secret AVANT d'être comparée.
--
-- Le tueur : le récap de mort (C_DeathRecap.GetRecapEvents(), la liste derrière le bouton
-- « Récapitulatif » de la fenêtre de mort). events[1] est le coup fatal (Blizzard_DeathRecap le marque
-- `causedDeath`), puis du plus récent au plus ancien. Le journal de combat, lui, est fermé aux addons
-- sur Forever. Mesuré par le user sur le PTR RETAIL 12.1.7.70493 le 2026-10-27, PAS sur Forever (M1) :
-- 10 événements, tout lisible ; tué par un chevalier de la mort, le coup fatal venait de son
-- Abomination (`Creature-`), et le joueur n'apparaissait qu'aux coups 2+. D'où la lecture de TOUT le
-- récap, pas du seul coup fatal.
local _, NS = ...
local Line = NS.Line

local Death = {}
NS.Death = Death

Death.FRESH = 2   -- s : une capture plus vieille est refaite (une fenêtre de mort ré-affichée plus tard)

local function readable(v) return Line.Readable(v) end

local function returns(ok, ...)
    if not ok then return nil end
    return ...
end

-- Appelle une sonde sans jamais lever ; ses retours, ou rien.
local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    return returns(pcall(fn, ...))
end

local function isTrue(v) return readable(v) and v == true end

-- Un champ d'une table du jeu, lisible ; nil s'il est absent, secret, ou si la lecture lève.
local function field(t, k)
    local ok, v = pcall(function() return t[k] end)
    if ok and readable(v) then return v end
    return nil
end

local function isFraction(v) return readable(v) and type(v) == "number" and v >= 0 and v <= 1 end

local function isMapId(v)
    return readable(v) and type(v) == "number" and v >= 1 and v == math.floor(v)
end

-- Ce que dit le GUID d'un coup. Un familier (`Pet-`) appartient peut-être à un joueur, sans moyen de
-- savoir lequel : « inconnu », donc l'encart s'ouvre quand même (D10). Une invocation (Abomination,
-- goule, totem…) a un GUID `Creature-` : seul son maître, s'il a frappé lui aussi, dit « joueur ».
local NPC_KINDS = { Creature = true, Vehicle = true, GameObject = true }
local MAX_EVENTS = 50   -- borne de la lecture du récap (10 coups mesurés sur le PTR Retail)

local function classOf(guid, playerInfo)
    local localized, token = call(playerInfo, guid)
    if not (readable(token) and type(token) == "string" and token:match("^%u+$")) then return nil end
    if readable(localized) and type(localized) == "string" and localized ~= "" then
        return token, localized
    end
    return token
end

-- Un coup du récap : "player" (+ son GUID), "npc" (monstre, invocation, véhicule, objet, chute,
-- noyade), ou "unknown" (familier, GUID absent, secret ou d'une sorte inattendue).
local function hitKind(hit)
    if field(hit, "event") == "ENVIRONMENTAL_DAMAGE" then return "npc" end
    local guid = field(hit, "sourceGUID")
    if type(guid) ~= "string" then return "unknown" end
    local kind = guid:match("^(%a+)%-")
    if kind == "Player" then return "player", guid end
    if NPC_KINDS[kind] then return "npc" end
    return "unknown"
end

-- Le nom du tueur, le plus complet possible (D22). Sur Forever, on n'a pas mesuré si le récap rend
-- « Prénom » ou « Prénom Nom » (M14) : un récap sans nom de famille est complété par GetPlayerInfoByGUID
-- (6e retour), seulement si ce nom commence par le même prénom. Le récap décide si le nom se montre.
local function killerNameOf(hit, guid, playerInfo)
    local shown = Line.KillerName(field(hit, "sourceName"))
    if not shown then return nil end
    local _, _, _, _, _, name = call(playerInfo, guid)
    local full = Line.KillerName(name)
    if full and full:find(shown .. " ", 1, true) == 1 then return full end
    return shown
end

-- Un joueur du récap, une fois par GUID : il entre dans la liste au premier de ses coups qui montre son
-- nom (un coup à `hideCaster`, un nom secret ne le montrent pas).
local function notePlayer(players, byGuid, hit, guid, playerInfo)
    local p = byGuid[guid]
    if not p then
        p = { key = guid }
        p.class, p.className = classOf(guid, playerInfo)
        byGuid[guid] = p
    end
    if p.name or field(hit, "hideCaster") == true then return end
    p.name = killerNameOf(hit, guid, playerInfo)
    if p.name then players[#players + 1] = p end
end

-- Les tueurs, lus dans TOUT le récap : { status = "player" | "npc" | "unknown", players }.
-- "player" dès qu'un coup vient d'un joueur ; `players` = TOUS les joueurs nommés du récap (D15, une
-- équipe qui campe), une fois chacun, dans l'ordre du récap (le coup fatal, puis du plus récent au plus
-- ancien) : { key = GUID, name, class, className }. "npc" seulement si TOUS les coups sont lisibles et
-- d'un monstre ; sinon "unknown" (le joueur décide, D10). `playerInfo(guid)` rend (classe localisée,
-- jeton de classe) comme GetPlayerInfoByGUID.
function Death.KillerFrom(events, playerInfo)
    if type(events) ~= "table" then return { status = "unknown", players = {} } end
    local seen, unsure, anyPlayer = 0, false, false
    local players, byGuid = {}, {}
    for i = 1, MAX_EVENTS do
        local hit = field(events, i)
        if type(hit) ~= "table" then break end
        seen = i
        local kind, guid = hitKind(hit)
        if kind == "player" then
            anyPlayer = true
            notePlayer(players, byGuid, hit, guid, playerInfo)
        elseif kind == "unknown" then
            unsure = true
        end
    end
    if anyPlayer then return { status = "player", players = players } end
    if seen == 0 or unsure then return { status = "unknown", players = {} } end
    return { status = "npc", players = {} }
end

-- L'encart a-t-il sa place ? En guilde, hors instance (D6), et sauf mort SÛREMENT pas due à un joueur
-- (monstre, chute, noyade) : un récap illisible laisse le joueur décider (D10).
function Death.ShouldOffer(ctx)
    local status = ctx.killer and ctx.killer.status
    return ctx.inGuild == true and ctx.inInstance ~= true and status ~= "npc"
end

-- Où est le cadavre : { map, zone, x, y } (x, y en FRACTIONS, absents si illisibles). La position du
-- cadavre d'abord ; à défaut celle du joueur, qui n'a pas bougé tant qu'il n'a pas libéré (D1).
-- Mesuré sur le PTR Retail (M3, pas sur Forever) : avant « Libérer », le cadavre rend nil et le joueur
-- est lisible ; après, le cadavre rend la même position. Un FANTÔME n'est plus sur son cadavre (chez la
-- gardienne des âmes, peut-être sur une autre carte) : jamais sa position, et rien du tout si le
-- cadavre n'est pas sur sa carte (carte et zone seraient celles du fantôme). L'envoi, lui, part de la
-- capture faite mort (NS.Call), jamais d'une capture de fantôme.
function Death.Snapshot(p)
    local snap = {}
    local map = call(p.bestMap)
    if not isMapId(map) then return snap end
    local x, y = call(p.corpsePos, map)
    if not (isFraction(x) and isFraction(y)) then
        if isTrue(call(p.isGhost)) then return snap end
        x, y = call(p.playerPos, map)
    end
    snap.map = map
    local zone = call(p.mapName, map)
    if readable(zone) and type(zone) == "string" and zone ~= "" then snap.zone = zone end
    if isFraction(x) and isFraction(y) then snap.x, snap.y = x, y end
    return snap
end

-- ===== Textes de l'encart =====

local SHOWN = 3   -- noms affichés au plus dans l'encart ; les autres en « +N »

-- « Tueur : Xyz (Voleur) » pour un seul ; « Tueurs : Xyz, Abc, Def +2 » pour plusieurs, les noms
-- seuls, pour que la ligne tienne dans l'encart (D15).
function Death.KillerText(k, L)
    if not k or k.status ~= "player" then return nil end
    local players = k.players or {}
    local first = players[1]
    if not first then return L["Tueur : un joueur"] end
    if #players == 1 then
        if first.className then return string.format(L["Tueur : %s (%s)"], first.name, first.className) end
        return string.format(L["Tueur : %s"], first.name)
    end
    local names = {}
    for i = 1, math.min(#players, SHOWN) do names[i] = players[i].name end
    local text = table.concat(names, ", ")
    if #players > SHOWN then text = text .. " +" .. (#players - SHOWN) end
    return string.format(L["Tueurs : %s"], text)
end

function Death.WhereText(snap, L)
    local zone = snap.zone or L["zone inconnue"]
    if snap.x and snap.y then
        return string.format("%s (%.1f, %.1f)", zone, snap.x * 100, snap.y * 100)
    end
    return zone .. " · " .. L["position inconnue"]
end

-- ===== Sondes du jeu (remplacées par les tests) =====

local function xy(vec)
    if vec and vec.GetXY then return vec:GetXY() end
    return nil
end

Death.probe = {
    events     = function() return C_DeathRecap.GetRecapEvents() end,
    playerInfo = function(guid) return GetPlayerInfoByGUID(guid) end,
    bestMap    = function() return C_Map.GetBestMapForUnit("player") end,
    mapName    = function(map) local info = C_Map.GetMapInfo(map); return info and info.name end,
    corpsePos  = function(map) return xy(C_DeathInfo.GetCorpseMapPosition(map)) end,
    playerPos  = function(map) return xy(C_Map.GetPlayerMapPosition(map, "player")) end,
    isGhost    = function() return UnitIsGhost("player") end,
    inInstance = function() return (IsInInstance()) end,
    inGuild    = function() return IsInGuild() end,
    now        = function() return GetTime() end,
    isDead     = function() return UnitIsDead("player") end,
    guid       = function() return UnitGUID("player") end,
    db         = function() return NS.db end,
}

-- D17 (user, 2026-10-28) : un appel survit à un /reload et à une déco-reco. Le numéro de mort et l'état
-- « mort » sont donc gardés par perso (db.lastDeath[GUID] = { serial, dead }) : les morts d'un appel
-- gardé sont rangées par ce numéro, qui ne doit jamais repartir de 1. Sans GUID ni base (tests, tout
-- début de session), rien n'est gardé et tout marche comme avant.
local function ident(self)
    local p = self.probe
    local db, key = call(p.db), call(p.guid)
    if type(db) == "table" and readable(key) and type(key) == "string" and key ~= "" then return db, key end
    return nil
end

local function slot(self, create)
    local db, key = ident(self)
    if not db then return nil end
    if type(db.lastDeath) ~= "table" then
        if not create then return nil end
        db.lastDeath = {}
    end
    local s = db.lastDeath[key]
    if type(s) ~= "table" then
        if not create then return nil end
        s = {}
        db.lastDeath[key] = s
    end
    return s
end

-- Reprend le numéro gardé, une fois (dès que la base et le GUID sont là). Encore mort (pas libéré)
-- au retour : c'est LA MÊME mort, la fenêtre qui rouvre ne compte pas une mort de plus. Fantôme ou
-- vivant : la mort gardée est finie.
function Death:Restore()
    if self.restored or not ident(self) then return end
    self.restored = true
    local s = slot(self, false)
    if not s then return end
    if type(s.serial) == "number" and s.serial > (self.serial or 0) then self.serial = s.serial end
    local still = call(self.probe.isDead)
    if s.dead and readable(still) and still == true then self.dead = true else s.dead = nil end
end

local function save(self)
    local s = slot(self, true)
    if s then s.serial, s.dead = self.serial, self.dead end
end

-- Une mort dure du passage à « mort » jusqu'à PLAYER_ALIVE ou PLAYER_UNGHOST. Rend (numéro, nouvelle ?).
-- Appelée à PLAYER_DEAD ET à l'ouverture de la fenêtre de mort, dans un ordre qui n'est pas sûr
-- (Blizzard ouvre la fenêtre sur son propre PLAYER_DEAD) : la première compte. Après un /reload en
-- étant mort, la fenêtre rouvre : c'est la même mort (Restore).
function Death:Mark()
    self:Restore()
    if self.dead then return self.serial, false end
    self.dead = true
    self.serial = (self.serial or 0) + 1
    save(self)
    return self.serial, true
end

function Death:Revive()
    self:Restore()
    self.dead = nil
    save(self)
end

-- Lit tout ce qu'on sait de la mort en cours et le garde dans Death.last.
function Death:Capture()
    local p = self.probe
    self.last = {
        killer = Death.KillerFrom(call(p.events), p.playerInfo),
        snap = Death.Snapshot(p),
        at = call(p.now) or 0,
    }
    return self.last
end

-- La capture de cette mort : celle de PLAYER_DEAD si elle date de moins de FRESH secondes, sinon une
-- nouvelle (l'ordre entre notre PLAYER_DEAD et celui de Blizzard, qui ouvre la fenêtre, n'est pas sûr).
function Death:Current()
    local now = call(self.probe.now) or 0
    if self.last and now - self.last.at <= Death.FRESH then return self.last end
    return self:Capture()
end

-- Relit le tueur seul (le récap peut arriver après la fenêtre de mort).
function Death:RereadKiller()
    if not self.last then return nil end
    self.last.killer = Death.KillerFrom(call(self.probe.events), self.probe.playerInfo)
    return self.last.killer
end

function Death:Offer(state)
    local p = self.probe
    return Death.ShouldOffer({ inGuild = isTrue(call(p.inGuild)), inInstance = isTrue(call(p.inInstance)),
                               killer = state and state.killer })
end
