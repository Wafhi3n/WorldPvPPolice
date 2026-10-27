-- WorldPvPPolice_Line.lua — les deux formats lus HORS de cette copie de l'addon (spec
-- docs/specs/appel-a-l-aide.md, section « Contrat ») :
--   - la ligne du fil Discord de la guilde, lue par le bot et par des humains ;
--   - le message d'addon de guilde (préfixe WPPolice), lu par les autres copies de l'addon.
-- Ce qui est gelé, c'est la forme produite : toute évolution s'ajoute en fin de ligne et un test
-- prouve que les lignes d'avant se relisent encore (tests/test_wpp_lines.lua).
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

local TAB = string.char(9)
local WIRE_FIELDS = { SOS = 10, OMW = 4, END = 3 }

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

local RESERVED = "[%s%c|%[%]#:]"

-- Un nom à AFFICHER : sans royaume (règle du user : le pont entre royaumes reste invisible), sans
-- blanc ni caractère réservé. nil si illisible ou vide.
local function shortName(name)
    if not isText(name) then return nil end
    name = name:match("^([^%-]+)")
    if not name or name:find(RESERVED) then return nil end
    return name
end
Line.ShortName = shortName

-- Un nom sur le FIL entre copies de l'addon : garde le royaume (« Nom-Royaume » : c'est ce que rend
-- CHAT_MSG_ADDON entre royaumes, et ce qui sert à reconnaître l'appelant).
local function wireName(name)
    if not isText(name) or name == "" or name:find(RESERVED) then return nil end
    return name
end

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
-- n'est jamais coupée.
local function withMessage(head, msg, sep)
    msg = clean(msg)
    if msg == "" then return head, "" end
    msg = cutBytes(msg, Line.MAX_BYTES - #head - #sep)
    if msg == "" then return head, "" end
    return head .. sep .. msg, msg
end

-- Les champs communs d'un appel, validés ; nil + raison sinon. `c` : { n, map, x, y, deaths, killer,
-- class, msg } (+ who, zone pour la ligne Discord).
local function checkCall(c)
    if not (isFraction(c.x) and isFraction(c.y)) then return nil, "pos" end
    if not (isCount(c.n, 1) and isCount(c.map, 1) and isCount(c.deaths, 1)) then return nil, "num" end
    return true
end

-- ===== Ligne du fil Discord =====

-- SOS <Perso> <Zone> (<x>, <y>) #SOS<n> m<uiMapID> d<morts>[ k<Tueur>][ c<CLASSE>][ : <message>]
function Line.BuildSOS(c)
    local who = shortName(c.who)
    if not who then return nil, "who" end
    local ok, why = checkCall(c)
    if not ok then return nil, why end
    local zone = clean(c.zone, "[%(%)]")
    if zone == "" then return nil, "zone" end
    local head = string.format("SOS %s %s (%s, %s) #SOS%d m%d d%d",
        who, zone, pct(c.x), pct(c.y), c.n, c.map, c.deaths)
    local killer = shortName(c.killer)
    if killer then head = head .. " k" .. killer end
    local class = classToken(c.class)
    if class then head = head .. " c" .. class end
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

local SOS_HEAD = "^SOS (%S+) (.-) %((%d+%.%d), (%d+%.%d)%) #SOS(%d+) m(%d+) d(%d+)(.*)$"

local function parseSOS(text)
    local who, zone, x, y, n, map, d, rest = text:match(SOS_HEAD)
    if not who then return nil end
    local t = { kind = "SOS", who = who, zone = zone, x = frac(x), y = frac(y),
                n = tonumber(n), map = tonumber(map), deaths = tonumber(d) }
    local k, afterK = rest:match("^ k(%S+)(.*)$")
    if k then t.killer, rest = k, afterK end
    local cl, afterC = rest:match("^ c(%u+)(.*)$")
    if cl then t.class, rest = cl, afterC end
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
--   1 SOS <n> <uiMapID> <x> <y> <morts> <tueur|-> <CLASSE|-> <message>   (émetteur = l'appelant)
--   1 OMW <n> <appelant>                                                (émetteur = le répondant)
--   1 END <n>                                                           (émetteur = l'appelant)

function Line.EncodeSOS(c)
    local ok, why = checkCall(c)
    if not ok then return nil, why end
    local head = table.concat({ Line.WIRE_VERSION, "SOS", c.n, c.map, pct(c.x), pct(c.y), c.deaths,
        shortName(c.killer) or "-", classToken(c.class) or "-" }, TAB)
    local payload, msg = withMessage(head, c.msg, TAB)
    if msg == "" then payload = head .. TAB end
    return payload
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

local function decodeSOS(f)
    local n, map, d = num(f[3], 1), num(f[4], 1), num(f[7], 1)
    if not (n and map and d and f[5]:match("^%d+%.%d$") and f[6]:match("^%d+%.%d$")) then return nil end
    local x, y = frac(f[5]), frac(f[6])
    if x > 1 or y > 1 then return nil end
    local killer = f[8] ~= "-" and shortName(f[8]) or nil
    local class = f[9] ~= "-" and classToken(f[9]) or nil
    return { kind = "SOS", n = n, map = map, x = x, y = y, deaths = d,
             killer = killer, class = class, msg = clean(f[10]) }
end

-- Relit un message d'addon ; nil (sans erreur) pour une autre version, une autre sorte ou un nombre
-- de champs inattendu.
function Line.Decode(payload)
    if not isText(payload) then return nil end
    local f = split(payload)
    if f[1] ~= Line.WIRE_VERSION or #f ~= WIRE_FIELDS[f[2]] then return nil end
    if f[2] == "SOS" then return decodeSOS(f) end
    local n = num(f[3], 1)
    if not n then return nil end
    if f[2] == "OMW" then
        local caller = wireName(f[4])
        return caller and { kind = "OMW", n = n, caller = caller } or nil
    end
    return { kind = "END", n = n }
end
