-- WorldPvPPolice.lua — socle : table d'addon, réglages par défaut, SavedVariables, commande /wpp.
--
-- Chargé APRÈS la locale, AVANT les modules. Les SavedVariables sont prêtes sur l'ADDON_LOADED de
-- CET addon ; les modules démarrent sur PLAYER_LOGIN, quand tous les fichiers du .toc sont chargés
-- (même découpage que LeyLines.lua).
local ADDON, NS = ...
local L = NS.L

NS.VERSION = "0.1.0"   -- = ## Version du .toc ; scripts\bump_version.ps1 -Addon WorldPvPPolice la tient égale
_G.WorldPvPPolice = NS

-- Réglages par défaut. CopyDefaults complète la base sans écraser ce que le joueur a changé ;
-- schemaVer sert le jour où une migration de la base devient nécessaire. nextCall : prochain numéro
-- d'appel par perso (clé = son GUID, NS.Call). alerts : recevoir les appels des guildiens (/wpp on|off,
-- pour tout le compte). fusion : « Discord en chat fusionné » (/wpp fusion on|off, pour tout le compte).
NS.DEFAULTS = {
    schemaVer = 1,
    nextCall = {},
    alerts = true,
    fusion = false,
}

local function CopyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            CopyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

function NS:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffWorld PvP Police Guild|r " .. tostring(msg))
end

function NS:Printf(fmt, ...)
    self:Print(string.format(fmt, ...))
end

function NS:PrintAlertsState()
    if self.db.alerts == false then
        self:Print(L["Alertes de la guilde : désactivées."])
    else
        self:Print(L["Alertes de la guilde : activées."])
    end
end

-- Le chat fusionné dit son état, et s'il sert à quelque chose : l'addon voit le fil séparé, pas le reste.
function NS:PrintFusionState()
    if not self.Discord.FusionOn() then
        self:Print(L["Discord en chat fusionné : désactivé."])
    elseif self.Discord.Stream() then
        self:Print(L["Discord en chat fusionné : activé, mais sans effet : la guilde a son fil Discord séparé."])
    else
        self:Print(L["Discord en chat fusionné : activé. Tes appels s'écrivent aussi dans le chat de guilde, les « J'arrive » suivent."])
    end
end

-- /wpp discord : où en est le lien, et qui peut y remédier (O1).
function NS:PrintDiscordState()
    if self.Discord.Stream() then
        self:Print(L["Discord : relié."])
    elseif self.Discord.FusionOn() then
        self:PrintFusionState()
    else
        self:Print(L["Discord : non relié. Le maître de guilde ou un officier relie la guilde et coche la case qui sépare le chat Discord (Guilde et communautés, clic droit sur la guilde). Guilde en chat fusionné : /wpp fusion on."])
    end
end

-- Une ligne par commande (skill chat-output) : /wpp seul dit l'état des alertes, /wpp on|off le
-- change et dit le nouvel état ; /wpp fusion de même ; l'aide est la seule réponse en plusieurs lignes.
function NS:Slash(msg)
    local cmd, arg = (msg or ""):match("^%s*(%S*)%s*(%S*)")
    cmd, arg = (cmd or ""):lower(), (arg or ""):lower()
    if cmd == "" then
        self:PrintAlertsState()
    elseif cmd == "on" or cmd == "off" then
        self.db.alerts = (cmd == "on")
        if cmd == "off" and self.Alert then self.Alert:Clear() end
        self:PrintAlertsState()
    elseif cmd == "discord" then
        self:PrintDiscordState()
    elseif cmd == "fusion" then
        if arg == "on" or arg == "off" then self.db.fusion = (arg == "on") end
        self:PrintFusionState()
    elseif cmd == "version" then
        self:Printf(L["version %s"], self.VERSION)
    else
        self:Print(L["Commandes :"])
        self:Print("/wpp - " .. L["état des alertes de la guilde"])
        self:Print("/wpp on | off - " .. L["recevoir ou non les appels des guildiens"])
        self:Print("/wpp discord - " .. L["où en est le lien avec Discord"])
        self:Print("/wpp fusion on | off - " .. L["guilde en chat fusionné : l'appel passe par le chat de guilde"])
        self:Print("/wpp version - " .. L["affiche la version"])
    end
end

SLASH_WORLDPVPPOLICE1 = "/wpp"
SlashCmdList["WORLDPVPPOLICE"] = function(msg) NS:Slash(msg) end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        WorldPvPPoliceDB = WorldPvPPoliceDB or {}
        CopyDefaults(WorldPvPPoliceDB, NS.DEFAULTS)
        NS.db = WorldPvPPoliceDB
    elseif event == "PLAYER_LOGIN" then
        -- Muet à la connexion, sauf la première après une installation ou une mise à jour (règle du
        -- user du 2026-10-11, skill publique `chat-output`). seenVersion vit dans la base du COMPTE :
        -- une ligne par compte, pas par perso.
        if NS.db.seenVersion ~= NS.VERSION then
            NS.db.seenVersion = NS.VERSION
            NS:Printf(L["version %s. Tape /%s pour l'aide."], NS.VERSION, "wpp")
        end
        -- Un appel gardé d'avant le /reload ou la déco (D17) : « Ton appel » réapparaît.
        if NS.Call then NS.Call:Changed() end
    end
end)
