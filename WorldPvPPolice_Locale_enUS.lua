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
    ["Voir sur la carte"]             = "Show on map",
    ["Prévient la guilde et pose ton point de route sur lui (il remplace le tien)."] = "Tells the guild and sets your waypoint on them (it replaces yours).",
    ["En route"]                      = "On the way",
    ["Ton appel n°%d"]                = "Your call #%d",
    ["C'est réglé"]                   = "All clear",
    ["Discord : pas envoyé"]          = "Discord: not sent",
    ["Discord : pas à jour"]          = "Discord: not up to date",
    ["Personne en route pour l'instant"] = "Nobody on the way yet",
    -- Sans lien avec Discord
    ["Discord : par le chat de guilde"] = "Discord: through guild chat",
    ["L'appel part en jeu, pas sur Discord. Il faut :"] = "The call goes out in game, not to Discord. It takes:",
    ["- la guilde reliée à un serveur Discord ;"] = "- the guild linked to a Discord server;",
    ["- la case qui sépare le chat Discord du chat de guilde, cochée ;"] = "- the box that separates Discord chat from guild chat, checked;",
    ["- peut-être aussi ton compte Battle.net relié à Discord."] = "- maybe also your Battle.net account linked to Discord.",
    ["Le maître de guilde ou un officier s'en charge : Guilde et communautés (J), clic droit sur la guilde, ses réglages Discord."] = "The guild leader or an officer does this: Guild & Communities (J), right-click the guild, its Discord settings.",
    ["Guilde en chat fusionné : /wpp fusion on."] = "Guild with merged chat: /wpp fusion on.",
    ["Discord en chat fusionné : désactivé."] = "Discord with merged chat: off.",
    ["Discord en chat fusionné : activé, mais sans effet : la guilde a son fil Discord séparé."] = "Discord with merged chat: on, but it does nothing: the guild has its separate Discord chat.",
    ["Discord en chat fusionné : activé. Tes appels s'écrivent aussi dans le chat de guilde, les « J'arrive » suivent."] = "Discord with merged chat: on. Your calls are also written to guild chat, and “On my way” follows.",
    ["Discord : relié."] = "Discord: linked.",
    ["Discord : non relié. Le maître de guilde ou un officier relie la guilde et coche la case qui sépare le chat Discord (Guilde et communautés, clic droit sur la guilde). Guilde en chat fusionné : /wpp fusion on."] = "Discord: not linked. The guild leader or an officer links the guild and checks the box that separates Discord chat (Guild & Communities, right-click the guild). Guild with merged chat: /wpp fusion on.",
    ["guilde en chat fusionné : l'appel passe par le chat de guilde"] = "guild with merged chat: the call goes through guild chat",
    -- Discord coupé par le joueur, et la page d'options
    ["le lien avec Discord ; off : tes appels restent en jeu"] = "the link with Discord; off: your calls stay in game",
    ["ouvre la page des réglages"] = "opens the settings page",
    ["Discord : coupé, tes appels restent en jeu. Pour les écrire sur Discord : /wpp discord on."] = "Discord: off, your calls stay in game. To write them to Discord: /wpp discord on.",
    ["Discord en chat fusionné : activé, mais sans effet : Discord est coupé (/wpp discord on)."] = "Discord with merged chat: on, but it does nothing: Discord is off (/wpp discord on).",
    ["Pas de bot World PvP Police sur le Discord de la guilde ? /wpp discord off : l'appel reste en jeu, sans ce rappel."] = "No World PvP Police bot on the guild's Discord? /wpp discord off: the call stays in game, without this reminder.",
    ["Réglages communs à tous les personnages du compte."] = "Settings shared by every character on the account.",
    ["Recevoir les appels des guildiens"] = "Receive guildmates' calls",
    ["Une fenêtre s'ouvre quand un guildien tué par un joueur appelle à l'aide. Comme /wpp on | off."] = "A window opens when a guildmate killed by a player calls for help. Same as /wpp on | off.",
    ["Écrire les appels sur Discord"] = "Write calls to Discord",
    ["Pour une guilde dont le Discord a le bot World PvP Police. Décoché : tes appels et tes « J'arrive » restent en jeu, rien n'est écrit sur Discord, et l'addon n'en parle plus. Comme /wpp discord on | off."] = "For a guild whose Discord has the World PvP Police bot. Unchecked: your calls and your “On my way” stay in game, nothing is written to Discord, and the addon stops mentioning it. Same as /wpp discord on | off.",
    ["Discord en chat fusionné"] = "Discord with merged chat",
    ["Guilde reliée à Discord sans fil séparé : l'appel s'écrit aussi dans le chat de guilde, que toute la guilde voit. Comme /wpp fusion on | off."] = "Guild linked to Discord without a separate chat: the call is also written to guild chat, which the whole guild sees. Same as /wpp fusion on | off.",
    ["Toutes les commandes : /wpp help."] = "All commands: /wpp help.",
    ["Les options s'ouvrent hors combat."] = "Options open out of combat only.",
    ["La page d'options n'existe pas sur ce client."] = "The options page doesn't exist on this client.",
}
for k, v in pairs(T) do NS.L[k] = v end
