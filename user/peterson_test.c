#include "kernel/types.h"
#include "user/user.h"

// משתנה משותף - אין שמירה אמיתית על שיתוף, אך זה מספיק לזיהוי תקלות גסות
volatile int in_cs[2] = {0, 0};

int
main(void)
{
  int lock_id = peterson_create();
  if (lock_id < 0) {
    printf("Failed to create Peterson lock\n");
    exit(1);
  }

  int pid = fork();
  int role = (pid > 0) ? 0 : 1;  // Parent = 0, Child = 1

  for (int i = 0; i < 5; i++) {
    peterson_acquire(lock_id, role);

    // בדיקה אם שניהם נכנסו לסקשן הקריטי
    if (in_cs[0] && in_cs[1]) {
      printf("❌ BUG: both processes in critical section!\n");
      exit(1);
    }

    in_cs[role] = 1;

    // סקשן קריטי אמיתי
    printf("✅ Role %d (PID %d) in critical section [iteration %d]\n", role, getpid(), i);
    sleep(10);  // Simulate work

    in_cs[role] = 0;

    peterson_release(lock_id, role);
    sleep(5);  // simulate work outside critical section
  }

  if (pid > 0) {
    wait(0);
    peterson_destroy(lock_id);
    printf("✔️ Parent destroyed Peterson lock\n");
  }

  exit(0);
}
