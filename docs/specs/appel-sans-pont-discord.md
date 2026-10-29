# Un appel sans pont entre le jeu et Discord

> État : **brouillon** · 2026-10-29 · Demande du user (« penser à créer une spec si on n'a pas de liaison
> de données entre WoW et Discord ») ; options et recommandations de l'agent, **rien de décidé**. La
> spec de l'appel lui-même reste `appel-a-l-aide.md`.

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
- **O3 — En flux mêlé, la ligne dans le chat de guilde.** Sur le même geste que l'envoi Discord,
  l'addon écrit aussi la ligne `SOS` dans le chat de guilde, et le pont mêlé la porte sur Discord.
  Mesuré le 2026-10-10 avec une ligne de Crafting Order : une ligne écrite par un addon dans le chat de
  guilde arrive lisible sur Discord en flux mêlé.
  - Le prix : une ligne visible par toute la guilde à chaque appel. Dans une guilde non reliée (a), ce
    n'est que du bruit en double de l'alerte, et l'addon ne sait pas distinguer (a) de (b).
  - Donc **seulement sur demande du joueur** (`/wpp chatguilde on`, éteint par défaut), avec la même
    limite qu'aujourd'hui sur Discord : une mise à jour toutes les 2 minutes au plus.
  - **Recommandée comme option** pour les guildes qui ont choisi le flux mêlé ; à mesurer d'abord (M12).
- **O4 — Hors du jeu** (une appli sur le PC qui lit le journal de chat et poste sur un webhook) :
  écartée, voir ci-dessous.

## Ce qu'on NE fait PAS

- **Aucun envoi sans geste**, relais compris (règle de `appel-a-l-aide.md`).
- **Rien hors du jeu** (O4) : un addon n'a pas de réseau, ses SavedVariables ne s'écrivent qu'au
  `/reload` ou à la déconnexion, et une appli à installer sur chaque PC sort du projet. À rouvrir
  seulement si le user le demande.
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

## Décisions à prendre (user)

1. O1 (expliquer « non relié ») : oui ou non ?
2. O2 (relais par un guildien) : seulement si M4 dit non ?
3. O3 (ligne dans le chat de guilde, éteinte par défaut) : à proposer aux guildes en flux mêlé ?
4. Ce qui doit être prêt pour le lancement du 4/11, et ce qui peut attendre.

## Critères d'acceptation (des options retenues)

1. [test] (O1) Guilde sans fil Discord : l'encart dit « Discord : non relié », son infobulle énumère
   les trois conditions et nomme le maître de guilde ou un officier ; aucun envoi Discord n'est tenté.
   `/wpp discord` répond en une ligne (skill `chat-output`).
2. [test] (O2) Au clic de B sur « J'arrive », la ligne `SOS` de A ne part que si elle n'a pas été vue
   dans le fil, une fois par version, et avant l'`OMW` de B ; jamais hors d'un clic.
3. [test, bot] (O2) Une ligne `SOS` relayée tombe sur la carte de A ; la ligne de A arrivée ensuite la
   met à jour sans nouvelle mention. Déjà vrai : à épingler par un test nommé « relais ».
4. [test] (O3) Éteinte : aucune ligne dans le chat de guilde. Allumée : une ligne par geste, au plus
   une mise à jour toutes les 2 minutes ; rien en instance.
5. [human] (O3) Dans une guilde en flux mêlé, sur le serveur de test : un appel fait sa carte dans
   `#alertes-pvp`. Témoin : le même appel en flux séparé.

## Renvois

- `appel-a-l-aide.md` : D5 (flux séparé), D12 (« J'arrive » sur Discord), D16 (le retour de la ligne),
  M2, M4, « Ce qu'on NE fait PAS » (relais) et « Cas particuliers » (guilde non reliée), qui renvoient ici.
- Bot : `WorldPvPPoliceBot/docs/specs/alertes-pvp.md` (P4, P10 à P12), guide d'hébergement
  (`docs/hebergement.md`, « Ce qu'il faut »).
- Skill public `wow-forever-api`, `chat-channels-and-communities.md` : « Guild chat bridged to a
  Discord channel » (flux mêlé, fil séparé, `C_Club.SendMessage` sur un geste).
