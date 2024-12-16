set terminal png size 1024,768
set output 'graphs/lv_bar_chart.png'

set style data histograms
set style histogram clustered gap 1
set style fill solid 1.0 border -1

set boxwidth 0.9
set xtics rotate by -45

set xlabel "Stations (IDs)"
set ylabel "Différence en kWh"
set title "Production des stations (10 les plus élevées en rouge, 10 les plus faibles en vert)"

# Couleurs des 10 premières et 10 dernières
plot 'top_10_stations.csv' using 2:xtic(1) title 'Stations élevées' linecolor rgb "red", \
     'bottom_10_stations.csv' using 2:xtic(1) title 'Stations faibles' linecolor rgb "green"

