#include "user.h"

int main(int argc, char *argv[]) {
  if (argc != 2) {
    printf("Usage: tournament N\n");
    exit(1);
  }

  int n = atoi(argv[1]);
  if (tournament_create(n) < 0) {
    printf("Failed to create tournament\n");
    exit(1);
  }

  exit(0);
}
