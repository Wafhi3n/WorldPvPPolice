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
    ["Discord : pas envoyé"]          = "Discord: nicht gesendet",
    ["Discord : pas à jour"]          = "Discord: nicht aktuell",
    ["Personne en route pour l'instant"] = "Noch niemand unterwegs",
    -- Sans lien avec Discord
    ["Discord : par le chat de guilde"] = "Discord: über den Gildenchat",
    ["L'appel part en jeu, pas sur Discord. Il faut :"] = "Der Ruf geht im Spiel raus, nicht zu Discord. Dafür braucht es:",
    ["- la guilde reliée à un serveur Discord ;"] = "- die Gilde mit einem Discord-Server verknüpft;",
    ["- la case qui sépare le chat Discord du chat de guilde, cochée ;"] = "- das Häkchen, das den Discord-Chat vom Gildenchat trennt;",
    ["- peut-être aussi ton compte Battle.net relié à Discord."] = "- vielleicht auch dein Battle.net-Konto mit Discord verknüpft.",
    ["Le maître de guilde ou un officier s'en charge : Guilde et communautés (J), clic droit sur la guilde, ses réglages Discord."] = "Das erledigt die Gildenleitung oder ein Offizier: Gilde & Communitys (J), Rechtsklick auf die Gilde, ihre Discord-Einstellungen.",
    ["Guilde en chat fusionné : /wpp fusion on."] = "Gilde mit zusammengelegtem Chat: /wpp fusion on.",
    ["Discord en chat fusionné : désactivé."] = "Discord im zusammengelegten Chat: aus.",
    ["Discord en chat fusionné : activé, mais sans effet : la guilde a son fil Discord séparé."] = "Discord im zusammengelegten Chat: an, aber ohne Wirkung: Die Gilde hat ihren getrennten Discord-Chat.",
    ["Discord en chat fusionné : activé. Tes appels s'écrivent aussi dans le chat de guilde, les « J'arrive » suivent."] = "Discord im zusammengelegten Chat: an. Deine Rufe erscheinen auch im Gildenchat, „Ich komme“ folgt ihnen.",
    ["Discord : relié."] = "Discord: verknüpft.",
    ["Discord : non relié. Le maître de guilde ou un officier relie la guilde et coche la case qui sépare le chat Discord (Guilde et communautés, clic droit sur la guilde). Guilde en chat fusionné : /wpp fusion on."] = "Discord: nicht verknüpft. Die Gildenleitung oder ein Offizier verknüpft die Gilde und setzt das Häkchen, das den Discord-Chat trennt (Gilde & Communitys, Rechtsklick auf die Gilde). Gilde mit zusammengelegtem Chat: /wpp fusion on.",
    ["où en est le lien avec Discord"] = "wie es um die Verknüpfung mit Discord steht",
    ["guilde en chat fusionné : l'appel passe par le chat de guilde"] = "Gilde mit zusammengelegtem Chat: Der Ruf läuft über den Gildenchat",
}
for k, v in pairs(T) do NS.L[k] = v end
