#ifndef PETERSONLOCK_H
#define PETERSONLOCK_H

#define MAX_PETERSON_LOCKS 15

struct petersonlock {
  int active;
  volatile int flag[2];
  volatile int turn;
};

#endif
