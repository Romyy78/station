
# Lancement du traitement
echo "Traitement en cours pour le type de station '$station' et consommateur '$consommateur'..."
if [[ "$station" == "hvb" ]]
then
    if [[ "$consommateur" == "comp" ]]
    then
        awk -F';' '
            $2 != "-" && $3 == "-" && $4 == "-" && $6 == "-" {
                gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                print $2 ";" $7 ";" $8
            }
        ' "$fichier" > tmp/hvb_comp.dat
        echo "Résultat : tmp/hvb_comp.dat"
        "$CWIRE_BINARY" tmp/hvb_comp.dat > tmp/hvb_result.csv
        echo "Résultat final : tmp/hvb_result.csv"

        # Tri de tmp/hvb_result.csv par la deuxième colonne (en croissant) en utilisant ':' comme séparateur
        sort -t':' -k2,2n tmp/hvb_result.csv > tmp/hvb_resultat_trier.csv
        echo "Résultat trié : tmp/hvb_result_sorted.csv"
    fi

elif [[ "$station" == "hva" ]]
then
    if [[ "$consommateur" == "comp" ]]
    then
        awk -F';' '
            $3 != "-"  && $6 == "-" && $4 == "-" {
                gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                print  $3 ";" $7 ";" $8 
            }
        ' "$fichier" > tmp/hva_comp.dat
        echo "Résultat : tmp/hva_comp.csv"
        "$CWIRE_BINARY" tmp/hva_comp.dat > tmp/hva_result.csv
        echo "Résultat final : tmp/hva_result.csv"

        # Tri de tmp/hva_result.csv par la deuxième colonne (en croissant) en utilisant ':' comme séparateur
        sort -t':' -k2,2n tmp/hva_result.csv > tmp/hva_result_sorted.csv
        echo "Résultat trié : tmp/hva_result_sorted.csv"
    fi

elif [[ "$station" == "lv" ]]
then
    if [[ "$consommateur" == "comp" ]]
    then
        awk -F';' '
            $4 != "-"  && $6 == "-" {
                gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                print $4 ";" $7 ";" $8
            }
        ' "$fichier" > tmp/lv_comp.dat
        echo "Résultat : tmp/lv_comp.csv"
        "$CWIRE_BINARY" tmp/lv_comp.dat > tmp/lv_comp_result.csv
        echo "Résultat final : tmp/lv_comp_result.csv"

        # Tri de tmp/lv_comp_result.csv par la deuxième colonne (en croissant) en utilisant ':' comme séparateur
        sort -t':' -k2,2n tmp/lv_comp_result.csv > tmp/lv_comp_result_sorted.csv
        echo "Résultat trié : tmp/lv_comp_result_sorted.csv"

    elif [[ "$consommateur" == "indiv" ]]
    then
        awk -F';' '
            $4 != "-" && $5 == "-" {
                gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                print $4 ";" $7 ";" $8
            }
        ' "$fichier" > tmp/lv_indiv.dat
        echo "Résultat : tmp/lv_indiv.csv"
        "$CWIRE_BINARY" tmp/lv_indiv.dat > tmp/lv_indiv_result.csv
        echo "Résultat final : tmp/lv_indiv_result.csv"

        # Tri de tmp/lv_indiv_result.csv par la deuxième colonne (en croissant) en utilisant ':' comme séparateur
        sort -t':' -k2,2n tmp/lv_indiv_result.csv > tmp/lv_indiv_result_sorted.csv
        echo "Résultat trié : tmp/lv_indiv_result_sorted.csv"

    elif [[ "$consommateur" == "all" ]]
    then
        awk -F';' '
            $4 != "-" && $2 == "-" {
                gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                print $4 ";" $7 ";" $8
            }
        ' "$fichier" > tmp/lv_all.dat
        echo "Résultat : tmp/lv_all.dat"
        "$CWIRE_BINARY" tmp/lv_all.dat > tmp/lv_all_result.csv
        echo "Résultat final : tmp/lv_all_result.csv"

        # Tri de tmp/lv_all_result.csv par la deuxième colonne (en croissant) en utilisant ':' comme séparateur
        sort -t':' -k3,3n tmp/lv_all_result.csv > tmp/lv_all_result_sorted.csv
        echo "Résultat trié : tmp/lv_all_result_sorted.csv"

        # Sélection des 10 postes avec la plus grande consommation (les 10 derniers en triant par ordre croissant)
tail -n 10 tmp/lv_all_result_sorted.csv | sort -t':' -k3,3nr > tmp/lv_all_max.csv

        echo "Top 10 postes avec la plus grande consommation : tmp/lv_all_max.csv"

        # Sélection des 10 postes avec la plus faible consommation (les 10 premiers)
        head -n 10 tmp/lv_all_result_sorted.csv > tmp/lv_all_min.csv
        echo "Top 10 postes avec la plus faible consommation : tmp/lv_all_min.csv"

        # Fusionner les résultats dans un fichier final lv_all_minmax.csv
        cat tmp/lv_all_min.csv tmp/lv_all_max.csv > tmp/lv_all_minmax.csv
        echo "Résultats min et max fusionnés dans : tmp/lv_all_minmax.csv"
    fi





else
    echo "Erreur : Type de station invalide."
    echo "Utilisez -h pour afficher l'aide."
fi

