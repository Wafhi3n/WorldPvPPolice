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

-- Le tueur, lu dans TOUT le récap : { status = "player" | "npc" | "unknown", name, class, className }.
-- "player" dès qu'un coup vient d'un joueur, nommé d'après le PREMIER dans l'ordre du récap (le coup
-- fatal, sinon le plus récent) ; "npc" seulement si TOUS les coups sont lisibles et d'un monstre ;
-- sinon "unknown" (le joueur décide, D10). `playerInfo(guid)` rend (classe localisée, jeton de classe)
-- comme GetPlayerInfoByGUID.
function Death.KillerFrom(events, playerInfo)
    if type(events) ~= "table" then return { status = "unknown" } end
    local seen, unsure = 0, false
    for i = 1, MAX_EVENTS do
        local hit = field(events, i)
        if type(hit) ~= "table" then break end
        seen = i
        local kind, guid = hitKind(hit)
        if kind == "player" then
            local k = { status = "player" }
            if field(hit, "hideCaster") ~= true then k.name = Line.ShortName(field(hit, "sourceName")) end
            k.class, k.className = classOf(guid, playerInfo)
            return k
        end
        if kind == "unknown" then unsure = true end
    end
    if seen == 0 or unsure then return { status = "unknown" } end
    return { status = "npc" }
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

function Death.KillerText(k, L)
    if not k or k.status ~= "player" then return nil end
    if k.name and k.className then return string.format(L["Tueur : %s (%s)"], k.name, k.className) end
    if k.name then return string.format(L["Tueur : %s"], k.name) end
    return L["Tueur : un joueur"]
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
}

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
