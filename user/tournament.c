#include "user.h"

extern int proc_index;

int main(int argc, char *argv[]) {
  if (argc != 2) {
    printf("Usage: tournament N\n");
    exit(1);
  }

  int n = atoi(argv[1]);
  int tid = tournament_create(n);
  if (tid < 0) {
    printf("Failed to create tournament\n");
    exit(1);
  }

  if (tournament_acquire() == 0) {
    printf("PID %d got lock as tournament ID %d\n", proc_index, tid);
    tournament_release();
  }

  exit(0);
}
