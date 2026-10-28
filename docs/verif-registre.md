# Registre de verification en jeu - WorldPvPPolice

Meme role que celui de Crafting Order - Classic : dire jusqu'ou l'addon a ete **vu fonctionner**
dans le client, puisque aucune porte automatique ne sait le dire. `scripts/untested.ps1 -Addon
WorldPvPPolice` fait l'union de tous les releves ci-dessous et liste ce qu'aucun n'avait dans le client.

Format d'un releve (le plus recent EN TETE) :

```
- AAAA-MM-JJ HH:MM - jusqu'a <sha> - <build> - <verdict> - <ce qui a ete observe>
```

Le `<sha>` est le dernier commit reellement present dans le client pendant la seance. On n'ecrit
un releve qu'APRES avoir observe, et on dit ce qui n'a PAS ete observe. Plusieurs sessions peuvent
ecrire ici en parallele : l'heure plutot qu'un numero du jour, et le fichier fusionne en
`merge=union` (`.gitattributes`) sans conflit.

**Un rebase perime le sha d'un releve** : apres le rebase d'une branche deja couverte, avancer son
sha (`git log --oneline` sur la nouvelle branche donne l'equivalent, le message est identique).

## Releves

- 2026-10-28 14:56 - jusqu'a a014ac6 - **PTR Retail 12.1.7.70493, PAS Forever**, deux comptes, build
  charge par `/reload` (clients lances a 13:57 et 14:09, deploiement de 14:50 : le nouveau fichier
  `_MapPins.lua` du .toc s'est charge au /reload, vu a l'ecran) - **GO PTR sur D20** - fiche
  `mesure--wpp-voir-carte`, cinq gestes coches OK par le user de 14:55 a 14:56, plus une capture.
  Vu OK : l'alerte a « Voir sur la carte » et « J'arrive » (infobulle de « J'arrive ») ; le clic
  ouvre la carte du monde sur Strangleronce septentrionale avec la tete de mort la ou est le cadavre
  (capture : au sud-est de Grom'gol, comme la carte Discord), sans rien envoyer ; la carte ouverte a
  la main la montre aussi, a sa taille au zoom ; « J'arrive » ensuite marche comme avant ; carte
  ouverte et fermee, combat : aucune erreur, aucune action bloquee (dit par le user).
  Taint : pas de `taint.log` (niveau 1 = n'ecrit qu'au blocage ; activation non prouvee) : FAIBLE.
  PAS observe : un appel en zone seule (carte sans repere) ; « Ton appel » cache en instance ; tout
  sur Forever.

- 2026-10-28 14:12 - jusqu'a 1ed7036 - **PTR Retail 12.1.7.70493, PAS Forever**, deux comptes (clients
  relances a 13:57 et 14:09, apres le deploiement de 13:50), bot CraftingOrderBot `main@263e680`
  (image de la zone + rattrapage) - **GO PTR sur D19 et sur l'image** - fiche `mesure--wpp-d19-carte`,
  six gestes coches OK par le user de 14:09 a 14:11, plus deux captures de la carte Discord.
  Vu OK : B connecte recoit l'appel par la guilde (temoin) ; B deconnecte puis revenu pendant l'appel
  le recoit a lui seul, avec le message (connexion : le WHISPER part bien au nom que donne la liste de
  guilde, et B accepte l'emetteur comme guildien) ; une seule fois (pas-deux-fois) ; la carte Discord
  montre Strangleronce septentrionale avec le point la ou est le cadavre (image ; « le point est au
  bon endroit », dit le user) et le garde a la mise a jour (image-maj).
  PAS releve : la sortie de la sonde `noms` (geste coche sans recopie : la forme du nom de la liste
  de guilde reste inconnue) ; le delai exact avant l'alerte ; tout sur Forever.

- 2026-10-28 13:35 - jusqu'a c066033 - **PTR Retail 12.1.7.70493, PAS Forever**, deux comptes, avec le
  bot CraftingOrderBot `main@e726d52` sur Coolify (salon relie #g du Discord de test « Ost Ardent - Le
  foyer », cartes dans #alertes-pvp, role pvp-police) - **GO PTR sur la chaine addon + bot** - fiche
  `mesure--wpp-bot-ptr`, gestes coches par le user de 13:29 a 13:34, plus une capture de la carte.
  Vu OK : « SOS test discussion » tape en jeu reste dans #g, sans carte ; un appel (mort par
  Camparind, « test bot », Liberer) donne une carte « Palrien appelle a l'aide ! », zone et
  coordonnees (39.7, 55.4), Morts 1, « Camparind (Chevalier de la mort) », pied « #SOS8 · Palrien »,
  et la ligne brute quitte #g ; la mention @pvp-police notifie ; « Ton appel » atteint
  « Discord : envoye » MEME avec l'effacement de la ligne par le bot (M2 : le retour arrive avant) ;
  « J'arrive » de B, un nouveau message et « C'est regle » mettent a jour la MEME carte.
  Vu en passant : l'horloge du serveur Coolify retarde de 114 s (lue a 13:36, PC a 3 s de
  l'heure de reference) : la carte dit 13:28 pour une ligne de 13:30.
  Remarque du user (au geste jarrive) : un guildien qui se connecte pendant un appel ne recoit pas
  l'alerte (attendu : le message de guilde ne touche que les presents ; a decider).
  PAS observe : la carte qui passe au gris apres 30 minutes (geste gris pas fait) ; tout sur Forever.

- 2026-10-28 12:52 - jusqu'a e6fb0c8 - **PTR Retail 12.1.7.70493, PAS Forever**, deux comptes
  (A = Palrien #4, B = #6), `feat/wpp-lignes@e6fb0c8` deploye a 12:48 - **GO PTR sur D18** - fiche
  `mesure--wpp-ptr-appel`, gestes fantome-msg (12:51) et encart-msg (12:52) coches OK, plus les
  SavedVariables relues sur le disque.
  Vu OK : en fantome, la case de « Ton appel » montre le message de l'appel ; un nouveau message
  et « Mettre a jour » : B le recoit, meme numero ; la ligne Discord revient en jeu avec le nouveau
  message (A : `discordSig` = `SOS Palrien Strangleronce septentrionale (39.8, 55.5) #SOS7 m50 d1
  kCamparind cDEATHKNIGHT : ON ME CAMPE ATLANCE SAUVE MOA`). Remort pendant l'appel : une seule
  case a l'ecran (« Ton appel » retrecie), la case de l'encart montre le message de l'appel, la
  frappe reste ; B a ensuite l'appel n°7 a 2 morts avec le meme message (pas efface).
  Avant (build dabe06b, capture du user) : les deux cases a l'ecran en meme temps, d'ou e6fb0c8 ;
  mise en page lisible, et la fenetre de mort affiche « Liberation dans 6 minutes ».
  PAS observe : l'etat « Discord : dans N s » puis « pas a jour » (non rapporte) ; la 2e mort
  n'etait pas encore sur Discord a 12:52 (d1, rythme de 2 minutes ou pas de geste depuis).

- 2026-10-28 12:29 - jusqu'a 27a2cc3 - **PTR Retail 12.1.7.70493, PAS Forever**, deux comptes,
  `feat/wpp-appel-persistant@27a2cc3` - **GO PTR sur la liberation automatique** - geste auto coche
  OK par le user (remarque « fait ») : mort par un joueur, message ecrit, pas de clic, le jeu libere
  seul au bout du minuteur ; attendu de la fiche : B voit l'alerte, RIEN sur Discord. Rapporte par
  le user, pas relu sur le disque (SavedVariables reecrites depuis). Tranche la mesure contestee
  par la revue : la liberation automatique arrive bien.

- 2026-10-28 12:13 - jusqu'a 27a2cc3 - **PTR Retail 12.1.7.70493, PAS Forever**, deux comptes
  (A = Palrien, compte #4 ; B = compte #6), `feat/wpp-appel-persistant@27a2cc3` deploye a 10:28 -
  **GO PTR, sauf la liberation auto (pas faite)** - fiche `mesure--wpp-ptr-appel`, gestes coches
  par le user de 11:57 a 12:08, plus les SavedVariables relues sur le disque.
  Vu OK : contre un monstre, pas d'encart (monstre-2, remarque « avec Cvampard ») ; deux morts
  face a Camparind pendant un appel, « Ton appel » passe a 2 des la 2e mort, avant de liberer
  (repetee-2, corrige le KO de 5808935) ; `/reload` avec un appel en cours, l'appel revient (reload) ;
  `/reload` mort sans liberer, pas de mort en plus (reload-mort) ; chez B, alerte avec zone,
  coordonnees, morts, tueurs et message, « J'arrive », point de route, ligne OMW, alerte toujours la
  apres un `/reload` de B (alerte, jarrive, alerte-reload) ; le « J'arrive » de B apparait dans
  « Ton appel » de A (en-route, M9 sur le PTR) ; « C'est regle » ferme chez A et chez B (regle-b) ;
  fenetre deplacee, revenue a sa place apres `/reload` (pile).
  Deco-reco (coche KO par le user, mais pour poser une question) : deconnecte MORT, le jeu le
  ramene en FANTOME (il libere l'esprit a la deconnexion : l'addon n'y peut rien, l'encart ne
  revient donc pas) ; « Ton appel » reste affiche (dit par le user). SavedVariables : a la
  deconnexion (12:03) appel n°5 a 2 morts ; apres le retour, B a recu le meme n°5 a 3 morts,
  message « HELP » : le numero d'appel et le numero de mort ont survecu.
  Lu dans la SavedVariable de A : `discordSig` pose, donc le retour `CHAT_MSG_GUILD_DISCORD` est
  arrive (D16). Emetteur des messages de guilde en « Nom-Royaume » (`Palrien-Anasterian`).
  Taint : aucun `taint.log` apres `/console taintLog 1`, un appel complet et un `/reload` (12:13) ;
  le niveau 1 n'ecrit qu'au blocage, mais rien ne prouve que le journal etait allume : FAIBLE.
  PAS observe : la liberation automatique au bout du minuteur (geste auto) ; le delai du retour
  Discord en secondes ; la pierre d'ame ; une alerte qui expire (15 min) ; tout sur Forever.

- 2026-10-28 09:48 - jusqu'a 5808935 - **PTR Retail 12.1.7.70493, PAS Forever**, compte A (Palrien),
  `feat/wpp-lignes@5808935` deploye a 08:37 - **NO-GO sur les morts repetees** - fiche
  `mesure--wpp-ptr-appel`, gestes coches de 09:30 a 09:48.
  Vu OK : `/wpp` et `/wpp version` (charge) ; sonde des noms (noms, sa sortie n'a pas ete recopiee) ;
  encart sous la fenetre de mort apres une mort par Camparind (encart) ; « Libérer l'esprit » avec
  un message envoie l'appel, ligne vue sur Discord : `SOS Palrien Strangleronce septentrionale
  (39.9, 55.7) #SOS1 m50 d1 kCamparind cDEATHKNIGHT : test libérer` (liberer) ; « C'est regle »
  (regle) ; envoi depuis le bouton « Appeler » (bouton) et depuis Entree (entree).
  KO : deux morts face a Camparind pendant un appel, « Ton appel » reste a « Morts : 1 » (repetee ;
  `Call:NoteDeath` ne redessinait pas la fenetre, corrige en 39c8b7c, vu OK ci-dessus) ; contre un
  monstre (monstre), sans remarque : cause inconnue, pas reproduit sur 27a2cc3.
