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
    -- Compte rendu d'un envoi, dans l'encart
    ["Mettre à jour"]                 = "Update",
    ["Appel n°%d"]                    = "Call #%d",
    ["guilde : prévenue"]             = "guild: notified",
    ["guilde : échec"]                = "guild: failed",
    ["Position illisible : appel impossible"] = "Position unreadable: cannot call",
    ["Appel impossible"]              = "Cannot call",
    -- Alertes reçues, et « Ton appel »
    ["%s appelle à l'aide !"]         = "%s is calling for help!",
    ["Morts : %d"]                    = "Deaths: %d",
    ["« %s »"]                        = "“%s”",
    ["En route : %s"]                 = "On the way: %s",
    ["J'arrive"]                      = "On my way",
    ["Voir sur la carte"]             = "Show on map",
    ["Prévient la guilde et pose ton point de route sur lui (il remplace le tien)."] = "Tells the guild and sets your waypoint on them (it replaces yours).",
    ["En route"]                      = "On the way",
    ["Ton appel n°%d"]                = "Your call #%d",
    ["C'est réglé"]                   = "All clear",
    ["Personne en route pour l'instant"] = "Nobody on the way yet",
    -- La page d'options
    ["ouvre la page des réglages"] = "opens the settings page",
    ["Réglages communs à tous les personnages du compte."] = "Settings shared by every character on the account.",
    ["Recevoir les appels des guildiens"] = "Receive guildmates' calls",
    ["Une fenêtre s'ouvre quand un guildien tué par un joueur appelle à l'aide. Comme /wpp on | off."] = "A window opens when a guildmate killed by a player calls for help. Same as /wpp on | off.",
    ["Toutes les commandes : /wpp help."] = "All commands: /wpp help.",
    ["Les options s'ouvrent hors combat."] = "Options open out of combat only.",
    ["La page d'options n'existe pas sur ce client."] = "The options page doesn't exist on this client.",
}
for k, v in pairs(T) do NS.L[k] = v end
