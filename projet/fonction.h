#ifndef fonction_h
#define fonction_h

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

typedef struct AVL {
    int station_id;              // Identifiant unique de la station
    unsigned long  capacité;             // Capacité de la station en MW
    unsigned long  consommateur;         // Somme des valeurs de consommation
    struct AVL* fg;              // Pointeur vers le sous-arbre gauche
    struct AVL* fd;              // Pointeur vers le sous-arbre droit
    int eq;                      // Facteur d'équilibre (différence de hauteur entre sous-arbre gauche et droit)
} AVL;

int min(int a, int b);
int max(int a, int b); 
int min3(int a, int b, int c); 
int max3(int a, int b, int c); 
AVL* RotationGauche(AVL* racine);
AVL* RotationDroite(AVL* racine);
AVL* creation(int id, unsigned long capacite, unsigned long  conso);
AVL* DoubleRotationDroite(AVL* A);
AVL* DoubleRotationGauche(AVL* A);
AVL* equilibrerAVL(AVL* A);
AVL* insertion(AVL* A, int ID, unsigned long  capa, unsigned long  conso, int* h); 
void parcourinfixe(AVL* racine);
void libererMemoire(AVL* racine);


#endif

