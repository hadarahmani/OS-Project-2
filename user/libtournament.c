#include "user.h"

#define MAX_PROCS 16
#define MAX_LOCKS (MAX_PROCS - 1)

static int proc_index;
static int num_procs;
static int num_levels;
static int locks[MAX_LOCKS];

// Assigned role and lock at each level per process
static int roles[4];
static int lock_idxs[4];

int tournament_create(int n) {
  if (n <= 0 || n > MAX_PROCS || (n & (n - 1)) != 0) {
    return -1; // not a power of 2 or out of bounds
  }
  num_procs = n;
  num_levels = 0;
  while ((1 << num_levels) < n) num_levels++;

  for (int i = 0; i < n - 1; i++) {
    int lid = peterson_create();
    if (lid < 0) return -1;
    locks[i] = lid;
  }

  for (int i = 0; i < n; i++) {
    int pid = fork();
    if (pid < 0) return -1;
    if (pid == 0) {
      proc_index = i;
      for (int l = 0; l < num_levels; l++) {
        int role = (i & (1 << (num_levels - l - 1))) >> (num_levels - l - 1);
        int lock_id = i >> (num_levels - l);
        int arr_idx = ((1 << l) - 1) + lock_id;
        roles[l] = role;
        lock_idxs[l] = arr_idx;
      }

      // Acquire tournament lock
      if (tournament_acquire() == 0) {
        // Safe to print here — only one process holds the lock
        printf("Proc %d got lock as tournament ID %d\n", proc_index, i);
        tournament_release();
      }

      exit(0);
    }
  }

  for (int i = 0; i < n; i++) wait(0);
  exit(0);
}

int tournament_acquire(void) {
  for (int l = 0; l < num_levels; l++) {
    int lock_id = locks[lock_idxs[l]];
    int role = roles[l];
    if (peterson_acquire(lock_id, role) < 0)
      return -1;
  }
  return 0;
}

int tournament_release(void) {
  for (int l = num_levels - 1; l >= 0; l--) {
    int lock_id = locks[lock_idxs[l]];
    int role = roles[l];
    if (peterson_release(lock_id, role) < 0)
      return -1;
    peterson_destroy(lock_id);
  }
  return 0;
}
