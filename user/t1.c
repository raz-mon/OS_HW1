#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"


void example_pause_system(int interval, int pause_seconds, int loop_size) {
    int n_forks = 2;
    for (int i = 0; i < n_forks; i++) {
    	fork();
    }
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2){
            pause_system(pause_seconds);
        }
    }
    printf("\n");
}

void example_kill_system(int interval, int loop_size) {
    int n_forks = 2;
    for (int i = 0; i < n_forks; i++) {
    	fork();
    }
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2){
            kill_system();
        }
    }
    printf("\n");
}

int main(){
<<<<<<< HEAD
  example_kill_system(5, 10);
  print_stats();
  // sleep(50);

  // example_pause_system(2, 4, 3);

    return 1;
=======
  example_pause_system(10, 3, 100);
  example_kill_system(10, 100);
  exit(0);
>>>>>>> 16a362093766c74b1cb38788e205d9d7abb74b25
}
