# Appeler un mercenaire (tank, soigneur) sur Discord

> État : **brouillon** · Idée du user le 2026-11-03 (« en jeu, quand on recherche un groupe, on peut appeler
> un tank sur le Discord ») ; R1 à R4 tranchées par le user le même jour, puis les noms des rôles, le
> salon à part et le widget près de la recherche de groupe (R6) ; R5 et R7 à R11 proposées par l'agent,
> **à confirmer**. Rien de codé, rien de mesuré. Le bot qui lit la ligne a sa propre spec :
> `F:\WorldPvPPoliceBot\docs\specs\mercenaires.md` (même branche `docs/spec-mercenaires`).

## Le problème

Un groupe qui monte un donjon attend souvent un tank ou un soigneur. Le canal Recherche de groupe et
le chat de guilde ne touchent que les joueurs connectés. Or les guildiens qui viendraient tanker ou
soigner s'ils savaient qu'on cherche quelqu'un sont souvent ailleurs : sur Discord, sur leur
téléphone, dans un autre jeu. Sur le Discord de la guilde, ceux qui acceptent d'être appelés prennent
un rôle de **mercenaire** dans « Salons et rôles », comme `pvp-police` pour les appels PvP. Aujourd'hui,
rien ne relie le jeu à ces rôles : il faut sortir du jeu et taper `@Tank Mercenaire` à la main.

## Ce qu'on veut

1. **Une petite fenêtre « Appeler un mercenaire »**, à nous : deux cases **Tank** et **Soigneur**
   (au moins une cochée), une case de message (« Profondeurs de Rochenoire, on est 4 à l'entrée ») et
   un bouton **Appeler**. **Elle apparaît d'elle-même, collée au bord de la fenêtre de recherche de
   groupe** quand on l'ouvre, et disparaît quand on la ferme (R6). Elle s'ouvre aussi par `/wpp tank`
   ou `/wpp heal` (la case est déjà cochée) et par `/wpp merc`.
2. **L'appel part au clic**, ou à Entrée dans la case : une ligne dans le fil Discord de la guilde,
   par le même chemin que le SOS (option `/wpp fusion` comprise). Elle porte le nom complet de
   l'appelant, les rôles cherchés, la zone où il se trouve (le donjon s'il y est déjà) et le message.
3. **Sur Discord**, le bot en fait une carte dans un salon dédié et mentionne `@Tank Mercenaire`,
   `@Heal Mercenaire`, ou les deux. La carte dit qui chuchoter en jeu.
4. **Le mercenaire répond en chuchotant l'appelant** (R4). L'addon n'invite personne et n'alerte
   personne en jeu.
5. **Tant que l'appel est ouvert**, la fenêtre l'affiche (« Ton appel : tank, sur Discord depuis
   21:04 ») avec un bouton **Trouvé** qui le ferme : la carte passe en gris. Sans « Trouvé », l'appel
   expire **30 minutes après sa dernière ligne** (R10), la même horloge que le bot.
6. **Changer le message** d'un appel ouvert met la carte à jour sans relancer la mention (R7).

## Ce qu'on NE fait PAS

- **Rien n'est écrit DANS la recherche de groupe de Blizzard** (R3, R6) : notre fenêtre se pose à
  côté, et elle ne touche ni à la fenêtre de Blizzard ni à ses tables ou à ses fonctions (aucun
  `SetParent`, `SetPoint` ou `HookScript` sur elle, aucun `hooksecurefunc` dans son code). Pas de
  lecture de l'annonce non plus (activité, places libres) : le taint LFG imputé à COC n'est toujours
  pas résolu, et lire l'annonce par `C_LFGList` sur Forever n'a jamais été mesuré. Au mieux une v2,
  après mesure.
- **Pas d'alerte en jeu** pour les guildiens (R4) : pas de message d'addon, pas de « J'arrive », pas
  de point de route.
- **Pas d'invitation automatique.**
- **Pas de rôle DPS** (R2).
- **Pas de relance automatique** : une ligne par geste du joueur, jamais d'envoi sur un minuteur.
- **Pas de repli sans pont** (R11) : sans fil Discord et sans `/wpp fusion on`, rien ne part, ni
  dans le chat de guilde, ni dans le canal Recherche de groupe.
- **Ni niveau, ni classe, ni composition du groupe** dans la ligne : le message les porte si
  l'appelant le veut.
- **Rien dans le chat** hors des réponses à `/wpp` (skill `chat-output`).

## Cas particuliers

- **Pas de guilde**, ou **ni fil Discord ni fusion** : la fenêtre s'ouvre, Appeler est grisé, et
  l'infobulle donne la raison (le texte de `Discord.WhyLines`, O1 de `appel-sans-pont-discord.md`).
- **En combat** : Appeler est grisé (R9), car le chat se verrouille en combat de boss (mesuré, voir
  le skill public `wow-forever-api`) et le combat ordinaire n'a jamais été mesuré (MR3).
- **En instance ou en groupe** : permis (R9). On cherche souvent un tank alors qu'on est déjà dans le
  donjon, et la zone de la ligne est alors le nom du donjon.
- **Un appel déjà ouvert, clic sur Appeler avec les mêmes rôles** : mise à jour du message, même
  numéro, sans nouvelle mention (R7).
- **Un appel déjà ouvert, avec d'autres rôles** : l'ancien est fermé (`END`), un nouveau part avec un
  nouveau numéro (R8). Le bot ne re-sonne pas un rôle déjà mentionné il y a moins de 10 minutes pour
  le même appelant (sa spec, B5).
- **La ligne ne revient pas en jeu** : l'état dit « Discord : pas encore vu » ; elle ne compte comme
  partie qu'une fois revenue (D16 de `appel-a-l-aide.md`).
- **`/reload` ou déco-reco** : l'appel ouvert survit, heures en `time()` (comme D17).
- **Expiration** : 30 minutes après la dernière ligne envoyée (une mise à jour relance l'horloge),
  l'addon montre l'appel fermé ; aucune ligne `END` ne part, faute de geste du joueur. Le bot grise
  la carte 30 minutes après la dernière ligne reçue : la même règle des deux côtés.
- **Une mise à jour à la limite des 30 minutes** (envoyée à 29:59, reçue à 30:01) : le bot peut y voir
  un nouvel appel et ouvrir une 2e carte. Elle ne sonne pas (B5 du bot), et la 1re expire seule.
- **Message trop long** : coupé sans casser un caractère, comme le SOS (255 octets la ligne).
- **Nom illisible ou réservé** : pas d'appel, et l'infobulle le dit. Cas rare.
- **Deux personnages du même nom complet** : la clé est `Nom + n`, collision acceptée.
- **PTR de Retail** : le nom est « Nom-Royaume », et le royaume est retiré (règle du user : le pont
  entre royaumes reste invisible).
- **Une ligne `LFM` lue par un bot qui ne la connaît pas** (le bot d'avant ce chantier,
  CraftingOrderBot) : ignorée, la ligne brute reste lisible dans le salon relié. Rien ne casse,
  quel que soit l'ordre de déploiement.

## Décisions

- **R1** (user, 2026-11-03) : c'est dans **World PvP Police**, addon et bot. `pvp-police` devient un
  mercenaire parmi d'autres.
- **R2** (user) : deux rôles, nommés exactement **`Tank Mercenaire`** et **`Heal Mercenaire`** sur le
  serveur (noms donnés par le user le 2026-11-03). Pas de DPS. Les rôles se prennent dans « Salons et
  rôles » du Discord, comme `pvp-police` ; le bot les cherche par leur nom, casse ignorée (B3 du bot).
- **R3** (user) : **notre fenêtre + `/wpp tank|heal`**. Rien n'est greffé dans la recherche de groupe
  de Blizzard.
- **R4** (user) : **le mercenaire chuchote l'appelant** ; pas d'alerte en jeu.
- **R5** (agent, à confirmer) : une ligne **`LFM`** qui porte le **nom complet** (`Prénom_Nom`, comme
  les tueurs de D22) et la zone de l'appelant. Le mercenaire doit pouvoir chuchoter, et le prénom
  seul, celui des lignes SOS, ne suffit pas sur Forever. « LFM » se comprend aussi sans le bot. Le nom
  complet est lisible : `GetUnitName("player", true)` rend « Prénom Nom » sur Forever (mesuré le
  2026-09-27, skill `wow-forever-api`, chat-channels-and-communities.md), et un chuchotement au nom
  complet atteint le bon personnage (même source).
- **R6** (user, 2026-11-03, « quand on ouvre l'interface de recherche de groupe un widget apparaît ?
  c'est possible sans taint l'UI ? ») : **notre fenêtre apparaît collée au bord de la recherche de
  groupe** quand elle s'ouvre, et part avec elle ; on garde `/wpp tank|heal|merc`. Pas d'entrée dans
  le menu des addons. La méthode, proposée par l'agent, est la seule mesurée sans taint sur Forever (le
  2026-09-19, sur la fenêtre des métiers ; skill `wow-forever-api`, taint-and-protected-frames.md) :
  notre fenêtre a `UIParent` pour parent, s'ancre par `SetPoint` sur le bord de `LFGParentFrame`, et
  rien n'est écrit dans la fenêtre de Blizzard. Pour savoir qu'elle s'ouvre, on lit
  `LFGParentFrame:IsShown()` quelques fois par seconde, sans `HookScript` ni `hooksecurefunc` : la
  recherche de groupe charge à la demande (`Blizzard_GroupFinder_VanillaStyle`, `## Secure: 1`), et sa
  recherche automatique (`C_LFGList.Search` sans clic) est le chemin même du taint LFG encore ouvert.
  On n'y touche pas, même par un crochet réputé sûr. Ce n'est mesuré que sur la fenêtre des métiers :
  MR4 doit le confirmer sur la recherche de groupe avant toute release. Si MR4 est KO, on retire le
  widget et il reste le slash.
- **R7** (agent, à confirmer) : une seule mention par appel ; une mise à jour ne relance pas la mention.
- **R8** (agent, à confirmer) : un seul appel ouvert par personnage ; changer de rôles = fermer et
  rouvrir.
- **R9** (agent, à confirmer) : permis en instance et en groupe, grisé en combat.
- **R10** (agent, à confirmer) : un appel vit 30 minutes après sa dernière ligne, comme un SOS (D11),
  et le bot compte de la même façon.
- **R11** (agent, à confirmer) : sans pont, aucun repli vers un autre canal.

## Mesures à faire (Forever, à partir du 2026-11-04)

- **MR1, taper `/w Prénom Nom message`** : est-ce que ça part au bon personnage ? Le code de Blizzard
  le prévoit (`ExtractTellTarget`, `Blizzard_ChatFrameBase/Shared/ChatFrameEditBox.lua` : « Prénom Nom »
  et « Prénom-Nom » quand les noms uniques par région sont actifs), mais on ne l'a jamais tapé. C'est ce
  qui décide la ligne « Pour répondre » de la carte. Témoin : clic droit sur un guildien dans la liste
  de guilde, « Chuchoter », puis lire ce que le jeu écrit dans la case de saisie.
- **MR2, le fil Discord depuis un donjon**, hors combat : la ligne revient-elle en jeu (D16) ?
- **MR3, en combat ordinaire** (hors boss) : l'envoi au fil Discord passe-t-il ? Si oui, R9 peut
  s'assouplir.
- **MR4, le widget ne teinte pas la recherche de groupe** : `/console taintLog 1`, puis on ouvre et
  on ferme la recherche de groupe, on crée une annonce, on la modifie, on rejoint le groupe d'un autre
  compte (c'est ce chemin, `LFG_LIST_ACTIVE_ENTRY_UPDATE` → `C_LFGList.Search`, que vise le bug ouvert),
  le tout aussi en combat. On attend : aucun `ADDON_ACTION_BLOCKED`, et rien qui nomme WorldPvPPolice
  dans `Logs/taint.log`. Témoin : le même parcours, addon désactivé. Attention : au niveau 1, le
  journal n'écrit qu'au moment d'un blocage (vu au banc PTR du 2026-10-28), donc un journal vide reste
  une preuve faible ; le niveau 2, plus bavard, si le temps le permet.

## Critères d'acceptation

1. [test] Une ligne `LFM` ou `END … #LFM` produite puis relue rend les mêmes champs, et les exemples
   du contrat sortent identiques à l'octet. → `tests/test_wpp_lfm.lua` (outillage)
2. [test] Une ligne `LFM` n'est jamais lue comme un SOS, un OMW ou un END d'appel PvP, et l'inverse
   non plus. → même fichier
3. [test] Sans fil Discord et sans fusion, Appeler n'envoie rien. Avec la fusion, la ligne part dans
   le chat de guilde. → même fichier, sur le vrai module devant un jeu factice
4. [test] Changer le message d'un appel ouvert garde le numéro et relance les 30 minutes ; changer
   les rôles envoie `END` puis un nouveau numéro ; un `/reload` rend l'appel ouvert ; 30 minutes après
   la dernière ligne, l'appel est fermé. → même fichier
5. [test] Aucune ligne dans le chat hors d'une réponse à `/wpp`, comptée comme le demande le skill
   `chat-output`.
6. [check] Les quatre portes, dont la locale : tout le texte de la fenêtre est en FR, avec ses
   overlays en/de/es.
7. [human] Forever, compte A dans une guilde reliée : `/wpp tank`, un message, Appeler. L'état passe
   à « sur Discord », la carte arrive dans le salon des mercenaires avec `@Tank Mercenaire`, et le
   téléphone d'un porteur du rôle sonne. Témoin : une carte SOS le même jour (même pont, même bot).
   Observateur : le user.
8. [human] Le compte B chuchote ce que la carte indique, et A reçoit le chuchotement (MR1).
   Observateur : le user, sur les deux comptes.
8 bis. [human] On ouvre la recherche de groupe : notre fenêtre apparaît collée à son bord, elle suit
   la fenêtre quand on la déplace et part quand on la ferme. Le parcours de MR4 ne bloque rien.
   Témoin : le même parcours, addon désactivé. Observateur : le user.
9. [human] Sur A, « Trouvé » : la carte passe en gris en moins d'une minute. Témoin : le `END` d'un
   SOS. Observateur : le user.
10. [agent] `api-gotcha-reviewer` : rien n'est écrit dans une fenêtre de Blizzard, et rien ne part
    sans geste du joueur.

## Contrat

### Ligne du fil Discord (lue par le bot et par des humains)

Deux formes nouvelles. Les lignes SOS, OMW et END d'un appel PvP ne changent pas d'un octet.

```
LFM <Nom> <Rôles> <Zone> #LFM<n>[ : <message>]
END <Nom> #LFM<n>
```

- `<Nom>` : le nom le plus complet connu, sans royaume, ses espaces remplacées par `_`
  (`Gnomi_Ombrelune`) ; on le relit « Gnomi Ombrelune ». C'est le nom à chuchoter, la règle des tueurs
  (D22) et non celle du `<Perso>` des SOS (le prénom seul).
- `<Rôles>` : `TANK`, `HEAL` ou `TANK,HEAL`, dans cet ordre. Toute autre valeur est refusée.
- `<Zone>` : la zone où se trouve l'appelant, dans sa langue (le donjon s'il y est), avec les mêmes
  garanties que la zone d'un SOS (ni `( ) # | [ ]`) ; `-` si elle est illisible.
- `<n>` : un numéro d'appel du personnage, sauvegardé. C'est un **compteur à part** de celui des SOS.
  Clé d'un appel : `Nom + n`.
- `<message>` : les mêmes garanties que le message d'un SOS (ni `# | [ ]`, ni caractère de contrôle).
- Ni coordonnées ni carte : la carte du bot n'a pas d'image.
- 255 octets au plus ; le message est coupé sans casser un caractère UTF-8.
- Un `LFM` dont le `#LFM<n>` a eu sa **dernière ligne** il y a moins de 30 minutes met cet appel à
  jour. Au-delà, c'est un nouvel appel. L'addon ne change jamais les rôles sous le même numéro (R8) ;
  si un lecteur le voit quand même, il prend les rôles de la nouvelle ligne.

Exemples :

```
LFM Gnomi_Ombrelune TANK Montagne de Rochenoire #LFM3 : Profondeurs de Rochenoire, on est 4 à l'entrée
LFM Gnomi_Ombrelune TANK,HEAL Les Mortemines #LFM4
END Gnomi_Ombrelune #LFM4
```

### Données sauvegardées

`WorldPvPPoliceDB.merc = { n = <dernier numéro>, open = { n, roles, msg, lastAt, seenAt } | nil }`
(`lastAt` : la dernière ligne envoyée, en `time()`, d'où part l'expiration).
On peut l'effacer : un numéro repart de 1, et une nouvelle carte se crée (aucune ne date de moins de
30 minutes sous ce numéro).

## Renvois

- `docs/specs/appel-a-l-aide.md` : le contrat des lignes SOS (D16 ligne revenue, D17 persistance,
  D22 noms complets).
- `docs/specs/appel-sans-pont-discord.md` : O1 (pourquoi pas de Discord), O3 (`/wpp fusion`).
- Le bot : `F:\WorldPvPPoliceBot\docs\specs\mercenaires.md`.
- Skills : `wow-addon-dev:wow-forever-api` (chat et communautés, valeurs secrètes),
  `wow-addon-dev:chat-output`.
- GuildManagerBot compte ses rôles `TANK` et `HEAL` par leur nom exact : `Tank Mercenaire` ne gonfle
  pas le #roster (lu dans `bot/roster.py` le 2026-11-03).

## Plan (2026-11-03) : provisoire, à supprimer une fois fait

Rien n'entre dans `main` avant que la bascule du lancement (4/11) soit faite et vue.

- **T1, addon + outillage** : `Line` sait produire et relire `LFM` et `END … #LFM`. Critères 1 et 2.
- **T2, addon** : la fenêtre, `/wpp tank|heal|merc`, le widget collé à la recherche de groupe (R6), l'envoi, Trouvé,
  l'expiration, la persistance, les locales. Critères 3 à 6, puis 10.
- **T3, bot** : voir sa spec (carte, salon, rôles, `/setup`, guide FR/EN, témoin dans CraftingOrderBot).
- **Banc** : fiche `mesure--wpp-mercenaires` (MR1 à MR4, critères 7 à 9), Forever, deux comptes.
