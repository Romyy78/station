elif [[ "$station" == "lv" ]]
then
    if [[ "$consommateur" == "comp" ]]
    then
        if [[ -n "$centrale" ]]  # Si une centrale est spécifiée
        then
            # Filtrage par centrale et traitement
            awk -v centrale="$centrale" -F';' '
                $4 == centrale && $6 == "-" {
                    gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                    print $4 ";" $7 ";" $8
                }
            ' "$fichier" > tmp/lv_comp_$centrale.dat
            echo "Résultat pour centrale spécifiée : tmp/lv_comp_$centrale.dat"
        else
            # Si aucune centrale n'est spécifiée, on prend tout le fichier
            awk -F';' '
                $4 != "-" && $6 == "-" {
                    gsub(/-/, "0", $7); gsub(/-/, "0", $8);
                    print $4 ";" $7 ";" $8
                }
            ' "$fichier" > tmp/lv_comp.dat
            echo "Résultat sans centrale spécifiée : tmp/lv_comp.dat"
        fi

        # Compilation avec c-wire
        "$CWIRE_BINARY" tmp/lv_comp_$centrale.dat > tmp/lv_comp_result.csv
        echo "Résultat final : tmp/lv_comp_result.csv"

        # Tri de tmp/lv_comp_result.csv par la deuxième colonne (en croissant)
        sort -t':' -k2,2n tmp/lv_comp_result.csv > tmp/lv_comp_result_sorted.csv
        echo "Résultat trié : tmp/lv_comp_result_sorted.csv"
    fi

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

else
    echo "Erreur : Type de station invalide."
    echo "Utilisez -h pour afficher l'aide."
fi

