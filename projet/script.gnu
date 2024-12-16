# Définition du terminal
set terminal pngcairo size 1280,720 enhanced font 'Arial,12'
set output 'graphique_stations.png'

# Titre et axes
set title "Production des 20 stations classées avec valeurs négatives et positives" font ",14"
set xlabel "Stations"
set ylabel "Production (unités)"
set grid ytics

# Éviter les puissances de 10 pour l'axe Y
set format y "%g"

# Ajustement des labels et rotation
set xtics rotate by -45
set style data histograms
set style histogram cluster gap 1
set style fill solid 1.00 border -1
set boxwidth 0.9

# Ajustement automatique de la plage de l'axe Y pour inclure les valeurs négatives et positives
set yrange [*:*]

# Lecture des données avec des barres (offre support aux valeurs négatives et positives)
plot "plot_data.dat" using 2:xtic(1) title "" linecolor rgb var

