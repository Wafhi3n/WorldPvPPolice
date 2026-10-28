-- WorldPvPPolice_Panel.lua — l'encart d'appel sous la fenêtre de mort (spec
-- docs/specs/appel-a-l-aide.md, « Ce qu'on veut » 1 et 2, D2, D3, D4, D13).
--
-- La fenêtre de mort est un StaticPopup de Blizzard (« DEATH » ; « HARDCORE_DEATH » en mode hardcore,
-- où la mort est définitive : pas d'encart). On ne l'écrit JAMAIS : on s'accroche à StaticPopup_Show
-- et à StaticPopup_OnClick (hooksecurefunc, après Blizzard) et notre cadre, à nous, s'ancre sous elle.
-- Un champ posé sur la fenêtre ou un script remplacé pourrait gâter « Libérer l'esprit » (M7 au banc).
--
-- Quatre chemins vers NS.Call:Send : le bouton Appeler, Entrée dans la case, le clic sur « Libérer
-- l'esprit », tous trois des gestes ; et la libération automatique (fin du minuteur), sans geste : la
-- guilde seulement. « Libérer » n'a PAS de touche : seules les fenêtres à `enterClicksFirstButton` en
-- posent une (StaticPopup.lua, lu le 2026-10-27 dans les sources Forever 70532 et PTR 12.1.7), et DEATH
-- n'en a pas. Le compte rendu s'affiche dans l'encart, jamais dans le chat (skill chat-output) ; celui
-- de Discord se complète quand la ligne revient en jeu (CHAT_MSG_GUILD_DISCORD, NS.Call:OnEcho).
local _, NS = ...
local L = NS.L

local Panel = {}
NS.Panel = Panel

local WHICH = "DEATH"
local WIDTH, HEIGHT = 330, 128
local MAX_MESSAGE_BYTES = 120   -- la ligne Discord entière tient en 255 octets (NS.Line coupe de toute façon)
local CHECK_EVERY = 0.25        -- s entre deux vérifications « la fenêtre de mort est-elle encore là ? »
local RECAP_RETRY = 1           -- s : le récap peut arriver après la fenêtre ; on le relit une fois

local function deathDialog()
    if not _G.StaticPopup_FindVisible then return nil end
    local ok, dialog = pcall(_G.StaticPopup_FindVisible, WHICH)
    if ok then return dialog end
    return nil
end

-- Le bas de la pile. Blizzard empile ses fenêtres l'une SOUS l'autre, sans écart
-- (StaticPopup_SetUpPosition, lu dans la source 70450) : une offre de résurrection d'un guildien venu
-- nous aider se placerait juste sous la fenêtre de mort, donc sous l'encart, qui cacherait son bouton
-- Accepter. L'encart va donc sous la DERNIÈRE fenêtre affichée (les fenêtres à place fixe exceptées).
local function lowestDialog(fallback)
    local lowest = fallback
    if _G.StaticPopup_ForEachShownDialog then
        pcall(_G.StaticPopup_ForEachShownDialog, function(dialog)
            if dialog:IsShown() and not dialog.hasFixedPosition then lowest = dialog end
        end)
    end
    return lowest
end

local function text(parent, template, anchor, rel, y)
    local fs = parent:CreateFontString(nil, "ARTWORK", template)
    fs:SetPoint("TOP", rel or parent, anchor, 0, y)
    fs:SetWidth(WIDTH - 40)
    return fs
end

local function buildMessageBox(f)
    local box = CreateFrame("EditBox", "WorldPvPPolicePanelMessage", f, "InputBoxInstructionsTemplate")
    box:SetSize(WIDTH - 160, 22)
    box:SetPoint("BOTTOMLEFT", 28, 30)
    box:SetAutoFocus(false)
    box:SetMaxBytes(MAX_MESSAGE_BYTES)
    box.Instructions:SetText(L["Message (facultatif)"])
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        Panel:Call("enter")
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

function Panel:Build()
    if self.frame then return self.frame end
    local f = CreateFrame("Frame", "WorldPvPPolicePanel", UIParent, "BackdropTemplate")
    f:SetSize(WIDTH, HEIGHT)
    f:SetFrameStrata("DIALOG")
    if _G.BACKDROP_DIALOG_32_32 then f:SetBackdrop(_G.BACKDROP_DIALOG_32_32) end
    f:Hide()
    f.title = text(f, "GameFontNormal", "TOP", nil, -18)
    f.title:SetText(L["Appeler la guilde à l'aide ?"])
    f.killer = text(f, "GameFontHighlightSmall", "BOTTOM", f.title, -6)
    f.killer:SetWordWrap(false)   -- « Tueurs : A, B, C +2 » sur une ligne : l'encart a une hauteur fixe
    f.where = text(f, "GameFontHighlightSmall", "BOTTOM", f.killer, -3)
    f.where:SetWordWrap(false)
    f.box = buildMessageBox(f)
    f.call = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.call:SetSize(110, 22)   -- « Mettre à jour », « Aktualisieren » pendant un appel en cours
    f.call:SetPoint("LEFT", f.box, "RIGHT", 8, 0)
    f.call:SetText(L["Appeler"])
    f.call:SetScript("OnClick", function() Panel:Call("button") end)
    f.discord = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    f.discord:SetPoint("BOTTOM", 0, 14)
    f.discord:SetWidth(WIDTH - 24)
    f.discord:SetWordWrap(false)   -- le compte rendu tient sur une ligne, sous la case (coupé au pire)
    local since = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        since = since + elapsed
        if since < CHECK_EVERY then return end
        since = 0
        local death = deathDialog()
        if not death then
            self:Hide()
        elseif lowestDialog(death) ~= Panel.anchor then
            Panel:Anchor(death)   -- une fenêtre est arrivée sous la pile (une résurrection) : on descend
        end
    end)
    self.frame = f
    return f
end

function Panel:Anchor(death)
    local f = self.frame
    self.anchor = lowestDialog(death)
    f:ClearAllPoints()
    f:SetPoint("TOP", self.anchor, "BOTTOM", 0, -2)
end

function Panel:Refresh(state)
    local f = self.frame
    if not (f and state) then return end
    f.killer:SetText(NS.Death.KillerText(state.killer, L) or "")
    f.where:SetText(NS.Death.WhereText(state.snap, L))
    f.call:SetText(NS.Call:IsActive() and L["Mettre à jour"] or L["Appeler"])
    if self.status then
        f.discord:SetText(self.status)
    elseif NS.Discord.Stream() then
        f.discord:SetText(L["Discord : relié"])
    else
        f.discord:SetText(L["Discord : non relié (appel en jeu seulement)"])
    end
end

local function discordText(r)
    if r.discord == "later" then return string.format(L["Discord : dans %d s"], r.wait or 0) end
    if r.discord == "pending" then return L["Discord : envoi en cours"] end
    if r.discord == "sent" or r.discord == "same" then return L["Discord : envoyé"] end
    if r.discord == "noecho" then return L["Discord : pas de retour"] end
    if r.discord == "none" or r.discord == "nogesture" then return L["Discord : non relié"] end
    return L["Discord : refusé"]
end

-- Le compte rendu d'un envoi, en une ligne : « Appel n°7 · guilde : prévenue · Discord : envoyé ».
function Panel.ReportText(r)
    if r.err == "pos" then return L["Position illisible : appel impossible"] end
    if r.err then return L["Appel impossible"] end
    local guild = r.guild == "failed" and L["guilde : échec"] or L["guilde : prévenue"]
    return string.format(L["Appel n°%d"], r.n) .. " · " .. guild .. " · " .. discordText(r)
end

-- Pendant un appel en cours, la case reprend SON message (envoyé d'ici, de « Ton appel », ou gardé
-- avant un /reload) : une case vide l'effacerait au clic, et « Libérer » n'enverrait rien (D3). Une
-- fois par mort, et jamais sous les doigts du joueur : la fenêtre de mort se réaffiche pendant la même
-- mort (sort de rez changé), ce qu'il tapait reste.
function Panel:SyncBox(always)
    local f = self.frame
    if not (f and NS.Call:IsActive()) or f.box:HasFocus() then return end
    if not always and self.syncedFor == self.offered then return end
    f.box:SetText(NS.Call.active.msg or "")
    self.syncedFor = self.offered
end

function Panel:ShowUnder(dialog, state)
    local f = self:Build()
    self:SyncBox()
    self:Anchor(dialog)
    self:Refresh(state)
    f:Show()
end

-- Une nouvelle mort efface le compte rendu de la précédente. Hors d'un appel en cours, elle repart
-- aussi d'une case VIDE : sinon le message d'un vieil appel repartirait, des heures plus tard, au
-- premier clic sur « Libérer l'esprit » (D3). Pendant un appel en cours, la case reprend le message de
-- l'appel (ShowUnder) : le clic sur « Libérer » envoie la mise à jour (compteur de morts).
function Panel:NewDeath()
    self.status, self.report = nil, nil
    if not self.frame or NS.Call:IsActive() then return end
    self.frame.box:SetText("")
end

function Panel:Hide()
    if self.frame then
        self.frame.box:ClearFocus()
        self.frame:Hide()
    end
end

-- Envoie l'appel (ou sa mise à jour) pour la mort en cours, si l'encart lui a été proposé. Le message
-- est relu ici, au geste ; la capture est celle faite MORT (Death.last), jamais refaite à l'envoi.
function Panel:Call(origin)
    local Death = NS.Death
    if not (self.frame and Death.serial and self.offered == Death.serial) then return end
    local report = NS.Call:Send(self.frame.box:GetText() or "", origin, Death.last, Death.serial)
    if not report or origin == "auto" then return end
    self.report = report
    self.status = Panel.ReportText(report)
    self:Refresh(Death.last)
end

-- La ligne Discord en cours est revenue en jeu (« sent ») ou pas à temps (« noecho ») : le compte
-- rendu se complète, s'il est encore celui de cette mort.
function Panel:OnDiscord(state)
    if not (self.report and self.report.discord == "pending") then return end
    self.report.discord = state
    self.status = Panel.ReportText(self.report)
    if self.frame and self.frame:IsShown() then self:Refresh(NS.Death.last) end
end
NS.Call.onDiscord = function(state) Panel:OnDiscord(state) end

-- Le récap a pu arriver après la fenêtre : un tueur devenu « monstre » ferme l'encart (et cette mort
-- ne compte plus dans l'appel en cours), un joueur trouvé s'affiche.
function Panel:Recheck()
    if not (self.frame and self.frame:IsShown()) then return end
    NS.Death:RereadKiller()
    if NS.Death:Offer(NS.Death.last) then
        self:Refresh(NS.Death.last)
    else
        NS.Call:ForgetDeath(NS.Death.serial)
        self.offered = nil
        self:Hide()
    end
end

local function markDeath()
    local serial, isNew = NS.Death:Mark()
    if isNew then Panel:NewDeath() end
    return serial
end

local function onPopupShow(which)
    if which ~= WHICH then return end
    local serial = markDeath()
    local state = NS.Death:Current()
    local dialog = deathDialog()
    if not (dialog and NS.Death:Offer(state)) then
        Panel.offered = nil
        Panel:Hide()
        return
    end
    Panel.offered = serial
    NS.Call:NoteDeath(serial)
    Panel:ShowUnder(dialog, state)
    if state.killer.status == "unknown" and _G.C_Timer then
        _G.C_Timer.After(RECAP_RETRY, function() Panel:Recheck() end)
    end
end

-- « Libérer l'esprit » cliqué : StaticPopup_OnClick(fenêtre DEATH, 1), qui a déjà appelé RepopMe()
-- quand on passe. On est encore dans la pile du clic, donc avec le geste qu'exige C_Club.SendMessage
-- (M2 au banc ; s'il manquait, la ligne ne reviendrait pas et l'encart ne dirait pas « envoyé »). Sans
-- message dans la case, libérer reste un simple « libérer » (D3).
local function onPopupClick(dialog, index)
    if index ~= 1 then return end
    local ok, which = pcall(function() return dialog.which end)
    if not (ok and which == WHICH) then return end
    local serial = NS.Death.serial
    if not serial or Panel.released == serial then return end
    Panel.released = serial
    Panel:Call("release")
end

if hooksecurefunc and _G.StaticPopup_Show then
    hooksecurefunc("StaticPopup_Show", onPopupShow)
end
if hooksecurefunc and _G.StaticPopup_OnClick then
    hooksecurefunc("StaticPopup_OnClick", onPopupClick)
end

local function isGhost()
    local ok, ghost = pcall(UnitIsGhost, "player")
    return ok and NS.Line.Readable(ghost) and ghost == true
end

-- PLAYER_ALIVE en FANTÔME sans clic sur « Libérer » = la libération automatique (fin du minuteur : la
-- fenêtre se ferme sans OnButton1, Blizzard_Game/Camelot). Pas de geste : la guilde seulement (D13).
-- PLAYER_ALIVE sans être fantôme = ressuscité sans libérer : rien ne part.
local function onAlive()
    local serial = NS.Death.serial
    if serial and Panel.released ~= serial and isGhost() then
        Panel.released = serial
        Panel:Call("auto")
    end
    NS.Death:Revive()
    Panel:Hide()
end

-- PLAYER_DEAD capture la mort (la fenêtre s'ouvre sur le même événement, chez Blizzard, parfois avant
-- nous) ; libérer ou être ressuscité referme l'encart. CHAT_MSG_GUILD_DISCORD rend notre ligne Discord
-- (texte en 1er, GUID en 12e) : inscrit sous pcall, un événement inconnu d'un client lèverait.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_DEAD")
events:RegisterEvent("PLAYER_ALIVE")
events:RegisterEvent("PLAYER_UNGHOST")
pcall(events.RegisterEvent, events, "CHAT_MSG_GUILD_DISCORD")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "CHAT_MSG_GUILD_DISCORD" then
        NS.Call:OnEcho((...), (select(12, ...)))
    elseif event == "PLAYER_DEAD" then
        markDeath()
        NS.Death:Capture()
    elseif event == "PLAYER_ALIVE" then
        onAlive()
    else
        NS.Death:Revive()
        Panel:Hide()
    end
end)
