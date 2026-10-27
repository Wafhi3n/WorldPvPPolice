# Appel à l'aide de guilde à la mort (PvP sauvage)

> État : **validée** le 2026-10-27 par le user (D1 à D13) · Idée et décisions du user (D1 à D9),
> mise en forme par l'agent ; D10 à D13 proposées par l'agent, validées par le user le même jour
> (« je suis d'accord avec tes spec »). Rien n'est codé. Rien n'est mesuré en
> jeu : le jeu est fermé du 2026-10-21 au lancement du 2026-11-04 ; les mesures M1 à M7 se font au
> banc après le lancement. Le bot qui lit la ligne Discord a sa propre spec :
> `F:\CraftingOrderBot\docs\specs\alertes-pvp.md`.

## Le problème

Au lancement de WoW: Forever (2026-11-04), la guilde du user part sur le royaume **PvP**, côté
**Alliance**. En PvP sauvage, un joueur seul se fait tuer, puis **camper** : l'ennemi attend à côté
du cadavre et le retue à chaque résurrection. Aujourd'hui, pour appeler à l'aide il faut taper dans le
chat de guilde, de mémoire, la zone et l'endroit ; les guildiens qui ne sont pas connectés (sur leur
téléphone, sur Discord) ne le voient pas, ou trop tard.

Rien de tel n'existe sur Forever (recherche faite le 2026-10-21 : WorldPvP Gank Signal, le plus
proche, envoie un message à la guilde, sans réponse ni Discord, et vise Classic Era).

## Ce qu'on veut

1. **À la mort, tué par un joueur, en extérieur**, un encart apparaît sous la fenêtre « Libérer
   l'esprit ». Il propose d'appeler la guilde à l'aide, avec une case pour un message court
   (« 3 voleurs au pont ») et un bouton **Appeler**. Si on sait qui nous a tués, l'encart le dit
   (« Tué par Xyz, voleur »).
2. **L'appel part** au clic sur Appeler, à Entrée dans la case, ou au clic sur **Libérer l'esprit**
   si la case contient un message. Il porte **la position du cadavre** (zone et coordonnées).
3. **En jeu**, chaque guildien qui a l'addon voit une alerte : qui appelle, où, tué par qui, combien
   de morts, le message. Un bouton **J'arrive** pose un point de route sur le cadavre et prévient
   l'appelant. L'appelant voit la liste de ceux qui arrivent.
4. **Sur Discord**, l'appel s'écrit dans le fil Discord de la guilde. Le bot de la guilde en fait une
   carte lisible dans un salon dédié (`#alertes-pvp`), la met à jour (morts, qui arrive, réglé) et
   retire la ligne brute.
5. **Camper = mourir en boucle** : tant que l'appel est en cours, une nouvelle mort met l'appel à
   jour (compteur de morts) au lieu d'en ouvrir un autre.
6. L'appelant clôt l'appel par un bouton **C'est réglé** ; sinon il expire tout seul.

## Ce qu'on NE fait PAS

- **Aucun envoi sans geste du joueur.** Pas d'appel automatique sur des dégâts ni à la mort : écrire
  sur Discord exige un clic ou une touche (fait mesuré, `C_Club.SendMessage`), et un appel non voulu
  serait du spam.
- **Rien en instance** (champ de bataille, arène, donjon, raid) : décision du user (D6). Ni encart, ni
  alerte reçue.
- **Pas d'encart quand on sait que la mort ne vient pas d'un joueur** (monstre, chute, noyade).
- **Pas d'image de carte** en v1 : c'est la phase 2 du bot (sa spec).
- **Pas de réponse depuis Discord** : un texte écrit sur Discord arrive en jeu illisible pour un
  addon (K-string, mesuré le 2026-10-10). Répondre « j'arrive », c'est en jeu.
- **Rien hors de la guilde** : pas de canal public, pas de « à tous », pas d'amis (règle du user :
  envoi dirigé).
- **Pas de ligne de chat** sur un événement ou un message d'un autre joueur : l'alerte est une
  fenêtre, pas une ligne dans le chat (skill `chat-output`). Le chat ne répond qu'à `/wpp`.
- **Pas de royaume affiché** (règle du user) : les noms s'écrivent sans royaume.
- **Pas de liste d'ennemis** (KOS), pas de suivi des tueurs entre les appels.
- **Pas de relais par un autre guildien** pour un joueur sans Discord relié : on attend la mesure M4
  avant de décider s'il en faut un.

## Cas particuliers

- **On ne sait pas qui nous a tués** (récap de mort vide, illisible ou valeurs secrètes) : l'encart
  apparaît quand même en extérieur, sans la ligne « Tué par » ; c'est le joueur qui décide d'appeler.
- **Le nom du tueur est une valeur secrète** : on ne le concatène jamais (erreur Lua) ; l'appel part
  sans tueur.
- **On est ressuscité sans libérer** (pierre d'âme, prêtre) : la fenêtre de mort se ferme, l'encart
  aussi, rien ne part.
- **La libération automatique** (fin du minuteur) n'est pas un geste : rien ne part sur Discord, sans
  erreur visible. Seul le message d'addon de guilde peut partir (il ne demande pas de geste) — à
  trancher, D13.
- **Guilde non reliée à Discord, ou en flux mêlé** : l'appel part en jeu seulement ; l'encart le dit
  discrètement (« Discord : non relié »). En flux mêlé, l'addon ne peut pas savoir que la guilde est
  reliée (mesuré) : on traite comme non relié.
- **Pas de guilde** : pas d'encart.
- **Morts répétées** : pendant un appel en cours (D11), chaque mort par un joueur augmente le compteur.
  Sur Discord, au plus une ligne de mise à jour toutes les 2 minutes ; un compteur qui n'a pas pu
  partir part avec le geste suivant.
- **Deux appels en même temps** (deux guildiens) : deux alertes empilées, 3 au plus à l'écran.
- **Le guildien qui reçoit est en instance** : pas d'alerte (D6).
- **L'appelant se déconnecte** : l'appel expire (D11).
- **Message trop long ou piégé** : coupé pour que la ligne entière tienne en 255 octets ; `|`, `[`,
  `]`, `#`, retours à la ligne et tabulations retirés (un `[objet]` ferait répondre au bot des liens
  Wowhead, un `#SOS` tromperait sa lecture). Le bot échappe lui-même mentions et mise en forme.
- **Deux persos du même nom sur deux royaumes de la guilde** : rare, accepté ; la clé d'un appel est
  `nom + numéro`.

## Décisions

- **D1** (user, 2026-10-27) — La position envoyée est **celle du cadavre**, pas un point de ralliement.
- **D2** (user) — Le déclencheur est **la mort**, avec un encart sous la fenêtre « Libérer l'esprit ».
- **D3** (user) — L'appel part au clic de **Libérer l'esprit**. Précisé avec l'agent : seulement si la
  case contient un message (sans message, libérer reste un simple « libérer »).
- **D4** (user, proposition 1 de l'agent) — **Notre propre bouton « Appeler »** en plus : on peut
  appeler sans libérer (attendre une rez), et la libération automatique n'est pas un geste.
- **D5** (user) — La guilde utilise le **flux Discord séparé** (case « Séparer le chat Discord »
  cochée par le maître de guilde ou un officier).
- **D6** (user) — **Désactivé en instance.**
- **D7** (user) — **Addon séparé** de Crafting Order : dossier `WorldPvPPolice`, titre « World PvP
  Police Guild », commande `/wpp`. Le dossier ne se renomme plus après la première release.
- **D8** (user) — Le bot **supprime la ligne brute** du salon relié une fois sa carte faite.
- **D9** (user) — Morts répétées : la carte se met à jour au lieu d'en publier une autre (proposition 3
  de l'agent, acceptée).
- **D10** (agent, validée par le user le 2026-10-27) — **L'encart n'apparaît que si un joueur nous a tués**, lu dans le récap
  de mort (`C_DeathRecap.GetRecapEvents`, GUID `Player-…` du coup fatal) ; si le récap est illisible,
  l'encart apparaît à chaque mort en extérieur.
- **D11** (agent, validée par le user le 2026-10-27) — **Un appel dure 15 minutes après sa dernière mise à jour**, puis
  expire chez tout le monde.
- **D12** (agent, validée par le user le 2026-10-27) — **« J'arrive » et « C'est réglé » s'écrivent aussi sur Discord** (ce
  sont des clics, donc des gestes) : la carte du bot dit qui arrive et quand c'est réglé.
- **D13** (agent, validée par le user le 2026-10-27) — Le message d'addon de guilde **part même sans geste** (libération
  automatique) : les guildiens en jeu sont prévenus, Discord non.
- **Le nom du personnage est toujours dans la ligne Discord.** Sur Discord, une ligne venue du jeu
  s'affiche sous le nom du compte Discord ; avec la case Discord « afficher ce que je joue », sous le
  nom du perso (dit par le user le 2026-10-27, non mesuré : M5). L'addon ne peut pas lire ce réglage
  (getter protégé) ; le bot n'affiche que le nom de la ligne, jamais l'auteur Discord : pas de doublon.

## Mesures à faire au banc (après le 2026-11-04)

Aucune n'est faite. Le banc demande **un perso de l'autre faction** pour tuer (un duel ne tue pas).

- **M1** — Après une mort par un joueur en extérieur : `C_DeathRecap.GetRecapEvents()` est-il rempli,
  lisible (pas de valeurs secrètes), et le coup fatal a-t-il un `sourceGUID` `Player-…` et un
  `sourceName` ? Et après une mort par un monstre ?
- **M2** — `C_Club.SendMessage` vers le fil Discord, **mort** : depuis notre bouton, depuis Entrée,
  et accroché au clic de « Libérer l'esprit ». Aucun `ADDON_ACTION_BLOCKED` (`/console taintLog 1`).
- **M3** — Position : `C_Map.GetPlayerMapPosition` mort avant de libérer, et
  `C_DeathInfo.GetCorpseMapPosition` après ; mêmes coordonnées ?
- **M4** — Un guildien **sans Discord relié** à son Battle.net peut-il écrire dans le fil Discord ?
- **M5** — Nom affiché sur Discord, case « afficher ce que je joue » cochée puis décochée.
- **M6** — Les messages d'addon de guilde passent-ils **entre royaumes** de la même guilde ?
- **M7** — L'encart sous la fenêtre de mort ne casse ni « Libérer », ni la pierre d'âme, ni le récap
  (aucune erreur d'action interdite, taintLog propre).

## Critères d'acceptation

Tests headless : `tests/test_wpp_*.lua` de l'outillage (le banc et l'addon atterrissent le même jour,
règle de CLAUDE.md).

1. [test] Une ligne Discord construite puis relue redonne exactement le nom, le numéro, la zone, les
   coordonnées, le nombre de morts, le tueur, sa classe et le message.
2. [test] Une ligne avec un message de 300 caractères, des `|`, `[ ]`, `#SOS9` et des retours à la
   ligne fait au plus 255 octets et ne contient aucun de ces caractères dans le message ; le message
   est coupé, jamais la queue `#SOS<n> m… d…`.
3. [test] Un nom de tueur secret (`debug.newsecret` de notre Elune) donne une ligne sans tueur, sans
   erreur.
4. [test] Trois morts en 3 minutes pendant un appel : un seul numéro d'appel, compteur à 3, au plus
   deux lignes Discord (la 1re, puis une mise à jour après 2 minutes).
5. [test] En instance, ou sans guilde, ou mort par un monstre (récap lisible) : pas d'encart.
6. [test] Un message d'addon de version inconnue est ignoré, sans erreur ni ligne de chat.
7. [test] Aucune ligne de chat à la réception d'un appel ; `/wpp` seul dit l'état, `/wpp on|off`
   le change, une ligne chacun (skill `chat-output`).
8. [check] Portes Lua 5.1, tailles, locale (tout le texte d'interface localisé, clé = FR, overlays
   enUS/deDE/esES) → `.\deploy.ps1 -Check`.
9. [agent] Pas d'écriture dans la fenêtre de mort de Blizzard (seulement accrochée), pas d'appel
   protégé hors geste → agent `api-gotcha-reviewer`.
10. [human] Mort tuée par un joueur en extérieur : l'encart apparaît sous la fenêtre de mort, avec
    « Tué par <nom> ». Témoin : une mort par un monstre, sans encart. Observateur : le user, compte A.
11. [human] Clic sur Appeler : sur le compte B, une alerte apparaît avec la zone et les coordonnées ;
    « J'arrive » pose un point de route sur le cadavre de A ; A voit B dans « en route ». Témoin : le
    point de route mène bien à l'endroit où A est mort (A le dit).
12. [human] Sur Discord : la carte apparaît dans `#alertes-pvp` avec le nom du perso de A, la ligne
    brute disparaît du salon relié et du fil Discord en jeu. Observateur : le user, sur Discord.
13. [human] « C'est réglé » : l'alerte disparaît chez B, la carte passe à « réglé ». Sans clic, au
    bout de 15 minutes, l'alerte disparaît chez B.

## Contrat

Deux formats, lus par d'autres que l'addon : le gelé, c'est ce qui suit. Toute évolution s'ajoute en
fin de ligne et se prouve par un test de relecture des lignes d'avant.

### Ligne du fil Discord (lue par le bot et par des humains)

Texte lisible sans le bot (le bot peut être éteint), sans `[ ]` ni `|`, noms sans royaume. Trois
formes, chacune sur une ligne :

```
SOS <Perso> <Zone> (<x>, <y>) #SOS<n> m<uiMapID> d<morts>[ k<Tueur>][ c<CLASSE>][ : <message>]
OMW <Répondant> > <Perso> #SOS<n>
END <Perso> #SOS<n>
```

- `<Perso>`, `<Répondant>`, `<Tueur>` : nom de personnage seul, sans espace.
- `<Zone>` : nom de la zone dans la langue de l'appelant (peut contenir espaces et apostrophes).
- `<x>`, `<y>` : coordonnées en pourcentage de la carte de zone, une décimale, point décimal.
- `<n>` : numéro d'appel du personnage (compteur sauvegardé, croissant). Clé d'un appel = `Perso` + `n`.
- `<uiMapID>` : carte de zone (`C_Map.GetBestMapForUnit("player")` à la mort).
- `<morts>` : morts depuis l'ouverture de l'appel (1 à la première ligne).
- `<CLASSE>` : jeton de classe anglais (`ROGUE`, `MAGE`…), si connu.
- Une ligne `SOS` avec un `#SOS<n>` déjà vu = mise à jour de cet appel (morts, message).

Exemples :

```
SOS Gnomi Forêt d'Elwynn (42.1, 65.3) #SOS7 m1429 d1 kXyz cROGUE : 3 voleurs au pont
SOS Gnomi Forêt d'Elwynn (42.1, 65.3) #SOS7 m1429 d3 kXyz cROGUE : 3 voleurs au pont
OMW Gnomette > Gnomi #SOS7
END Gnomi #SOS7
```

Le lecteur de commandes du bot (`WTB […] … #CO<n>`) ne lit aucune de ces lignes.

### Message d'addon de guilde (lu par les autres copies de l'addon)

Préfixe `WPPolice`, canal `GUILD`. Premier champ = **version du format** (1) ; un lecteur ignore une
version qu'il ne connaît pas. Champs séparés par une tabulation, texte libre privé de tabulations et
de `|`, 255 octets au plus.

- `1 SOS <n> <uiMapID> <x> <y> <morts> <tueur|-> <CLASSE|-> <message>` — appel ou mise à jour
- `1 OMW <n> <Perso appelant>` — j'arrive (l'émetteur est le répondant)
- `1 END <n>` — réglé (l'émetteur est l'appelant)

### Données sauvegardées

`WorldPvPPoliceDB` : `nextCall` (prochain numéro d'appel, par personnage), `alerts` (on/off, compte).
Aucun appel n'est sauvegardé : un `/reload` les oublie (ils expirent en 15 minutes de toute façon).

## Renvois

- Skill public `wow-addon-dev:wow-forever-api`, `chat-channels-and-communities.md` : écrire dans le fil
  Discord, flux séparé, ce que voit Discord, ce qu'un bot ne peut pas faire.
- Skill `wow-addon-dev:chat-output` (aucune ligne de chat non demandée), skill `human-verification`
  (critères 10 à 13).
- Le même chemin, déjà éprouvé : spec `annonce-discord.md` de CraftingOrderClassic (ligne
  `C_Club.SendMessage` au clic, bot qui lit et supprime).
- Bot : `F:\CraftingOrderBot\docs\specs\alertes-pvp.md`.
- Source Forever lue (build 70450, inchangé en 70532) : `StaticPopupDialogs["DEATH"]`
  (`GameDialogDefs.lua`, bouton 1 → `RepopMe()`), `C_DeathInfo.GetCorpseMapPosition`,
  `C_DeathRecap.GetRecapEvents` (Blizzard lit lui-même `sourceGUID` du coup fatal dans
  `Blizzard_PTRFeedback_Events.lua`), `C_Map.SetUserWaypoint` (sans restriction). Le journal de
  combat est fermé aux addons sur Forever.

## Plan (2026-10-27) — volatile, meurt quand c'est fait

Une tâche = une session, avec son critère.

- **T1** — Lignes et messages : construire / relire, nettoyer, couper (critères 1, 2, 3, 6).
- **T2** — Mort : détection, lecture du récap, position, encart sous la fenêtre de mort (5, 10).
- **T3** — Envoi : Appeler / Entrée / Libérer, fil Discord + message de guilde, morts répétées (4).
- **T4** — Réception : alerte, J'arrive + point de route, liste « en route », C'est réglé, expiration,
  `/wpp on|off` (7, 11, 13).
- **T5** — Bot : sa spec, son dépôt.
- **T6** — Au lancement : mesures M1 à M7 au banc, puis critères 10 à 13.
