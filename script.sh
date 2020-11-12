#!/bin/bash

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
    local fileType=`file $file | cut -d ':' -f 2`
    echo $fileType
}

# Renvoie la taille d'un fichier
getFileSize()
{
    local file=$1
    local fileSize=`wc -c $file | cut -d ' ' -f 1`
    echo $fileSize
}

# Renvoie le nom d'un fichier sans le chemin de son dossier
#getFileName()
# {
#    local path=$1
#    local fileName=basename $path
#    echo $fileName
# }

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

# Renvoie la gatégorie d'un fichier en fonction de son type
getCategory()
{
    local file=$1
    IFS=$'\n'
    if [ $(getFileType $file) = " data" ]
        then
            echo "data"
            exit
    fi
    for line in `cat $INIT_FILE`
        do 
            local type=`echo $line | cut -d ':' -f 2`
            local category=`echo $line | cut -d ':' -f 3`
            local result=`getFileType $file | grep -c $type`
            if [ $result -ne 0 ]
                then
                    echo $category
                    exit
            fi
    done
    IFS=$' '
    echo "divers"
}


# Début du programme

# Suppression de la liste des fichiers si elle existe déja
if [ -f $FILE_LIST ]
    then 
        rm $FILE_LIST
fi

# Suppression du répertoire categories si il existe déja
if [ -d $CATEGORIES ]
    then 
        rm -r $CATEGORIES
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

# Suppression du dossier tmp
#rm -r $TMP
