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
    ["Discord : relié"]               = "Discord: vinculado",
    ["Discord : non relié (appel en jeu seulement)"] = "Discord: no vinculado (llamada solo en el juego)",
    -- Compte rendu d'un envoi, dans l'encart
    ["Mettre à jour"]                 = "Actualizar",
    ["Appel n°%d"]                    = "Llamada n.º %d",
    ["guilde : prévenue"]             = "hermandad: avisada",
    ["guilde : échec"]                = "hermandad: fallo",
    ["Discord : envoyé"]              = "Discord: enviado",
    ["Discord : envoi en cours"]      = "Discord: enviando",
    ["Discord : pas de retour"]       = "Discord: sin eco, no enviado",
    ["Discord : dans %d s"]           = "Discord: en %d s",
    ["Discord : non relié"]           = "Discord: no vinculado",
    ["Discord : refusé"]              = "Discord: rechazado",
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
    ["Discord : pas envoyé"]          = "Discord: no enviado",
    ["Discord : pas à jour"]          = "Discord: sin actualizar",
    ["Personne en route pour l'instant"] = "Nadie en camino todavía",
    -- Sans lien avec Discord
    ["Discord : par le chat de guilde"] = "Discord: por el chat de hermandad",
    ["L'appel part en jeu, pas sur Discord. Il faut :"] = "La llamada sale en el juego, no en Discord. Hace falta:",
    ["- la guilde reliée à un serveur Discord ;"] = "- la hermandad vinculada a un servidor de Discord;",
    ["- la case qui sépare le chat Discord du chat de guilde, cochée ;"] = "- la casilla que separa el chat de Discord del de hermandad, marcada;",
    ["- peut-être aussi ton compte Battle.net relié à Discord."] = "- quizá también tu cuenta de Battle.net vinculada a Discord.",
    ["Le maître de guilde ou un officier s'en charge : Guilde et communautés (J), clic droit sur la guilde, ses réglages Discord."] = "Se encarga quien lidera la hermandad o un oficial: Hermandad y comunidades (J), clic derecho en la hermandad, sus ajustes de Discord.",
    ["Guilde en chat fusionné : /wpp fusion on."] = "Hermandad con chat combinado: /wpp fusion on.",
    ["Discord en chat fusionné : désactivé."] = "Discord con chat combinado: desactivado.",
    ["Discord en chat fusionné : activé, mais sans effet : la guilde a son fil Discord séparé."] = "Discord con chat combinado: activado, pero sin efecto: la hermandad tiene su chat de Discord separado.",
    ["Discord en chat fusionné : activé. Tes appels s'écrivent aussi dans le chat de guilde, les « J'arrive » suivent."] = "Discord con chat combinado: activado. Tus llamadas también se escriben en el chat de hermandad, y «Voy» las sigue.",
    ["Discord : relié."] = "Discord: vinculado.",
    ["Discord : non relié. Le maître de guilde ou un officier relie la guilde et coche la case qui sépare le chat Discord (Guilde et communautés, clic droit sur la guilde). Guilde en chat fusionné : /wpp fusion on."] = "Discord: sin vincular. Quien lidera la hermandad o un oficial la vincula y marca la casilla que separa el chat de Discord (Hermandad y comunidades, clic derecho en la hermandad). Hermandad con chat combinado: /wpp fusion on.",
    -- Discord coupé par le joueur, et la page d'options
    ["le lien avec Discord ; off : tes appels restent en jeu"] = "el vínculo con Discord; off: tus llamadas se quedan en el juego",
    ["ouvre la page des réglages"] = "abre la página de ajustes",
    ["Discord : coupé, tes appels restent en jeu. Pour les écrire sur Discord : /wpp discord on."] = "Discord: desactivado, tus llamadas se quedan en el juego. Para escribirlas en Discord: /wpp discord on.",
    ["Discord en chat fusionné : activé, mais sans effet : Discord est coupé (/wpp discord on)."] = "Discord con chat combinado: activado, pero sin efecto: Discord está desactivado (/wpp discord on).",
    ["Pas de bot World PvP Police sur le Discord de la guilde ? /wpp discord off : l'appel reste en jeu, sans ce rappel."] = "¿No hay bot de World PvP Police en el Discord de la hermandad? /wpp discord off: la llamada se queda en el juego, sin este aviso.",
    ["Réglages communs à tous les personnages du compte."] = "Ajustes comunes a todos los personajes de la cuenta.",
    ["Recevoir les appels des guildiens"] = "Recibir las llamadas de la hermandad",
    ["Une fenêtre s'ouvre quand un guildien tué par un joueur appelle à l'aide. Comme /wpp on | off."] = "Se abre una ventana cuando alguien de la hermandad, muerto por un jugador, pide ayuda. Igual que /wpp on | off.",
    ["Écrire les appels sur Discord"] = "Escribir las llamadas en Discord",
    ["Pour une guilde dont le Discord a le bot World PvP Police. Décoché : tes appels et tes « J'arrive » restent en jeu, rien n'est écrit sur Discord, et l'addon n'en parle plus. Comme /wpp discord on | off."] = "Para una hermandad cuyo Discord tiene el bot de World PvP Police. Sin marcar: tus llamadas y tu «Voy» se quedan en el juego, no se escribe nada en Discord y el addon deja de mencionarlo. Igual que /wpp discord on | off.",
    ["Discord en chat fusionné"] = "Discord con chat combinado",
    ["Guilde reliée à Discord sans fil séparé : l'appel s'écrit aussi dans le chat de guilde, que toute la guilde voit. Comme /wpp fusion on | off."] = "Hermandad vinculada a Discord sin chat separado: la llamada también se escribe en el chat de hermandad, que ve toda la hermandad. Igual que /wpp fusion on | off.",
    ["Toutes les commandes : /wpp help."] = "Todos los comandos: /wpp help.",
    ["Les options s'ouvrent hors combat."] = "Las opciones solo se abren fuera de combate.",
    ["La page d'options n'existe pas sur ce client."] = "La página de opciones no existe en este cliente.",
    ["guilde en chat fusionné : l'appel passe par le chat de guilde"] = "hermandad con chat combinado: la llamada pasa por el chat de hermandad",
}
for k, v in pairs(T) do NS.L[k] = v end
