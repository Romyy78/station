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


if [ ! -d "input" ]
then
    echo "Le dossier 'input' n'existe pas. Création du dossier..."
    mkdir "input"
else
    echo "Le dossier 'input' existe déjà."
    echo
fi

if [ ! -d "output" ]
then
    echo "Le dossier 'output' n'existe pas. Création du dossier..."
    mkdir "output"
else
    echo "Le dossier 'output' existe déjà."
    echo
fi

if [ ! -d "tests" ]
then
    echo "Le dossier 'tests' n'existe pas. Création du dossier..."
    mkdir "tests"
else
    echo "Le dossier 'tests' existe déjà."
    echo
fi

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
    echo "Durée du traitement : 0 secondes."
    echo
    afficher_aide
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
    echo
    afficher_aide
    exit 1
fi

# Vérification des valeurs pour type de station
if [[ "$station" != "hvb" && "$station" != "hva" && "$station" != "lv" ]]
then
    echo "Erreur : Le type de station '$station' est invalide. Valeurs possibles : hvb, hva, lv."
    echo "Durée du traitement : 0 secondes."
    echo
    afficher_aide
    exit 1
fi

# Vérification des valeurs pour type de consommateur
if [[ "$consommateur" != "comp" && "$consommateur" != "indiv" && "$consommateur" != "all" ]]
then
    echo "Erreur : Le type de consommateur '$consommateur' est invalide. Valeurs possibles : comp, indiv, all."
    echo "Durée du traitement : 0 secondes."
    afficher_aide
    exit 1
fi

# Vérification des combinaisons interdites
if [[ "$station" == "hvb" && ("$consommateur" == "all" || "$consommateur" == "indiv") ]] || \
   [[ "$station" == "hva" && ("$consommateur" == "all" || "$consommateur" == "indiv") ]]
then
    echo "Erreur : La combinaison '$station' et '$consommateur' est interdite."
    echo "Durée du traitement : 0 secondes."    
    afficher_aide
    exit 1
fi

# Vérification si l'identifiant de la centrale (centrale) est un nombre
if [[ -n "$centrale" && ! "$centrale" =~ ^[0-9]+$ ]]
then
    echo "Erreur : L'identifiant de la centrale '$centrale' doit être un nombre."
    echo "Durée du traitement : 0 secondes."
    echo
    afficher_aide
    exit 1
fi

# Traitement principal
echo
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


for dir in "tmp" "graphs" "output"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "Le dossier '$dir' n'existe pas. creation de '$dir'... "
        echo
    else
        # Vider le répertoire s'il n'est pas vide
        if [ "$(ls -A $dir)" ]; then
            mv "$dir"/* tests/
        fi
        rm -f "$dir"/*
    fi
done

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
            sort -t':' -k2,2n tmp/hvb_AFTER_C.csv > output/hvb_comp_$centrale.csv
            echo "Résultat final : output/hvb_comp_$centrale.csv"
            echo "HVB:Capacité:Consommation (entreprises)"\
            | cat - output/hvb_comp_$centrale.csv > temp && mv temp output/hvb_comp_$centrale.csv
        else
            sort -t':' -k2,2n tmp/hvb_AFTER_C.csv > output/hvb_comp.csv
            echo "HVB:Capacité:Consommation (entreprises)" cat - output/hvb_comp.csv > temp && mv temp output/hvb_comp.csv
            echo "Résultat final : output/hvb_comp.csv"
        fi
    fi


elif [[ "$station" == "hva" ]]
then
    if [[ "$consommateur" == "comp" ]]
    then
        if [[ -n "$centrale" ]]  
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
            sort -t':' -k2,2n tmp/hva_AFTER_C.csv > output/hva_comp_$centrale.csv
            echo "Résultat final : output/hva_comp_$centrale.csv"
            echo "HVA:Capacité:Consommation (entreprises)"\
            | cat - output/hva_comp_$centrale.csv > temp && mv temp output/hva_comp_$centrale.csv
        else
            sort -t':' -k2,2n tmp/hva_AFTER_C.csv > output/hva_comp.csv
            echo "Résultat final : output/hva_comp.csv"
 	    echo "HVA:Capacité:Consommation (entreprises)" | cat - output/hvb_comp.csv > temp && mv temp output/hvb_comp.csv

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
            sort -t':' -k2,2n tmp/lv_comp_APRES_C.csv > output/lv_comp_$centrale.csv
            echo "Résultat final : output/lv_comp_$centrale.csv"
            echo "LV:Capacité:Consommation (entreprises)"\
            | cat - output/lv_comp_$centrale.csv > temp && mv temp output/lv_comp_$centrale.csv
        else
            sort -t':' -k2,2n tmp/lv_comp_APRES_C.csv > output/lv_comp.csv
            echo "Résultat final : output/lv_comp.csv"
            echo "LV:Capacité:Consommation (entreprises)" | cat - output/lv_comp.csv > temp && mv temp output/lv_comp.csv
        fi
    


 elif [[ "$consommateur" == "indiv" ]]
    then
    if [[ -n "$centrale" ]]  # Si une centrale est spécifiée
        then
        awk -v centrale="$centrale" -F';' '
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
            sort -t':' -k2,2n tmp/lv_indiv_APRES_C.csv > output/lv_indiv_$centrale.csv
            echo "Résultat final : output/lv_indiv_$centrale.csv"
            echo "LV:Capacité:Consommation (particuliers)"\
            | cat - output/lv_indiv_$centrale.csv > temp && mv temp output/lv_indiv_$centrale.csv
        else
            sort -t':' -k2,2n tmp/lv_indiv_APRES_C.csv > output/lv_indiv.csv
            echo "Résultat final : output/lv_indiv.csv"
            echo "LV:Capacité:Consommation (particuliers)" | cat - output/lv_indiv.csv > temp && mv temp output/lv_indiv.csv
        fi



    elif [[ "$consommateur" == "all" ]]
    then
   	 if [[ -n "$centrale" ]] 
        then    	 
        awk -v centrale="$centrale" -F';' '
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
        	 sort -t':' -k2,2n tmp/lv_all_APRES_C.csv > output/lv_all_$centrale.csv
       		 echo "Résultat final : output/lv_all_$centrale.csv"
        else
       	 	 sort -t':' -k2,2n tmp/lv_all_APRES_C.csv > output/lv_all.csv
       		 echo "Résultat final : output/lv_all.csv"
        fi

       
input_file_c="tmp/lv_all_top20_$centrale.csv"
input_file="tmp/lv_all_top20.csv"
output_file="output/lv_all_minmax.csv"
output_file_c="output/lv_all_minmax_$centrale.csv"

      


	if [[ -n "$centrale" ]]
        then
        
		sort -t':' -k3,3n tmp/lv_all_APRES_C.csv | head -n 10 > "$input_file_c"
		sort -t':' -k3,3n tmp/lv_all_APRES_C.csv | tail -n 10 >> "$input_file_c"

       		echo "VOICI LES 20 DONT FAUT FAIRE LA DIFF ABSOLUE : tmp/lv_all_top20_$centrale.csv"
	       		
		awk -F: '{diff = ($2 - $3) < 0 ? ($3 - $2) : ($2 - $3); print $1 ":" $2 ":" $3 ":" diff}' "$input_file_c" \
		| sort -t: -k4 -n -r > "$output_file_c"

		echo "Le fichier trié avec la différence absolue : $output_file_c"

		   
        else
        
       		sort -t':' -k3,3n tmp/lv_all_APRES_C.csv | head -n 10 > "$input_file"
		sort -t':' -k3,3n tmp/lv_all_APRES_C.csv | tail -n 10 >> "$input_file"

       		echo "VOICI LES 20 DONT FAUT FAIRE LA DIFF ABSOLUE : tmp/lv_all_top20.csv"
	       		
		awk -F: '{diff = ($2 - $3) < 0 ? ($3 - $2) : ($2 - $3); print $1 ":" $2 ":" $3 ":" diff}' "$input_file" \
		| sort -t: -k4 -n -r > "$output_file"

		echo "Le fichier trié avec la différence absolue : $output_file"
        
        fi
      fi
INPUT_FILE="output/lv_all_minmax.csv"

# Vérification si le fichier existe
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Erreur : Fichier $INPUT_FILE introuvable."
  exit 1
fi

# Extraction des 10 premières stations dans un fichier temporaire
awk -F':' 'NR<=10 {print $1, $4}' "$INPUT_FILE" > top_10_stations.csv

# Extraction des 10 dernières stations dans un fichier temporaire
awk -F':' 'NR>10 {print $1, $4}' "$INPUT_FILE" > bottom_10_stations.csv

# Exécution du script Gnuplot
gnuplot lv.gnu

rm -f top_10_stations.csv bottom_10_stations.csv

      
      

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
