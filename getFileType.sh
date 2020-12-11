#!/bin/bash

IFS=$'\n'

# Renvoie le type d'un fichier
getFileType()
{
    local file=$1
    local fileType=`file -b $file | cut -d ',' -f 1`
    echo $fileType
}

printFileType()
{
    local file=$1
    local type=`getFileType $file`
    echo $file" : "$type
}

printAllFilesType()
{
    local folder=$1
    for file in `find $folder -type f`
    do
        printFileType $file
    done
}

case $# in
    # Aucun parametre pour le script : on utilise ./ comme dossier de recherche
    0) 
        echo "Aucun dossier de recherche ou fichier défini en parametre, recherche à partir du dossier ./"
        echo ""
        folder=./
        printAllFilesType $folder
    ;;
    # Un parametre : dossier ou fichier, sinon on ne fait rien
    1) 
        
        # On vérifie si le dossier existe. Si il n'existe pas, on sort du ptogramme
        if [ -d "$1" ]
        then
            folder=$1
            printAllFilesType $folder
        elif [ -f "$1" ]
        then
            file=$1
            printFileType $file
        else
            echo "$1 n'existe pas, usage : \"script.sh [fichier | dossier]\""
        fi
    ;;
    # Plusieurs paramètres
    *) 
        echo "Les paramètres donnés sont invalides, usage : \"script.sh [fichier | dossier]\""
    ;;
esac

echo ""


IFS=$' '