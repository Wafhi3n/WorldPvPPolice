-- WorldPvPPolice_Roster.lua — D19 (user, 2026-10-28) : un guildien qui se connecte PENDANT mon appel le
-- reçoit, à lui seul (spec docs/specs/appel-a-l-aide.md).
--
-- Le message de guilde ne touche que les présents : un guildien qui arrive après ne voyait l'appel qu'à
-- la mise à jour suivante. Tant que MON appel est en cours, la liste de guilde est relue (une demande
-- toutes les POLL secondes, C_GuildInfo.GuildRoster, réponse GUILD_ROSTER_UPDATE) : qui n'était pas en
-- ligne à la lecture d'avant reçoit mon dernier SOS en message d'addon WHISPER, LATE secondes plus tard
-- (le temps de son écran de chargement), s'il est toujours là. Rien ne part tant que personne n'appelle,
-- rien vers ceux qui l'avaient déjà (envoi dirigé, jamais « à tous »).
-- La première lecture d'un appel sert de base : ceux qui sont là ont eu le message de guilde.
local _, NS = ...
local Line = NS.Line

local Roster = {}
NS.Roster = Roster

Roster.POLL = 30   -- s entre deux demandes de la liste de guilde, appel en cours seulement
Roster.LATE = 20   -- s entre « vu en ligne » et l'envoi : son addon doit être chargé pour l'entendre

local function readable(v) return Line.Readable(v) end
local function isText(v) return readable(v) and type(v) == "string" and v ~= "" end

local function returns(ok, ...)
    if ok then return ... end
    return nil
end
local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    return returns(pcall(fn, ...))
end

-- État d'un appel : `n` (son numéro), `online` = { [GUID] = nom } à la dernière lecture, `told` = { [GUID]
-- = true } déjà prévenus (oubliés quand ils se déconnectent : à leur retour, ils le recevront encore).
Roster.state = nil
Roster.since = nil   -- s depuis la dernière demande ; nil = pas d'appel suivi
Roster.canRequest = true

function Roster:Reset()
    self.state, self.since = nil, nil
end

-- Une seconde de plus (le passage de _AlertFrame.lua) : sans appel, rien ; sinon une demande de la liste
-- toutes les POLL secondes, la première tout de suite.
function Roster:Tick(elapsed)
    if not NS.Call:IsActive() then
        self:Reset()
        return
    end
    self.since = (self.since or self.POLL) + (elapsed or 0)
    if self.since < self.POLL or not self.canRequest then return end
    self.since = 0
    call(self.probe.request)
end

-- Les guildiens en ligne dans le jeu, moi exclu : { [GUID] = nom complet }, ou nil si illisible.
local function onlineNow(p)
    local list = call(p.members)
    if type(list) ~= "table" then return nil end
    local me = call(p.guid)
    local out = {}
    for _, m in ipairs(list) do
        if type(m) == "table" and isText(m.guid) and isText(m.name) and not (isText(me) and m.guid == me) then
            out[m.guid] = m.name
        end
    end
    return out
end

-- GUILD_ROSTER_UPDATE (payload : la liste peut-elle être redemandée). Compare avec la lecture d'avant.
function Roster:OnRoster(canRequest)
    if readable(canRequest) and type(canRequest) == "boolean" then self.canRequest = canRequest end
    if not NS.Call:IsActive() then
        self:Reset()
        return
    end
    local now = onlineNow(self.probe)
    if not now then return end
    local n, st = NS.Call.active.n, self.state
    if not st or st.n ~= n then
        self.state = { n = n, online = now, told = {} }
        return
    end
    for guid, name in pairs(now) do
        if not st.online[guid] and not st.told[guid] then
            st.told[guid] = true
            call(self.probe.after, self.LATE, function() self:Tell(guid, name) end)
        end
    end
    for guid in pairs(st.told) do
        if not now[guid] then st.told[guid] = nil end
    end
    st.online = now
end

-- Envoie mon dernier SOS (celui parti à la guilde) à ce guildien, s'il est toujours en ligne et l'appel
-- toujours en cours. Rend true si le message est parti.
function Roster:Tell(guid, name)
    local st = self.state
    if not (NS.Call:IsActive() and st and st.n == NS.Call.active.n and st.online[guid]) then return false end
    local payload = NS.Call.active.guildSig
    if not isText(payload) then return false end
    local result = call(self.probe.whisper, payload, name)
    return readable(result) and (result == 0 or result == true)
end

-- ===== Sondes du jeu (remplacées par les tests) =====

Roster.probe = {
    request = function() C_GuildInfo.GuildRoster() end,
    guid    = function() return UnitGUID("player") end,
    -- La liste classique (vivante sur Forever, skill wow-forever-api) : nom 1er, en ligne 9e, sur le
    -- téléphone 14e, GUID 17e. Le téléphone ne compte pas : il n'a pas l'addon.
    members = function()
        local out = {}
        for i = 1, (GetNumGuildMembers()) or 0 do
            local name, _, _, _, _, _, _, _, online, _, _, _, _, mobile, _, _, guid = GetGuildRosterInfo(i)
            if online == true and mobile ~= true then out[#out + 1] = { guid = guid, name = name } end
        end
        return out
    end,
    after   = function(seconds, fn) C_Timer.After(seconds, fn) end,
    whisper = function(payload, target)
        return C_ChatInfo.SendAddonMessage(Line.PREFIX, payload, "WHISPER", target)
    end,
}
