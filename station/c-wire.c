#include <stdio.h>
#include <stdlib.h>
#include <time.h>

typedef struct noeud {
    int station_id;              // Identifiant unique de la station
    double capacité;              // Capacité de la station en MW 
    double consommateur;           // somme des valeurs de consommation 
    struct noeud* gauche;        // Pointeur vers le sous-arbre gauche
    struct noeud* droite;       // Pointeur vers le sous-arbre droit
    int hauteur;                  // Hauteur du nœud pour l'équilibre de l'AVL
} noeud;

int hauteur(noeud* noeud) {
    return (noeud == NULL) ? 0 : noeud->hauteur;
}

int max(int a, int b) {
    return (a > b) ? a : b;
}

noeud* rotationGauche(noeud* y) {
    if (y == NULL || y->droite == NULL) {
        return y;
    }

    noeud* x = y->droite;
    noeud* T2 = x->gauche;

    x->gauche = y;
    y->droite = T2;

    y->hauteur = 1 + max(hauteur(y->gauche), hauteur(y->droite));
    x->hauteur = 1 + max(hauteur(x->gauche), hauteur(x->droite));

    return x;
}

noeud* rotationDroite(noeud* x) {
    if (x == NULL || x->gauche == NULL) {
        return x;
    }

    noeud* y = x->gauche;
    noeud* T2 = y->droite;

    y->droite = x;
    x->gauche = T2;

    x->hauteur = 1 + max(hauteur(x->gauche), hauteur(x->droite));
    y->hauteur = 1 + max(hauteur(y->gauche), hauteur(y->droite));

    return y;
}

int getEquilibre(noeud* noeud) {
    return (noeud == NULL) ? 0 : hauteur(noeud->gauche) - hauteur(noeud->droite);
}

noeud* insertion(noeud* racine, int ID, float capa, float conso) {
    if (racine == NULL) {
        noeud* nouveau_noeud = malloc(sizeof(noeud));
        if (nouveau_noeud == NULL) {
            fprintf(stderr, "Erreur d'allocation de mémoire.\n");
            exit(EXIT_FAILURE);
        }

        nouveau_noeud->station_id = ID;
        nouveau_noeud->capacité = capa;
        nouveau_noeud->consommateur = conso;
        nouveau_noeud->gauche = NULL;
        nouveau_noeud->droite = NULL;
        nouveau_noeud->hauteur = 1;
        return nouveau_noeud;
    }

    if (racine->station_id == ID) {  // Correction de l'assignation `=`
        racine->capacité = racine->capacité + capa;
        racine->consommateur = racine->consommateur + conso;
    } else {
        if (racine->station_id > ID) {
            racine->gauche = insertion(racine->gauche, ID, capa, conso);
        } else {
            racine->droite = insertion(racine->droite, ID, capa, conso);
        }
        racine->hauteur = 1 + max(hauteur(racine->gauche), hauteur(racine->droite));

        int equilibre = getEquilibre(racine);

        // Cas de l'équilibre positif
        if (equilibre > 1) {
            if (ID < racine->station_id) {
                return rotationDroite(racine);
            } else {
                racine->gauche = rotationGauche(racine->gauche);
                return rotationDroite(racine);
            }
        }

        // Cas de l'équilibre négatif
        if (equilibre < -1) {
            if (ID > racine->station_id) {
                return rotationGauche(racine);
            } else {
                racine->droite = rotationDroite(racine->droite);
                return rotationGauche(racine);
            }
        }
    }

    return racine;
}

void parcourinfixe(noeud* racine) {
    if (racine == NULL) {
        return;  // Ne rien faire si l'arbre est vide
    }
    parcourinfixe(racine->gauche);
    printf("%d:%f:%f:\n", racine->station_id, racine->capacité, racine->consommateur);
    parcourinfixe(racine->droite);
}

void libererMemoire(noeud* racine) {
    if (racine != NULL) {
        libererMemoire(racine->gauche);
        libererMemoire(racine->droite);
        free(racine);
    }
}

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

    noeud* racine = NULL;

    char ligne[1000]; // Vous pouvez ajuster cette taille en fonction de vos besoins

    while (fgets(ligne, sizeof(ligne), fichier) != NULL) {
        int id;
        double capacité;
        double consommation;
        if (sscanf(ligne, "%d;%lf;%lf", &id, &capacité, &consommation) != 3) {
            fprintf(stderr, "Erreur de lecture de la ligne : %s\n", ligne);
            continue; // Ignorer la ligne incorrecte et passer à la suivante
        }

        racine = insertion(racine, id, capacité, consommation);
    }

    parcourinfixe(racine);

    fclose(fichier);

    libererMemoire(racine);

    return 0;
}


