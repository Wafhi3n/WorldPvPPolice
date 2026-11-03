# Appeler un mercenaire (tank, soigneur) sur Discord

> État : **brouillon** · Idée du user le 2026-11-03 (« en jeu, quand on recherche un groupe, on peut appeler
> un tank sur le Discord ») ; R1 à R4 tranchées par le user le même jour ; R5 à R11 proposées par l'agent,
> **à confirmer**. Rien de codé, rien de mesuré. Le bot qui lit la ligne a sa propre spec :
> `F:\WorldPvPPoliceBot\docs\specs\mercenaires.md` (même branche `docs/spec-mercenaires`).

## Le problème

Un groupe qui monte un donjon attend souvent un tank ou un soigneur. Le canal Recherche de groupe et
le chat de guilde ne touchent que les joueurs connectés. Or les guildiens qui viendraient tanker ou
soigner s'ils savaient qu'on cherche quelqu'un sont souvent ailleurs : sur Discord, sur leur
téléphone, dans un autre jeu. Sur le Discord de la guilde, ceux qui acceptent d'être appelés prennent
un rôle de **mercenaire** dans « Salons et rôles », comme `pvp-police` pour les appels PvP. Aujourd'hui,
rien ne relie le jeu à ces rôles : il faut sortir du jeu et taper `@tank-mercenaire` à la main.

## Ce qu'on veut

1. **Une petite fenêtre « Appeler un mercenaire »**, à nous : deux cases **Tank** et **Soigneur**
   (au moins une cochée), une case de message (« Profondeurs de Rochenoire, on est 4 à l'entrée ») et
   un bouton **Appeler**. Elle s'ouvre par `/wpp tank` ou `/wpp heal` (la case est déjà cochée), par
   `/wpp merc`, et par l'entrée de l'addon dans le menu des addons de la minicarte (R6).
2. **L'appel part au clic**, ou à Entrée dans la case : une ligne dans le fil Discord de la guilde,
   par le même chemin que le SOS (option `/wpp fusion` comprise). Elle porte le nom complet de
   l'appelant, les rôles cherchés, la zone où il se trouve (le donjon s'il y est déjà) et le message.
3. **Sur Discord**, le bot en fait une carte dans un salon dédié et mentionne `@tank-mercenaire`,
   `@heal-mercenaire`, ou les deux. La carte dit qui chuchoter en jeu.
4. **Le mercenaire répond en chuchotant l'appelant** (R4). L'addon n'invite personne et n'alerte
   personne en jeu.
5. **Tant que l'appel est ouvert**, la fenêtre l'affiche (« Ton appel : tank, sur Discord depuis
   21:04 ») avec un bouton **Trouvé** qui le ferme : la carte passe en gris. Sans « Trouvé », l'appel
   expire au bout de 30 minutes (R10).
6. **Changer le message** d'un appel ouvert met la carte à jour sans relancer la mention (R7).

## Ce qu'on NE fait PAS

- **Rien dans la recherche de groupe de Blizzard** (R3) : pas de bouton greffé, pas de lecture de
  l'annonce (activité, places libres). Le taint LFG imputé à COC n'est toujours pas résolu, et lire
  l'annonce par `C_LFGList` sur Forever n'a jamais été mesuré. Au mieux une v2, après mesure.
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
- **Expiration** : l'addon montre l'appel fermé ; aucune ligne `END` ne part, faute de geste du joueur.
  C'est le bot qui grise la carte au bout de 30 minutes.
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
- **R2** (user) : deux rôles, **`tank-mercenaire`** et **`heal-mercenaire`**. Pas de DPS. Les rôles se
  prennent dans « Salons et rôles » du Discord, comme `pvp-police`.
- **R3** (user) : **notre fenêtre + `/wpp tank|heal`**. Rien n'est greffé dans la recherche de groupe
  de Blizzard.
- **R4** (user) : **le mercenaire chuchote l'appelant** ; pas d'alerte en jeu.
- **R5** (agent, à confirmer) : une ligne **`LFM`** qui porte le **nom complet** (`Prénom_Nom`, comme
  les tueurs de D22) et la zone de l'appelant. Le mercenaire doit pouvoir chuchoter, et le prénom
  seul, celui des lignes SOS, ne suffit pas sur Forever. « LFM » se comprend aussi sans le bot.
- **R6** (agent, à confirmer) : on ouvre la fenêtre par `/wpp tank|heal|merc` et par une entrée dans
  le menu des addons de la minicarte (`## AddonCompartmentFunc`, déjà vu en jeu avec LeyLines). Pas de
  bouton de minicarte en plus.
- **R7** (agent, à confirmer) : une seule mention par appel ; une mise à jour ne relance pas la mention.
- **R8** (agent, à confirmer) : un seul appel ouvert par personnage ; changer de rôles = fermer et
  rouvrir.
- **R9** (agent, à confirmer) : permis en instance et en groupe, grisé en combat.
- **R10** (agent, à confirmer) : un appel vit 30 minutes, comme un SOS (D11).
- **R11** (agent, à confirmer) : sans pont, aucun repli vers un autre canal.

## Mesures à faire (Forever, à partir du 2026-11-04)

- **MR1, chuchoter un « Prénom Nom »** : quelle commande marche (`/w Prénom Nom`, des guillemets, le
  prénom seul ?). C'est ce qui décide la ligne « Pour répondre » de la carte. Témoin : clic droit sur
  un guildien dans la liste de guilde, « Chuchoter », puis lire ce que le jeu écrit dans la case de
  saisie.
- **MR2, le fil Discord depuis un donjon**, hors combat : la ligne revient-elle en jeu (D16) ?
- **MR3, en combat ordinaire** (hors boss) : l'envoi au fil Discord passe-t-il ? Si oui, R9 peut
  s'assouplir.

## Critères d'acceptation

1. [test] Une ligne `LFM` ou `END … #LFM` produite puis relue rend les mêmes champs, et les exemples
   du contrat sortent identiques à l'octet. → `tests/test_wpp_lfm.lua` (outillage)
2. [test] Une ligne `LFM` n'est jamais lue comme un SOS, un OMW ou un END d'appel PvP, et l'inverse
   non plus. → même fichier
3. [test] Sans fil Discord et sans fusion, Appeler n'envoie rien. Avec la fusion, la ligne part dans
   le chat de guilde. → même fichier, sur le vrai module devant un jeu factice
4. [test] Changer le message d'un appel ouvert garde le numéro ; changer les rôles envoie `END` puis
   un nouveau numéro ; un `/reload` rend l'appel ouvert. → même fichier
5. [test] Aucune ligne dans le chat hors d'une réponse à `/wpp`, comptée comme le demande le skill
   `chat-output`.
6. [check] Les quatre portes, dont la locale : tout le texte de la fenêtre est en FR, avec ses
   overlays en/de/es.
7. [human] Forever, compte A dans une guilde reliée : `/wpp tank`, un message, Appeler. L'état passe
   à « sur Discord », la carte arrive dans le salon des mercenaires avec `@tank-mercenaire`, et le
   téléphone d'un porteur du rôle sonne. Témoin : une carte SOS le même jour (même pont, même bot).
   Observateur : le user.
8. [human] Le compte B chuchote ce que la carte indique, et A reçoit le chuchotement (MR1).
   Observateur : le user, sur les deux comptes.
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
- Un `LFM` dont le `#LFM<n>` a déjà été vu il y a moins de 30 minutes, avec les mêmes rôles, met cet
  appel à jour.

Exemples :

```
LFM Gnomi_Ombrelune TANK Montagne de Rochenoire #LFM3 : Profondeurs de Rochenoire, on est 4 à l'entrée
LFM Gnomi_Ombrelune TANK,HEAL Les Mortemines #LFM4
END Gnomi_Ombrelune #LFM4
```

### Données sauvegardées

`WorldPvPPoliceDB.merc = { n = <dernier numéro>, open = { n, roles, msg, sentAt, seenAt } | nil }`.
On peut l'effacer : un numéro repart de 1, et une nouvelle carte se crée (aucune ne date de moins de
30 minutes sous ce numéro).

## Renvois

- `docs/specs/appel-a-l-aide.md` : le contrat des lignes SOS (D16 ligne revenue, D17 persistance,
  D22 noms complets).
- `docs/specs/appel-sans-pont-discord.md` : O1 (pourquoi pas de Discord), O3 (`/wpp fusion`).
- Le bot : `F:\WorldPvPPoliceBot\docs\specs\mercenaires.md`.
- Skills : `wow-addon-dev:wow-forever-api` (chat et communautés, valeurs secrètes),
  `wow-addon-dev:chat-output`.
- GuildManagerBot compte ses rôles `TANK` et `HEAL` par leur nom exact : `tank-mercenaire` ne gonfle
  pas le #roster (lu dans `bot/roster.py` le 2026-11-03).

## Plan (2026-11-03) : provisoire, à supprimer une fois fait

Rien n'entre dans `main` avant que la bascule du lancement (4/11) soit faite et vue.

- **T1, addon + outillage** : `Line` sait produire et relire `LFM` et `END … #LFM`. Critères 1 et 2.
- **T2, addon** : la fenêtre, `/wpp tank|heal|merc`, l'entrée du compartiment, l'envoi, Trouvé,
  l'expiration, la persistance, les locales. Critères 3 à 6, puis 10.
- **T3, bot** : voir sa spec (carte, salon, rôles, `/setup`, guide FR/EN, témoin dans CraftingOrderBot).
- **Banc** : fiche `mesure--wpp-mercenaires` (MR1 à MR3, critères 7 à 9), Forever, deux comptes.
