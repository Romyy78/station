#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "fonction.h"



int main(int argc, char* argv[]) {

    if (argc != 2) {
        fprintf(stderr, "Usage: %s <fichier_donnees>\n", argv[0]);
        return 1;
    }

    FILE* fichier = fopen(argv[1], "r");
    if (fichier == NULL) {
        perror("Erreur lors de l'ouverture du fichier");
        return 1;
    }

    AVL* racine = NULL;

    char ligne[1000]; 

    while (fgets(ligne, sizeof(ligne), fichier) != NULL) {
        int id;
        unsigned long  capacité;
        unsigned long  consommation;
        if (sscanf(ligne, "%d;%lu;%lu", &id, &capacité, &consommation) != 3) {
            fprintf(stderr, "Erreur de lecture de la ligne : %s\n", ligne);
            continue; // Ignorer la ligne incorrecte et passer à la suivante
        }

        int hauteur = 0; 
        racine = insertion(racine, id, capacité, consommation, &hauteur);
    }

    parcourinfixe(racine);

    fclose(fichier);

    libererMemoire(racine);

    return 0;
}
