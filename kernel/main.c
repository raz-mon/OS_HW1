
#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"

int a = 0;
#ifdef SJF
a = 1
// scheduler_sjf();
#endif
#ifdef FCFS
a = 2;
// schduler_fcfs();
#endif
#ifdef DEFAULT
a = 3;
// scheduler();
#endif

#ifdef SCHEDFLAG
a = 4;
#endif


volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
  if(cpuid() == 0){
    consoleinit();
    printfinit();
    printf("\n");
    printf("xv6 kernel is booting\n");
    printf("\n");
    kinit();         // physical page allocator
    kvminit();       // create kernel page table
    kvminithart();   // turn on paging
    procinit();      // process table
    trapinit();      // trap vectors
    trapinithart();  // install kernel trap vector
    plicinit();      // set up interrupt controller
    plicinithart();  // ask PLIC for device interrupts
    binit();         // buffer cache
    iinit();         // inode table
    fileinit();      // file table
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
      ;
    __sync_synchronize();
    printf("hart %d starting\n", cpuid());
    kvminithart();    // turn on paging
    trapinithart();   // install kernel trap vector
    plicinithart();   // ask PLIC for device interrupts
  }

  #ifdef SCHEDFLAG
  print("policy known..\n");
  #endif

  #ifdef SJF
  print("entering shceduler_sjf()\n");
  // scheduler_sjf();
  #endif

  #ifdef FCFS
  print("entering shceduler_fcfs()\n");
  // schduler_fcfs();
  #endif

  #ifdef DEFAULT
  print("entering shceduler()\n");
  // scheduler();
  #endif



  #if 1
  printf("party rock\n");
  #endif

  printf("a is : %d\n", a);
  printf("entering scheduler..........\n");
  scheduler();

  

  
}
