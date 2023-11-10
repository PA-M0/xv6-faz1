#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
#include "historyBuffer.h"


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

uint64
sys_history(void)
{
   // struct syshistory *history;

    int historyNum;
    argint(0, &historyNum);
    int err = 0;
//    printf("hellooooo\n");

    int target = 0;
//    printf("[%d]", historyBuf.lastCommandIndex);
    target = historyBuf.lastCommandIndex - historyNum;
//    printf(" targer: %d \n", target);
//    for (int i = 0; i < 16 ; ++i) {
//        for (int j = 0; j < 128 ; ++j) {
//            consputc(historyBuf.bufferArr[i][j]);
//
//        }
//        printf(" ");

       // consputc(historyBuf.bufferArr[5][i]);
//    }
    for (int i = 0; i < 128; ++i) {
        consputc(historyBuf.bufferArr[target-1][i]);

    }








    return err;
}

