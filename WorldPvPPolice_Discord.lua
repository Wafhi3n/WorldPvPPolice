-- WorldPvPPolice_Discord.lua — le fil « Discord » de la guilde (spec docs/specs/appel-a-l-aide.md, D5).
--
-- Mesuré le 2026-10-10 (skill public wow-forever-api, chat-channels-and-communities.md) : un addon écrit
-- dans ce fil depuis un geste du joueur, et le fil n'existe qu'en flux SÉPARÉ ; en flux mêlé, rien ne
-- dit à un addon que la guilde est reliée (les getters de C_Discord sont protégés). Même lecture que
-- CraftingOrderClassic (Orders_AnnounceDiscord.lua, D.DiscordStream), mais chaque valeur est testée
-- AVANT d'être comparée : une valeur secrète lève même sur `== nil`.
local _, NS = ...

local Discord = {}
NS.Discord = Discord

local function readable(v) return NS.Line.Readable(v) end

-- Une fonction du jeu, appelée sans jamais lever : ses retours, ou rien.
local function try(fn, ...)
    if type(fn) ~= "function" then return false end
    return pcall(fn, ...)
end

-- Le fil « Discord » de MA guilde : (clubId, streamId), ou nil — pas de guilde, flux mêlé, guilde pas
-- reliée, clubs pas encore prêts juste après la connexion. Relu à chaque appel : le chef peut délier
-- ou décocher pendant la session. Seulement des fonctions sans `HasRestrictions`.
function Discord.Stream()
    local okG, inGuild = try(_G.IsInGuild)
    if not (okG and readable(inGuild) and inGuild) then return nil end
    local GI, Club = _G.C_GuildInfo, _G.C_Club
    local want = _G.Enum and _G.Enum.ClubStreamType and _G.Enum.ClubStreamType.Discord
    if not (want and GI and Club) then return nil end
    local okS, separate = try(GI.IsDiscordStreamSeparate)
    if not (okS and readable(separate) and separate == true) then return nil end
    local okC, clubId = try(Club.GetGuildClubId)
    if not (okC and readable(clubId)) then return nil end
    local okL, streams = try(Club.GetStreams, clubId)
    if not (okL and type(streams) == "table") then return nil end
    for _, s in ipairs(streams) do
        local ok, isDiscord, id = pcall(function() return s.streamType == want, s.streamId end)
        if ok and isDiscord == true and readable(id) then return clubId, id end
    end
    return nil
end
