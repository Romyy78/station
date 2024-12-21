# projet

# README

## Instructions pour compiler et utiliser l'application

### Prérequis
- **Système d'exploitation** : Linux/Unix
- **Logiciels nécessaires** :
  - GCC (compilateur C)
  - Make (outil de compilation)
  - Bash (pour exécuter le script Shell)
  - GnuPlot (pour le graphique)

### Exécution
1. Accédez à la racine du projet et mettez IMPERATIVEMENT le fichier a traiter dans le sous dossier input : cd projet
2. Se donner les permissions :
   ``` bash
       chmod +x c-wire.sh
       ```
3. Exécutez le script Shell pour traiter les données :
   
   ./c-wire.sh <chemin_fichier_csv> <type_station> <type_consommateur> [<id_centrale>] [-h]
   
   - **Exemples** :
   - 
     - Pour traiter les stations HV-B avec les entreprises :
       ```bash
       ./c-wire.sh c-wire_v25.dat hvb comp
       ```
     - Pour afficher l'aide :
       ```bash
       ./c-wire.sh -h
       ```
       
4. Les fichiers de sortie seront générés dans le dossier `output/` sous des noms comme `lv_all.csv` ou `lv_all_minmax.csv`.
5. Les graphique seront générés dans le dossier `graphs/` sous le nom `graphs/lv_top_minmax.png`.
6. pour supprimer l'executable et les .o faire : cd codeC puis make clean et enfin cd .. pour retourné au coeur du projet.



## Structure des fichiers
- **input/** : Contient le fichier CSV brut.
- **output/** : Résultats des traitements (ex. `lv_all.csv`, `lv_all_minmax.csv`).
- **codeC/** :
  - Fichiers source C.
  - `Makefile`.
  - Exécutable généré (`main`).
- **tmp/** : Fichiers intermédiaires.
-  **graphs/** : graphique généré.
- **tests/** : Résultats d'execution précedentes.


