#include "types.h"
#include "param.h"
#include "peterson.h"

// הגדרה גלובלית של מערך המנעולים
struct petersonlock peterson_locks[MAX_PETERSON_LOCKS];

// אתחול כל המנעולים במערכת
void
petersoninit(void)
{
  for (int i = 0; i < MAX_PETERSON_LOCKS; i++) {
    peterson_locks[i].active = 0;
    peterson_locks[i].flag[0] = 0;
    peterson_locks[i].flag[1] = 0;
    peterson_locks[i].turn = 0;
  }
}
