# Appel à l'aide de guilde à la mort (PvP sauvage)

> État : **validée** le 2026-10-27 par le user (D1 à D13 ; D14 et D15 décidées par lui le même jour,
> leurs précisions et le contrat changé en attente de son accord) · Idée et décisions du user (D1 à D9),
> mise en forme par l'agent ; D10 à D13 proposées par l'agent, validées par le user le même jour
> (« je suis d'accord avec tes spec »). **T1 codé le 2026-10-27** (branche `feat/wpp-lignes` de
> l'addon ET de l'outillage) : `WorldPvPPolice_Line.lua`, critères 1, 2, 3 et 6 tenus en test
> (`tests/test_wpp_lines.lua`, 44 vérifications, dont une vraie valeur secrète). **T2 codé le même
> jour**, mêmes branches : `WorldPvPPolice_Discord.lua`, `_Death.lua` (logique pure + sondes),
> `_Panel.lua` (l'encart) ; critère 5 tenu en test (`tests/test_wpp_death.lua`). **Le même jour, le
> user a mesuré M1 à M3 sur le PTR RETAIL** (12.1.7.70493, pas sur Forever : à refaire au banc) ; ses
> mesures ont changé la lecture du tueur (tout le récap, D10 révisée) et la position d'un fantôme.
> **T3 codé le même jour** : l'envoi (`WorldPvPPolice_Call.lua`, crochets dans `_Panel.lua`) ;
> critère 4 tenu en test (`tests/test_wpp_call.lua`), branchement de l'encart (quel geste envoie quoi,
> une seule fois) en test sur le vrai `_Panel.lua` devant une fenêtre factice (`tests/test_wpp_panel.lua`).
> **D14 et D15 décidées par le user le même jour** (zone seule si les coordonnées sont illisibles ;
> plusieurs tueurs quand une équipe campe) et codées : le contrat v1 a changé AVANT toute release
> (section « Contrat ») ; les quatre premiers exemples sont restés identiques à l'octet. **Critère 9
> relu** par l'agent `api-gotcha-reviewer` le même jour, sur Forever et le PTR Retail ; d'où **D16**
> (user) : une ligne Discord ne compte comme envoyée que revenue en jeu. **T4 codé le même jour** :
> la réception (alertes, « J'arrive », point de route, « Ton appel », « C'est réglé », `/wpp on|off`),
> après avoir corrigé les noms : sur Forever un nom complet est « Prénom Nom », et le format le refusait.
> Rien n'est mesuré sur Forever : le jeu est fermé du 2026-10-21 au lancement du 2026-11-04 ; les
> mesures M1 à M8 se font au banc après le lancement. Le bot qui lit la ligne Discord a sa propre spec :
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
   (« Tueur : Xyz (Voleur) », ou « Tueurs : Xyz, Abc, Def +2 » quand une équipe nous campe).
2. **L'appel part** au clic sur Appeler, à Entrée dans la case, ou au clic sur **Libérer l'esprit**
   si la case contient un message. Il porte **la position du cadavre** (zone et coordonnées ; la zone
   seule si les coordonnées sont illisibles, D14).
3. **En jeu**, chaque guildien qui a l'addon voit une alerte : qui appelle, où, tué par qui (tous les
   joueurs qui l'ont frappé, D15), combien de morts, le message. Un bouton **J'arrive** pose un point de route sur le cadavre et prévient
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
  Lu dans **tout le récap** (D10 révisée) : un GUID `Player-…` n'importe où = joueur, nommé d'après le
  premier dans l'ordre du récap (le coup fatal, sinon le plus récent) ; pas d'encart seulement si
  **tous** les coups sont lisibles et viennent de `Creature-`, `Vehicle-`, `GameObject-` ou de
  l'environnement (chute, noyade, lave) ; un **familier** (`Pet-…`), un GUID secret ou absent = inconnu
  (son maître est peut-être un joueur) : encart.
- **Tué par une invocation** (Abomination ou goule de chevalier de la mort, totem, infernal…) : son GUID
  est `Creature-`, comme un monstre (mesuré sur le PTR Retail, M1). Si son maître a frappé lui aussi
  dans les derniers coups du récap (10 sur le PTR), c'est lui le tueur affiché. **Limite connue** :
  tué par les seules invocations d'un joueur qui n'a jamais frappé dans ces coups, l'addon croit à un
  monstre et l'encart n'apparaît pas.
- **Le récap arrive après la fenêtre de mort** : il est relu une fois, 1 s plus tard ; un tueur
  devenu « monstre » referme l'encart.
- **Mode hardcore** (fenêtre `HARDCORE_DEATH`, mort définitive) : pas d'encart.
- **Une offre de résurrection arrive** (le guildien venu nous aider) : Blizzard empile ses fenêtres
  l'une sous l'autre, la sienne se placerait sous la fenêtre de mort, donc sous l'encart. L'encart se
  met toujours sous la DERNIÈRE fenêtre de la pile, et redescend dans le quart de seconde.
- **Le message d'un vieil appel** : une nouvelle mort hors d'un appel en cours repart d'une case vide.
  Sinon, des heures plus tard, un clic machinal sur « Libérer l'esprit » renverrait l'ancien message
  (D3). Pendant un appel en cours, le texte reste (la mise à jour le reprend).
- **Le nom du tueur est une valeur secrète** : on ne le concatène jamais (erreur Lua) ; l'appel part
  sans tueur.
- **On est ressuscité sans libérer** (pierre d'âme, prêtre) : la fenêtre de mort se ferme, l'encart
  aussi, rien ne part.
- **La libération automatique** (fin du minuteur) n'est pas un geste : rien ne part sur Discord, sans
  erreur visible (hors geste, `C_Club.SendMessage` serait un `ADDON_ACTION_BLOCKED`, que `pcall` ne
  voit pas : l'addon ne l'appelle donc jamais sur ce chemin). Seul le message d'addon de guilde part
  (D13), si la case contient un message. Reconnue à PLAYER_ALIVE en fantôme sans clic sur « Libérer ».
- **Un clic sur « Libérer » envoie une fois** : le crochet du clic passe avant PLAYER_ALIVE et marque
  la mort ; la libération automatique ne repart pas derrière lui.
- **Double clic sur Appeler**, ou « Libérer » juste après Appeler avec le même message : rien ne repart
  (ni guilde, ni Discord), et l'appel n'est pas prolongé.
- **Rien n'est parti** (guilde qui refuse et pas de Discord) : l'appel n'est pas ouvert et garde son
  numéro ; l'encart le dit (« guilde : échec »).
- **Ce qui est parti** s'écrit dans l'encart, jamais dans le chat : « Appel n°7 · guilde : prévenue ·
  Discord : envoyé » (ou « Discord : envoi en cours », « pas de retour », « dans 60 s », « non relié »,
  « refusé »). Pendant un appel en cours, le bouton devient « Mettre à jour ».
- **Un envoi Discord bloqué** (pas de geste reconnu par le jeu : `ADDON_ACTION_BLOCKED`, que le code
  ne voit pas) : la ligne ne revient pas en jeu. Elle reste « en cours » 10 s, puis « pas de retour » ;
  rien n'est compté (ni délai de 2 minutes, ni « déjà envoyée »), et le geste suivant la renvoie (D16).
  Pendant ces 10 s, un nouveau geste n'envoie pas une deuxième ligne. Une ligne revenue après les 10 s
  est ignorée : au pire, le geste suivant en envoie une deuxième.
- **Guilde non reliée à Discord, ou en flux mêlé** : l'appel part en jeu seulement ; l'encart le dit
  discrètement (« Discord : non relié »). En flux mêlé, l'addon ne peut pas savoir que la guilde est
  reliée (mesuré) : on traite comme non relié.
- **Pas de guilde** : pas d'encart.
- **Morts répétées** : pendant un appel en cours (D11), chaque mort par un joueur (l'encart s'ouvre)
  augmente le compteur ; rien ne part à la mort elle-même, la mise à jour part au geste suivant
  (Appeler, Entrée, ou « Libérer » : la case garde son message pendant l'appel). Sur Discord, au plus
  une ligne de mise à jour toutes les 2 minutes ; une mise à jour retenue part avec le geste suivant.
  Une mort relue « monstre » après coup ne compte plus. Sans position lisible, la mise à jour garde
  celle de l'appel ; sans tueur connu, le tueur de l'appel.
- **Deux appels en même temps** (deux guildiens) : deux alertes empilées, 3 au plus à l'écran, les
  plus récentes ; la croix d'une alerte l'écarte, et une mort de plus (même appel) la fait revenir.
- **Le même guildien rappelle** (nouveau numéro) : son nouvel appel remplace l'ancien à l'écran.
- **Le guildien qui reçoit est en instance** : pas d'alerte (D6) ; une alerte reçue dehors se cache en
  entrant et revient en sortant, si elle n'a pas expiré.
- **Où s'affichent les fenêtres** (choix de l'agent, à confirmer au banc) : une pile en haut, au centre
  (`TOP`, 0, -20), au-dessus des fenêtres de Blizzard (la fenêtre de mort est à `TOP` -135) ; on la
  déplace en tirant n'importe laquelle de ses fenêtres, et la position est gardée pour le compte. En
  tête, « Ton appel » chez l'appelant ; dessous, les alertes reçues.
- **« Ton appel »** (chez l'appelant, tant que l'appel est en cours) : numéro, morts, état Discord
  (envoyé seulement une fois revenu, D16), qui est en route, bouton « C'est réglé ». Elle reste après
  « Libérer l'esprit » : c'est là que l'appelant voit si son appel est parti (l'encart, lui, se ferme).
- **Les lignes Discord « OMW » et « END »** partent au clic, sans suivi de leur retour : rien n'en
  dépend (pas de délai, pas de « déjà envoyée »). Un `END` ne part sur Discord que si une ligne `SOS`
  de l'appel y est partie ou en cours.
- **Le nom affiché** d'un appelant ou d'un répondant : son nom complet sans royaume (« Prénom Nom »
  sur Forever) ; dans une ligne Discord, le prénom seul (contrat).
- **L'appelant se déconnecte** : l'appel expire (D11).
- **Message trop long ou piégé** : coupé pour que la ligne entière tienne en 255 octets ; `|`, `[`,
  `]`, `#`, retours à la ligne et tabulations retirés (un `[objet]` ferait répondre au bot des liens
  Wowhead, un `#SOS` tromperait sa lecture). Le bot échappe lui-même mentions et mise en forme.
- **Deux persos du même nom sur deux royaumes de la guilde** : rare, accepté ; la clé d'un appel est
  `nom + numéro`.
- **Position illisible** (pas de coordonnées du cadavre) : l'appel part avec **la zone seule** (D14).
  Une mort suivante sans coordonnées garde le point de l'appel s'il est sur la même carte ; sur une
  autre carte, elle part en zone seule (un point dans la mauvaise zone serait pire que pas de point).
  Sans carte du tout (rien de lisible), pas d'appel : l'encart le dit. Sur le PTR Retail (M3), mort
  avant « Libérer », la position du joueur était lisible : le cas reste rare, pas mesuré sur Forever.
- **Zone seule chez celui qui reçoit** (T4) : l'alerte montre la zone, et « J'arrive » ne pose PAS de
  point de route (il n'y a pas de point) ; il prévient l'appelant quand même.
- **Après « Libérer »**, le fantôme apparaît chez la gardienne des âmes, peut-être sur une autre carte.
  La position envoyée est celle lue **mort**, avant de libérer (mesurée identique au cadavre sur le
  PTR Retail, M3) ; un fantôme ne prête jamais sa position, ni sa carte ni sa zone.
- **Camper en équipe** (D15) : l'appel liste TOUS les joueurs qui nous ont frappés, pas un seul tueur.
  Chaque mort apporte les joueurs nommés de son récap ; ceux de la dernière mort passent devant, chacun
  une fois (reconnu par son GUID, qui ne part jamais sur le fil), **5 au plus** dans l'appel, 3 noms
  dans l'encart (« +2 » pour le reste). Mêmes limites que le tueur : les 10 derniers coups du récap,
  une invocation sans son maître ne nomme personne, un soigneur ennemi qui ne frappe pas n'y est
  jamais. Un joueur caché par le jeu (`hideCaster`) ou au nom secret n'est pas listé. Trop de noms
  pour la ligne : les derniers sont retirés, l'appel part toujours.

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
  de mort (`C_DeathRecap.GetRecapEvents`) ; si le récap est illisible, l'encart apparaît à chaque mort
  en extérieur. **Révisée le 2026-10-27 par l'agent, après la mesure du user sur le PTR Retail**
  (l'intention ne change pas, la règle si) : la première version ne lisait que le coup fatal, et le
  user a été tué par un chevalier de la mort dont l'Abomination (`Creature-`) portait ce coup :
  l'encart se serait caché. La règle est désormais : un GUID `Player-…` **n'importe où** dans le récap.
- **D14** (user, 2026-10-27, « oui la zone si illisible ») — **Position illisible : l'appel part avec
  la zone seule**, au lieu de ne pas partir.
- **D15** (user, 2026-10-27, « le kill feed doit avoir plusieurs tueurs s'ils se font camper par une
  équipe ») — **L'appel nomme plusieurs tueurs.** Précisé par l'agent, à confirmer par le user : les
  joueurs de la dernière mort devant, chacun une fois, 5 au plus dans l'appel, 3 noms dans l'encart ;
  deux listes alignées dans la ligne (`kXyz,Abc cROGUE,MAGE`, section « Contrat »).
- **D16** (user, 2026-10-27, « par le retour », après la revue `api-gotcha-reviewer`) — **Une ligne
  Discord ne compte comme envoyée que quand elle revient en jeu** : `CHAT_MSG_GUILD_DISCORD` (mesuré sur
  Forever le 2026-10-10 : la ligne écrite depuis le jeu y revient, nom du perso et GUID), même texte
  (blancs regroupés), GUID de l'auteur = le nôtre quand il est lisible. Attente : 10 s (délai du
  retour jamais mesuré, M2). Raison : un `C_Club.SendMessage` bloqué faute de geste ne lève aucune
  erreur, l'encart aurait dit « envoyé » et le délai de 2 minutes aurait empêché de réessayer.
- **D17** (user, 2026-10-28, « après le reload il faudrait pas que les compteurs soient reset au cas
  d'une déco-reco », après la séance PTR) — **Un appel survit à un `/reload` et à une déco-reco** :
  même numéro, mêmes morts, 15 minutes après sa dernière mise à jour comme avant (D11). Un joueur
  campé se déconnecte souvent pour s'en sortir. Précisé par l'agent : gardé par perso (GUID), sur le
  poste seulement (SavedVariables) ; un `/reload` en étant mort, pas libéré, ne compte pas une mort de
  plus ; une ligne Discord « en cours » ne survit pas (le geste suivant la renvoie). Les alertes REÇUES
  (fenêtres des autres) ne sont pas gardées : question posée au user.
  Remplace la phrase « Aucun appel n'est sauvegardé : un `/reload` les oublie ».
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

Aucune n'est faite **sur Forever**. Le banc demande **un perso de l'autre faction** pour tuer (un duel
ne tue pas). M1 à M3 ont un précédent : mesurées par le user sur le **PTR Retail 12.1.7.70493** le
2026-10-27, par des macros `/run` (même chemin qu'un clic d'addon), perso de guilde tué par un
chevalier de la mort de la Horde, puis par un monstre. Ce précédent guide le code ; il ne remplace pas
la mesure sur Forever.

- **M1** — Après une mort par un joueur en extérieur : `C_DeathRecap.GetRecapEvents()` est-il rempli,
  lisible (pas de valeurs secrètes), avec des `sourceGUID` `Player-…` et des `sourceName` ? Et après
  une mort par un monstre ? *PTR Retail* : 10 événements, `[1]` = coup fatal, puis du plus récent au
  plus ancien ; `sourceName`, `sourceGUID`, `spellName`, `amount` lisibles, aucune valeur secrète, en
  PvP comme contre un monstre ; attaque en mêlée : `spellName` = nil. Coup fatal porté par une
  invocation (`Creature-`) : 6 coups d'invocations, 4 du joueur. `GetPlayerInfoByGUID` du joueur :
  `"DEATHKNIGHT"`, « Chevalière de la mort » (lisible, accordé au sexe de la cible).
- **M2** — `C_Club.SendMessage` vers le fil Discord, **mort** : depuis notre bouton, depuis Entrée,
  et accroché au clic de « Libérer l'esprit ». Aucun `ADDON_ACTION_BLOCKED` (`/console taintLog 1`).
  *PTR Retail*, par macro : marche en combat (sur un mannequin) et une fois mort ; sur Discord la ligne
  porte le nom du compte, en jeu celui du perso. Pas mesuré : depuis notre bouton, Entrée, « Libérer ».
  À relever aussi (D16) : la ligne revient-elle en `CHAT_MSG_GUILD_DISCORD`, avec notre GUID en 12e
  argument, et en combien de temps (l'addon attend 10 s) ? L'encart doit passer de « envoi en cours »
  à « envoyé ». « Libérer » n'a pas de touche (seul le clic compte) : source lue, rien à mesurer.
- **M3** — Position : `C_Map.GetPlayerMapPosition` mort avant de libérer, et
  `C_DeathInfo.GetCorpseMapPosition` après ; mêmes coordonnées ? *PTR Retail* : mort avant de libérer,
  joueur lisible et cadavre = nil ; après, cadavre lisible et identique (0.482, 0.417 les deux fois).
  Pas vu : une gardienne des âmes sur une autre carte que le cadavre.
- **M4** — Un guildien **sans Discord relié** à son Battle.net peut-il écrire dans le fil Discord ?
- **M5** — Nom affiché sur Discord, case « afficher ce que je joue » cochée puis décochée.
- **M6** — Les messages d'addon de guilde passent-ils **entre royaumes** de la même guilde ?
- **M7** — L'encart sous la fenêtre de mort ne casse ni « Libérer », ni la pierre d'âme, ni le récap
  (aucune erreur d'action interdite, taintLog propre).
- **M8** — Un message d'addon `WPPolice` séparé par des **tabulations** arrive-t-il intact en guilde ?
  Aucun précédent chez nous (COC et CraftLink séparent par `|` ou `.`). S'il arrive abîmé, un autre
  séparateur = format v2 ; d'ici là, le contrôle du nombre de champs refuse un message abîmé.
- **M9** — Sur les DEUX clients (Forever et PTR Retail) : sous quel nom exact un message d'addon de
  `GUILD` arrive-t-il (4e argument de `CHAT_MSG_ADDON`) — « Prénom Nom » sur Forever, « Nom-Royaume »
  sur Retail, comme le suppose l'addon ? Mon propre message de guilde me revient-il (mesuré en groupe
  seulement, le 2026-10-05) ? Et donc : un « J'arrive » de B fait-il apparaître B dans « Ton appel » de
  A (`Alert:IsMe`) ? Sans M9, une liste « en route » vide au critère 11 ne dit pas pourquoi.
  Témoin : `/dump GetUnitName("player", true), UnitFullName("player")` sur A, à comparer.

## Critères d'acceptation

Tests headless : `tests/test_wpp_*.lua` de l'outillage (le banc et l'addon atterrissent le même jour,
règle de CLAUDE.md).

1. [test] Une ligne Discord construite puis relue redonne exactement le nom, le numéro, la zone, les
   coordonnées (ou leur absence, D14), le nombre de morts, les tueurs et leurs classes (D15) et le
   message ; 5 tueurs aux noms les plus longs tiennent encore en 255 octets (les derniers retirés).
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
    « Tueur : <nom> (<classe>) ». Témoin : une mort par un monstre, sans encart. Puis B offre une
    résurrection : la fenêtre de B se voit en entier, bouton Accepter cliquable, l'encart passe
    dessous. Observateur : le user, compte A. Si le banc a deux persos de l'autre faction (D15) : une
    mort sous les coups des deux affiche « Tueurs : <nom1>, <nom2> » sur UNE ligne, et la ligne du lieu
    ne touche pas la case du message.
11. [human] Clic sur Appeler : sur le compte B, une alerte apparaît avec la zone et les coordonnées ;
    « J'arrive » pose un point de route sur le cadavre de A ; A voit B dans « en route ». Témoin : le
    point de route mène bien à l'endroit où A est mort (A le dit). Un appel en zone seule (D14) ne
    pose pas de point de route : l'alerte montre la zone.
12. [human] Sur Discord : la carte apparaît dans `#alertes-pvp` avec le nom du perso de A, la ligne
    brute disparaît du salon relié et du fil Discord en jeu. Observateur : le user, sur Discord. La
    carte montre la liste des tueurs de la ligne (D15) ; un appel en zone seule (D14), s'il se
    produit, montre la zone sans coordonnées.
13. [human] « C'est réglé » : l'alerte disparaît chez B, la carte passe à « réglé ». Sans clic, au
    bout de 15 minutes, l'alerte disparaît chez B.

## Contrat

Deux formats, lus par d'autres que l'addon : le gelé, c'est ce qui suit. Toute évolution s'ajoute en
fin de ligne et se prouve par un test de relecture des lignes d'avant.

**Changé en place le 2026-10-27** (décision de l'agent, à confirmer par le user), AVANT toute release
et avant tout lecteur (le bot n'est pas écrit) : coordonnées facultatives (D14) et listes de tueurs
(D15). La version du message d'addon reste 1. La forme à un tueur avec coordonnées n'a pas bougé d'un
octet : les exemples 1 à 4 sortent identiques (`tests/test_wpp_lines.lua`). Seul changement de
lecture : une classe sans nom (`c` sans `k`) était relue, elle est désormais refusée.

### Ligne du fil Discord (lue par le bot et par des humains)

Texte lisible sans le bot (le bot peut être éteint), sans `[ ]` ni `|`, noms sans royaume. Trois
formes, chacune sur une ligne :

```
SOS <Perso> <Zone>[ (<x>, <y>)] #SOS<n> m<uiMapID> d<morts>[ k<T1>,<T2>…][ c<C1>,<C2>…][ : <message>]
OMW <Répondant> > <Perso> #SOS<n>
END <Perso> #SOS<n>
```

- `<Perso>`, `<Répondant>`, `<T1>…` : le PREMIER MOT du nom, sans royaume, ni espace, ni virgule.
  Sur Forever un nom complet est « Prénom Nom » (mesuré le 2026-09-27) : la ligne n'en garde que le
  prénom ; sur Retail, « Nom-Royaume » : elle garde le nom. Affiché seulement, jamais comparé.
- `<Zone>` : nom de la zone dans la langue de l'appelant (peut contenir espaces et apostrophes).
  **Garanti par l'addon** : ni `( ) # | [ ]` dans la zone, ni `# | [ ]` ni caractère de contrôle dans
  le message ; le lecteur coupe donc la queue au ` #SOS`, puis détache ` (<x>, <y>)` en fin de zone
  s'il y est. Une parenthèse restée dans la zone, ou un de ces caractères dans le message : ce n'est
  pas une ligne de l'addon (refusée à la relecture).
- `(<x>, <y>)` : coordonnées en pourcentage de la carte de zone, une décimale, point décimal ;
  **absentes** quand elles sont illisibles (D14 : zone seule). Dans le code, x et y sont des FRACTIONS
  (0..1, comme `C_Map.GetPlayerMapPosition`) : le pourcentage n'existe que dans le texte. Une seule
  des deux, ou au-delà de 100 : refusé.
- `k<T1>,<T2>…` et `c<C1>,<C2>…` (D15) : les tueurs, 5 au plus, les plus récents devant, en deux
  listes **alignées** séparées par des virgules : `c` a exactement autant d'éléments que `k`, `-` pour
  une classe inconnue, et `c` est absent si aucune classe n'est connue. Un `c` sans `k`, des listes de
  longueurs différentes, un nom vide : refusé. Si la ligne manque de place, les derniers tueurs sont
  retirés (la tête garde au plus 200 octets, le message prend le reste).
- `<n>` : numéro d'appel du personnage (compteur sauvegardé, croissant). Clé d'un appel = `Perso` + `n`.
- `<uiMapID>` : carte de zone (`C_Map.GetBestMapForUnit("player")` à la mort).
- `<morts>` : morts depuis l'ouverture de l'appel (1 à la première ligne).
- `<C1>…` : jeton de classe anglais (`ROGUE`, `MAGE`…), ou `-`.
- Une ligne `SOS` avec un `#SOS<n>` déjà vu **depuis moins de 15 minutes** (D11) = mise à jour de cet
  appel (morts, message). Au-delà, c'est un nouvel appel : le numéro vit dans les SavedVariables du
  poste, et un autre poste (ou une base effacée) repart de 1.

Exemples :

```
SOS Gnomi Forêt d'Elwynn (42.1, 65.3) #SOS7 m1429 d1 kXyz cROGUE : 3 voleurs au pont
SOS Gnomi Forêt d'Elwynn (42.1, 65.3) #SOS7 m1429 d3 kXyz cROGUE : 3 voleurs au pont
OMW Gnomette > Gnomi #SOS7
END Gnomi #SOS7
SOS Gnomi Forêt d'Elwynn #SOS8 m1429 d1 kXyz cROGUE
SOS Gnomi Forêt d'Elwynn (42.1, 65.3) #SOS7 m1429 d3 kXyz,Abc,Def cROGUE,MAGE,- : 3 voleurs au pont
```

Les deux derniers (ajoutés le 2026-10-27) : zone seule (D14), et trois tueurs dont un de classe
inconnue (D15). Le bot fige les six mêmes.

Le lecteur de commandes du bot (`WTB […] … #CO<n>`) ne lit aucune de ces lignes.

### Message d'addon de guilde (lu par les autres copies de l'addon)

Préfixe `WPPolice`, canal `GUILD`. Premier champ = **version du format** (1) ; un lecteur ignore une
version qu'il ne connaît pas. Champs séparés par une tabulation, texte libre privé de tabulations et
de `|`, 255 octets au plus.

- `1 SOS <n> <uiMapID> <x|-> <y|-> <morts> <tueurs|-> <CLASSES|-> <message>` — appel ou mise à jour
- `1 OMW <n> <Perso appelant>` — j'arrive (l'émetteur est le répondant)
- `1 END <n>` — réglé (l'émetteur est l'appelant)

Nombre de champs exact par sorte (10, 4, 3) : un message décalé est refusé, pas relu de travers.
`<x>`, `<y>` : pourcentage à une décimale, comme la ligne Discord, ou `-` tous les deux (zone seule,
D14). `<tueurs>`, `<CLASSES>` : les deux listes alignées de la ligne Discord (`Xyz,Abc,Def`,
`ROGUE,MAGE,-`), `-` pour une liste vide ; des tueurs sans aucune classe connue = `-` en `<CLASSES>`.
`<message>` peut être vide (le champ reste). Les tueurs s'écrivent au premier mot (ils ne sont
qu'affichés) ; l'appelant d'un `OMW` s'écrit en **nom complet**, tel que `CHAT_MSG_ADDON` l'a donné
comme émetteur du `SOS` : « Prénom Nom » sur Forever (une espace, pas de royaume), « Nom-Royaume »
sur Retail. Il sert à reconnaître l'appel ; le royaume et le nom de famille ne s'affichent jamais dans
une ligne. Nom du fil : mots séparés d'une espace, ni blanc au bord, ni tabulation, ni `| [ ] # : ,`.

### Données sauvegardées

`WorldPvPPoliceDB` : `nextCall` (prochain numéro d'appel, par personnage : clé = GUID du perso,
consommé seulement quand un appel part), `alerts` (on/off, compte ; `/wpp on|off`), `pile` (position
de la pile des fenêtres, compte : `{ point, point relatif, x, y }`, absente = position par défaut).
Depuis D17 (2026-10-28), par personnage (clé = GUID) : `calls` (MON appel en cours, la table même de
`NS.Call.active` : `n`, `serial`, `deaths`, `snap`, `killers`, `msg`, `sentAt` et `discordAt` en
secondes réelles `time()`, `guildSig`, `discordSig`, `enRoute` ; repris au retour s'il a moins de 15
minutes, sans `pending` ; effacé par « C'est réglé » ou l'expiration) et `lastDeath` (`serial`, le
numéro de ma dernière mort, qui ne repart jamais de 1 ; `dead`, vrai tant qu'elle n'est pas finie).
Les alertes reçues des autres ne sont pas gardées.

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

- ~~**T1** — Lignes et messages : construire / relire, nettoyer, couper (critères 1, 2, 3, 6).~~ FAIT
  le 2026-10-27.
- ~~**T2** — Mort : détection, lecture du récap, position, encart sous la fenêtre de mort (5, 10).~~
  FAIT le 2026-10-27 (critère 10 : au banc).
- ~~**T3** — Envoi : Appeler / Entrée / Libérer, fil Discord + message de guilde, morts répétées (4).~~
  FAIT le 2026-10-27 : `WorldPvPPolice_Call.lua` (logique pure + sondes), crochets dans `_Panel.lua`
  (`StaticPopup_OnClick` de la fenêtre DEATH, PLAYER_ALIVE en fantôme) ; critère 4 tenu en test
  (`tests/test_wpp_call.lua`) ; le branchement (clic puis libération auto = un envoi, rez acceptée =
  rien, appel expiré = case vide) dans `tests/test_wpp_panel.lua`. **Critère 9 relu le 2026-10-27**
  (agent `api-gotcha-reviewer`, sources Forever 70532 ET PTR Retail 12.1.7.70493, sur le mot du user) :
  aucune écriture dans la fenêtre de mort, aucun chemin de taint, valeurs secrètes testées partout,
  API présentes sur les deux clients. Suites données : D16 (confirmation par le retour), commentaires
  corrigés (« Libérer » n'a pas de touche). Laissés tels quels : l'encart peut chevaucher une nouvelle
  fenêtre un quart de seconde ; le compte rendu après « Libérer » ne se voit pas (l'encart se ferme :
  T4, l'écran de l'appelant). Contesté : l'agent tient la libération automatique pour presque
  inatteignable ; la fenêtre de mort décompte pourtant `GetReleaseTimeRemaining()` (lu dans la source) :
  à mesurer au banc (rester mort jusqu'au bout). Reste M2 au banc. ⚠️ Cette relecture date d'AVANT
  T4 : les envois de T4 (« J'arrive » et « C'est réglé », `C_Club.SendMessage` et `SendAddonMessage`
  dans nos propres `OnClick`) et les fenêtres de la réception n'ont pas été relus.
- ~~**T4** — Réception : alerte, J'arrive + point de route, liste « en route », C'est réglé, expiration,
  `/wpp on|off` (7, 11, 13).~~ FAIT le 2026-10-27, en trois commits : les deux formes de nom complet
  (`Line.WireName`, `Line.ShortName`) ; la logique (`WorldPvPPolice_Alert.lua`, `Call:AddResponder`,
  `Call:Settle`, `/wpp`), tenue par `tests/test_wpp_alert.lua` ; les fenêtres (`_AlertFrame.lua`,
  `_CallerFrame.lua`), tenues par `tests/test_wpp_alertframe.lua` (vrais fichiers, cadres factices).
  Critère 7 tenu en test ; 11 et 13 : au banc. Le piège noté ici (`OMW.caller` en nom COMPLET,
  « Prénom Nom » sur Forever, « Nom-Royaume » sur Retail) est réglé par `Alert:IsMe`, qui compare des
  noms complets et apprend le sien au retour de son propre SOS.
- **T5** — Bot : sa spec, son dépôt.
- **T6** — Au lancement : mesures M1 à M8 au banc, puis critères 10 à 13.
