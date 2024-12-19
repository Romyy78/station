#include "fonction.h"


int min(int a, int b) {
    return (a < b) ? a : b;
}

// Fonction pour trouver le maximum de deux valeurs
int max(int a, int b) {
    return (a > b) ? a : b;
}

// Fonction pour trouver le minimum parmi trois valeurs
int min3(int a, int b, int c) {
    return min(min(a, b), c);
}

// Fonction pour trouver le maximum parmi trois valeurs
int max3(int a, int b, int c) {
    return max(max(a, b), c);
}

// Fonction de rotation gauche pour l'équilibrage de l'AVL
AVL* RotationGauche(AVL* racine) {
    if (racine == NULL || racine->fd == NULL) {
        return racine;
    }

    AVL* pivot = racine->fd;
    int eq_racine = racine->eq;
    int eq_pivot = pivot->eq;

    racine->fd = pivot->fg;
    pivot->fg = racine;

    racine->eq = eq_racine - max(eq_pivot, 0) - 1;
    pivot->eq = min3(eq_racine - 2, eq_racine + eq_pivot - 2, eq_pivot - 1);

    return pivot;
}

// Fonction de rotation droite pour l'équilibrage de l'AVL
AVL* RotationDroite(AVL* racine) {
    if (racine == NULL || racine->fg == NULL) {
        return racine;
    }

    AVL* pivot = racine->fg;
    int eq_racine = racine->eq;
    int eq_pivot = pivot->eq;

    racine->fg = pivot->fd;
    pivot->fd = racine;

    racine->eq = eq_racine - min(eq_pivot, 0) + 1;
    pivot->eq = max3(eq_racine + 2, eq_racine + eq_pivot + 2, eq_pivot + 1);

    return pivot;
}

// Fonction de création d'un nouveau nœud AVL
AVL* creation(int id, unsigned long  capacite, unsigned long  conso) {
    AVL* new = (AVL*)malloc(sizeof(AVL));

    if (new == NULL) {
        printf("Erreur d'allocation de mémoire.\n");
        exit(1);
    }

    new->station_id = id;
    new->capacité = capacite;
    new->consommateur = conso;
    new->fg = NULL;
    new->fd = NULL;
    new->eq = 0;

    return new;
}

// Fonction de double rotation droite pour équilibrer l'arbre
AVL* DoubleRotationDroite(AVL* A) {
    A->fg = RotationGauche(A->fg);
    return RotationDroite(A);
}

// Fonction de double rotation gauche pour équilibrer l'arbre
AVL* DoubleRotationGauche(AVL* A) {
    A->fd = RotationDroite(A->fd);
    return RotationGauche(A);
}

// Fonction d'équilibrage de l'arbre AVL
AVL* equilibrerAVL(AVL* A) {
    if (A->eq > 1) {
        if (A->fg->eq < 0) {
            return DoubleRotationDroite(A);  // Double rotation droite si le fils gauche est déséquilibré à gauche
        } else {
            return RotationDroite(A);  // Rotation droite simple
        }
    }
    if (A->eq < -1) {
        if (A->fd->eq > 0) {
            return DoubleRotationGauche(A);  // Double rotation gauche si le fils droit est déséquilibré à droite
        } else {
            return RotationGauche(A);  // Rotation gauche simple
        }
    }
    return A;  // L'arbre est équilibré
}

// Fonction d'insertion dans l'arbre AVL
AVL* insertion(AVL* A, int ID, unsigned long  capa, unsigned long  conso, int* h) {
    if (A == NULL) {
        *h = 1;  // Indicateur de changement de hauteur
        return creation(ID, capa, conso);
    }

    // Insertion dans l'ABR classique
    if (A->station_id > ID) {
        A->fg = insertion(A->fg, ID, capa, conso, h);
        if (*h == 1) A->eq++;  // Insertion dans le sous-arbre gauche
    } 
    else if (A->station_id < ID) {
        A->fd = insertion(A->fd, ID, capa, conso, h);
        if (*h == 1) A->eq--;  // Insertion dans le sous-arbre droit
    } 
    else {
        A->capacité += capa;  // Mise à jour de la capacité si l'élément est déjà dans l'arbre
        A->consommateur += conso;  // Mise à jour de la consommation
        *h = 0;  // Pas de changement de hauteur si l'élément est déjà dans l'arbre
    }

    // Rééquilibrage après insertion
    if (*h != 0) {
        A = equilibrerAVL(A);  // Effectue l'équilibrage du sous-arbre
        if (A->eq == 0) {
            *h = 0;  // L'arbre est équilibré
        } else {
            *h = 1;  // L'arbre a changé de hauteur
        }
    }

    return A;
}

// Fonction de parcours infixe de l'arbre pour afficher les valeurs
void parcourinfixe(AVL* racine) {
    if (racine == NULL) {
        return;
    }
    parcourinfixe(racine->fg);
    printf("%d:%lu:%lu\n", racine->station_id, racine->capacité, racine->consommateur);
    parcourinfixe(racine->fd);
}

// Fonction pour libérer la mémoire de l'arbre
void libererMemoire(AVL* racine) {
    if (racine != NULL) {
        libererMemoire(racine->fg);
        libererMemoire(racine->fd);
        free(racine);
    }
}

