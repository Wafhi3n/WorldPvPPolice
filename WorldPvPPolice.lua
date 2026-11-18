-- WorldPvPPolice.lua — socle : table d'addon, réglages par défaut, SavedVariables, commande /wpp.
--
-- Chargé APRÈS la locale, AVANT les modules. Les SavedVariables sont prêtes sur l'ADDON_LOADED de
-- CET addon ; les modules démarrent sur PLAYER_LOGIN, quand tous les fichiers du .toc sont chargés
-- (même découpage que LeyLines.lua).
local ADDON, NS = ...
local L = NS.L

NS.VERSION = "0.1.0-beta"   -- = ## Version du .toc ; scripts\bump_version.ps1 -Addon WorldPvPPolice la tient égale
NS.TITLE = "World PvP Police Guild"   -- le nom de l'addon, jamais traduit
_G.WorldPvPPolice = NS

-- Réglages par défaut. CopyDefaults complète la base sans écraser ce que le joueur a changé ;
-- schemaVer sert le jour où une migration de la base devient nécessaire. nextCall : prochain numéro
-- d'appel par perso (clé = son GUID, NS.Call). alerts : recevoir les appels des guildiens (/wpp on|off,
-- pour tout le compte). Discord n'a pas de réglage ici (S7 de docs/specs/appel-sans-pont-discord.md) :
-- c'est le module WorldPvPPoliceDiscord, installé ou non, et ses réglages vivent dans SA base.
NS.DEFAULTS = {
    schemaVer = 1,
    nextCall = {},
    alerts = true,
}

-- Les réglages que la page d'options (_Options.lua) et les commandes changent, par le même chemin.
NS.OPTIONS = { alerts = true }

function NS:SetOption(key, value)
    if not NS.OPTIONS[key] then return end
    self.db[key] = value and true or false
    if key == "alerts" and not value and self.Alert then self.Alert:Clear() end   -- couper vide l'écran
    self:SettingsChanged()
end

-- Un réglage a changé, ici ou dans un module : « Ton appel », l'encart ouvert (mort) et la page
-- d'options suivent tout de suite.
function NS:SettingsChanged()
    if self.Call then self.Call:Changed() end
    local P = self.Panel
    if P and P.frame and P.frame:IsShown() and self.Death then P:Refresh(self.Death.last) end
    if type(self.onOptionChange) == "function" then pcall(self.onOptionChange) end
end

-- Les commandes qu'un module ajoute à /wpp (NS.commands.<mot> = function(arg)) et ses lignes d'aide.
-- Celles de la base passent avant : un module ne les remplace pas.
NS.commands = {}
NS.helpLines = {}

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
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccff" .. NS.TITLE .. "|r " .. tostring(msg))
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

-- Une ligne par commande (skill chat-output) : /wpp seul dit l'état des alertes, /wpp on|off le
-- change et dit le nouvel état ; les commandes d'un module suivent la même règle ; l'aide est la seule
-- réponse en plusieurs lignes.
function NS:Slash(msg)
    local cmd, arg = (msg or ""):match("^%s*(%S*)%s*(%S*)")
    cmd, arg = (cmd or ""):lower(), (arg or ""):lower()
    if cmd == "" then
        self:PrintAlertsState()
    elseif cmd == "on" or cmd == "off" then
        self:SetOption("alerts", cmd == "on")
        self:PrintAlertsState()
    elseif cmd == "options" then
        if self.OptionsPanel then self.OptionsPanel:Open() end
    elseif cmd == "version" then
        self:Printf(L["version %s"], self.VERSION)
    elseif cmd ~= "help" and type(self.commands[cmd]) == "function" then
        pcall(self.commands[cmd], arg)
    else
        self:PrintHelp()
    end
end

function NS:PrintHelp()
    self:Print(L["Commandes :"])
    self:Print("/wpp - " .. L["état des alertes de la guilde"])
    self:Print("/wpp on | off - " .. L["recevoir ou non les appels des guildiens"])
    for _, line in ipairs(self.helpLines) do self:Print(line) end
    self:Print("/wpp options - " .. L["ouvre la page des réglages"])
    self:Print("/wpp version - " .. L["affiche la version"])
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
