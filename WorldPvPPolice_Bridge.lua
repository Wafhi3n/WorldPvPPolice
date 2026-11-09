-- WorldPvPPolice_Bridge.lua — la prise d'un module de sortie (spec docs/specs/appel-sans-pont-discord.md,
-- S7 : le pont vers Discord est un addon à part, WorldPvPPoliceDiscord).
--
-- L'addon de base ne parle qu'à la guilde, en jeu, et son écran ne dit pas un mot de Discord. Un module
-- qui écrit ailleurs se branche ici par NS:Plug(objet), au chargement de ses fichiers (donc avant
-- PLAYER_LOGIN, avant que nos fenêtres se construisent) ; la base l'appelle aux moments où il a quelque
-- chose à faire. Rien de branché : chaque appel rend nil, et l'écran ne montre que la guilde.
--
-- RÈGLE DURE : la base appelle le module DANS la pile du geste (clic, Entrée), jamais depuis un
-- minuteur. C_Club.SendMessage exige un geste du joueur, et le module n'a que celui-là.
--
-- Ce que le module peut fournir, tout facultatif ; chaque appel passe par pcall : une erreur du module
-- ne casse jamais ce qui part à la guilde.
--   Fusion()               → true : le SOS porte le champ F (S5), les « J'arrive » suivent l'appel
--   Deliver(a, c, gesture) → état, attente, parti : l'appel `a` (ses champs `c`) vient de partir à la
--                            guilde ; « parti » = quelque chose est sorti chez le module (l'appel s'ouvre)
--   Settle(a)              → état : « C'est réglé » sur l'appel `a` (déjà clos chez nous)
--   Respond(alert)         → état : « J'arrive » sur l'alerte d'un guildien
--   PanelLine()            → la ligne du bas de l'encart, avant tout envoi
--   ReportSuffix(report)   → ajouté au compte rendu d'un envoi (« Appel n°7 · guilde : prévenue · … »)
--   CallerSuffix(a)        → ajouté aux morts dans « Ton appel »
--   Attach(parent, region) → appelé quand une ligne de texte de nos fenêtres se construit (un survol)
-- L'état rendu par Deliver va dans report.discord ; « pending » y veut dire « la suite viendra » : le
-- module la donne plus tard par NS.Call:Notify(état), et l'encart complète son compte rendu.
local _, NS = ...

NS.bridge = nil

function NS:Plug(bridge)
    if type(bridge) == "table" then NS.bridge = bridge end
end

local function returns(ok, ...)
    if not ok then return nil end
    return ...
end

function NS.Bridged(name, ...)
    local b = NS.bridge
    local fn = type(b) == "table" and b[name]
    if type(fn) ~= "function" then return nil end
    return returns(pcall(fn, b, ...))
end
