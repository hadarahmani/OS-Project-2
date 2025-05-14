#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "syscall.h"
#include "peterson.h"


extern struct petersonlock peterson_locks[MAX_PETERSON_LOCKS];

uint64
sys_peterson_create(void)
{
  for (int i = 0; i < MAX_PETERSON_LOCKS; i++) {
    if (!peterson_locks[i].active) {
      peterson_locks[i].active = 1;
      __sync_synchronize();
      return i;
    }
  }
  return -1;
}

uint64
sys_peterson_acquire(void)
{
  int lock_id;
  int role;

  argint(0, &lock_id);
  argint(1, &role);

  struct petersonlock *lock = &peterson_locks[lock_id];

  __sync_lock_test_and_set(&lock->flag[role], 1);
  __sync_synchronize();
  lock->turn = 1 - role;
  __sync_synchronize();

  while (lock->flag[1 - role] && lock->turn == 1 - role) {
    yield();
  }

  return 0;
}

uint64
sys_peterson_release(void)
{
  int lock_id;
  int role;

  argint(0, &lock_id);
  argint(1, &role);

  struct petersonlock *lock = &peterson_locks[lock_id];

  __sync_lock_release(&lock->flag[role]);
  __sync_synchronize();

  return 0;
}

uint64
sys_peterson_destroy(void)
{
  int lock_id;

  argint(0, &lock_id);

  peterson_locks[lock_id].active = 0;
  __sync_synchronize();

  return 0;
}


uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}
