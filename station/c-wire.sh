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
if [[ "$#" -lt 3 ]]; then
    echo "Erreur : Au moins 3 paramètres obligatoires sont nécessaires."
    echo "Utilisez -h pour afficher l'aide."
    exit 1
fi

# Récupération des paramètres
fichier="$1"
station="$2"
consommateur="$3"
centrale="${4:-}" # Optionnel : valeur par défaut vide

# Vérification du fichier d'entrée
if [[ ! -f "$fichier" ]]; then
    echo "Erreur : Le fichier '$fichier' est introuvable."
    exit 1
fi

# Vérification des valeurs pour type de station
if [[ "$station" != "hvb" && "$station" != "hva" && "$station" != "lv" ]]; then
    echo "Erreur : Le type de station '$station' est invalide. Valeurs possibles : hvb, hva, lv."
    exit 1
fi

# Vérification des valeurs pour type de consommateur
if [[ "$consommateur" != "comp" && "$consommateur" != "indiv" && "$consommateur" != "all" ]]; then
    echo "Erreur : Le type de consommateur '$consommateur' est invalide. Valeurs possibles : comp, indiv, all."
    exit 1
fi

# Vérification des combinaisons interdites
if [[ "$station" == "hvb" && ("$consommateur" == "all" || "$consommateur" == "indiv") ]] || \
   [[ "$station" == "hva" && ("$consommateur" == "all" || "$consommateur" == "indiv") ]]; then
    echo "Erreur : La combinaison '$station' et '$consommateur' est interdite."
    exit 1
fi

# Traitement principal
echo "Traitement en cours..."
echo "  Fichier d'entrée         : $fichier"
echo "  Type de station          : $station"
echo "  Type de consommateur     : $consommateur"
if [[ -n "$centrale" ]]; then
    echo "  Identifiant de centrale  : $centrale"
else
    echo "  Pas d'identifiant de centrale spécifié, traitement global."
fi

# Compilation de c-wire
CWIRE_SOURCE="c-wire.c"
CWIRE_BINARY="./c-wire"

echo "Compilation de c-wire..."
if [ ! -f "$CWIRE_SOURCE" ]; then
    echo "Erreur : Le fichier source $CWIRE_SOURCE est introuvable."
    exit 1
fi

gcc -o "$CWIRE_BINARY" "$CWIRE_SOURCE"
if [ $? -ne 0 ]; then
    echo "Erreur : Échec de la compilation de c-wire."
    exit 1
fi
echo "Compilation réussie."

# Création du dossier tmp et nettoyage
mkdir -p tmp
rm -f tmp/*

# Enregistrement du début du traitement
start_time=$(date +%s)

# Lancement du traitement
echo "Traitement en cours pour le type de station '$station' et consommateur '$consommateur'..."

case $station in
    hvb)
        if [[ "$consommateur" == "comp" ]]; then
            awk -F';' '
    $2 != "-" && $3 == "-" && $4 == "-" && $6 == "-" {
        gsub(/-/, "0", $7); gsub(/-/, "0", $8);
        print $2 ";" $7 ";" $8
    }
' "$fichier" > tmp/hvb_comp.dat
            echo "Résultat : tmp/hvb_comp.dat"
            "$CWIRE_BINARY" tmp/hvb_comp.dat > tmp/hvb_result.dat
            echo "Résultat final : tmp/hvb_result.dat"
        fi
        ;;
    hva)
        if [[ "$consommateur" == "comp" ]]; then
            awk -F';' '
                $3 != "-"  && $6 == "-" {
                    gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                    print $3 ";" $7 ";" $8
                }' "$fichier" > tmp/hva_comp.dat
            echo "Résultat : tmp/hva_comp.dat"
        fi
        ;;
    lv)
        case $consommateur in
            comp)
                awk -F';' '
                    $4 != "-"  && $6 == "-" {
                        gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                        print $4 ";" $7 ";" $8
                    }' "$fichier" > tmp/lv_comp.dat
                echo "Résultat : tmp/lv_comp.dat"
                ;;
            indiv)
                awk -F';' '
                    $4 != "-" && $5 == "-" {
                        gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                        print $4 ";" $7 ";" $8
                    }' "$fichier" > tmp/lv_indiv.dat
                echo "Résultat : tmp/lv_indiv.dat"
                ;;
            all)
                awk -F';' '
                    $4 != "-"  {
                        gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                        print $4 ";" $7 ";" $8
                    }' "$fichier" > tmp/lv_all.dat
                echo "Résultat : tmp/lv_all.dat"
                ;;
        esac
        ;;
    *)
        echo "Erreur : Type de station invalide."
		echo "tapez -h pour l'aide"
        ;;
esac

# Enregistrement de la fin du traitement
end_time=$(date +%s)
execution_time=$((end_time - start_time))

# Affichage de la durée
echo "Durée du traitement : ${execution_time} secondes."

exit 0


