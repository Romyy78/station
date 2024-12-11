# Variables
CC = gcc
CFLAGS = -Wall -Wextra -O2
TARGET = c-wire

# Fichiers source et objets
SRC = main.c fonction.c
OBJ = $(SRC:.c=.o)

# Règle par défaut
all: $(TARGET)

# Génération de l'exécutable
$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJ)

# Génération des fichiers objets
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Nettoyage
clean:
	rm -f $(OBJ) $(TARGET)

