# Un appel sans pont entre le jeu et Discord

> État : **validée** · 2026-10-30 · Demande du user (« penser à créer une spec si on n'a pas de
> liaison de données entre WoW et Discord ») ; options de l'agent, **tranchées par le user** (S1 à S5).
> O1 et O3 codées, jamais vues en jeu (M12 à faire) ; O2 attend M4 et M13. S7 (Discord dans un module
> à part, `WorldPvPPoliceDiscord` ; remplace l'interrupteur S6) codée le 2026-11-09, jamais vue en jeu.
> La spec de l'appel lui-même reste `appel-a-l-aide.md`.

## Le problème

Un appel n'arrive sur Discord que si TOUT ceci est vrai :

1. la guilde est reliée à un serveur Discord (réglage du maître de guilde ou d'un officier) ;
2. la case qui **sépare le chat Discord** du chat de guilde est cochée (D5 de `appel-a-l-aide.md`) :
   le fil « Discord » de la guilde, où l'addon écrit, n'existe qu'en flux séparé ;
3. l'appelant peut écrire dans ce fil (jamais mesuré pour un guildien dont le Battle.net n'est pas relié
   à Discord : M4 de `appel-a-l-aide.md`).

Sinon, l'appel part en jeu seulement et l'encart affiche « Discord : non relié » (cas particulier
« Guilde non reliée à Discord, ou en flux mêlé » de `appel-a-l-aide.md`). Ça touche :

- **(a)** une guilde qui n'a jamais relié Discord : personne ne peut rien envoyer ;
- **(b)** une guilde reliée **en flux mêlé**. C'est le cas le plus probable d'une autre guilde qui
  installe l'addon public, et l'addon ne peut pas le reconnaître : les lectures de `C_Discord` sont
  protégées (mesuré le 2026-10-10) ;
- **(c)** un guildien sans Discord dans une guilde reliée en flux séparé, si M4 dit qu'il ne peut pas
  écrire dans le fil ;
- **(d)** une ligne bloquée faute de geste. Déjà traité : elle repart au geste suivant (D16).

Aujourd'hui, l'appelant lit « non relié » sans savoir pourquoi ni qui peut y remédier.

## Ce qu'on veut

- **La base ne bouge pas** : l'alerte en jeu passe par les messages d'addon de guilde et ne dépend
  jamais de Discord. Une guilde sans Discord a un addon complet, moins les cartes.
- **Le joueur sait pourquoi** un appel ne va pas sur Discord, et qui peut y remédier.
- **Quand c'est possible, l'appel atteint quand même Discord** par un chemin du jeu, toujours sur un
  geste d'un joueur.

## Les options

- **O1 — Dire pourquoi, et quoi faire.** Une infobulle sur « Discord : non relié » (encart et « Ton
  appel »), et `/wpp discord` qui dit la même chose en une réponse : les trois conditions ci-dessus, et
  que c'est le maître de guilde ou un officier qui relie la guilde et coche la case. L'addon ne peut pas
  dire laquelle manque (flux mêlé indétectable) ; il les énumère. Petit coût, aide les cas (a), (b) et
  (c). **Recommandée.**
- **O2 — Relais par un guildien relié, à SON geste.** B reçoit l'alerte de A. Si la ligne `SOS` de A
  n'est pas apparue dans le fil Discord au bout de quelques secondes, le prochain clic de B sur
  « J'arrive » (qui écrit déjà sur Discord, D12) écrit d'abord la ligne de A telle que B l'a reçue,
  puis son `OMW`. B lit le fil par `CHAT_MSG_GUILD_DISCORD`, comme l'appelant lit déjà le retour de sa
  propre ligne (D16).
  - Contraintes : écrire dans le fil exige un geste (`C_Club.SendMessage`, `HasRestrictions`), donc
    jamais de relais en arrière-plan. Au plus un relais par version de l'appel.
  - Côté bot, rien à changer : un appel se reconnaît au texte de la ligne (prénom + numéro), pas à
    celui qui l'a postée. La ligne relayée tombe sur la carte de A, et si celle de A arrive ensuite, elle
    met la carte à jour sans nouvelle mention (P4, P11 de `alertes-pvp.md` du bot ;
    `test_pvp_relay.OneCard.test_un_appel_une_carte`).
  - Ne sert que le cas (c) : en (a) personne ne peut écrire, en (b) le fil n'existe pas.
  - **Recommandée seulement si M4 dit non.**
- **O3 — En flux mêlé, la ligne dans le chat de guilde** (retenue par le user sous le nom « forcer
  Discord en chat fusionné », S3). Sur le même geste que l'envoi Discord, l'addon écrit la ligne
  (`SOS`, et aussi `OMW` et `END`, sinon la carte ne saurait ni qui arrive ni quand c'est réglé) dans le
  chat de guilde, et le pont mêlé la porte sur Discord. Les lignes tiennent déjà dans les 255 octets
  d'une ligne de chat (`Line.MAX_BYTES`).
  Mesuré le 2026-10-10 avec une ligne de Crafting Order : une ligne écrite par un addon dans le chat de
  guilde arrive lisible sur Discord en flux mêlé.
  - Le prix : une ligne visible par toute la guilde à chaque appel. Dans une guilde non reliée (a), ce
    n'est que du bruit en double de l'alerte, et l'addon ne sait pas distinguer (a) de (b).
  - Donc **seulement sur demande du joueur** (`/wpp fusion on`, éteint par défaut), avec la même
    limite qu'aujourd'hui sur Discord : une mise à jour toutes les 2 minutes au plus.
  - **Recommandée comme option** pour les guildes qui ont choisi le flux mêlé ; à mesurer d'abord (M12).
- **O4 — Hors du jeu** (une appli sur le PC qui lit le journal de chat et poste sur un webhook) :
  écartée, voir ci-dessous.

## Ce qu'on NE fait PAS

- **Aucun envoi sans geste**, relais compris (règle de `appel-a-l-aide.md`).
- **Rien hors du jeu** (O4, écartée par le user : S4) : un addon n'a pas de réseau, ses SavedVariables
  ne s'écrivent qu'au `/reload` ou à la déconnexion. Le seul chemin est le pont du jeu vers Discord,
  puis le bot.
- **Pas de détection du flux mêlé** : impossible pour un addon (mesuré). O1 énumère, O3 est un choix
  du joueur.
- **Pas de réglage de la guilde à la place du joueur** : le lien Discord et sa case restent au maître de
  guilde ou aux officiers.
- **Pas de ligne dans le chat de guilde par défaut** (O3) : règle « pas de spam » du user.

## Cas particuliers

- **O2, la ligne de A arrive après le relais de B** : même appelant, même numéro, donc même carte. Elle
  met la carte à jour sans nouvelle mention.
- **O2, deux guildiens relaient le même appel** : deux lignes pour un même appel ; le bot met à jour
  la même carte. Chez chacun, au plus un relais par version.
- **O2, B relaie une version ancienne** (A est remort entre-temps, et B n'a pas encore reçu la
  mise à jour) : la carte montre la version de B jusqu'à la ligne suivante. Accepté.
- **O2, nom sur Discord** : la ligne relayée paraît sous le compte Discord de B, mais elle nomme A, et
  le bot l'efface dès sa carte faite.
- **Une fausse ligne** : un guildien peut déjà écrire à la main un `SOS` au nom d'un autre. O2 ne
  change rien à ce risque, limité à la guilde.
- **O3 dans une guilde en flux séparé** : la ligne de guilde ne va pas sur Discord (seul le fil y va),
  et la ligne du fil part comme aujourd'hui. Un joueur qui a mis O3 par erreur ne fait que du bruit en
  jeu : O1 le lui dit.
- **O3, le bot efface la ligne brute du salon relié** : en flux mêlé, l'effacer sur Discord la retire-t-il
  aussi du chat de guilde en jeu ? Pas mesuré (M12).
- **O3 allumée alors que la guilde a le fil séparé** : le module voit le fil (`Stream.Get()`) et
  l'emploie ; l'option ne sert alors à rien et n'écrit rien dans le chat de guilde.
- **O3, pas de retour à attendre** : en flux mêlé, aucune ligne ne revient dans un fil Discord. L'addon
  sait seulement que la ligne est partie dans le chat de guilde, et l'encart le dit (« Discord : par le
  chat de guilde ») au lieu de « envoyé ».
- **O3, côté bot** : en flux mêlé, TOUT le chat de guilde arrive dans le salon relié comme des messages
  du jeu. Le bot n'y traite que les lignes d'appel, mais aujourd'hui il note chaque message du jeu dans
  son journal, donc tout le chat de guilde. En `repondre`, il ne devra plus noter que les lignes
  d'appel. Son rattrapage relit au plus 200 messages du salon relié (`HISTORY`) : dans une guilde
  bavarde, une ligne ratée de plus de 200 messages ne sera pas reprise. Accepté.

## Mesures, avant de coder

- **M4** (`appel-a-l-aide.md`) — Un guildien sans Discord relié peut-il écrire dans le fil Discord ?
  Décide O2.
- **M12** (O3) — En flux mêlé, une ligne `SOS` écrite par WPP dans le chat de guilde sur un geste :
  - arrive-t-elle sur Discord, et sous quel nom pour un guildien sans Discord ?
  - le bot en fait-il sa carte (`is_from_game`) ?
  - l'effacer sur Discord la retire-t-il du chat en jeu ?
- **M13** (O2) — B reçoit-il la ligne de A dans `CHAT_MSG_GUILD_DISCORD` (texte lisible, GUID de A),
  et en combien de temps ? Le 2026-10-10 on a mesuré la réception du fil, pas une ligne d'un autre
  guildien en particulier.

Les trois demandent un client Forever ou le PTR, avec une guilde dont on peut changer les réglages
Discord (le serveur de test du user).

## Décisions

- **S1** (user, 2026-10-29, « 1 OUI ») — **O1 retenue** : l'addon explique « Discord : non relié » et
  qui peut y remédier.
- **S2** (user, 2026-10-29, « 2 OUI ») — **O2 retenue, si M4 dit non** : un guildien relié relaie la
  ligne restée bloquée, à son propre clic sur « J'arrive ».
- **S3** (user, 2026-10-29, « on peut rajouter une option pour forcer l'activation de Discord (Discord
  avec chat fusionné) ») — **O3 retenue comme une option** que le joueur allume : « Discord en chat
  fusionné ». Éteinte par défaut ; sans effet quand l'addon voit le fil séparé. O1 la nomme.
- **S4** (user, 2026-10-29, « pas d'appli hors jeu, on doit juste avoir une liaison WoW > Discord, le
  bot récupère la data sur Discord ») — **Un seul chemin : le pont du jeu vers Discord**, puis le bot
  qui lit Discord. O4 écartée pour de bon ; rien ne repasse de Discord vers le jeu.
- **S5** (user, 2026-10-30, « oui suivre l'appel », ex-Q5) — **L'option suit l'appel** : l'appelant l'a
  allumée, son message d'addon le dit (11e champ `F`, `appel-a-l-aide.md`, « Contrat »), et le `J'arrive`
  de chaque guildien prend le même chemin. Une seule personne à régler par appel : dans une guilde en
  flux mêlé, c'est souvent un seul officier qui saura qu'il faut l'allumer. Le drapeau ne part que si
  l'option est allumée ET que l'appelant ne voit pas le fil séparé ; un répondant qui voit le fil
  l'emploie, drapeau ou non.
- **S6** (user, 2026-11-09, « on va le publier sur CurseForge donc faudrait aussi une option sans
  Discord pour ceux qui vont le télécharger à l'extérieur de notre guilde ») — le besoin : une guilde
  sans le bot sur son Discord, mais reliée en fil séparé, recevrait des lignes `SOS …` brutes que
  personne ne lit. D'abord codé en interrupteur par joueur (`/wpp discord on|off`, une case, branche
  `feat/wpp-sans-discord`, jamais fusionnée ni publiée) ; **remplacé le même jour par S7**.
- **S7** (user, 2026-11-09, « on crée un module à télécharger sur CurseForge ou bien ? pvp police et un
  autre pvp police discord avec le module ? », puis « oui vas-y ») — **Deux addons** :
  - **World PvP Police Guild** (`WorldPvPPolice`, l'addon de base) : l'appel en jeu, la guilde seule.
    Pas un mot de Discord à l'écran (encart, « Ton appel », aide de `/wpp`, page d'options, traductions)
    et aucun chemin vers Discord ni vers le chat de guilde ; le SOS ne porte jamais le drapeau `F`. C'est
    ce que télécharge une guilde sans le bot.
  - **World PvP Police Guild - Discord** (`WorldPvPPoliceDiscord` : le script de création refuse le
    `_`) : la moitié « en jeu » du bot. Ce qui touchait à Discord y est passé tel quel : le fil, la ligne
    du bot, son retour, le délai de 2 minutes, O1, O3 (S3, S5). `## Dependencies: WorldPvPPolice`.
    Installé = allumé ; pour couper, on le désactive dans la liste des AddOns : plus d'interrupteur
    `discord`, plus de défaut à choisir. Il ajoute `/wpp discord`, `/wpp fusion` et sa case « Discord en
    chat fusionné » à la page de la base ; `fusion` vit dans SA base (`WorldPvPPoliceDiscordDB`), reprise
    une fois de `WorldPvPPoliceDB` où le PTR l'avait posée.
  - **La prise** (`WorldPvPPolice_Bridge.lua`) : le module s'y branche (`NS:Plug`) ; la base l'appelle
    dans la pile du geste (`C_Club.SendMessage` l'exige), sous `pcall`, et lui laisse une part du texte
    (« · Discord : envoyé »). `WorldPvPPolice_Line.lua` (les deux formats, gelés) reste dans la base.
  - Conséquence pour S5 : un répondant sans le module n'écrit pas son `OMW` dans le chat de guilde, même
    si l'appelant a le drapeau. Une guilde en chat fusionné installe le module chez tous.
  - CurseForge : deux projets ; le module doit déclarer la base comme dépendance requise (`.pkgmeta`,
    `required-dependencies`, ou la page du projet) pour que l'appli l'installe avec. Pas encore vérifié,
    à régler avant la première version.

## Critères d'acceptation (des options retenues)

1. [test] (O1) Guilde sans fil Discord : l'encart dit « Discord : non relié », son infobulle énumère
   les trois conditions, nomme le maître de guilde ou un officier, et l'option « Discord en chat
   fusionné » ; aucun envoi Discord n'est tenté. `/wpp discord` répond en une ligne (skill
   `chat-output`).
2. [test] (O2) Au clic de B sur « J'arrive », la ligne `SOS` de A ne part que si elle n'a pas été vue
   dans le fil, une fois par version, et avant l'`OMW` de B ; jamais hors d'un clic.
3. [test, bot] (O2) Une ligne `SOS` relayée tombe sur la carte de A ; la ligne de A arrivée ensuite la
   met à jour sans nouvelle mention. Déjà vrai : à épingler par un test nommé « relais ».
4. [test] (O3) Éteinte : aucune ligne dans le chat de guilde. Allumée : une ligne par geste, au plus
   une mise à jour toutes les 2 minutes ; rien en instance ; rien dans le chat de guilde quand le fil
   séparé existe.
5. [human] (O3) Dans une guilde en flux mêlé, sur le serveur de test : un appel fait sa carte dans
   `#alertes-pvp`, avec qui arrive et « réglé ». Témoin : le même appel en flux séparé.
6. [test, bot] (O3) En `repondre`, le journal du bot ne note que les lignes d'appel ; un message de chat
   ordinaire venu du jeu n'y laisse aucune trace de son texte.
7. [test] (S7) La base seule : aucune sonde vers Discord ; `C_Club.SendMessage` et
   `SendChatMessage` jamais appelés à l'appel, à la mise à jour, au « J'arrive » (même pour un appel au
   drapeau `F`) ni à « C'est réglé », guilde reliée en fil séparé ou non ; pas de drapeau `F`. Le module
   branché, sans fil ni chat fusionné : le message de guilde identique à l'octet ; avec le fil, la ligne
   part. (`tests/test_wpp_sans_discord.lua`, puis les tests WPP qui chargent le module)
8. [test] (S7) La base seule ne dit pas un mot de Discord : compte rendu de l'encart, sa ligne du bas
   avant l'envoi, « Ton appel », l'aide de `/wpp`, la page d'options, aucune de ses traductions ;
   `/wpp discord` et `/wpp fusion` y répondent par l'aide. Le module branché les ajoute, une ligne chacun.
9. [test] (S7) La page d'options de la base a une case (les alertes), qui écrit le même réglage que
   `/wpp on|off` ; le module y ajoute la sienne, qui lit et écrit SA base et suit `/wpp fusion` ; aucune
   ligne de chat ; `/wpp options` refuse en combat.
10. [human] (S7) En jeu (PTR, puis Forever), la base SEULE : la page a une case, un appel ne laisse
    aucune ligne dans le salon relié et l'encart ne parle pas de Discord. Puis le module ajouté (client
    relancé : un addon neuf) : la liste des AddOns le montre dépendant de la base, sa case apparaît, la
    ligne de l'appel arrive dans le salon relié (témoin), `/wpp discord` répond.

## Renvois

- `appel-a-l-aide.md` : D5 (flux séparé), D12 (« J'arrive » sur Discord), D16 (le retour de la ligne),
  M2, M4, « Ce qu'on NE fait PAS » (relais) et « Cas particuliers » (guilde non reliée), qui renvoient ici.
- Bot : `WorldPvPPoliceBot/docs/specs/alertes-pvp.md` (P4, P10 à P12), guide d'hébergement
  (`docs/hebergement.md`, « Ce qu'il faut »).
- Skill public `wow-forever-api`, `chat-channels-and-communities.md` : « Guild chat bridged to a
  Discord channel » (flux mêlé, fil séparé, `C_Club.SendMessage` sur un geste).

## Plan (2026-10-29) — volatile, meurt quand c'est fait

- **T1** — CODÉ le 2026-10-30 (`feat/wpp-sans-pont`, addon + outillage, `tests/test_wpp_sans_pont.lua`) :
  O1, l'infobulle et `/wpp discord`.
- **T2** — CODÉ le 2026-10-30 (même branche) : O3 selon S5, `/wpp fusion`, la route par le chat de guilde
  (`C_ChatInfo.SendChatMessage`), le compte rendu « par le chat de guilde ». Reste M12 au banc, sur le
  serveur de test en flux mêlé.
- **T3** (bot) — En `repondre`, ne noter que les lignes d'appel (critère 6).
- **T4** (addon) — O2, seulement après M4 (un guildien sans Discord : un testeur extérieur) et M13.
- **T5** (addon) — S6 codée sur `feat/wpp-sans-discord` : remplacée par T6, qui en reprend `/wpp options`
  et la page d'options. Cette branche ne se fusionne jamais seule.
- **T6** (addon + module + outillage) — CODÉ le 2026-11-09 (`feat/wpp-module-discord` dans les trois
  dépôts, par-dessus `feat/wpp-sans-discord`) : S7, la prise, le module `WorldPvPPoliceDiscord`. Les
  trois branches se fusionnent le même jour (les tests de l'outillage lisent le dossier du module).
  Reste le critère 10 en jeu, et la dépendance requise côté CurseForge.
