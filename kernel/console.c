//
// Console input and output, to the uart.
// Reads are line at a time.
// Implements special input characters:
//   newline -- end of line
//   control-h -- backspace
//   control-u -- kill line
//   control-d -- end of file
//   control-p -- print process list
//

#include <stdarg.h>

#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "fs.h"
#include "file.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"
#include "proc.h"
#include "historyBuffer.h"
//#include "../user/user.h"


#define BACKSPACE 0x100
#define C(x)  ((x)-'@')  // Control-x
#define MAX_HISTORY 16
#define INPUT_BUF_SIZE 128

//
// send one character to the uart.
// called by printf(), and to echo input characters,
// but not from write().
//

struct historyBufferArray historyBuf;
int index = 0;
int row = 0;

void printToConsole(void)
{
//    consputc(historyBufArr.current_cm[index]);
//    for (int i = 0; i < INPUT_BUF_SIZE; ++i) {
//        consputc(historyBufArr.current_cm[i]);
//    }

}
void call_sys_history(void){
    int size = 0;
    for (int i = 0; historyBuf.current_cm[i] != '\n' ; ++i) {
        size++;
    }

    historyBuf.lengthsArr[row] = size;

    for (int i = 0; i < size ; i++) {
        historyBuf.bufferArr[row][i]= historyBuf.current_cm[i];

    }










    row++;
}

void
consputc(int c)
{
  if(c == BACKSPACE){
    // if the user typed backspace, overwrite with a space.
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
  } else {
    uartputc_sync(c);
  }
}

struct {
  struct spinlock lock;
  
  // input
#define INPUT_BUF_SIZE 128
  char buf[INPUT_BUF_SIZE];
  uint r;  // Read index
  uint w;  // Write index
  uint e;  // Edit index
} cons;

//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
  int i;

  for(i = 0; i < n; i++){
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
      break;
    uartputc(c);
  }

  return i;
}

//
// user read()s from the console go here.
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
  uint target;
  int c;
  char cbuf;

  target = n;
  acquire(&cons.lock);
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        cons.r--;
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
      break;

    dst++;
    --n;

    if(c == '\n'){
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);

  return target - n;
}

//
// the console input interrupt handler.
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
  acquire(&cons.lock);



  switch(c){
  case C('P'):  // Print process list.
    procdump();
    break;
  case C('U'):  // Kill line.
    while(cons.e != cons.w &&
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
      cons.e--;
      consputc(BACKSPACE);
    }
    break;
  case C('H'): // Backspace
  case '\x7f': // Delete key
    index--;
    if(cons.e != cons.w){
      cons.e--;
      consputc(BACKSPACE);
    }
    break;
  default:
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
      c = (c == '\r') ? '\n' : c;

      historyBuf.current_cm[index] = c;
      index++;

      // echo back to the user.


      // store for consumption by consoleread().
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;

      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
        // wake up consoleread() if a whole line (or end-of-file)
        // has arrived.
        index = 0;
        call_sys_history();
        historyBuf.lastCommandIndex++;




        cons.w = cons.e;
        wakeup(&cons.r);
      }
    }
    break;
  }




  
  release(&cons.lock);
  //  printf(cons.w);
}

void
consoleinit(void)
{
  initlock(&cons.lock, "cons");

  uartinit();

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
  devsw[CONSOLE].write = consolewrite;
}





//chat GPT=======================================================================
//int sys_history(void) {
//    int historyid;
//    if (argint(0, &historyid) < 0 || historyid < 1 || historyid > historyBuf.numOfCommandsInMem) {
//        return -1;  // Error: Invalid history ID
//    }
//
//    // Calculate the actual index in historyBuf based on historyid
//    int index = (historyBuf.lastCommandIndex - historyid + historyBuf.numOfCommandsInMem) % MAX_HISTORY;
//    if (historyBuf.numOfCommandsInMem <= MAX_HISTORY) {
//        index = (index + 1) % MAX_HISTORY;
//    }
//
//    // Print the requested command
//    cprintf("requested command: %s\n", historyBuf.bufferArr[index]);
//
//    return 0;  // Successful system call execution
//}
