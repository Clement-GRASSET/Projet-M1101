#!/bin/bash

IFS=$'\n'

# Définition des constantes
TMP=./tmp                           # Chemin du repertoire temporaire
FILE_LIST=$TMP/fileList             # Chemin du fichier qui va contenir la liste des fichiers à traiter
CATEGORIES=$TMP/categories          # Chemin du répertoire contenant les listes des fichiers par categories
ARCHIVE_FOLDER=$TMP/archives        # Chemin du répertoire temporaire où vont être stockée les archives
INIT_FILE=./init.txt                # Chemin du fichier d'initialisation

# Renvoie le type d'un fichier
getFileType()
{
    local file=$1
    local fileType=`file -b $file | cut -d ',' -f 1`
    echo `Uppercase $fileType`
}

# Renvoie la taille d'un fichier
getFileSize()
{
    local file=$1
    local fileSize=`wc -c $file | cut -d ' ' -f 1`
    echo $fileSize
}

getFileExtension()
{
    local fileName=`basename $1`
    echo "${fileName#*.}"
}

# Crée un dossier et les dossiers parents si besoin
createFolder()
{
    local folder=$1
    if [ ! -d $folder ]
    then
        mkdir -p $folder
    fi
}

# liste dans ./temp/fileList.txt tous les fichiers d'un répertoire et ses sous répertoires
makeFileList()
{
    local folder=$1
    `find $folder -type f >> $FILE_LIST`
}

# Extrait une archive dans un dossier
extractFile()
{
    local archive=$1
    local destination=$2
    tar -xf $archive -C $destination 2>/dev/null
}

# extrait une archive vers le dossier temporaire en créant un répertoire unique
extractFileToTmp()
{
    local archive=$1
    local destination=$ARCHIVE_FOLDER/$archive
    createFolder $destination
    extractFile $archive $destination
}

# Renvoie la catégorie d'un fichier en fonction de son type
getCategory()
{
    local file=$1

    if [ $(getFileType $file) = "DATA" ]
    then
        echo "data"
        exit
    fi
    for line in `cat $INIT_FILE`
    do 
        local type=`echo $line | cut -d ':' -f 2`
        local type=`Uppercase $type`
        local category=`echo $line | cut -d ':' -f 3`
        local result=`getFileType $file | grep -c $type`
        if [ $result -ne 0 ]
            then
                echo $category
                exit
        fi
    done

    echo "divers"
}

# Converti des octets en megaoctets
ByteToMegabyte()
{
    local size=$1
    printf "%.2f" "$(($size))e-6"
}

# Remplace les caractères minuscules par leur version en majuscule
Uppercase()
{
    local text=$1
    echo $text | tr [a-z] [A-Z]
}

# Vérifie si l'extension d'un fichier correspond a son type renvoyé par file
isValidExtension()
{
    local file=$1
    local isValid=false     # La condition qui détermine si l'extension est valide

    # On vérifie pour chaque ligne du fichier d'initialisation si le type donné dans la ligne correspond au type du fichier testé
    for line in `cat $INIT_FILE`
    do
        local fileType=`getFileType $file`                      # Le type du fichier testé
        local checkType=`Uppercase $line | cut -d ':' -f 2`     # Le type associé à la ligne du fichier d'initialisation testé
        if [ `echo $fileType | grep -c $checkType` -ge 1 ]
        then
            extension=`echo $line | cut -d ':' -f 1`    # L'extension associée à la ligne du fichier d'initialisation testé

            # On teste si l'extension du fichier correspond à l'extension présente dans la ligne
            if [ `Uppercase $file | grep -c ".$extension"` -eq 1 ]
            then
                isValid=true    # Les types et extensions correspondent, donc le l'extension est valide
            fi
        fi
    done
    echo $isValid
}

# Début du programme

# Vérification de l'existance de ./tmp
if [ -d $TMP ]
then 
    echo "./tmp existe déja, supprimez le répertoire et réessayez"
    echo ""
    exit
fi

# Définition du dossier de recherche
case $# in
    # Aucun parametre pour le script : on utilise ./ comme dossier de recherche
    0) 
        echo "Aucun dossier de recherche défini en parametre,"
        folder=./
    ;;
    # Un parametre : si c'est un dossier, on vérifie si il existe et on l'utilise comme dossier de recherche
    1) 
        folder=$1
        # On vérifie si le dossier existe. Si il n'existe pas, on sort du ptogramme
        if [ ! -d "$folder" ]
        then
            echo "Le dossier $folder n'existe pas"
            exit
        fi
    ;;
    # Plusieurs paramètres
    *) 
        echo "Les paramètres donnés sont invalides, sortie du programme"
        exit
    ;;
esac
echo "Recherche de fichiers à partir de $folder"
echo ""

# Creation des dossiers tmp et archives
createFolder $TMP
createFolder $CATEGORIES
createFolder $ARCHIVE_FOLDER

makeFileList $folder

for file in `cat $FILE_LIST`
do 
    extractFileToTmp $file
done

makeFileList $ARCHIVE_FOLDER

for file in `cat $FILE_LIST`
do 
    fileCategory=`getCategory $file`
    echo $file >> $CATEGORIES/$fileCategory
done

for category in `ls $CATEGORIES`
do
    totalSize=0
    plusGros=""
    plusPetit=""
    mauvaiseExtension=()
    for file in `cat $CATEGORIES/$category`
    do 
        fileSize=`getFileSize $file`

        # Vérifie si le fichier est le plus grand
        if [[ -f $plusGros ]]
        then
            if [ `getFileSize $plusGros` -le $fileSize ]
            then
                plusGros=$file
            fi
        else
            plusGros=$file
        fi

        # Vérifie si le fichier est le plus petit
        if [[ -f $plusPetit ]]
        then
            if [ `getFileSize $plusPetit` -ge $fileSize ]
            then
                plusPetit=$file
            fi
        else
            plusPetit=$file
        fi

        totalSize=`expr $totalSize + $fileSize`

        # On vérifie si le fichier a la bonne extension, saut s'il appartient à la catégorie "data" ou "divers"
        if [ `isValidExtension $file` = false ] && [ $category != "data" ] && [ $category != "divers" ]
        then
            mauvaiseExtension+=($file)
        fi
        
    done

    echo $category" :"
    taillePlusPetit=`getFileSize $plusPetit`
    taillePlusPetit=`ByteToMegabyte $taillePlusPetit`
    taillePlusGros=`getFileSize $plusGros`
    taillePlusGros=`ByteToMegabyte $taillePlusGros`
    echo "Taille totale : "`ByteToMegabyte $totalSize`" Mo"
    echo -e "Plus petit fichier  : \t"`basename $plusPetit`" ("$taillePlusPetit" Mo) \t"$plusPetit
    echo -e "Plus gros fichier   : \t"`basename $plusGros`" ("$taillePlusGros" Mo) \t"$plusGros

    for file in "${mauvaiseExtension[@]}"
    do
        echo `basename $file`" n'a pas la bonne extension    ("$file")"
    done

    echo ""
done

# Suppression du répertoire tmp
rm -r $TMP

IFS=$' '