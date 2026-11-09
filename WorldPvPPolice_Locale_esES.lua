-- WorldPvPPolice_Locale_esES.lua — overlay ESPAGNOL (esES/esMX). Clé FR → texte ES.
-- Chargé APRÈS WorldPvPPolice_Locale.lua (qui crée NS.L). Sur un client non espagnol : early-return.
local _, NS = ...
NS = NS or _G.WorldPvPPolice
if not NS or not NS.L then return end

local locale = GetLocale and GetLocale() or "enUS"
if locale ~= "esES" and locale ~= "esMX" then return end

local T = {
    ["version %s. Tape /%s pour l'aide."] = "versión %s. Escribe /%s para ver la ayuda.",
    ["version %s"]                    = "versión %s",
    ["Commandes :"]                   = "Comandos:",
    ["affiche la version"]            = "muestra la versión",
    ["Alertes de la guilde : activées."]    = "Alertas de la hermandad: activadas.",
    ["Alertes de la guilde : désactivées."] = "Alertas de la hermandad: desactivadas.",
    ["état des alertes de la guilde"]       = "estado de las alertas de la hermandad",
    ["recevoir ou non les appels des guildiens"] = "recibir o no las llamadas de la hermandad",
    -- Encart sous la fenêtre de mort
    ["Appeler la guilde à l'aide ?"]  = "¿Pedir ayuda a la hermandad?",
    ["Tueur : %s (%s)"]               = "Asesino: %s (%s)",
    ["Tueur : %s"]                    = "Asesino: %s",
    ["Tueur : un joueur"]             = "Asesino: un jugador",
    ["Tueurs : %s"]                   = "Asesinos: %s",
    ["zone inconnue"]                 = "zona desconocida",
    ["position inconnue"]             = "posición desconocida",
    ["Message (facultatif)"]          = "Mensaje (opcional)",
    ["Appeler"]                       = "Llamar",
    -- Compte rendu d'un envoi, dans l'encart
    ["Mettre à jour"]                 = "Actualizar",
    ["Appel n°%d"]                    = "Llamada n.º %d",
    ["guilde : prévenue"]             = "hermandad: avisada",
    ["guilde : échec"]                = "hermandad: fallo",
    ["Position illisible : appel impossible"] = "Posición ilegible: no se puede llamar",
    ["Appel impossible"]              = "No se puede llamar",
    -- Alertes reçues, et « Ton appel »
    ["%s appelle à l'aide !"]         = "¡%s pide ayuda!",
    ["Morts : %d"]                    = "Muertes: %d",
    ["« %s »"]                        = "«%s»",
    ["En route : %s"]                 = "En camino: %s",
    ["J'arrive"]                      = "Voy",
    ["Voir sur la carte"]             = "Ver en el mapa",
    ["Prévient la guilde et pose ton point de route sur lui (il remplace le tien)."] = "Avisa a la hermandad y pone tu punto de ruta sobre él (reemplaza el tuyo).",
    ["En route"]                      = "En camino",
    ["Ton appel n°%d"]                = "Tu llamada n.º %d",
    ["C'est réglé"]                   = "Resuelto",
    ["Personne en route pour l'instant"] = "Nadie en camino todavía",
    -- La page d'options
    ["ouvre la page des réglages"] = "abre la página de ajustes",
    ["Réglages communs à tous les personnages du compte."] = "Ajustes comunes a todos los personajes de la cuenta.",
    ["Recevoir les appels des guildiens"] = "Recibir las llamadas de la hermandad",
    ["Une fenêtre s'ouvre quand un guildien tué par un joueur appelle à l'aide. Comme /wpp on | off."] = "Se abre una ventana cuando alguien de la hermandad, muerto por un jugador, pide ayuda. Igual que /wpp on | off.",
    ["Toutes les commandes : /wpp help."] = "Todos los comandos: /wpp help.",
    ["Les options s'ouvrent hors combat."] = "Las opciones solo se abren fuera de combate.",
    ["La page d'options n'existe pas sur ce client."] = "La página de opciones no existe en este cliente.",
}
for k, v in pairs(T) do NS.L[k] = v end
