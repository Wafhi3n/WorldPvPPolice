-- WorldPvPPolice_Locale_enUS.lua — overlay ANGLAIS (enUS/enGB). Clé FR → texte EN.
-- Chargé APRÈS WorldPvPPolice_Locale.lua (qui crée NS.L). Sur un client non anglais : early-return.
local _, NS = ...
NS = NS or _G.WorldPvPPolice
if not NS or not NS.L then return end

local locale = GetLocale and GetLocale() or "enUS"
if locale ~= "enUS" and locale ~= "enGB" then return end

local T = {
    ["version %s. Tape /%s pour l'aide."] = "version %s. Type /%s for help.",
    ["version %s"]                    = "version %s",
    ["Commandes :"]                   = "Commands:",
    ["affiche la version"]            = "shows the version",
    ["Alertes de la guilde : activées."]    = "Guild alerts: on.",
    ["Alertes de la guilde : désactivées."] = "Guild alerts: off.",
    ["état des alertes de la guilde"]       = "guild alerts status",
    ["recevoir ou non les appels des guildiens"] = "receive guildmates' calls or not",
    -- Encart sous la fenêtre de mort
    ["Appeler la guilde à l'aide ?"]  = "Call your guild for help?",
    ["Tueur : %s (%s)"]               = "Killer: %s (%s)",
    ["Tueur : %s"]                    = "Killer: %s",
    ["Tueur : un joueur"]             = "Killer: a player",
    ["Tueurs : %s"]                   = "Killers: %s",
    ["zone inconnue"]                 = "unknown zone",
    ["position inconnue"]             = "position unknown",
    ["Message (facultatif)"]          = "Message (optional)",
    ["Appeler"]                       = "Call",
    ["Discord : relié"]               = "Discord: linked",
    ["Discord : non relié (appel en jeu seulement)"] = "Discord: not linked (in-game call only)",
    -- Compte rendu d'un envoi, dans l'encart
    ["Mettre à jour"]                 = "Update",
    ["Appel n°%d"]                    = "Call #%d",
    ["guilde : prévenue"]             = "guild: notified",
    ["guilde : échec"]                = "guild: failed",
    ["Discord : envoyé"]              = "Discord: sent",
    ["Discord : envoi en cours"]      = "Discord: sending",
    ["Discord : pas de retour"]       = "Discord: no echo, not sent",
    ["Discord : dans %d s"]           = "Discord: in %d s",
    ["Discord : non relié"]           = "Discord: not linked",
    ["Discord : refusé"]              = "Discord: refused",
    ["Position illisible : appel impossible"] = "Position unreadable: cannot call",
    ["Appel impossible"]              = "Cannot call",
    -- Alertes reçues, et « Ton appel »
    ["%s appelle à l'aide !"]         = "%s is calling for help!",
    ["Morts : %d"]                    = "Deaths: %d",
    ["« %s »"]                        = "“%s”",
    ["En route : %s"]                 = "On the way: %s",
    ["J'arrive"]                      = "On my way",
    ["En route"]                      = "On the way",
    ["Ton appel n°%d"]                = "Your call #%d",
    ["C'est réglé"]                   = "All clear",
    ["Discord : pas envoyé"]          = "Discord: not sent",
    ["Discord : pas à jour"]          = "Discord: not up to date",
    ["Personne en route pour l'instant"] = "Nobody on the way yet",
}
for k, v in pairs(T) do NS.L[k] = v end
