#!/bin/bash

# Fonction d'affichage de l'aide
afficher_aide() {
    echo "Usage : $0 [chemin_du_fichier] [type_de_station] [type_de_consommateur] [id_centrale] [-h]"
    echo
    echo "Paramètres obligatoires :"
    echo "  chemin_du_fichier         Chemin vers le fichier CSV contenant les données."
    echo "  type_de_station           Type de station à traiter (valeurs possibles : hvb, hva, lv)."
    echo "  type_de_consommateur      Type de consommateur à traiter (valeurs possibles : comp, indiv, all)."
    echo
    echo "Paramètre optionnel :"
    echo "  id_centrale               Identifiant de la centrale spécifique (facultatif)."
    echo
    echo "Option :"
    echo "  -h                        Affiche cette aide et ignore tous les autres paramètres."
    echo
    echo "ATTENTION : Certaines combinaisons sont interdites :"
    echo "  - hvb all"
    echo "  - hvb indiv"
    echo "  - hva all"
    echo "  - hva indiv"
    echo
    echo "Exemple :"
    echo "  $0 /chemin/vers/fichier.csv hvb comp 12345"
    exit 0
}

# Vérifie si l'option d'aide (-h) est présente
for arg in "$@"; do
    if [[ "$arg" == "-h" ]]; then
        afficher_aide
    fi
done

# Vérification du nombre d'arguments minimum (3 requis)
if [[ "$#" -lt 3 ]]
then
    echo "Erreur : Au moins 3 paramètres obligatoires sont nécessaires."
    echo "Utilisez -h pour afficher l'aide."
    exit 1
fi

# Récupération des paramètres
fichier="input/$1"
station="$2"
consommateur="$3"
centrale="${4:-}" # Optionnel : valeur par défaut vide

# Vérification du fichier d'entrée
if [[ ! -f "$fichier" ]]
then
    echo "Erreur : Le fichier '$fichier' est introuvable."
    exit 1
fi

# Vérification des valeurs pour type de station
if [[ "$station" != "hvb" && "$station" != "hva" && "$station" != "lv" ]]
then
    echo "Erreur : Le type de station '$station' est invalide. Valeurs possibles : hvb, hva, lv."
    echo "Durée du traitement : 0 secondes."
    exit 1
fi

# Vérification des valeurs pour type de consommateur
if [[ "$consommateur" != "comp" && "$consommateur" != "indiv" && "$consommateur" != "all" ]]
then
    echo "Erreur : Le type de consommateur '$consommateur' est invalide. Valeurs possibles : comp, indiv, all."
    exit 1
fi

# Vérification des combinaisons interdites
if [[ "$station" == "hvb" && ("$consommateur" == "all" || "$consommateur" == "indiv") ]] || \
   [[ "$station" == "hva" && ("$consommateur" == "all" || "$consommateur" == "indiv") ]]
then
    echo "Erreur : La combinaison '$station' et '$consommateur' est interdite."
    exit 1
fi

# Vérification si l'identifiant de la centrale (centrale) est un nombre
if [[ -n "$centrale" && ! "$centrale" =~ ^[0-9]+$ ]]
then
    echo "Erreur : L'identifiant de la centrale '$centrale' doit être un nombre."
    exit 1
fi

# Traitement principal
echo "Traitement en cours..."
echo
echo "  Fichier d'entrée         : $fichier"
echo "  Type de station          : $station"
echo "  Type de consommateur     : $consommateur"

if [[ -n "$centrale" ]]
then
    echo "  Identifiant de centrale  : $centrale"
    echo
else
    echo "  Pas d'identifiant de centrale spécifié, traitement global."
    echo
fi

# Compilation de c-wire
# Définir les fichiers source et l'exécutable
CWIRE_SOURCES="main.c fonction.c"  # Liste de tous les fichiers sources
CWIRE_BINARY="./c-wire"             # Nom de l'exécutable


executable="c-wire"

# Vérification de la présence de l'exécutable
if [ ! -x "$executable" ]; then
   echo "L'exécutable n'est pas présent. Compilation en cours..."
   
   # Compilation du programme C
   make
   
   # Vérification du déroulement de la compilation
   if [ $? -eq 0 ]; then
       echo "Compilation réussie. L'exécutable $executable a été créé."
       echo
   else
       echo "Erreur lors de la compilation."
       exit 1
   fi
else
    echo "L'exécutable $executable existe déjà."
    echo
fi


if [ ! -d "tmp" ]
then
    echo "Le répertoire tmp n'existe pas. Création du répertoire tmp."
    mkdir -p tmp
else
    echo "Le répertoire tmp existe déjà. Vide le contenu."
    rm -f tmp/*
fi

# Vérifier et créer le répertoire graphs s'il n'existe pas
if [ ! -d "graphs" ]
then
    echo "Le répertoire graphs n'existe pas. Création du répertoire graphs."
    echo
    mkdir -p graphs
else
    echo "Le répertoire graphs existe déjà."
    echo
fi



# Enregistrement du début du traitement
start_time=$(date +%s)


# Lancement du traitement
if [[ "$station" == "hvb" ]]
then
    if [[ "$consommateur" == "comp" ]]
    then
        if [[ -n "$centrale" ]]  # Si une centrale est spécifiée
        then
            # Filtrage par centrale et traitement
            awk -v centrale="$centrale" -F';' '
                $1 == centrale && $2 != "-" && $3 == "-" && $4 == "-" && $6 == "-" {
                    gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                    print $2 ";" $7 ";" $8
                }
            ' "$fichier" > tmp/hvb_comp_BEFORE_C.dat
            echo "Résultat avant le script c : tmp/hvb_comp_BEFORE_C.dat"
        else
            # Si aucune centrale n'est spécifiée, on prend tout le fichier
            awk -F';' '
                $2 != "-" && $3 == "-" && $4 == "-" && $6 == "-" {
                    gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                    print $2 ";" $7 ";" $8
                }
            ' "$fichier" > tmp/hvb_comp_BEFORE_C.dat
            echo "Résultat AVANT le script c  : tmp/hvb_comp_BEFORE_C.dat"
        fi

        # Compilation avec c-wire
        "$CWIRE_BINARY" tmp/hvb_comp_BEFORE_C.dat > tmp/hvb_AFTER_C.csv
        echo "Résultat APRES le script c : tmp/hvb_AFTER_C.csv"

        # Tri de tmp/hvb_AFTER_C.csv par la deuxième colonne (en croissant)
        if [[ -n "$centrale" ]]; then
            sort -t':' -k2,2n tmp/hvb_AFTER_C.csv > tmp/hvb_comp_$centrale.csv
            echo "Résultat final : tmp/hvb_comp_$centrale.csv"
        else
            sort -t':' -k2,2n tmp/hvb_AFTER_C.csv > tmp/hvb_comp.csv
            echo "Résultat final : tmp/hvb_comp.csv"
        fi
    fi


elif [[ "$station" == "hva" ]]
then
    if [[ "$consommateur" == "comp" ]]
    then
        if [[ -n "$centrale" ]]  # Si une centrale est spécifiée
        then
            # Filtrage par centrale et traitement
            awk -v centrale="$centrale" -F';' '
             $1 == centrale && $3 != "-" && $6 == "-" && $4 == "-" {
                    gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                    print  $3 ";" $7 ";" $8
                }
            ' "$fichier" > tmp/hva_comp_BEFORE_C.dat
            echo "Résultat AVANT le script c : tmp/hva_comp_BEFORE_C.dat"
        else
            # Si aucune centrale n'est spécifiée, on prend tout le fichier
            awk -F';' '
                $3 != "-" && $6 == "-" && $4 == "-" {
                    gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                    print  $3 ";" $7 ";" $8
                }
            ' "$fichier" > tmp/hva_comp_BEFORE_C.dat
            echo "Résultat AVANT le script c : tmp/hva_comp_BEFORE_C.dat"
        fi

        # Compilation avec c-wire
        "$CWIRE_BINARY" tmp/hva_comp_BEFORE_C.dat > tmp/hva_AFTER_C.csv
        echo "Résultat APRES le script c : tmp/hva_comp_AFTER_C.csv"

       # Tri de tmp/hva_AFTER_C.csv par la deuxième colonne (en croissant)
        if [[ -n "$centrale" ]]
        then
            sort -t':' -k2,2n tmp/hva_AFTER_C.csv > tmp/hva_comp_$centrale.csv
            echo "Résultat final : tmp/hva_comp_$centrale.csv"
        else
            sort -t':' -k2,2n tmp/hva_AFTER_C.csv > tmp/hva_comp.csv
            echo "Résultat final : tmp/hva_comp.csv"
        fi
    fi


elif [[ "$station" == "lv" ]]
then

    if [[ "$consommateur" == "comp" ]]
    then
        if [[ -n "$centrale" ]]  # Si une centrale est spécifiée
        then
            # Filtrage par centrale et traitement
            awk -v centrale="$centrale" -F';' '
             $1 == centrale && $4 != "-" && $6 == "-" {
                    gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                    print $4 ";" $7 ";" $8
                }
            ' "$fichier" > tmp/lv_comp_AVANT_C.dat
            echo "Résultat AVANT le script c : tmp/lv_comp_AVANT_C.dat"
        else
            # Si aucune centrale n'est spécifiée, on prend tout le fichier
            awk -F';' '
                $4 != "-" && $6 == "-" {
                    gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                    print $4 ";" $7 ";" $8
                }
            ' "$fichier" > tmp/lv_comp_AVANT_C.dat
            echo "Résultat AVANT le script c : tmp/lv_comp_AVANT_C.dat"
        fi

        # Compilation avec c-wire
        "$CWIRE_BINARY" tmp/lv_comp_AVANT_C.dat > tmp/lv_comp_APRES_C.csv
        echo "Résultat APRES le script c : tmp/lv_comp_APRES_C.csv"

          if [[ -n "$centrale" ]]
        then
            sort -t':' -k2,2n tmp/lv_comp_APRES_C.csv > tmp/lv_comp_$centrale.csv
            echo "Résultat final : tmp/lv_comp_$centrale.csv"
        else
            sort -t':' -k2,2n tmp/lv_comp_APRES_C.csv > tmp/lv_comp.csv
            echo "Résultat final : tmp/lv_comp.csv"
        fi
    


    elif [[ "$consommateur" == "indiv" ]]
    then
    if [[ -n "$centrale" ]]  # Si une centrale est spécifiée
        then
        awk -F';' '
        $1 == centrale && $4 != "-" && $5 == "-" {
                gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                print $4 ";" $7 ";" $8
            }
        ' "$fichier" > tmp/lv_indiv_AVANT_C.dat
        echo "Résultat AVANT le script c : tmp/lv_indiv_AVANT_C.dat"
        else
        awk -F';' '
            $4 != "-" && $5 == "-" {
                gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                print $4 ";" $7 ";" $8
            }
        ' "$fichier" > tmp/lv_indiv_AVANT_C.dat
        echo "Résultat AVANT le script c : tmp/lv_indiv_AVANT_C.dat"  
      fi
        
        
        "$CWIRE_BINARY" tmp/lv_indiv_AVANT_C.dat > tmp/lv_indiv_APRES_C.csv
        echo "Résultat APRES le script c : tmp/lv_indiv_APRES_C.csv"
        
        

      if [[ -n "$centrale" ]]
        then
            sort -t':' -k2,2n tmp/lv_indiv_APRES_C.csv > tmp/lv_indiv_$centrale.csv
            echo "Résultat final : tmp/lv_indiv_$centrale.csv"
        else
            sort -t':' -k2,2n tmp/lv_indiv_APRES_C.csv > tmp/lv_indiv.csv
            echo "Résultat final : tmp/lv_indiv.csv"
        fi


    elif [[ "$consommateur" == "all" ]]
    then
   	 if [[ -n "$centrale" ]] 
        then    	 
        awk -F';' '
          $1 == centrale && $4 != "-" && $2 == "-" {
                gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                print $4 ";" $7 ";" $8
            }
        ' "$fichier" > tmp/lv_all_AVANT_C.dat
        echo "Résultat AVANT le script c : tmp/lv_all_AVANT_C.dat"
        else  
        awk -F';' '
            $4 != "-" && $2 == "-" {
                gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                print $4 ";" $7 ";" $8
            }
        ' "$fichier" > tmp/lv_all_AVANT_C.dat
        echo "Résultat AVANT le script c : tmp/lv_all_AVANT_C.dat"
        fi
        
        
        "$CWIRE_BINARY" tmp/lv_all_AVANT_C.dat > tmp/lv_all_APRES_C.csv
        echo "Résultat APRES le script c  : tmp/lv_all_APRES_C.csv"
        
       
        
         # Tri de tmp/lv_all_result.csv par la troisieme colonne (en croissant) en utilisant ':' comme séparateur
        if [[ -n "$centrale" ]]
        then
        	 sort -t':' -k3,3n tmp/lv_all_APRES_C.csv > tmp/lv_all_$centrale.csv
       		 echo "Résultat final : tmp/lv_all_$centrale.csv"
        else
       	 	 sort -t':' -k3,3n tmp/lv_all_APRES_C.csv > tmp/lv_all.csv
       		 echo "Résultat final : tmp/lv_all.csv"
        fi

       
       


	if [[ -n "$centrale" ]]
        then
		# Sélection des 10 postes avec la plus grande consommation (les 10 derniers en triant par ordre croissant)
		tail -n 10 tmp/lv_all_$centrale.csv | sort -t':' -k3,3nr > tmp/lv_all_max_$centrale.csv
		echo "Top 10 postes avec la plus grande consommation : tmp/lv_all_max_$centrale.csv"

		# Sélection des 10 postes avec la plus faible consommation (les 10 premiers)
		head -n 10 tmp/lv_all_$centrale.csv > tmp/lv_all_min_$centrale.csv
		echo "Top 10 postes avec la plus faible consommation : tmp/lv_all_min_$centrale.csv"

		# Fusionner les résultats dans un fichier final lv_all_minmax.csv
		cat tmp/lv_all_min_$centrale.csv tmp/lv_all_max_$centrale.csv > tmp/lv_all_minmax_$centrale.csv
		echo "Résultats min et max fusionnés dans : tmp/lv_all_minmax_$centrale.csv"
		   
        else
        
		# Sélection des 10 postes avec la plus grande consommation (les 10 derniers en triant par ordre croissant)
		tail -n 10 tmp/lv_all.csv | sort -t':' -k3,3nr > tmp/lv_all_max.csv
		echo "Top 10 postes avec la plus grande consommation : tmp/lv_all_max.csv"

		# Sélection des 10 postes avec la plus faible consommation (les 10 premiers)
		head -n 10 tmp/lv_all.csv > tmp/lv_all_min.csv
		echo "Top 10 postes avec la plus faible consommation : tmp/lv_all_min.csv"

		# Fusionner les résultats dans un fichier final lv_all_minmax.csv
		cat tmp/lv_all_min.csv tmp/lv_all_max.csv > tmp/lv_all_minmax.csv
		echo "Résultats min et max fusionnés dans : tmp/lv_all_minmax.csv"
        
        fi
fi

else
    echo "Erreur : Type de station invalide."
    echo "Utilisez -h pour afficher l'aide."
fi



# Enregistrement de la fin du traitement
end_time=$(date +%s)
execution_time=$((end_time - start_time))

# Affichage de la durée
echo
echo "Durée du traitement : ${execution_time} secondes."

exit 0

