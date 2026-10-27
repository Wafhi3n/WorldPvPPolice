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
    ["Discord : relié"]               = "Discord: verbunden",
    ["Discord : non relié (appel en jeu seulement)"] = "Discord: nicht verbunden (Ruf nur im Spiel)",
    -- Compte rendu d'un envoi, dans l'encart
    ["Mettre à jour"]                 = "Aktualisieren",
    ["Appel n°%d"]                    = "Ruf Nr. %d",
    ["guilde : prévenue"]             = "Gilde: benachrichtigt",
    ["guilde : échec"]                = "Gilde: fehlgeschlagen",
    ["Discord : envoyé"]              = "Discord: gesendet",
    ["Discord : envoi en cours"]      = "Discord: wird gesendet",
    ["Discord : pas de retour"]       = "Discord: kein Echo, nicht gesendet",
    ["Discord : dans %d s"]           = "Discord: in %d s",
    ["Discord : non relié"]           = "Discord: nicht verbunden",
    ["Discord : refusé"]              = "Discord: abgelehnt",
    ["Position illisible : appel impossible"] = "Position unlesbar: Ruf unmöglich",
    ["Appel impossible"]              = "Ruf unmöglich",
}
for k, v in pairs(T) do NS.L[k] = v end
