set terminal png size 1024,768
set output 'graphs/lv_top_minmax.png'

set style data histograms
set style histogram clustered gap 1
set style fill solid 1.0 border -1

set boxwidth 0.7

set xtics rotate by -45
set xlabel "Stations (ID)"
set ylabel "Différence en kWh"

set title "Production des stations (10 les plus élevées en rouge, 10 les plus faibles en vert)"

set datafile separator ":"


# Utiliser la colonne 1 pour les abscisses, la colonne 4 pour les ordonnées, et la colonne 5 pour les couleurs
plot 'tmp/lv_all_minmax_grouped.csv' using 5:xtic(1) title 'top 10 LV max' with boxes lc rgb "red", \
     'tmp/lv_all_minmax_grouped.csv' using 6:xtic(1) title 'top 10 LV min' with boxes lc rgb "blue"
