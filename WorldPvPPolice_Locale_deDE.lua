-- WorldPvPPolice_Locale_deDE.lua — overlay ALLEMAND. Clé FR → texte DE.
-- Chargé APRÈS WorldPvPPolice_Locale.lua (qui crée NS.L). Sur un client non allemand : early-return.
local _, NS = ...
NS = NS or _G.WorldPvPPolice
if not NS or not NS.L then return end

if (GetLocale and GetLocale() or "enUS") ~= "deDE" then return end

local T = {
    ["version %s. Tape /%s pour l'aide."] = "Version %s. Gib /%s für die Hilfe ein.",
    ["version %s"]                    = "Version %s",
    ["Commandes :"]                   = "Befehle:",
    ["affiche la version"]            = "zeigt die Version",
    ["Alertes de la guilde : activées."]    = "Gildenalarme: an.",
    ["Alertes de la guilde : désactivées."] = "Gildenalarme: aus.",
    ["état des alertes de la guilde"]       = "Status der Gildenalarme",
    ["recevoir ou non les appels des guildiens"] = "Hilferufe der Gildenmitglieder empfangen oder nicht",
    -- Encart sous la fenêtre de mort
    ["Appeler la guilde à l'aide ?"]  = "Die Gilde um Hilfe rufen?",
    ["Tueur : %s (%s)"]               = "Getötet von %s (%s)",
    ["Tueur : %s"]                    = "Getötet von %s",
    ["Tueur : un joueur"]             = "Von einem Spieler getötet",
    ["Tueurs : %s"]                   = "Getötet von %s",
    ["zone inconnue"]                 = "unbekanntes Gebiet",
    ["position inconnue"]             = "Position unbekannt",
    ["Message (facultatif)"]          = "Nachricht (optional)",
    ["Appeler"]                       = "Rufen",
    -- Compte rendu d'un envoi, dans l'encart
    ["Mettre à jour"]                 = "Aktualisieren",
    ["Appel n°%d"]                    = "Ruf Nr. %d",
    ["guilde : prévenue"]             = "Gilde: benachrichtigt",
    ["guilde : échec"]                = "Gilde: fehlgeschlagen",
    ["Position illisible : appel impossible"] = "Position unlesbar: Ruf unmöglich",
    ["Appel impossible"]              = "Ruf unmöglich",
    -- Alertes reçues, et « Ton appel »
    ["%s appelle à l'aide !"]         = "%s ruft um Hilfe!",
    ["Morts : %d"]                    = "Tode: %d",
    ["« %s »"]                        = "„%s“",
    ["En route : %s"]                 = "Unterwegs: %s",
    ["J'arrive"]                      = "Ich komme",
    ["Voir sur la carte"]             = "Auf der Karte",
    ["Prévient la guilde et pose ton point de route sur lui (il remplace le tien)."] = "Sagt der Gilde Bescheid und setzt deinen Wegpunkt auf ihn (er ersetzt deinen).",
    ["En route"]                      = "Unterwegs",
    ["Ton appel n°%d"]                = "Dein Ruf Nr. %d",
    ["C'est réglé"]                   = "Erledigt",
    ["Personne en route pour l'instant"] = "Noch niemand unterwegs",
    -- La page d'options
    ["ouvre la page des réglages"] = "öffnet die Einstellungsseite",
    ["Réglages communs à tous les personnages du compte."] = "Einstellungen für alle Charaktere des Accounts.",
    ["Recevoir les appels des guildiens"] = "Rufe der Gildenmitglieder empfangen",
    ["Une fenêtre s'ouvre quand un guildien tué par un joueur appelle à l'aide. Comme /wpp on | off."] = "Ein Fenster öffnet sich, wenn ein von einem Spieler getötetes Gildenmitglied um Hilfe ruft. Wie /wpp on | off.",
    ["Toutes les commandes : /wpp help."] = "Alle Befehle: /wpp help.",
    ["Les options s'ouvrent hors combat."] = "Die Optionen öffnen sich nur außerhalb des Kampfes.",
    ["La page d'options n'existe pas sur ce client."] = "Die Optionsseite gibt es auf diesem Client nicht.",
}
for k, v in pairs(T) do NS.L[k] = v end
