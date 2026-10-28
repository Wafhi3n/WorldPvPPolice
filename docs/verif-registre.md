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
