# Projet-M1101

BARTHET-ECOFFARD Léo
DOS SANTOS Enzo
GRASSET Clément

## Sujet

On veut lister les fichiers d'un utilisateur, selon leurs types et leurs tailles. L'application en script Bash (uniquement, pas de développement dans un autre langage, pas d'appel à des applications) parcourt les répertoires et les sous-répertoires à partir d'un chemin de base, liste les fichiers présents en récupérant leur taille (via la commande ls par exemple) et détermine de quel type ils sont (via la commande file).

Les types de fichier possibles (cf les fichiers test fournis) sont :

 - texte simple
 - document (EXCEL ODT HTML PDF)
 - archive (tar.gz)
 - image (GIF JPG SVG PNG)
 - son (MP3)
 - vidéos (MP4 GIF animé)

L'application doit être basée sur un fichier d'initialisation qui permet de spécifier les types à lister, avec un format à définir, comme par exemple :

SVG:Scalable Vector Graphics:image  
MPEG:audio Monaural:son  

La sortie de l'application est la liste, pour chaque type, de la taille totale en megaoctets des fichiers de ce type, du nom, de la taille et du chemin du fichier de taille la plus grande de ce type, et de taille la plus petite. Si des fichiers ont une extension qui ne correspond pas à leur type, il faut les lister (soupçon de fraude).

Les fichiers archive doivent être détectés et parcourus comme des répertoires, i.e. on liste également leurs tailles dans les autres types. Si on y trouve un fichier audio mp3, sa taille est ajoutée à la taille des fichiers mp3 globale par exemple.

Attention, ne vous fiez pas aux noms ou aux extensions des fichiers. Certains fichiers ne seront pas reconnus (data), il faudra des catégories "divers", pour ces "data" supplémentaires.

Vous pouvez apporter des ajouts aux points précédents (sortie en HTML, test date et heure...) mais ils ne seront notés en bonus que si les points obligatoires sont remplis.

## Fonctionnement

Utilisation : 

- script.sh
    Lance la recherche  dans le répertoire courant

- script.sh [répertoire]
    Lance la recherche dans le répertoire fourni en paramètre

Les appels du script qui fournissent autre chose qu'un répertoire en paramètre ou plus d'un paramètre causeront la fin de l'execution du script (géré dans les lignes 147 à 171)

### Détection des fichiers

Le script commence par lister les fichiers dans le répertoire de recherche avec la commande "find". Les chemins des fichiers sont stockés dans ./tmp/fileList

### Détection des fichiers présents dans les archives

Ensuite, on tente d'extraire tous les fichiers avec la commante "tar" en ignorant les messages d'erreur dans le cas des fichiers qui ne sont pas des archives.
L'arborescence du répertoire de recherche est reproduite dans ./tmp/archives mais les fichiers sont tranformés en dossiers
Les fichiers extraits sont placés dans le dossier correspondant à l'archive extraite.
Pour résumer : une archive ./rep/archive.tar.gz qui contient texte.txt donnera ./tmp/archives/rep/archive.tar.gz/texte.txt
Pour lister les fichier extraits, on refait une dectection des fichiers présents dans ./tmp/archive et on ajoute les chemins à la liste déja existante (./tmp/fileList)

### Classement des fichiers par catégories

Pour chaque fichiers de ./tmp/fileList, on parcours le fichier d'initialisation en prenant en compte pour chaque ligne le type et la catégorie.
Exemple : 
type = "ASCII Text"
categorie = "texte"

- Si le type du fichier testé est "data", on ajoute son chemin dans le fichier ./tmp/categories/data
- Sinon on vérifie si un grep du type de la ligne testée du fichier d'initialisation sur le type du fichier testé (obtenu avec la commande "file") donne un résultat. 
Si il y a un réultat, alors le type du fichier correspond au type testé dans le fichier d'initialisation, on ajoute donc le chemin du fichier testé dans ./tmp/categories/[categorie].
- Si le fichier d'initalisation a été parcouru pour un fichier testé sans que le type ne corresponde, alors on ajoute le chemin du fichier à ./tmp/categories/divers

Pour éviter des erreurs liées à la casse, on converti les extensions en majuscule avant de les tester. L'utilisateur peut aussi renseigner un type incomplet mais suffisament unique pour être détecté (Exemple : "HTML" à la place de "HTML Document" fonctionne)

**Attention : le script ne teste que les informations renvoyées par "file" qui sont avant la première virgule. Par exemple, pour un fichier HTML, la commande "file" renvoie "HTML Document, ASCII Text" mais le type retenu sera "HTML Document" pour éviter de déctecter les mauvais types comme les fichiers textes qui sont de type "ASCII Text".**

### Sortie du script

Pour chaque catégories dans ./tmp/catégories, on ititialise les variables plusPetit, plusGrand, totalSize=0 et le tableau mauvaiseExtension=()
On parcours la liste des fichier contenus dans une catégorie. Pour chaque fichier, on ajoute sa taille à totalSize.
En même temps, on affecte le chemin du fichier à plusPetit si sa taille est plus petite que la taille de plusPetit ou on affecte le chemin du fichier à plusGrand si sa taille est plus grande que la taille de plusGrand, sauf si aucun chemin n'est présent dans plusPetit et plusGrand, dans ce cas les variables sont affectés de force.
Pour chaque fichier, on teste aussi si leur extension correspond au type listé dans le fichier d'initialisation avec les commandes "grep". Pour éviter des erreurs liées à la casse, on converti les extensions en majuscule avant de les tester. Si l'extension ne correspond pas, on ajoute le chemin du fichier au tableau mauvaiseExtension.
Après avoir parcouru la liste des fichiers dans une catégorie, on affiche la taille total (totalSize), le plus petit et plus grand fichier (plusPetit, plusGrand) et leur taille, et les fichiers qui n'ont pas la bonne extension.
Ensuite on passe à la catégorie suivante