-- WorldPvPPolice_Line.lua — les deux formats lus HORS de cette copie de l'addon (spec
-- docs/specs/appel-a-l-aide.md, section « Contrat ») :
--   - la ligne du fil Discord de la guilde, lue par le bot et par des humains ;
--   - le message d'addon de guilde (préfixe WPPolice), lu par les autres copies de l'addon.
-- Ce qui est gelé, c'est la forme produite : toute évolution s'ajoute en fin de ligne et un test
-- prouve que les lignes d'avant se relisent encore (tests/test_wpp_lines.lua). Seule exception,
-- datée : le 2026-10-27, AVANT toute release et tout lecteur, la v1 a reçu la zone seule (D14) et
-- plusieurs tueurs (D15) ; la forme à un tueur, avec coordonnées, est restée identique à l'octet.
--
-- Logique pure : rien n'est appelé au chargement, et les fonctions ne touchent au jeu que par
-- `issecretvalue` quand il existe. Les tests headless chargent ce fichier tel quel.
--
-- UNITÉ DES COORDONNÉES : dans tout ce module, x et y sont des FRACTIONS de la carte (0..1), comme les
-- rend C_Map.GetPlayerMapPosition. Le pourcentage à une décimale (« 42.1 ») n'existe que dans le texte
-- produit, et Parse/Decode rendent de nouveau des fractions.
local _, NS = ...

local Line = {}
NS.Line = Line

Line.MAX_BYTES = 255        -- une ligne de chat comme un message d'addon
Line.PREFIX = "WPPolice"    -- préfixe des messages d'addon de guilde
Line.WIRE_VERSION = "1"     -- premier champ du message d'addon ; un lecteur ignore une autre version
Line.MAX_KILLERS = 5        -- tueurs au plus dans un appel (D15)

local HEAD_MAX = 200        -- octets de tête au plus une fois les tueurs ajoutés : le message garde sa place
local TAB = string.char(9)
local WIRE_FIELDS = { SOS = 10, OMW = 4, END = 3 }
local FUSION = "F"          -- 11e champ facultatif d'un SOS : l'appel passe par le chat de guilde (S5)

-- Une valeur qu'on a le droit de lire. Une valeur SECRÈTE ne se concatène pas, ne se compare pas
-- (`v == nil` lève aussi : vu avec debug.newsecret de notre Elune) et ne se passe pas à :match : on
-- la teste AVANT toute opération, et `type` est le seul tri sûr avant ce test. Sans `issecretvalue`
-- (tests, autre client) tout est lisible ; un `issecretvalue` qui lève rend la valeur illisible.
local function readable(v)
    if type(v) == "nil" then return false end
    local probe = _G.issecretvalue
    if not probe then return true end
    local ok, secret = pcall(probe, v)
    return ok and not secret
end
Line.Readable = readable

local function isText(v) return readable(v) and type(v) == "string" end

local function isCount(v, min)
    return readable(v) and type(v) == "number" and v == math.floor(v) and v >= (min or 0)
end

local function isFraction(v)
    return readable(v) and type(v) == "number" and v >= 0 and v <= 1
end

-- Un texte libre sans ce qui casserait une lecture : `|` (codes du chat), `[ ]` (le bot répondrait des
-- liens Wowhead), `#` (un faux `#SOS`), les caractères de contrôle (retours à la ligne, tabulations) ;
-- `extra` retire d'autres caractères (les parenthèses d'une zone). Blancs regroupés, bords ôtés.
local function clean(s, extra)
    if not isText(s) then return "" end
    s = s:gsub("[%c|%[%]#]", " ")
    if extra then s = s:gsub(extra, " ") end
    s = s:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    return s
end
Line.Clean = clean

-- `,` sépare les tueurs d'une liste : jamais dans un nom (le jeu n'en produit pas, une ligne forgée
-- décalerait l'alignement des noms et des classes).
local RESERVED = "[%s%c|%[%]#:,]"

-- DEUX FORMES DE NOM COMPLET, selon le client (le serveur s'en sert partout : émetteur de
-- CHAT_MSG_ADDON, cible d'un chuchotement) :
--   - Forever : « Prénom Nom », une ESPACE, jamais de royaume (UnitName rend prénom, nom de famille ;
--     mesuré le 2026-09-27, skill public wow-forever-api) ;
--   - Retail / Midnight (le PTR, 2e cible jusqu'au lancement) : « Nom-Royaume ».

-- Un nom à AFFICHER dans une ligne : le premier mot, sans royaume (règle du user : le pont entre
-- royaumes reste invisible) ni nom de famille (la ligne Discord n'a pas d'espace dans un nom), sans
-- caractère réservé. nil si illisible ou vide. Jamais pour COMPARER : plusieurs joueurs partagent un
-- prénom.
local function shortName(name)
    if not isText(name) then return nil end
    name = name:match("^([^%-%s]+)")
    if not name or name:find(RESERVED) then return nil end
    return name
end
Line.ShortName = shortName

-- Un nom sur le FIL entre copies de l'addon : le nom COMPLET tel que CHAT_MSG_ADDON le rend (l'une ou
-- l'autre forme), qui sert à reconnaître l'appelant. Des mots séparés d'UNE espace ; ni tabulation
-- (séparateur du fil), ni `| [ ] # : ,`, ni caractère de contrôle.
local WIRE_RESERVED = "[%c|%[%]#:,]"
local function wireName(name)
    if not isText(name) or name == "" or name:find(WIRE_RESERVED) then return nil end
    if name:find("^%s") or name:find("%s$") or name:find("%s%s") then return nil end
    return name
end
Line.WireName = wireName

local function classToken(c)
    if isText(c) and c:match("^%u+$") then return c end
    return nil
end

local function pct(f) return string.format("%.1f", f * 100) end
local function frac(s) return tonumber(s) / 100 end

-- Coupe `s` à `budget` octets au plus sans couper un caractère UTF-8 : tant que l'octet qui suit la
-- coupe est une suite (10xxxxxx), on recule.
local function cutBytes(s, budget)
    if budget <= 0 then return "" end
    if #s <= budget then return s end
    local cut = budget
    while cut > 0 do
        local b = s:byte(cut + 1)
        if not b or b < 128 or b >= 192 then break end
        cut = cut - 1
    end
    return (s:sub(1, cut):gsub(" +$", ""))
end
Line.CutBytes = cutBytes

-- Ajoute « <sep><msg> » à `head` si le message (nettoyé, coupé) tient dans MAX_BYTES ; la tête, elle,
-- n'est jamais coupée. `reserve` : les octets à laisser après le message.
local function withMessage(head, msg, sep, reserve)
    msg = clean(msg)
    if msg == "" then return head, "" end
    msg = cutBytes(msg, Line.MAX_BYTES - #head - #sep - (reserve or 0))
    if msg == "" then return head, "" end
    return head .. sep .. msg, msg
end

-- Les champs communs d'un appel, validés : "xy" (coordonnées connues) ou "zone" (zone seule, D14) ;
-- nil + raison sinon. Coordonnées ABSENTES ou illisibles toutes les deux = zone seule ; une seule des
-- deux, ou hors de 0..1 (un pourcentage passé pour une fraction) = refus « pos ».
-- `c` : { n, map, x, y, deaths, killers (ou killer + class), msg } (+ who, zone pour la ligne Discord).
local function checkCall(c)
    local hasX, hasY = readable(c.x), readable(c.y)
    if (hasX or hasY) and not (isFraction(c.x) and isFraction(c.y)) then return nil, "pos" end
    if not (isCount(c.n, 1) and isCount(c.map, 1) and isCount(c.deaths, 1)) then return nil, "num" end
    return hasX and "xy" or "zone"
end

-- Les tueurs d'un appel (D15) : `c.killers` = { { name, class }, … }, ou le raccourci d'un seul tueur
-- `c.killer` / `c.class`. Seuls les noms lisibles restent (sans royaume), MAX_KILLERS au plus ; une
-- classe sans nom ne reste pas (elle n'a de sens qu'à côté d'un nom).
local function killersOf(c)
    local src = c.killers
    if type(src) ~= "table" then src = { { name = c.killer, class = c.class } } end
    local list = {}
    for _, k in ipairs(src) do
        local name = type(k) == "table" and shortName(k.name)
        if name and #list < Line.MAX_KILLERS then list[#list + 1] = { name = name, class = classToken(k.class) } end
    end
    return list
end

-- Les `count` premiers tueurs en deux listes ALIGNÉES : noms « A,B », classes « ROGUE,- » (`-` =
-- classe inconnue) ; pas de liste de classes (nil) si aucune n'est connue.
local function lists(list, count)
    local names, classes, known = {}, {}, false
    for i = 1, count do
        names[i] = list[i].name
        classes[i] = list[i].class or "-"
        if list[i].class then known = true end
    end
    return table.concat(names, ","), known and table.concat(classes, ",") or nil
end

-- Ajoute à `head` autant de tueurs que la tête en tient (HEAD_MAX), en retirant les derniers d'abord :
-- un appel ne se perd jamais pour trop de tueurs.
local function fitKillers(head, list, render)
    for count = #list, 1, -1 do
        local part = render(list, count)
        if #head + #part <= HEAD_MAX then return head .. part end
    end
    return head .. render(list, 0)
end

local function discordKillers(list, count)
    if count == 0 then return "" end
    local names, classes = lists(list, count)
    return " k" .. names .. (classes and " c" .. classes or "")
end

-- ===== Ligne du fil Discord =====

-- SOS <Perso> <Zone>[ (<x>, <y>)] #SOS<n> m<uiMapID> d<morts>[ k<T1>,<T2>…][ c<C1>,<C2>…][ : <message>]
function Line.BuildSOS(c)
    local who = shortName(c.who)
    if not who then return nil, "who" end
    local ok, why = checkCall(c)
    if not ok then return nil, why end
    local where = clean(c.zone, "[%(%)]")
    if where == "" then return nil, "zone" end
    if ok == "xy" then where = string.format("%s (%s, %s)", where, pct(c.x), pct(c.y)) end
    local head = string.format("SOS %s %s #SOS%d m%d d%d", who, where, c.n, c.map, c.deaths)
    head = fitKillers(head, killersOf(c), discordKillers)
    if #head > Line.MAX_BYTES then return nil, "long" end
    return (withMessage(head, c.msg, " : "))
end

-- OMW <Répondant> > <Perso> #SOS<n>
function Line.BuildOMW(responder, caller, n)
    local r, c = shortName(responder), shortName(caller)
    if not (r and c and isCount(n, 1)) then return nil end
    return string.format("OMW %s > %s #SOS%d", r, c, n)
end

-- END <Perso> #SOS<n>
function Line.BuildEND(caller, n)
    local c = shortName(caller)
    if not (c and isCount(n, 1)) then return nil end
    return string.format("END %s #SOS%d", c, n)
end

local SOS_HEAD = "^SOS (%S+) (.-) #SOS(%d+) m(%d+) d(%d+)(.*)$"

-- « Zone (42.1, 65.3) » ou « Zone » seule (D14). La zone ne contient jamais de parenthèse : une
-- parenthèse qui n'est pas celle des coordonnées fait refuser la ligne.
local function parseWhere(where)
    local zone, x, y = where:match("^(.-) %((%d+%.%d), (%d+%.%d)%)$")
    if not zone then zone = where end
    if zone == "" or zone:find("[%(%)]") then return nil end
    if not x then return zone end
    x, y = frac(x), frac(y)
    if x > 1 or y > 1 then return nil end
    return zone, x, y
end

-- (s .. ","):gmatch("(.-),") et non gmatch("([^,]*)") : même piège de Lua 5.1 que les tabulations.
local function splitList(s)
    local items = {}
    for item in (s .. ","):gmatch("(.-),") do items[#items + 1] = item end
    return items
end

-- Deux listes alignées (D15) : autant de classes que de noms, `-` = classe inconnue. Rend la liste
-- { { name, class }, … }, ou nil si elles ne s'alignent pas, si un nom est vide ou réservé, si une
-- classe n'est pas un jeton.
local function killerList(names, classes)
    names = splitList(names)
    classes = classes and splitList(classes)
    if classes and #classes ~= #names then return nil end
    local list = {}
    for i, raw in ipairs(names) do
        local name = shortName(raw)
        if name ~= raw then return nil end
        local class = classes and classes[i]
        if class == "-" then class = nil elseif class and not classToken(class) then return nil end
        list[i] = { name = name, class = class }
    end
    return list
end

-- Les tueurs de la ligne, posés dans `t` (killers, et le raccourci killer / class du premier) ; rend
-- la suite de la ligne, ou nil si elle est refusée (un `c` sans `k`, des listes mal alignées).
local function parseKillers(t, rest)
    local k, afterK = rest:match("^ k(%S+)(.*)$")
    if k then rest = afterK end
    local cl, afterC = rest:match("^ c(%S+)(.*)$")
    if cl then rest = afterC end
    t.killers = {}
    if not k then return not cl and rest or nil end
    local list = killerList(k, cl)
    if not list then return nil end
    t.killers, t.killer, t.class = list, list[1].name, list[1].class
    return rest
end

local function parseSOS(text)
    local who, where, n, map, d, rest = text:match(SOS_HEAD)
    if not who then return nil end
    local zone, x, y = parseWhere(where)
    if not zone then return nil end
    local t = { kind = "SOS", who = who, zone = zone, x = x, y = y,
                n = tonumber(n), map = tonumber(map), deaths = tonumber(d) }
    rest = parseKillers(t, rest)
    if not rest then return nil end
    local msg = rest:match("^ : (.*)$")
    if msg then
        -- BuildSOS ôte ces caractères du message : s'il en reste, la ligne n'est pas la nôtre.
        if msg:find("[%c|%[%]#]") then return nil end
        t.msg, rest = (msg:gsub("%s+$", "")), ""
    end
    if not rest:match("^%s*$") then return nil end
    return t
end

-- Relit une ligne du fil Discord ; nil si ce n'en est pas une (une commande de COC, du texte libre).
function Line.Parse(text)
    if not isText(text) then return nil end
    local kind = text:match("^(%u%u%u) ")
    if kind == "SOS" then return parseSOS(text) end
    if kind == "OMW" then
        local r, c, n = text:match("^OMW (%S+) > (%S+) #SOS(%d+)%s*$")
        if r then return { kind = "OMW", who = r, caller = c, n = tonumber(n) } end
    elseif kind == "END" then
        local c, n = text:match("^END (%S+) #SOS(%d+)%s*$")
        if c then return { kind = "END", who = c, n = tonumber(n) } end
    end
    return nil
end

-- ===== Message d'addon de guilde =====
-- Champs séparés par une tabulation, version en tête :
--   1 SOS <n> <uiMapID> <x|-> <y|-> <morts> <tueurs|-> <CLASSES|-> <message>[ F]   (émetteur = l'appelant)
--   1 OMW <n> <appelant>                                                      (émetteur = le répondant)
--   1 END <n>                                                                 (émetteur = l'appelant)
-- <tueurs> et <CLASSES> : listes alignées séparées par des virgules, comme sur la ligne Discord.
-- F (11e champ, absent sinon : un SOS sans lui ne change pas d'un octet) : l'appel passe par le chat de
-- guilde, les « J'arrive » le suivent (S5 de docs/specs/appel-sans-pont-discord.md).

local function wireKillers(list, count)
    if count == 0 then return TAB .. "-" .. TAB .. "-" end
    local names, classes = lists(list, count)
    return TAB .. names .. TAB .. (classes or "-")
end

function Line.EncodeSOS(c)
    local ok, why = checkCall(c)
    if not ok then return nil, why end
    local x, y = "-", "-"
    if ok == "xy" then x, y = pct(c.x), pct(c.y) end
    local head = table.concat({ Line.WIRE_VERSION, "SOS", c.n, c.map, x, y, c.deaths }, TAB)
    head = fitKillers(head, killersOf(c), wireKillers)
    local tail = c.fusion and TAB .. FUSION or ""
    local payload, msg = withMessage(head, c.msg, TAB, #tail)
    if msg == "" then payload = head .. TAB end
    return payload .. tail
end

function Line.EncodeOMW(n, caller)
    local c = wireName(caller)
    if not (c and isCount(n, 1)) then return nil end
    return table.concat({ Line.WIRE_VERSION, "OMW", n, c }, TAB)
end

function Line.EncodeEND(n)
    if not isCount(n, 1) then return nil end
    return table.concat({ Line.WIRE_VERSION, "END", n }, TAB)
end

-- (s .. TAB):gmatch("(.-)" .. TAB) et non gmatch("([^\t]*)") : en Lua 5.1, ce dernier rend des
-- champs vides en trop, et un message mal formé se lirait décalé au lieu d'être refusé.
local function split(payload)
    local fields = {}
    for f in (payload .. TAB):gmatch("(.-)" .. TAB) do fields[#fields + 1] = f end
    return fields
end

local function num(s, min)
    if not (s and s:match("^%d+$")) then return nil end
    local v = tonumber(s)
    if v < (min or 0) then return nil end
    return v
end

-- Les coordonnées du fil : « 42.1 » « 65.3 », ou « - » « - » (zone seule, D14). Rend (ok, x, y).
local function decodeWhere(fx, fy)
    if fx == "-" and fy == "-" then return true end
    if not (fx:match("^%d+%.%d$") and fy:match("^%d+%.%d$")) then return false end
    local x, y = frac(fx), frac(fy)
    if x > 1 or y > 1 then return false end
    return true, x, y
end

local function decodeSOS(f)
    local n, map, d = num(f[3], 1), num(f[4], 1), num(f[7], 1)
    local okXY, x, y = decodeWhere(f[5], f[6])
    local killers
    if f[8] == "-" then
        killers = f[9] == "-" and {} or nil
    else
        killers = killerList(f[8], f[9] ~= "-" and f[9] or nil)
    end
    if not (n and map and d and okXY and killers) then return nil end
    local first = killers[1] or {}
    return { kind = "SOS", n = n, map = map, x = x, y = y, deaths = d, killers = killers,
             killer = first.name, class = first.class, msg = clean(f[10]), fusion = f[11] == FUSION or nil }
end

local function fieldCountOk(f)
    if f[2] == "SOS" and #f == WIRE_FIELDS.SOS + 1 then return f[#f] == FUSION end
    return #f == WIRE_FIELDS[f[2]]
end

-- Relit un message d'addon ; nil (sans erreur) pour une autre version, une autre sorte ou un nombre
-- de champs inattendu.
function Line.Decode(payload)
    if not isText(payload) then return nil end
    local f = split(payload)
    if f[1] ~= Line.WIRE_VERSION or not fieldCountOk(f) then return nil end
    if f[2] == "SOS" then return decodeSOS(f) end
    local n = num(f[3], 1)
    if not n then return nil end
    if f[2] == "OMW" then
        local caller = wireName(f[4])
        return caller and { kind = "OMW", n = n, caller = caller } or nil
    end
    return { kind = "END", n = n }
end
